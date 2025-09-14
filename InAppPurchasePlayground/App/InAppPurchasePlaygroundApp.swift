//
//  InAppPurchasePlaygroundApp.swift
//  InAppPurchasePlayground
//
//  Created by 강건 on 9/9/25.
//

import SwiftUI

@main
struct InAppPurchasePlaygroundApp: App {
    @StateObject private var viewModel = StoreViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
