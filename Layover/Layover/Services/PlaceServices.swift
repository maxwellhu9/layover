//
//  PlaceServices.swift
//  Layover
//
//  Created by Maxwell Hu on 4/6/26.
//

import CoreLocation
import Foundation

struct Place: Identifiable {
    let id: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let rating: Double?
    let types: [String]
}

class PlacesService {

    private let apiKey: String = {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["GOOGLE_API_KEY"] as? String else {
            fatalError("Missing Secrets.plist or GOOGLE_API_KEY")
        }
        return key
    }()

    func fetchNearbyPlaces(
        coordinate: CLLocationCoordinate2D,
        radiusMeters: Int,
        type: String,
        completion: @escaping (Result<[Place], Error>) -> Void
    ) {
        let url = URL(
            string: "https://places.googleapis.com/v1/places:searchNearby"
        )!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(
            "places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.types",
            forHTTPHeaderField: "X-Goog-FieldMask"
        )

        let body: [String: Any] = [
            "includedTypes": [type],
            "locationRestriction": [
                "circle": [
                    "center": [
                        "latitude": coordinate.latitude,
                        "longitude": coordinate.longitude,
                    ],
                    "radius": Double(radiusMeters),
                ]
            ],
            "maxResultCount": 10,
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data else {
                completion(.failure(PlacesError.noData))
                return
            }
            do {
                let response = try JSONDecoder().decode(
                    PlacesNewResponse.self,
                    from: data
                )
                let places = (response.places ?? []).map { p in
                    Place(
                        id: p.id,
                        name: p.displayName.text,
                        address: p.formattedAddress ?? "No address",
                        coordinate: CLLocationCoordinate2D(
                            latitude: p.location.latitude,
                            longitude: p.location.longitude
                        ),
                        rating: p.rating,
                        types: p.types ?? []
                    )
                }
                completion(.success(places))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - Error

enum PlacesError: Error {
    case noData
}

// MARK: - Decodable structs (matches Places API New JSON)

private struct PlacesNewResponse: Decodable {
    let places: [PlaceResult]?
}

private struct PlaceResult: Decodable {
    let id: String
    let displayName: DisplayName
    let formattedAddress: String?
    let location: LatLng
    let rating: Double?
    let types: [String]?
}

private struct DisplayName: Decodable {
    let text: String
}

private struct LatLng: Decodable {
    let latitude: Double
    let longitude: Double
}
