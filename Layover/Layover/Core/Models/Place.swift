//
//  Place.swift
//  Layover
//
//  Created by Maxwell Hu on 4/6/26.
//

import CoreLocation

struct Place: Identifiable {
    let id: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let rating: Double?
    let types: [String]
    let photoURL: URL?
}
