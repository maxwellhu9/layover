//
//  ItineraryItem.swift
//  Layover
//
//  Created by Maxwell Hu on 4/19/26.
//

import CoreLocation
import Foundation

/// A single stop in an itinerary.
struct ItineraryItem: Identifiable, Codable {
    var id: UUID
    var placeId: String
    var name: String
    var address: String?
    var latitude: Double
    var longitude: Double
    var durationSeconds: Int      // time to spend at this place
    var travelSeconds: Int        // travel time from previous stop
    var sortOrder: Int

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var durationMinutes: Int { durationSeconds / 60 }
    var travelMinutes: Int { travelSeconds / 60 }

    enum CodingKeys: String, CodingKey {
        case id
        case placeId        = "place_id"
        case name
        case address
        case latitude
        case longitude
        case durationSeconds = "duration_seconds"
        case travelSeconds   = "travel_seconds"
        case sortOrder       = "sort_order"
    }
}
