//
//  ProfileView.swift
//  Layover
//
//  Created by Maxwell Hu on 4/17/26.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var vm: LayoverViewModel
    @ObservedObject var auth: AuthViewModel = .shared
    @AppStorage("hasOnboarded") private var hasOnboarded = true

    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignUp = false
    @State private var showEditProfile = false
    @State private var showNotificationSettings = false
    @State private var showHelp = false
    @State private var editName = ""
    @State private var notificationsEnabled = true

    @State private var showBufferPicker = false
    @State private var showCategoryPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    profileHeader
                    if auth.isSignedIn { quickActions }
                    preferencesSection
                    otherSection
                    Spacer(minLength: 100)
                }
                .padding(.top, 20)
            }
            .background(Color.white)
            .navigationTitle("Profile")
            .sheet(isPresented: $showEditProfile) { editProfileSheet }
            .sheet(isPresented: $showNotificationSettings) { notificationSheet }
            .sheet(isPresented: $showHelp) { helpSheet }
            .sheet(isPresented: $showBufferPicker) { bufferPickerSheet }
            .sheet(isPresented: $showCategoryPicker) { categoryPickerSheet }
        }
    }

    // MARK: - Header (Card with shadow like Airbnb profile)

    private var profileHeader: some View {
        VStack(spacing: 0) {
            // Profile card
            VStack(spacing: 20) {
                // Avatar + name centered
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 80, height: 80)
                        Image(systemName: auth.isSignedIn ? "person.crop.circle.fill" : "person.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Text(auth.userName ?? "Guest")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(auth.isSignedIn ? (auth.userEmail ?? "Traveler") : "Guest")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                
                // Stats row — like Airbnb
                if auth.isSignedIn {
                    HStack(spacing: 0) {
                        statColumn(value: "\(ItineraryService.shared.items.count)", label: "Stops")
                        Divider().frame(height: 32)
                        statColumn(value: "\(FavoritesService.shared.favorites.count)", label: "Saved")
                    }
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
            .padding(.horizontal, 20)

            // Auth form if not signed in
            if !auth.isSignedIn {
                authForm
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
            }

            if let error = auth.errorMessage {
                Text(error)
                    .font(.caption).foregroundStyle(AppTheme.danger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
            }
        }
    }

    // MARK: - Stat Column

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Auth Form

    private var authForm: some View {
        VStack(spacing: 12) {
            if isSignUp {
                TextField("Name", text: $name)
                    .textContentType(.name)
                    .padding(12)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
            }

            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .padding(12)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))

            SecureField("Password", text: $password)
                .textContentType(isSignUp ? .newPassword : .password)
                .padding(12)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))

            Button {
                Task {
                    if isSignUp {
                        await auth.signUp(email: email, password: password, name: name)
                    } else {
                        await auth.signIn(email: email, password: password)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if auth.isLoading { ProgressView().tint(.white) }
                    Text(isSignUp ? "Create Account" : "Sign In")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 12))
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
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }

    // MARK: - Quick Actions (spaced rows, no dividers)

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 8) {
            actionRow(icon: "pencil", label: "Edit Profile") {
                editName = auth.userName ?? ""
                showEditProfile = true
            }
            
            actionRow(icon: "bell", label: "Notifications") {
                showNotificationSettings = true
            }
            
            actionRow(icon: "questionmark.circle", label: "Get help") {
                showHelp = true
            }
        }
        .padding(.horizontal, 20)
    }

    private func actionRow(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(AppTheme.textPrimary)
                    .frame(width: 28)
                
                Text(label)
                    .font(.body)
                    .foregroundStyle(AppTheme.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(.vertical, 12)
        }
    }

    // MARK: - Preferences (spaced rows, no dividers)

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.bottom, 8)

            Button { showBufferPicker = true } label: {
                settingsRow(icon: "clock", label: "Boarding buffer", value: "\(vm.boardingBufferMinutes) min")
            }
            
            Button {
                vm.locationManager.requestPermission()
                vm.locationManager.startUpdating()
            } label: {
                settingsRow(icon: "location", label: "Location access", value: vm.hasRealLocation ? "On" : "Off")
            }
            
            Button { showCategoryPicker = true } label: {
                settingsRow(icon: "square.grid.2x2", label: "Default category", value: vm.selectedCategory.rawValue)
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Other Section
    
    private var otherSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Other")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.bottom, 8)

            resetButton
            
            if auth.isSignedIn {
                signOutButton
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Reset & Sign Out

    private var resetButton: some View {
        Button { hasOnboarded = false } label: {
            HStack(spacing: 16) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 22))
                    .frame(width: 28)
                Text("Reset onboarding")
                    .font(.body)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textMuted)
            }
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.vertical, 12)
        }
    }

    private var signOutButton: some View {
        Button {
            Task { await auth.signOut() }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 22))
                    .frame(width: 28)
                Text("Log out")
                    .font(.body)
                Spacer()
            }
            .foregroundStyle(AppTheme.danger)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Settings Row

    private func settingsRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(width: 28)
            
            Text(label)
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
            
            Spacer()
            
            if !value.isEmpty {
                Text(value)
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textMuted)
        }
        .padding(.vertical, 12)
    }

    // MARK: - Edit Profile Sheet

    private var editProfileSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Display Name", text: $editName)
                    .padding(14)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))

                Text("Email: \(auth.userEmail ?? "N/A")")
                    .font(.subheadline).foregroundStyle(AppTheme.textSecondary)

                Spacer()
            }
            .padding(24)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { showEditProfile = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        // Save name locally for now
                        showEditProfile = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Notification Sheet

    private var notificationSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Toggle(isOn: $notificationsEnabled) {
                    Label("Departure Reminders", systemImage: "bell.fill")
                        .font(.subheadline)
                }
                .tint(AppTheme.primary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Boarding Buffer")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.textPrimary)
                    Picker("Buffer", selection: $vm.boardingBufferMinutes) {
                        Text("60 min").tag(60)
                        Text("90 min").tag(90)
                        Text("120 min").tag(120)
                    }
                    .pickerStyle(.segmented)
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showNotificationSettings = false }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Help Sheet

    private var helpSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    helpItem(q: "How does Layover work?",
                             a: "Enter your departure time, pick a category, and we'll find places you can visit and return from before your flight boards.")
                    helpItem(q: "What's the play window?",
                             a: "Your available time minus a 90-minute boarding buffer. This is how long you have to explore.")
                    helpItem(q: "How is travel time calculated?",
                             a: "We use the Google Routes API with real-time traffic data to estimate drive times.")
                    helpItem(q: "Can I save places?",
                             a: "Yes! Sign in and tap the heart icon on any place to save it to your favorites.")
                    helpItem(q: "Is my location tracked?",
                             a: "We only use your location when the app is open to find nearby places. We never store or share it.")
                }
                .padding(24)
            }
            .navigationTitle("Help & FAQ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showHelp = false }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func helpItem(q: String, a: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(q).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.textPrimary)
            Text(a).font(.caption).foregroundStyle(AppTheme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Buffer Picker Sheet

    private var bufferPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("How much time do you need before boarding?")
                    .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)

                ForEach([60, 90, 120], id: \.self) { mins in
                    Button {
                        vm.boardingBufferMinutes = mins
                        showBufferPicker = false
                    } label: {
                        HStack {
                            Text("\(mins) minutes")
                                .font(.body.weight(.medium))
                                .foregroundStyle(vm.boardingBufferMinutes == mins ? AppTheme.primary : AppTheme.textPrimary)
                            Spacer()
                            if vm.boardingBufferMinutes == mins {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.primary)
                            }
                        }
                        .padding(16)
                        .background(
                            vm.boardingBufferMinutes == mins ? AppTheme.primaryLight : Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                    }
                }

                Spacer()
            }
            .padding(24)
            .navigationTitle("Boarding Buffer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showBufferPicker = false }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Category Picker Sheet

    private var categoryPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ForEach(PlaceCategory.allCases) { cat in
                    Button {
                        vm.selectedCategory = cat
                        showCategoryPicker = false
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(cat.color.opacity(0.12))
                                    .frame(width: 40, height: 40)
                                Image(systemName: cat.icon)
                                    .font(.body).foregroundStyle(cat.color)
                            }
                            Text(cat.rawValue)
                                .font(.body.weight(.medium))
                                .foregroundStyle(vm.selectedCategory == cat ? AppTheme.primary : AppTheme.textPrimary)
                            Spacer()
                            if vm.selectedCategory == cat {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.primary)
                            }
                        }
                        .padding(12)
                        .background(
                            vm.selectedCategory == cat ? AppTheme.primaryLight : Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                    }
                }
                Spacer()
            }
            .padding(24)
            .navigationTitle("Default Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showCategoryPicker = false }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview { ProfileView(vm: LayoverViewModel.shared) }
