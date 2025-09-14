//
//  StoreViewModel.swift
//  InAppPurchasePlayground
//
//  Created by 강건 on 9/10/25.
//

import Foundation
import StoreKit

@MainActor
final class StoreViewModel: ObservableObject {
    /// 소모성 상품 목록
    @Published private(set) var consumableProducts: [Product]
    
    /// 비소모성 상품 목록
    @Published private(set) var nonConsumableProducts: [Product]
    
    /// 구독형 상품 목록
    @Published private(set) var subscriptionProducts: [Product]
    
    /// 구매한 상품 목록 (비소모성 상품)
    @Published private(set) var purchasedNonConsumableProducts: [Product] = []
    
    /// 구매한 상품 목록 (소모성 상품)
    @Published private(set) var purchasedConsumableProducts: [String: Int] = [:]
    
    /// 구매한 상품 목록 (구독형 상품)
    @Published private(set) var purchasedSubscriptionProducts: [Product] = []
    
    /// 트랜색션 관리를 위한 변수
    // Task<Success, Failure>로 선언하기 때문에,
    // 성공하면 Void, 실패 시 Error를 던지는 옵셔널 Task 타입
    var updateListenerTask: Task<Void, Error>? = nil
    
    /// plist에서 불러온 Product ID와 Emoji 딕셔너리
    let productIdToEmoji: [String: String]
    
    init() {
        consumableProducts = []
        nonConsumableProducts = []
        subscriptionProducts = []
        
        // plist에서  Product ID와 Emoji 딕셔너리 가져오기
        // requestProducts 함수에서 ID로 프로덕트를 찾을 때 사용
        productIdToEmoji = StoreViewModel.loadProductIdToEmojiData()
        
        // 로컬에서 소모성 상품 구매 이력 불러오기
        loadConsumableProductsFromLocal()
        
        // 트랜색션 감지 시작
        // listenForTransactions의 비동기 시퀀스 Task 실행
        updateListenerTask = listenForTransactions()
        
        Task {
            // AppStore에서 상품 가져오기
            await requestProducts()
            // 기존 구매 이력 복원
            await restorePurchases()
        }
    }
    
    deinit {
        // Task 명시적 중단 (메모리 누수 방지)
        updateListenerTask?.cancel()
    }
    
    /// plist를 이용하여 Product ID와 상품에 해당하는 이모지 딕셔너리로 불러오기
    /// Init 시점에 사용하기 위해 static으로 만든듯하다.
    static private func loadProductIdToEmojiData() -> [String: String] {
        // plist 경로
        guard let path = Bundle.main.path(forResource: "Products", ofType: "plist"),
              // plist 파일
              let plist = FileManager.default.contents(atPath: path),
              // PropertyListSerialization => plist 파일(바이너리 형태의 Data)을 Swift 객체로 변환해주는 함수
              let data = try? PropertyListSerialization.propertyList(from: plist, format: nil) as? [String : String] else {
            return [:]
        }
        
        return data
    }
    
    /// AppStore에서 Product 불러오기
    private func requestProducts() async {
        do {
            let storeProducts = try await Product.products(for: productIdToEmoji.keys)
            
            var tempConsumableProductList: [Product] = []
            var tempNonConsumableProducts: [Product] = []
            var tempSubscriptionProducts: [Product] = []
            
            for product in storeProducts {
                switch product.type {
                case .consumable:
                    tempConsumableProductList.append(product)
                case .nonConsumable:
                    tempNonConsumableProducts.append(product)
                case .autoRenewable:
                    tempSubscriptionProducts.append(product)
                default:
                    print("Error")
                }
            }
            
            // 가격 오름차순으로 정렬
            tempConsumableProductList.sort { $0.price < $1.price }
            tempNonConsumableProducts.sort { $0.price < $1.price }
            tempSubscriptionProducts.sort { $0.price < $1.price }
            
            consumableProducts = tempConsumableProductList
            nonConsumableProducts = tempNonConsumableProducts
            subscriptionProducts = tempSubscriptionProducts
        } catch {
            print("Error")
        }
    }
    
