//
//  LayoverApp.swift
//  Layover
//
//  Created by Maxwell Hu on 4/4/26.
//

import SwiftUI

@main
struct LayoverApp: App {
    @StateObject private var vm = LayoverViewModel.shared
    @StateObject private var auth = AuthViewModel.shared
    @StateObject private var favService = FavoritesService.shared
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some Scene {
        WindowGroup {
            if hasOnboarded {
                RootTabView(vm: vm)
                    .onChange(of: auth.isSignedIn) { _, signedIn in
                        if signedIn {
                            Task { await favService.fetchFavorites() }
                        }
                    }
            } else {
                OnboardingView(isOnboarded: $hasOnboarded)
            }
        }
    }
}
