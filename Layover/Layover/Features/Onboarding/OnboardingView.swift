//
//  OnboardingView.swift
//  Layover
//
//  Created by Maxwell Hu on 4/16/26.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboarded: Bool
    @StateObject private var vm = LayoverViewModel.shared
    @StateObject private var auth = AuthViewModel.shared

    @State private var step = 0  // 0=auth, 1=departure
    @State private var departureDate = Date().addingTimeInterval(4 * 3600)
    @State private var animate = false

    // Auth fields
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.94, green: 0.98, blue: 0.96).ignoresSafeArea()

            VStack(spacing: 0) {
                switch step {
                case 0:  authStep.transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
                default: departureStep.transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                }

                Spacer()
                progressDots
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { animate = true }
        }
    }


    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<2) { i in
                Capsule()
                    .fill(i == step ? AppTheme.primary : AppTheme.textMuted.opacity(0.3))
                    .frame(width: i == step ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: step)
            }
        }
        .padding(.bottom, 40)
    }



    private var authStep: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)

            ZStack {
                Circle().fill(AppTheme.primaryLight).frame(width: 80, height: 80)
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.primary)
            }

            VStack(spacing: 8) {
                Text("Welcome")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Sign in to save favorites & itineraries")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.top, 16)

            // Auth form
            VStack(spacing: 12) {
                if isSignUp {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                        .padding(14)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                }

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .padding(14)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))

                SecureField("Password", text: $password)
                    .textContentType(isSignUp ? .newPassword : .password)
                    .padding(14)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))

                if let error = auth.errorMessage {
                    Text(error)
                        .font(.caption).foregroundStyle(AppTheme.danger)
                }

                Button {
                    Task {
                        if isSignUp {
                            await auth.signUp(email: email, password: password, name: name)
                        } else {
                            await auth.signIn(email: email, password: password)
                        }
                        if auth.isSignedIn {
                            withAnimation(.easeInOut(duration: 0.5)) { step = 1 }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if auth.isLoading { ProgressView().tint(.white) }
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 14))
                }
                .disabled(email.isEmpty || password.isEmpty || auth.isLoading)
                .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1)

                Button {
                    withAnimation { isSignUp.toggle() }
                } label: {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.caption).foregroundStyle(AppTheme.primary)
                }
            }
            .padding(24)
            .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
            .padding(.horizontal, 24)
            .padding(.top, 24)

            Spacer()

            // Guest mode
            Button {
                vm.locationManager.requestPermission()
                withAnimation(.easeInOut(duration: 0.5)) { step = 1 }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill.questionmark")
                    Text("Continue as Guest")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }


    private var departureStep: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 60)

            ZStack {
                Circle().fill(AppTheme.primaryLight).frame(width: 80, height: 80)
                Image(systemName: "clock.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.primary)
            }

            VStack(spacing: 8) {
                Text("When's your flight?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("We'll calculate how much time you have")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            VStack(spacing: 16) {
                DatePicker("", selection: $departureDate, in: Date()...,
                           displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.wheel)
                    .labelsHidden()

                Divider()

                let window = max(0, departureDate.timeIntervalSince(Date()) - 90 * 60)
                let hrs = Int(window) / 3600
                let mins = (Int(window) % 3600) / 60

                HStack(spacing: 6) {
                    Image(systemName: "hourglass").foregroundStyle(AppTheme.primary)
                    Text("Play window:").foregroundStyle(AppTheme.textSecondary)
                    Text("\(hrs)h \(mins)m").foregroundStyle(AppTheme.primary).fontWeight(.bold)
                }
                .font(.subheadline)
            }
            .cardStyle(padding: 20)
            .padding(.horizontal, 24)

            Spacer()

            Button {
                vm.departureTime = departureDate
                UserDefaults.standard.set(true, forKey: "hasOnboarded")
                withAnimation(.easeInOut(duration: 0.4)) { isOnboarded = true }
            } label: {
                HStack(spacing: 10) {
                    Text("Let's Go")
                        .font(.headline)
                    Image(systemName: "arrow.right")
                        .font(.body.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: AppTheme.primary.opacity(0.3), radius: 12, y: 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

#Preview {
    OnboardingView(isOnboarded: .constant(false))
}