    /// 트랜색션 업데이트를 감시하는 함수
    // 백그라운드(Task.detached)에서 비동기 시퀀스(for await...in)로,
    // 결제가 완료되거나 실패하는 이벤트가 발생하는지 감시한다.
    private func listenForTransactions() -> Task<Void, Error> {
        // Task.detached => 백그라운드에서 Task 작업 실행.
        return Task.detached {
            // (1) for await ... in
            // 비동기 스트림에서 이벤트가 올 때마다 처리하는 루프
            // 새 이벤트가 발생할때까지 중단 -> 이벤트가 발생하면 코드 실행 -> 다시 대기
            
            // (2) Transaction.updates
            // StoreKit은 Transaction 타입으로 사용자의 구매 요청 - 결과까지 추적해서 제공해준다.
            // Transaction.updates => Transaction이 제공하는 AsyncSequece (비동기 시퀀스)
            // result로 검증되지 않은 트랜잭션(VerificationResult<Transaction>)을 내보낸다
            for await result in Transaction.updates {
                do {
                    // 이벤트 발생(거래 시도) => 검증 시도
                    let transaction = try await self.checkVerified(result)
                    
                    // 상품 구매 결과 로컬에 저장
                    if let product = await self.findProduct(by: transaction.productID) {
                        await self.updatePurchase(product: product, transaction: transaction)
                    }
                    
                    // 해당 트랜색션 종료 (App Store에 완료 처리 완료를 알림)
                    // 트랜색션을 통해 앱스토어 서버 - 프로덕트의 교차 검증하는 느낌
                    await transaction.finish()
                } catch {
                    print("Error")
                }
            }
        }
    }
    
