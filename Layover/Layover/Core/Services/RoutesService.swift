//
//  RoutesService.swift
//  Layover
//
//  Created by Maxwell Hu on 4/6/26.
//

import CoreLocation
import Foundation


class RoutesService {

    private let apiKey: String = {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["GOOGLE_API_KEY"] as? String else {
            fatalError("Missing Secrets.plist or GOOGLE_API_KEY")
        }
        return key
    }()

    func fetchTravelSeconds(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        completion: @escaping (Int) -> Void
    ) {
        let url = URL(string: "https://routes.googleapis.com/directions/v2:computeRoutes")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("routes.duration", forHTTPHeaderField: "X-Goog-FieldMask")

        let body: [String: Any] = [
            "origin": ["location": ["latLng": ["latitude": origin.latitude, "longitude": origin.longitude]]],
            "destination": ["location": ["latLng": ["latitude": destination.latitude, "longitude": destination.longitude]]],
            "travelMode": "DRIVE",
            "routingPreference": "TRAFFIC_AWARE"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data,
                  let response = try? JSONDecoder().decode(RoutesResponse.self, from: data),
                  let durationString = response.routes?.first?.duration else {
                completion(0); return
            }
            let seconds = Int(durationString.dropLast()) ?? 0
            completion(seconds)
        }.resume()
    }

    func checkTravelTime(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D,
        playWindowSeconds: Int,
        minimumStaySeconds: Int = 1800,
        completion: @escaping (Result<TravelResult, Error>) -> Void
    ) {
        let url = URL(string: "https://routes.googleapis.com/directions/v2:computeRoutes")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("routes.duration,routes.distanceMeters", forHTTPHeaderField: "X-Goog-FieldMask")

        let body: [String: Any] = [
            "origin": [
                "location": [
                    "latLng": ["latitude": origin.latitude, "longitude": origin.longitude]
                ]
            ],
            "destination": [
                "location": [
                    "latLng": ["latitude": destination.latitude, "longitude": destination.longitude]
                ]
            ],
            "travelMode": "DRIVE",
            "routingPreference": "TRAFFIC_AWARE"
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(error)); return
            }
            guard let data else {
                completion(.failure(RoutesServiceError.noData)); return
            }
            do {
                let response = try JSONDecoder().decode(RoutesResponse.self, from: data)

                guard let route = response.routes?.first else {
                    completion(.failure(RoutesServiceError.noRoute)); return
                }

                let durationString = route.duration ?? "0s"
                let onewaySeconds = Int(durationString.dropLast()) ?? 0
                let distanceMeters = route.distanceMeters ?? 0

                let roundTripNeeded = (onewaySeconds * 2) + minimumStaySeconds
                let fits = roundTripNeeded <= playWindowSeconds

                let result = TravelResult(
                    durationSeconds: onewaySeconds,
                    durationText: Self.formatDuration(onewaySeconds),
                    distanceText: Self.formatDistance(distanceMeters),
                    fitsInWindow: fits
                )
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }


    private static func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        if mins < 60 { return "\(mins) mins" }
        let hrs = mins / 60
        let remainder = mins % 60
        return remainder > 0 ? "\(hrs) hr \(remainder) mins" : "\(hrs) hr"
    }

    private static func formatDistance(_ meters: Int) -> String {
        if meters >= 1000 {
            return String(format: "%.1f km", Double(meters) / 1000.0)
        }
        return "\(meters) m"
    }
}

enum RoutesServiceError: Error {
    case noData
    case noRoute
}


private struct RoutesResponse: Decodable {
    let routes: [RouteData]?
}

private struct RouteData: Decodable {
    let duration: String?
    let distanceMeters: Int?
}
