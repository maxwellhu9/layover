//
//  PlaceRow.swift
//  Layover
//
//  Created by Maxwell Hu on 4/6/26.
//

import CoreLocation

/// A place combined with its travel-time data, ready for display.
struct PlaceRow: Identifiable {
    let id: String
    let name: String
    let address: String
    let rating: Double?
    let coordinate: CLLocationCoordinate2D
    let durationText: String
    let distanceText: String
    let durationSeconds: Int
    let fits: Bool
    let photoURL: URL?
}
