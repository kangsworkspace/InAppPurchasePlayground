//
//  ShopView.swift
//  InAppPurchasePlayground
//
//  Created by 강건 on 9/10/25.
//

import SwiftUI
import StoreKit

struct ShopView: View {
    @EnvironmentObject var store: StoreViewModel
    
    var body: some View {
        List {
            // 비소모성 상품 리스트
            Section(header: Text("CARS")) {
                ForEach(store.nonConsumableProducts, id: \.id) { product in
                    NonConsumableProductCell(
                        product: product,
                        isPurchased: store.isPurchased(product)
                    )
                }
            }
            
            // 소모성 상품 리스트
            Section(header: Text("FUEL")) {
                ForEach(store.consumableProducts, id: \.id) { product in
                    ConsumableProductCell(
                        product: product,
                        isPurchased: store.isPurchased(product)
                    )
                }
            }
            
            // 구독형 상품 리스트
            Section(header: Text("SOFTWARE OPTIONS")) {
                ForEach(store.subscriptionProducts, id: \.id) { product in
                    SubscriptionProductCell(
                        product: product,
                        isPurchased: store.isPurchased(product)
                    )
                }
            }
        }
    }
}


private struct NonConsumableProductCell: View {
    @EnvironmentObject var store: StoreViewModel
    
    let product: Product
    let isPurchased: Bool
    
    var body: some View {
        HStack {
            Text(store.productIdToEmoji[product.id] ?? "")
                .font(.system(size: 46))
                .padding(.trailing, 6)
            
            VStack(alignment: .leading) {
                Text("\(product.displayName)")
                    .font(.callout.weight(.semibold))
                
                Text("\(product.description)")
                    .font(.callout.weight(.regular))
            }
            
            Spacer()
            
            Button {
                Task {
                    do {
                        _ = try await store.purchase(product: product)
                    } catch {
                        
                    }
                }
            } label: {
                if store.isPurchased(product) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15).bold())
                        .foregroundStyle(Color.white)
                } else {
                    Text("\(product.displayPrice)₩")
                        .font(.system(size: 12).bold())
                        .foregroundStyle(Color.white)
                }
            }
            .buttonStyle(BuyButtonStyle(isPurchased: store.isPurchased(product)))
            .disabled(store.isPurchased(product))
            .opacity(store.isPurchased(product) ? 0.6 : 1.0)
        }
        .padding(.horizontal, 4)
    }
}

private struct ConsumableProductCell: View {
    @EnvironmentObject var store: StoreViewModel
    
    let product: Product
    let isPurchased: Bool
    
    var body: some View {
        HStack {
            Text(store.productIdToEmoji[product.id] ?? "")
                .font(.system(size: 46))
                .padding(.trailing, 6)
            
            VStack(alignment: .leading) {
                Text("\(product.displayName)")
                    .font(.callout.weight(.semibold))
                
                Text("\(product.description)")
                    .font(.callout.weight(.regular))
                
                if store.purchasedCount(for: product) > 0 {
                    Text("보유: \(store.purchasedCount(for: product))개")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            Button {
                Task {
                    do {
                        _ = try await store.purchase(product: product)
                    } catch {
                        
                    }
                }
            } label: {
                Text("\(product.displayPrice)₩")
                    .font(.system(size: 12).bold())
                    .foregroundStyle(Color.white)
            }
            .buttonStyle(BuyButtonStyle())
        }
        .padding(.horizontal, 4)
    }
}

private struct SubscriptionProductCell: View {
    @EnvironmentObject var store: StoreViewModel
    
    let product: Product
    let isPurchased: Bool
    
    var body: some View {
        HStack {
            Text(store.productIdToEmoji[product.id] ?? "")
                .font(.system(size: 46))
                .padding(.trailing, 6)
            
            VStack(alignment: .leading) {
                Text("\(product.displayName)")
                    .font(.callout.weight(.semibold))
                
                Text("\(product.description)")
                    .font(.callout.weight(.regular))
            }
            
            Spacer()
            
            Button {
                Task {
                    do {
                        _ = try await store.purchase(product: product)
                    } catch {
                        
                    }
                }
            } label: {
                if store.isPurchased(product) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15).bold())
                        .foregroundStyle(Color.white)
                } else {
                    Text("\(product.displayPrice)₩/월")
                        .lineLimit(1)
                        .font(.system(size: 12).bold())
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(Color.white)
                }
            }
            .buttonStyle(BuyButtonStyle(isPurchased: store.isPurchased(product)))
            .disabled(store.isPurchased(product))
            .opacity(store.isPurchased(product) ? 0.6 : 1.0)
        }
        .padding(.horizontal, 4)
    }
}



#Preview {
    ShopView()
        .environmentObject(StoreViewModel())
}
