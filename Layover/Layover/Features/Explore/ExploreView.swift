//
//  ExploreView.swift
//  Layover
//
//  Created by Maxwell Hu on 4/4/26.
//

import SwiftUI

struct ExploreView: View {
    @ObservedObject var vm: LayoverViewModel
    @State private var navigateToResults = false
    @State private var showRadiusPicker = false
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    timeCard
                        .padding(.horizontal, 20)

                    categorySection

                    visitDurationSection
                        .padding(.horizontal, 20)

                    searchButton
                        .padding(.horizontal, 20)

                    tipsSection
                        .padding(.horizontal, 20)

                    Spacer(minLength: 100)
                }
            }
            .background(Color.white)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToResults) {
                ResultsView(vm: vm)
            }
            .sheet(isPresented: $showRadiusPicker) {
                radiusPickerSheet
            }
        }
    }


    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hi, \(AuthViewModel.shared.userName ?? "Traveler") 👋")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)

                    Text("Where do you want\nto go?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                }
                Spacer()
                // Profile avatar
                Button {
                    selectedTab = 4
                } label: {
                    ZStack {
                        Circle().fill(Color(.systemGray5)).frame(width: 44, height: 44)
                        Image(systemName: "person.fill")
                            .font(.system(size: 18)).foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
        }
    }



    private var timeCard: some View {
        VStack(spacing: 16) {
            // Departure time row
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Departure")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    DatePicker("", selection: $vm.departureTime, in: Date()...,
                               displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(AppTheme.primary)
                }
                Spacer()
            }

            // Stats row
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Available time")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(vm.playWindowShort)
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .foregroundStyle(AppTheme.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Search radius")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Button { showRadiusPicker = true } label: {
                        HStack(spacing: 4) {
                            Text(vm.searchRadiusLabel)
                                .font(.subheadline.weight(.medium))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundStyle(AppTheme.textPrimary)
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }


    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Categories")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PlaceCategory.allCases) { cat in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { vm.selectedCategory = cat }
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    // Photo background
                                    if let url = cat.imageURL {
                                        AsyncImage(url: url) { phase in
                                            if case .success(let img) = phase {
                                                img.resizable().aspectRatio(contentMode: .fill)
                                            } else {
                                                Color(.systemGray5)
                                            }
                                        }
                                    } else {
                                        Color(.systemGray5)
                                    }

                                    // Overlay
                                    Rectangle()
                                        .fill(vm.selectedCategory == cat
                                              ? AppTheme.primary.opacity(0.75)
                                              : Color.black.opacity(0.3))

                                    // Icon
                                    Image(systemName: cat.icon)
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundStyle(.white)
                                }
                                .frame(width: 72, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(vm.selectedCategory == cat ? AppTheme.primary : Color.clear, lineWidth: 2)
                                )

                                Text(cat.rawValue)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(vm.selectedCategory == cat ? AppTheme.primary : AppTheme.textSecondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Visit Duration

    private var visitDurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How long do you want to visit?")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(LayoverViewModel.visitDurations, id: \.self) { mins in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) { vm.visitMinutes = mins }
                        } label: {
                            Text(vm.visitDurationLabel(mins))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(vm.visitMinutes == mins ? .white : AppTheme.textPrimary)
                                .padding(.horizontal, 18).padding(.vertical, 10)
                                .background(
                                    vm.visitMinutes == mins ? AppTheme.textPrimary : Color.clear,
                                    in: Capsule()
                                )
                                .overlay(
                                    Capsule().stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                    }
                }
            }
        }
    }


    private var searchButton: some View {
        Button {
            vm.loadPlaces()
            navigateToResults = true
        } label: {
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.body.weight(.semibold))
                Text("Search")
                    .font(.body.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 12))
        }
    }


    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tips")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            TipCard(icon: "clock", title: "Plan ahead", subtitle: "Set your departure time for accurate results")
            TipCard(icon: "figure.walk", title: "Stay nearby", subtitle: "Shorter trips mean less stress")
            TipCard(icon: "heart", title: "Save favorites", subtitle: "Sign in to save places for later")
        }
    }


    private var radiusPickerSheet: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        vm.customSearchRadius = nil
                        showRadiusPicker = false
                    } label: {
                        HStack {
                            Text("Auto (based on time)")
                            Spacer()
                            if vm.customSearchRadius == nil {
                                Image(systemName: "checkmark").foregroundStyle(AppTheme.primary)
                            }
                        }
                    }
                }
                
                Section("Manual") {
                    ForEach(LayoverViewModel.radiusOptions, id: \.self) { radius in
                        Button {
                            vm.customSearchRadius = radius
                            showRadiusPicker = false
                        } label: {
                            HStack {
                                Text(radius >= 1000 ? "\(radius / 1000) km" : "\(radius) m")
                                Spacer()
                                if vm.customSearchRadius == radius {
                                    Image(systemName: "checkmark").foregroundStyle(AppTheme.primary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search Radius")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { showRadiusPicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 40, height: 40)
                Image(systemName: icon).font(.body).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(AppTheme.textMuted)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer()
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
    }
}

// MARK: - Tip Card

struct TipCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ExploreView(vm: LayoverViewModel.shared, selectedTab: .constant(0))
}
