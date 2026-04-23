//
//  ResultsView.swift
//  Layover
//
//  Created by Maxwell Hu on 4/17/26.
//

import SwiftUI

struct ResultsView: View {
    @ObservedObject var vm: LayoverViewModel
    @State private var viewMode: ViewMode = .list

    enum ViewMode: String, CaseIterable {
        case list = "List"
        case map  = "Map"
        var icon: String { self == .list ? "list.bullet" : "map" }
    }

    var body: some View {
        VStack(spacing: 0) {
            viewToggle
            if viewMode == .list { listContent } else { MapView(vm: vm) }
        }
        .background(Color(red: 0.94, green: 0.98, blue: 0.96))
        .navigationTitle(vm.selectedCategory.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                timeBadge
            }
        }
        .sheet(item: $vm.selectedPlace) { place in
            PlaceDetailView(place: place, vm: vm)
        }
    }



    private var viewToggle: some View {
        HStack(spacing: 0) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { viewMode = mode }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon).font(.caption.weight(.semibold))
                        Text(mode.rawValue).font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(viewMode == mode ? .white : AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        viewMode == mode ? AppTheme.primary : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
            }
        }
        .padding(4)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var timeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock").font(.caption)
            Text(vm.playWindowShort).font(.caption.weight(.semibold).monospacedDigit())
        }
        .foregroundStyle(AppTheme.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(AppTheme.primaryLight, in: Capsule())
    }


    private var listContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !vm.isLoading && !vm.rows.isEmpty { summaryCard.padding(.horizontal, 20) }

                if vm.isLoading {
                    loadingView
                } else if vm.rows.isEmpty {
                    emptyView
                } else {
                    if !vm.bestOptions.isEmpty  { groupSection(group: .bestOptions,  places: vm.bestOptions) }
                    if !vm.tightTiming.isEmpty   { groupSection(group: .tightTiming,  places: vm.tightTiming) }
                    if !vm.tooFar.isEmpty         { groupSection(group: .tooFar,       places: vm.tooFar) }
                }

                Spacer(minLength: 32)
            }
            .padding(.top, 4)
        }
        .refreshable {
            vm.loadPlaces()
            while vm.isLoading { try? await Task.sleep(nanoseconds: 200_000_000) }
        }
    }



    private var summaryCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(vm.summaryColor.opacity(0.12)).frame(width: 48, height: 48)
                Image(systemName: vm.summaryIcon).font(.title3).foregroundStyle(vm.summaryColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(vm.summaryText).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.textPrimary)
                Text("\(vm.reachableCount) of \(vm.totalCount) reachable · \(vm.visitDurationLabel(vm.visitMinutes)) visits")
                    .font(.caption).foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }


    private func groupSection(group: PlaceGroup, places: [PlaceRow]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: group.icon).foregroundStyle(group.color).font(.subheadline)
                Text(group.rawValue).font(.subheadline.weight(.bold)).foregroundStyle(AppTheme.textPrimary)
                Text("(\(places.count))").font(.caption).foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(places) { place in
                    PlaceCard(place: place, groupColor: group.color)
                        .onTapGesture { vm.selectedPlace = place }
                }
            }
            .padding(.horizontal, 20)
        }
    }


    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 60)
            ProgressView().scaleEffect(1.3).tint(AppTheme.primary)
            Text("Searching nearby…").font(.subheadline).foregroundStyle(AppTheme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 60)
            ZStack {
                Circle().fill(AppTheme.primaryLight).frame(width: 80, height: 80)
                Image(systemName: "mappin.slash").font(.system(size: 32)).foregroundStyle(AppTheme.primary.opacity(0.5))
            }
            Text("No places found").font(.headline).foregroundStyle(AppTheme.textPrimary)
            Text("Try a different category\nor adjust your departure time")
                .font(.caption).foregroundStyle(AppTheme.textMuted).multilineTextAlignment(.center)
            Spacer()
        }
    }
}


struct PlaceCard: View {
    let place: PlaceRow
    let groupColor: Color

    var body: some View {
        HStack(spacing: 0) {
            // Photo
            if let url = place.photoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        placeholderImage
                    }
                }
                .frame(width: 80, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.trailing, 12)
            } else {
                placeholderImage
                    .frame(width: 80, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.trailing, 12)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(place.name)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Label(place.durationText, systemImage: "car.fill")
                    Label(place.distanceText, systemImage: "arrow.left.and.right")
                }
                .font(.caption).foregroundStyle(AppTheme.textSecondary)

                if let rating = place.rating {
                    HStack(spacing: 3) {
                        ForEach(0..<5) { i in
                            Image(systemName: Double(i) < rating ? "star.fill" : "star")
                                .font(.system(size: 8))
                                .foregroundStyle(Double(i) < rating ? AppTheme.warning : AppTheme.warning.opacity(0.25))
                        }
                        Text(String(format: "%.1f", rating)).font(.caption2).foregroundStyle(AppTheme.textSecondary)
                    }
                }

                // Status badge
                HStack(spacing: 4) {
                    Circle().fill(groupColor).frame(width: 6, height: 6)
                    Text(place.fits ? (groupColor == AppTheme.success ? "Easy" : "Tight") : "Too Far")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(groupColor)
                }
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(groupColor.opacity(0.1), in: Capsule())
            }

            Spacer()

            Image(systemName: "chevron.right").font(.caption).foregroundStyle(AppTheme.textMuted)
        }
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }

    private var placeholderImage: some View {
        ZStack {
            AppTheme.primaryLight
            Image(systemName: "photo")
                .font(.title3).foregroundStyle(AppTheme.primary.opacity(0.3))
        }
    }
}

#Preview {
    NavigationStack { ResultsView(vm: LayoverViewModel.shared) }
}
