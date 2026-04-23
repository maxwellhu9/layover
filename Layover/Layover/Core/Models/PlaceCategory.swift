//
//  PlaceCategory.swift
//  Layover
//
//  Created by Maxwell Hu on 4/17/26.
//

import SwiftUI

enum PlaceCategory: String, CaseIterable, Identifiable {
    case attractions = "Attractions"
    case food        = "Food"
    case cafes       = "Cafes"
    case shopping    = "Shopping"
    case nightlife   = "Nightlife"
    case parks       = "Parks"

    var id: String { rawValue }

    var apiType: String {
        switch self {
        case .attractions: return "tourist_attraction"
        case .food:        return "restaurant"
        case .cafes:       return "coffee_shop"
        case .shopping:    return "shopping_mall"
        case .nightlife:   return "night_club"
        case .parks:       return "park"
        }
    }

    var icon: String {
        switch self {
        case .attractions: return "binoculars.fill"
        case .food:        return "fork.knife"
        case .cafes:       return "cup.and.saucer.fill"
        case .shopping:    return "bag.fill"
        case .nightlife:   return "moon.stars.fill"
        case .parks:       return "leaf.fill"
        }
    }

    var color: Color {
        switch self {
        case .attractions: return .cyan
        case .food:        return .orange
        case .cafes:       return .brown
        case .shopping:    return .pink
        case .nightlife:   return .purple
        case .parks:       return .green
        }
    }

    var defaultVisitMinutes: Int {
        switch self {
        case .attractions: return 60
        case .food:        return 45
        case .cafes:       return 30
        case .shopping:    return 60
        case .nightlife:   return 90
        case .parks:       return 45
        }
    }

    var imageURL: URL? {
        let slug: String
        switch self {
        case .attractions: slug = "photo-1499856871958-5b9627545d1a"
        case .food:        slug = "photo-1414235077428-338989a2e8c0"
        case .cafes:       slug = "photo-1509042239860-f550ce710b93"
        case .shopping:    slug = "photo-1441986300917-64674bd600d8"
        case .nightlife:   slug = "photo-1514525253161-7a46d19cd819"
        case .parks:       slug = "photo-1441974231531-c6227db76b6e"
        }
        return URL(string: "https://images.unsplash.com/\(slug)?w=200&h=200&fit=crop&q=80")
    }
}
