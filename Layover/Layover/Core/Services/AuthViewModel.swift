//
//  AuthViewModel.swift
//  Layover
//
//  Created by Maxwell Hu on 4/17/26.
//

import Combine
import Foundation
import Supabase
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {

    static let shared = AuthViewModel()

    @Published var isSignedIn = false
    @Published var userEmail: String?
    @Published var userName: String?
    @Published var userId: UUID?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var supabase: SupabaseClient { SupabaseManager.client }

    private init() {
        Task { await restoreSession() }
    }


    func restoreSession() async {
        do {
            let session = try await supabase.auth.session
            if session.isExpired {
                isSignedIn = false
            } else {
                applySession(session)
            }
        } catch {
            isSignedIn = false
        }
    }


    func signUp(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(name)]
            )
            if let session = result.session {
                applySession(session)
                userName = name
            } else {
                errorMessage = "Check your email to confirm your account."
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }


    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            applySession(session)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }


    func signOut() async {
        do {
            try await supabase.auth.signOut()
        } catch {
            print("Sign out error: \(error)")
        }
        isSignedIn = false
        userEmail = nil
        userName = nil
        userId = nil
    }


    private func applySession(_ session: Session) {
        isSignedIn = true
        userId = session.user.id
        userEmail = session.user.email
        if let meta = session.user.userMetadata["full_name"]?.stringValue {
            userName = meta
        }
    }
}

private extension Supabase.AnyJSON {
    var stringValue: String? {
        switch self {
        case .string(let s): return s
        default: return nil
        }
    }
}
