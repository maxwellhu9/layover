//
//  LayoverViewModel.swift
//  Layover
//
//  Created by Maxwell Hu on 4/6/26.
//

import CoreLocation
import Foundation
import Combine

struct PlaceRow: Identifiable {
    let id: String
    let name: String
    let durationText: String
    let fits: Bool
}

class LayoverViewModel: ObservableObject {
    @Published var rows: [PlaceRow] = []
    @Published var isLoading = false

    // Hardcoded POC values
    let airport = CLLocationCoordinate2D(latitude: 40.6413, longitude: -73.7781)  // JFK
    let playWindowSeconds = 3 * 3600 // 3-hour layover
    var placeType = "tourist_attraction" // valid types: restaurant, cafe, tourist_attraction, museum, park, night_club

    private let placesService = PlacesService()
    private let routesService = RoutesService()

    func loadPlaces() {
        isLoading = true
        rows = []

        placesService.fetchNearbyPlaces(
            coordinate: airport,
            radiusMeters: 5000,
            type: placeType
        ) { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure(let error):
                print("Places error: \(error)")
                DispatchQueue.main.async { self.isLoading = false }
            case .success(let places):
                let group = DispatchGroup()
                for place in places {
                    group.enter()
                    self.routesService.checkTravelTime(
                        from: self.airport,
                        to: place.coordinate,
                        playWindowSeconds: self.playWindowSeconds
                    ) { travelResult in
                        if case .success(let travel) = travelResult {
                            let row = PlaceRow(
                                id: place.id,
                                name: place.name,
                                durationText:
                                    "\(travel.durationText) away · \(travel.distanceText)",
                                fits: travel.fitsInWindow
                            )
                            DispatchQueue.main.async { self.rows.append(row) }
                        }
                        group.leave()
                    }
                }
                group.notify(queue: .main) { self.isLoading = false }
            }
        }
    }
}
