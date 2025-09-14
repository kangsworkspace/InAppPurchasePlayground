//
//  ContentView.swift
//  InAppPurchasePlayground
//
//  Created by 강건 on 9/9/25.
//

import SwiftUI

struct ContentView: View {
    @State private var carOffset: CGFloat = 0
    @State private var carOpacity: Double = 1
    @State private var isCarMoving: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading) {
                    Text("In App Purchase")
                        .font(.system(size: 32, weight: .bold))
                        .padding(.top, 32)
                    
                    Text("Playground")
                        .font(.system(size: 24, weight: .bold))
                }
                
                HStack {
                    Button {
                        guard !isCarMoving else { return }
                        
                        isCarMoving = true
                        
                        withAnimation(.easeInOut(duration: 1.5)) {
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
                    } label: {
                        Image("IAPIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                    }
                    
                    Text("Testing")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("storekit2")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.blue)
                }
            }
            
            Text("🚗💨")
                .font(.system(size: 120))
                .padding(.vertical, 48)
                .offset(x: carOffset)
                .opacity(carOpacity)
            
            NavigationLink {
                ShopView()
            } label: {
                Text("\(Image(systemName: "cart")) Shop")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 300, height: 40)
                    .background(Color.blue).cornerRadius(16.0)
            }
            .padding(.top, 32)
            
            NavigationLink {
                MyCarView()
            } label: {
                Text("\(Image(systemName: "car")) My Cars")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 300, height: 40)
                    .background(Color.blue).cornerRadius(16.0)
            }
            .padding(.top, 16)
            
            Spacer()
            
            Text("Made by Healthy")
                .foregroundStyle(Color.gray.opacity(0.3))
        }
    }
}

#Preview {
    ContentView()
}
