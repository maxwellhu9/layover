//
//  LayoverViewModel.swift
//  Layover
//
//  Created by Maxwell Hu on 4/6/26.
//

import Combine
import CoreLocation
import MapKit
import SwiftUI

/// Central view-model shared across the app. Owns departure state,
/// search results, and grouping logic.
class LayoverViewModel: ObservableObject {

    static let shared = LayoverViewModel()

    // MARK: - Published State

    @Published var rows: [PlaceRow] = []
    @Published var isLoading = false
    @Published var selectedCategory: PlaceCategory = .attractions
    @Published var departureTime: Date = Date().addingTimeInterval(4 * 3600)
    @Published var selectedPlace: PlaceRow? = nil
    @Published var tick: Date = Date()
    @Published var hasSearched = false
    @Published var visitMinutes: Int = 30
    @Published var boardingBufferMinutes: Int = 90
    @Published var customSearchRadius: Int? = nil  // nil = auto

    // MARK: - Dependencies

    let locationManager = LocationManager()

    private let placesService = PlacesService()
    private let routesService = RoutesService()
    private var timer: AnyCancellable?

    // MARK: - Init

    private init() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in self?.tick = date }

        // Auto-start location updates
        locationManager.requestPermission()
        locationManager.startUpdating()
    }

    // MARK: - Computed — Time

    var playWindowSeconds: Int {
        max(0, Int(departureTime.timeIntervalSince(tick) - Double(boardingBufferMinutes) * 60))
    }

    var playWindowFormatted: String {
        let total = playWindowSeconds
        let hrs = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        if hrs > 0 { return String(format: "%dh %02dm %02ds", hrs, mins, secs) }
        if mins > 0 { return String(format: "%dm %02ds", mins, secs) }
        return "\(secs)s"
    }

    var playWindowShort: String {
        let total = playWindowSeconds
        let hrs = total / 3600
        let mins = (total % 3600) / 60
        return hrs > 0 ? "\(hrs)h \(mins)m" : "\(mins)m"
    }

    var departureFormatted: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: departureTime)
    }

    var zoneName: String {
        let hrs = Double(playWindowSeconds) / 3600.0
        switch hrs {
        case ..<1:   return "Terminal only"
        case 1..<2:  return "Short trip zone"
        case 2..<4:  return "City sprint"
        case 4..<8:  return "Urban explorer"
        default:     return "Day trip mode"
        }
    }

    var searchRadius: Int {
        if let custom = customSearchRadius { return custom }
        let hrs = Double(playWindowSeconds) / 3600.0
        switch hrs {
        case ..<1:   return 3_000
        case 1..<2:  return 8_000
        case 2..<4:  return 15_000
        case 4..<8:  return 30_000
        default:     return 50_000
        }
    }

    var searchRadiusLabel: String {
        searchRadius >= 1000 ? "\(searchRadius / 1000) km" : "\(searchRadius) m"
    }

    static let radiusOptions = [3_000, 5_000, 8_000, 15_000, 30_000, 50_000]

    // MARK: - Visit duration options

    static let visitDurations = [15, 30, 45, 60, 90, 120]

    func visitDurationLabel(_ mins: Int) -> String {
        if mins < 60 { return "\(mins) min" }
        let hrs = mins / 60
        let rem = mins % 60
        return rem > 0 ? "\(hrs)h \(rem)m" : "\(hrs)h"
    }

    // MARK: - Computed — Grouped Results

    var bestOptions: [PlaceRow] {
        rows.filter { row in
            guard row.fits else { return false }
            let ratio = Double(row.durationSeconds * 2 + visitMinutes * 60) / Double(max(1, playWindowSeconds))
            return ratio < 0.65
        }
    }

    var tightTiming: [PlaceRow] {
        rows.filter { row in
            guard row.fits else { return false }
            let ratio = Double(row.durationSeconds * 2 + visitMinutes * 60) / Double(max(1, playWindowSeconds))
            return ratio >= 0.65
        }
    }

    var tooFar: [PlaceRow] {
        rows.filter { !$0.fits }
    }

    var reachableCount: Int { rows.filter(\.fits).count }
    var totalCount: Int     { rows.count }

    var userCoordinate: CLLocationCoordinate2D {
        locationManager.lastLocation
            ?? CLLocationCoordinate2D(latitude: 40.6413, longitude: -73.7781) // JFK fallback
    }

    var hasRealLocation: Bool {
        locationManager.lastLocation != nil
    }

    // MARK: - Computed — Summary

    var summaryText: String {
        if rows.isEmpty { return "No results yet" }
        let best = bestOptions.count
        let tight = tightTiming.count
        if best > 0 {
            return "Found \(best) great \(best == 1 ? "option" : "options") nearby!"
        } else if tight > 0 {
            return "\(tight) \(tight == 1 ? "place is" : "places are") reachable, but it'll be tight."
        }
        return "Nothing reachable with your current time window."
    }

    var summaryIcon: String {
        if bestOptions.count > 0   { return "hand.thumbsup.fill" }
        if tightTiming.count > 0   { return "exclamationmark.triangle.fill" }
        return "clock.badge.xmark"
    }

    var summaryColor: Color {
        if bestOptions.count > 0   { return AppTheme.success }
        if tightTiming.count > 0   { return AppTheme.warning }
        return AppTheme.danger
    }

    // MARK: - Actions

    func loadPlaces() {
        isLoading = true
        rows = []
        hasSearched = true

        let coord  = userCoordinate
        let window = playWindowSeconds
        let staySeconds = visitMinutes * 60

        placesService.fetchNearbyPlaces(
            coordinate: coord,
            radiusMeters: searchRadius,
            type: selectedCategory.apiType
        ) { [weak self] result in
            guard let self else { return }

            switch result {
            case .failure(let error):
                print("Places error: \(error)")
                DispatchQueue.main.async { self.isLoading = false }

            case .success(let places):
                let group = DispatchGroup()
                var newRows: [PlaceRow] = []
                let lock = NSLock()

                for place in places {
                    group.enter()
                    self.routesService.checkTravelTime(
                        from: coord,
                        to: place.coordinate,
                        playWindowSeconds: window,
                        minimumStaySeconds: staySeconds
                    ) { travelResult in
                        if case .success(let travel) = travelResult {
                            let row = PlaceRow(
                                id: place.id,
                                name: place.name,
                                address: place.address,
                                rating: place.rating,
                                coordinate: place.coordinate,
                                durationText: travel.durationText,
                                distanceText: travel.distanceText,
                                durationSeconds: travel.durationSeconds,
                                fits: travel.fitsInWindow,
                                photoURL: place.photoURL
                            )
                            lock.lock()
                            newRows.append(row)
                            lock.unlock()
                        }
                        group.leave()
                    }
                }

                group.notify(queue: .main) {
                    self.rows = newRows.sorted {
                        if $0.fits != $1.fits { return $0.fits }
                        return $0.durationSeconds < $1.durationSeconds
                    }
                    self.isLoading = false
                }
            }
        }
    }

    func updateDeparture(_ date: Date) {
        departureTime = date
        if hasSearched { loadPlaces() }
    }
}
