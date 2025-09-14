//
//  BuyButtonStyle.swift
//  InAppPurchasePlayground
//
//  Created by 강건 on 9/12/25.
//

import SwiftUI

struct BuyButtonStyle: ButtonStyle {
    let isPurchased: Bool
    
    init(isPurchased: Bool = false) {
        self.isPurchased = isPurchased
    }
    
    func makeBody(configuration: Configuration) -> some View {
        var backgroundColor: Color = isPurchased ? Color.green : Color.blue
        backgroundColor = configuration.isPressed ? backgroundColor.opacity(0.7) : backgroundColor.opacity(1)
        
        return configuration.label
            .frame(width: 65)
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .scaleEffect(configuration.isPressed ? 0.9: 1.0)
    }
}
