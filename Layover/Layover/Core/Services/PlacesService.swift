//
//  PlacesService.swift
//  Layover
//
//  Created by Maxwell Hu on 4/6/26.
//

import CoreLocation
import Foundation


class PlacesService {

    private let apiKey: String = {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["GOOGLE_API_KEY"] as? String else {
            fatalError("Missing Secrets.plist or GOOGLE_API_KEY")
        }
        return key
    }()

    func photoURL(for photoName: String, maxWidth: Int = 400) -> URL? {
        URL(string: "https://places.googleapis.com/v1/\(photoName)/media?maxWidthPx=\(maxWidth)&key=\(apiKey)")
    }

    func fetchNearbyPlaces(
        coordinate: CLLocationCoordinate2D,
        radiusMeters: Int,
        type: String,
        completion: @escaping (Result<[Place], Error>) -> Void
    ) {
        let url = URL(string: "https://places.googleapis.com/v1/places:searchNearby")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(
            "places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.types,places.photos",
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
            "maxResultCount": 20,
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            if let error {
                completion(.failure(error)); return
            }
            guard let data else {
                completion(.failure(PlacesError.noData)); return
            }
            
            print("Places API response: \(String(data: data, encoding: .utf8) ?? "nil")")
            
            
            do {
                let response = try JSONDecoder().decode(PlacesNewResponse.self, from: data)
                let places = (response.places ?? []).map { p in
                    let photo = p.photos?.first.flatMap { self?.photoURL(for: $0.name) }
                    return Place(
                        id: p.id,
                        name: p.displayName.text,
                        address: p.formattedAddress ?? "No address",
                        coordinate: CLLocationCoordinate2D(
                            latitude: p.location.latitude,
                            longitude: p.location.longitude
                        ),
                        rating: p.rating,
                        types: p.types ?? [],
                        photoURL: photo
                    )
                }
                completion(.success(places))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}



enum PlacesError: Error {
    case noData
}



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
    let photos: [PhotoRef]?
}

private struct DisplayName: Decodable {
    let text: String
}

private struct LatLng: Decodable {
    let latitude: Double
    let longitude: Double
}

private struct PhotoRef: Decodable {
    let name: String
}
