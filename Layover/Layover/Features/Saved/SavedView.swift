//
//  SavedView.swift
//  Layover
//
//  Created by Maxwell Hu on 4/17/26.
//

import CoreLocation
import SwiftUI

struct SavedView: View {
    @ObservedObject var vm: LayoverViewModel
    @ObservedObject var auth: AuthViewModel = .shared
    @ObservedObject var favService: FavoritesService = .shared
    @State private var selectedFavorite: PlaceRow? = nil

    var body: some View {
        NavigationStack {
            Group {
                if !auth.isSignedIn {
                    signInPrompt
                } else if favService.isLoading {
                    ProgressView().tint(AppTheme.primary).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if favService.favorites.isEmpty {
                    emptyState
                } else {
                    favoritesList
                }
            }
            .background(Color.white)
            .navigationTitle("Saved")
            .task {
                if auth.isSignedIn { await favService.fetchFavorites() }
            }
            .sheet(item: $selectedFavorite) { place in
                PlaceDetailView(place: place, vm: vm)
            }
        }
    }



    private var signInPrompt: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle().fill(AppTheme.primaryLight).frame(width: 100, height: 100)
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 44)).foregroundStyle(AppTheme.primary)
            }
            Text("Save your favorite spots")
                .font(.title3.weight(.bold)).foregroundStyle(AppTheme.textPrimary)
            Text("Sign in from your Profile to start\nsaving places for future layovers")
                .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }



    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle().fill(AppTheme.primaryLight).frame(width: 100, height: 100)
                Image(systemName: "heart")
                    .font(.system(size: 40)).foregroundStyle(AppTheme.primary.opacity(0.5))
            }
            Text("No saved places yet")
                .font(.title3.weight(.bold)).foregroundStyle(AppTheme.textPrimary)
            Text("Tap the heart icon on any place\nto save it for later")
                .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }


    private var favoritesList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(favService.favorites) { fav in
                    savedPlaceCard(fav)
                        .onTapGesture {
                            selectedFavorite = placeRow(from: fav)
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .refreshable {
            await favService.fetchFavorites()
        }
    }

    private func placeRow(from fav: Favorite) -> PlaceRow {
        PlaceRow(
            id: fav.placeId,
            name: fav.name,
            address: fav.address ?? "",
            rating: fav.rating,
            coordinate: CLLocationCoordinate2D(latitude: fav.latitude, longitude: fav.longitude),
            durationText: "—",
            distanceText: "—",
            durationSeconds: 0,
            fits: true,
            photoURL: nil
        )
    }

    private func savedPlaceCard(_ fav: Favorite) -> some View {
        HStack(spacing: 16) {
            Image(systemName: categoryIcon(fav.category))
                .font(.system(size: 22))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(fav.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)

                if let address = fav.address, !address.isEmpty {
                    Text(address)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                Task { await favService.removeFavorite(placeId: fav.placeId) }
            } label: {
                Image(systemName: "heart.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.danger)
            }
        }
        .padding(.vertical, 12)
    }

    private func categoryIcon(_ category: String?) -> String {
        switch category {
        case "tourist_attraction": return "binoculars.fill"
        case "restaurant":        return "fork.knife"
        case "coffee_shop":       return "cup.and.saucer.fill"
        case "shopping_mall":     return "bag.fill"
        case "night_club":        return "moon.stars.fill"
        case "park":              return "leaf.fill"
        default:                  return "mappin.circle.fill"
        }
    }

    private func categoryColor(_ category: String?) -> Color {
        switch category {
        case "tourist_attraction": return .cyan
        case "restaurant":        return .orange
        case "coffee_shop":       return .brown
        case "shopping_mall":     return .pink
        case "night_club":        return .purple
        case "park":              return .green
        default:                  return AppTheme.primary
        }
    }
}

#Preview { SavedView(vm: LayoverViewModel.shared) }
