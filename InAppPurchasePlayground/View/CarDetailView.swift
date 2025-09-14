//
//  CarDetailView.swift
//  InAppPurchasePlayground
//
//  Created by 강건 on 9/14/25.
//

import SwiftUI
import StoreKit

struct CarDetailView: View {
    @EnvironmentObject var store: StoreViewModel
    let car: Product
    
    @State private var carOffset: CGFloat = 0
    @State private var carOpacity: Double = 1
    @State private var isCarMoving: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            Text((store.productIdToEmoji[car.id] ?? "🚗") + "💨")
                .font(.system(size: 120))
                .padding(.vertical, 48)
                .padding(.top, 30)
                .offset(x: carOffset)
                .opacity(carOpacity)
            
            
            Text(car.displayName)
                .font(.title2.weight(.semibold))
                .padding(.bottom, 8)
            
            Text(car.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
            
            HStack(spacing: 20) {
                ForEach(store.consumableProducts, id: \.id) { fuelProduct in
                    FuelButton(
                        fuel: fuelProduct.displayName,
                        fuelCount: store.purchasedCount(for: fuelProduct)
                    ) {
                        useFuelAndMoveCar(fuelProduct: fuelProduct)
                    }
                }
            }
            .padding(.bottom, 120)
        }
    }
    
    private func useFuelAndMoveCar(fuelProduct: Product) {
        guard store.useFuel(product: fuelProduct) else { return }
        
        let duration: Double
        
        switch fuelProduct.id {
        case "consumable.fuel.octan87":
            duration = 1.5
        case "consumable.fuel.octan89":
            duration = 0.8
        case "consumable.fuel.octan91":
            duration = 0.4
        default:
            duration = 1.0
        }
        
        moveCar(product: fuelProduct, duration: duration)
    }
    
    private func moveCar(product: Product, duration: Double) {
        guard !isCarMoving else { return }
        
        isCarMoving = true
        
        withAnimation(.easeInOut(duration: duration)) {
            carOffset = -UIScreen.main.bounds.width
            carOpacity = 0
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            carOffset = UIScreen.main.bounds.width
            carOpacity = 0
            
            withAnimation(.easeInOut(duration: 1.5)) {
                carOffset = 0
                carOpacity = 1
            }
            
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            isCarMoving = false
        }
    }
}

#Preview {
    // 외부에서 store를 주입한 것처럼 하기 위한 프리뷰 래퍼
    struct PreviewWrapper: View {
        @StateObject private var store = StoreViewModel()
        
        var body: some View {
            if let firstCar = store.nonConsumableProducts.first {
                CarDetailView(car: firstCar)
                    .environmentObject(store)
            }
        }
    }
    
    return PreviewWrapper()
}


private struct FuelButton: View {
    let fuel: String
    let fuelCount: Int
    let fuelAction: () -> Void
    
    var body: some View {
        VStack {
            Button {
               fuelAction()
            } label: {
                RoundedRectangle(cornerRadius: 12)
                    .frame(width: 80, height: 80)
                    .foregroundStyle(Color.yellow)
                    .overlay {
                        VStack {
                            Text("⛽️")
                                .font(.system(size: 30))
                            
                            Text(fuel)
                                .foregroundStyle(Color.black)
                                .lineLimit(1)
                                .minimumScaleFactor(0.3)
                                .font(.caption.weight(.medium))
                        }
                    }
            }
            .disabled(fuelCount <= 0)
            
            Text("\(fuelCount)개")
                .foregroundStyle(Color.gray)
                .font(.caption)
        }
    }
}