    /// Apple의 디지털 서명을 검증하는 보안 함수
    /// - NOTE: 진짜로 애플에서 발급한 것인지 확인 (위조, 중간 공격 등을 방지)
    // VerificationResult<T> 타입을 받고 있다.
    // VerificationResult는 Transaction.updates의 result로 받아올 수 있다.
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
            // 검증되지 않았다면 => 에러 던짐
        case .unverified:
            throw StoreKitError.unknown
            // 검증되었다면 => 받았던 제너릭 타입 <T>를 반환
        case .verified(let safe):
            return safe
        }
    }
    
    /// 특정 프로덕트의 구매 요청을 하는 함수
    func purchase(product: Product) async throws -> Transaction? {
        // 구매 요청 => 결과값을 받아온다.
        let result = try await product.purchase()
        
        // 받아온 결과값에 따라 처리 (트랜색션 처리로 이어진다.)
        switch result {
        case .success(let verification):
            // 트랜색션 검증
            let transaction = try checkVerified(verification)
            
            // 구매 완료 시 상품을 목록에 추가
            await updatePurchase(product: product, transaction: transaction)
            
            // 트랜색션 종료
            await transaction.finish()
            
            return transaction
            // 취소, 완료되지 않은 상태일 때(승인 대기, 결제 수단 문제 등)
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }
    
    
    // MARK: - Purchase History Management
    
    /// 구매 완료 시 상품을 구매 목록에 추가하는 함수 (로컬 업데이트)
    private func updatePurchase(product: Product, transaction: Transaction) async {
        switch product.type {
        case .nonConsumable:
            // 비소모성 상품은 purchasedProducts에 추가 (중복 방지)
            if !purchasedNonConsumableProducts.contains(where: { $0.id == product.id }) {
                purchasedNonConsumableProducts.append(product)
            }
        case .consumable:
            // 소모성 상품은 구매 Count 추가 후 저장(실제 환경에서는 Count를 서버에 저장할 것!)
            let currentCount = purchasedConsumableProducts[product.id] ?? 0
            purchasedConsumableProducts[product.id] = currentCount + 1
            
            // UserDefaults에 저장
            saveConsumableProductsToLocal()
        case .autoRenewable:
            // 구독 상품은 purchasedSubscriptionProducts에 추가 (중복 방지)
            if !purchasedSubscriptionProducts.contains(where: { $0.id == product.id }) {
                purchasedSubscriptionProducts.append(product)
            }
        default:
            break
        }
    }
    
    /// 구매 이력을 불러오는 함수 (앱스토어에서 불러옴)
    /// - Warning: 소모성 상품의 경우, 구매 내역을 제공해주지 않기 때문에 실제 환경에서는 반드시 구매 내역을 서버에 저장하는 과정이 필요합니다.
    private func restorePurchases() async {
        // Transaction.currentEntitlements를 통해 현재 유효한 구매 내역 확인
        // 앱스토어에서 유효한 구매 내역을 가져옴
        for await result in Transaction.currentEntitlements {
            do {
                // 트랜잭션 검증
                // Transaction.currentEntitlements로 불러온 목록이라도,
                // 보안상 실제로 Apple에서 발급한 것인지 다시 확인 (위조 방지)
                let transaction = try checkVerified(result)
                
                // 해당 상품 찾기
                if let product = findProduct(by: transaction.productID) {
                    switch product.type {
                    case .nonConsumable:
                        // 구매한 목록에 추가 (비소모성 상품)
                        if !purchasedNonConsumableProducts.contains(where: { $0.id == product.id }) {
                            purchasedNonConsumableProducts.append(product)
                        }
                    case .autoRenewable:
                        // 구매한 목록에 추가 (구독형 상품)
                        if !purchasedSubscriptionProducts.contains(where: { $0.id == product.id }) {
                            purchasedSubscriptionProducts.append(product)
                        }
                    default:
                        break
                    }
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
    }
    
    /// 상품 ID로 상품 찾기
    /// - Note: 상품 ID에 해당하는 상품을 불러옵니다.
    /// - Warning: 반드시 `requestProducts` 함수 (등록된 상품 목록 불러오는 함수) 가 종료된 후 사용해야 합니다.
    private func findProduct(by productID: String) -> Product? {
        let allProducts = consumableProducts + nonConsumableProducts + subscriptionProducts
        return allProducts.first { $0.id == productID }
    }
    
    /// 유저 디폴트(로컬)에  구매한 소모성 상품을 저장하는 함수
    /// - Warning: 실제 서비스의 경우 서버에 저장하는 것이 안전합니다
    private func saveConsumableProductsToLocal() {
        // consumableProducts에 딕셔너리 [상품 ID : 수량] 로 저장
        UserDefaults.standard.set(purchasedConsumableProducts, forKey: "consumableProducts")
    }
    
    
    /// 유저 디폴트(로컬)에  구매한 소모성 상품을 불러오는 함수
    /// - Warning: 실제 서비스의 경우 서버에서 불러오는 것이 안전합니다
    private func loadConsumableProductsFromLocal() {
        if let saved = UserDefaults.standard.object(forKey: "consumableProducts") as? [String: Int] {
            purchasedConsumableProducts = saved
        }
    }
    
    
    // MARK: - Purchase Status Check Functions
    
    /// 비소모성 상품이 구매되었는지 확인하는 함수
    func isPurchased(_ product: Product) -> Bool {
        switch product.type {
        case .nonConsumable:
            return purchasedNonConsumableProducts.contains { $0.id == product.id }
        case .autoRenewable:
            return purchasedSubscriptionProducts.contains { $0.id == product.id }
        case .consumable:
            return (purchasedConsumableProducts[product.id] ?? 0) > 0
        default:
            return false
        }
    }
    
    /// 소모성 상품의 구매 개수를 반환하는 함수
    func purchasedCount(for product: Product) -> Int {
        guard product.type == .consumable else { return 0 }
        return purchasedConsumableProducts[product.id] ?? 0
    }
    
    /// 소모성 상품 사용하기 (개수 감소)
    func useFuel(product: Product) -> Bool {
        guard product.type == .consumable else { return false }
        guard let currentCount = purchasedConsumableProducts[product.id], currentCount > 0 else {
            return false
        }
        
        purchasedConsumableProducts[product.id] = currentCount - 1
        
        // 개수가 0이 되면 딕셔너리에서 제거
        if purchasedConsumableProducts[product.id] == 0 {
            purchasedConsumableProducts.removeValue(forKey: product.id)
        }
        
        // UserDefaults에 저장
        saveConsumableProductsToLocal()
        
        return true
    }
    
}

