//
//  MyCar.swift
//  InAppPurchasePlayground
//
//  Created by 강건 on 9/10/25.
//

import SwiftUI
import StoreKit

struct MyCarView: View {
    @EnvironmentObject var store: StoreViewModel
    
    var body: some View {
        List {
            // 비소모성 상품 리스트
            Section(header: Text("CARS")) {
                ForEach(store.purchasedNonConsumableProducts, id: \.id) { product in
                    NonConsumableProductCell(product: product)
                }
            }
            
            // 소모성 상품 리스트
            Section(header: Text("FUEL")) {
                ForEach(store.consumableProducts.filter { product in
                    store.purchasedConsumableProducts.keys.contains(product.id)
                }, id: \.id) { product in
                    ConsumableProductCell(product: product)
                }
            }
            
            // 구독형 상품 리스트
            Section(header: Text("SOFTWARE OPTIONS")) {
                ForEach(store.purchasedSubscriptionProducts, id: \.id) { product in
                    SubscriptionProductCell(product: product)
                }
            }
        }
    }
}

#Preview {
    MyCarView()
        .environmentObject(StoreViewModel())
}

private struct NonConsumableProductCell: View {
    @EnvironmentObject var store: StoreViewModel
    
    let product: Product
    
    var body: some View {
        NavigationLink {
            CarDetailView(car: product)
        } label: {
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
            }
        }
        .padding(.horizontal, 4)
    }
}

private struct ConsumableProductCell: View {
    @EnvironmentObject var store: StoreViewModel
    
    let product: Product
    
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
                
                Text("보유: \(store.purchasedCount(for: product))개")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

private struct SubscriptionProductCell: View {
    @EnvironmentObject var store: StoreViewModel

    let product: Product

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
        }
        .padding(.horizontal, 4)
    }
}
