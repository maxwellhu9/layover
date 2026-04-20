//
//  Review.swift
//  Layover
//
//  Created by Maxwell Hu on 4/19/26.
//

import Foundation

/// A user review for a specific place, stored in Supabase.
struct Review: Codable, Identifiable {
    let id: UUID?
    let userId: UUID
    let placeId: String
    let rating: Int          // 1-5 stars
    let text: String
    let userName: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId    = "user_id"
        case placeId   = "place_id"
        case rating
        case text
        case userName  = "user_name"
        case createdAt = "created_at"
    }
}
