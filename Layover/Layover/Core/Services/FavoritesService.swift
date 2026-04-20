//
//  FavoritesService.swift
//  Layover
//
//  Created by Maxwell Hu on 4/17/26.
//

import Combine
import CoreLocation
import Foundation
import Supabase

// MARK: - Favorite Model (matches Supabase `favorites` table)

struct Favorite: Codable, Identifiable {
    let id: UUID?
    let userId: UUID
    let placeId: String
    let name: String
    let address: String?
    let rating: Double?
    let latitude: Double
    let longitude: Double
    let category: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId    = "user_id"
        case placeId   = "place_id"
        case name
        case address
        case rating
        case latitude
        case longitude
        case category
        case createdAt = "created_at"
    }
}

// MARK: - Service

@MainActor
class FavoritesService: ObservableObject {

    static let shared = FavoritesService()

    @Published var favorites: [Favorite] = []
    @Published var favoriteIDs: Set<String> = []  // placeIds for quick lookup
    @Published var isLoading = false

    private var supabase: SupabaseClient { SupabaseManager.client }

    private init() {}

    // MARK: - Fetch

    func fetchFavorites() async {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        isLoading = true

        do {
            let result: [Favorite] = try await supabase
                .from("favorites")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            favorites = result
            favoriteIDs = Set(result.map(\.placeId))
        } catch {
            print("Fetch favorites error: \(error)")
        }

        isLoading = false
    }

    // MARK: - Add

    func addFavorite(place: PlaceRow, category: String?) async {
        guard let userId = try? await supabase.auth.session.user.id else { return }

        let fav = Favorite(
            id: nil,
            userId: userId,
            placeId: place.id,
            name: place.name,
            address: place.address,
            rating: place.rating,
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude,
            category: category,
            createdAt: nil
        )

        do {
            try await supabase
                .from("favorites")
                .insert(fav)
                .execute()

            favoriteIDs.insert(place.id)
            await fetchFavorites() // refresh full list
        } catch {
            print("Add favorite error: \(error)")
        }
    }

    // MARK: - Remove

    func removeFavorite(placeId: String) async {
        guard let userId = try? await supabase.auth.session.user.id else { return }

        do {
            try await supabase
                .from("favorites")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .eq("place_id", value: placeId)
                .execute()

            favoriteIDs.remove(placeId)
            favorites.removeAll { $0.placeId == placeId }
        } catch {
            print("Remove favorite error: \(error)")
        }
    }

    // MARK: - Toggle

    func toggleFavorite(place: PlaceRow, category: String?) async {
        if favoriteIDs.contains(place.id) {
            await removeFavorite(placeId: place.id)
        } else {
            await addFavorite(place: place, category: category)
        }
    }

    func isFavorite(_ placeId: String) -> Bool {
        favoriteIDs.contains(placeId)
    }
}
