//
//  ReviewsService.swift
//  Layover
//
//  Created by Maxwell Hu on 4/19/26.
//

import Combine
import Foundation
import Supabase

@MainActor
class ReviewsService: ObservableObject {

    static let shared = ReviewsService()

    @Published var reviews: [Review] = []
    @Published var isLoading = false
    @Published var averageRating: Double?

    private var supabase: SupabaseClient { SupabaseManager.client }
    private var currentPlaceId: String?

    private init() {}


    func fetchReviews(placeId: String) async {
        currentPlaceId = placeId
        isLoading = true

        do {
            let result: [Review] = try await supabase
                .from("reviews")
                .select()
                .eq("place_id", value: placeId)
                .order("created_at", ascending: false)
                .execute()
                .value

            reviews = result
            if !result.isEmpty {
                averageRating = Double(result.map(\.rating).reduce(0, +)) / Double(result.count)
            } else {
                averageRating = nil
            }
        } catch {
            print("Fetch reviews error: \(error)")
        }

        isLoading = false
    }


    func submitReview(placeId: String, rating: Int, text: String) async -> Bool {
        guard let session = try? await supabase.auth.session else { return false }

        let userName = session.user.userMetadata["full_name"]?.value as? String ?? "Anonymous"

        let review = Review(
            id: nil,
            userId: session.user.id,
            placeId: placeId,
            rating: rating,
            text: text,
            userName: userName,
            createdAt: nil
        )

        do {
            try await supabase
                .from("reviews")
                .insert(review)
                .execute()

            await fetchReviews(placeId: placeId)
            return true
        } catch {
            print("Submit review error: \(error)")
            return false
        }
    }


    func deleteReview(id: UUID, placeId: String) async {
        do {
            try await supabase
                .from("reviews")
                .delete()
                .eq("id", value: id.uuidString)
                .execute()

            reviews.removeAll { $0.id == id }
            if let pid = currentPlaceId { await fetchReviews(placeId: pid) }
        } catch {
            print("Delete review error: \(error)")
        }
    }
}
