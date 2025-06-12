//
//  RelayExampleApp.swift
//  RelayExample
//
//  Created by Samaila Bala on 18/03/2025.
//

import SwiftUI
import Relay

@main
struct RelayExampleApp: App {
    init() {
//        try? Relay.shared.initialize()
    }
    
    var body: some Scene {
        WindowGroup {
            RelayExampleView()
                .frame(minWidth: 1000, minHeight: 700)
        }
    }
}
