//
//  ItineraryService.swift
//  Layover
//
//  Created by Maxwell Hu on 4/19/26.
//

import Combine
import CoreLocation
import Foundation
import SwiftUI
import UserNotifications

@MainActor
class ItineraryService: ObservableObject {

    static let shared = ItineraryService()

    @Published var items: [ItineraryItem] = []
    @Published var itineraryName: String = "My Layover"
    @Published var remindersEnabled: Bool = false

    private let storageKey = "layover_itinerary"

    private init() { load() }



    var returnToAirportMinutes: Int {
        items.last?.travelMinutes ?? 0
    }

    var totalTravelMinutes: Int {
        items.reduce(0) { $0 + $1.travelMinutes } + returnToAirportMinutes
    }

    var totalStayMinutes: Int {
        items.reduce(0) { $0 + $1.durationMinutes }
    }

    var totalMinutes: Int {
        totalTravelMinutes + totalStayMinutes
    }

    var isEmpty: Bool { items.isEmpty }

    private let routesService = RoutesService()


    func addPlace(_ place: PlaceRow, travelSeconds: Int, stayMinutes: Int = 30) {
        guard !items.contains(where: { $0.placeId == place.id }) else { return }

        let destination = place.coordinate

        // Determine origin: last stop in itinerary, or user's current location
        let origin: CLLocationCoordinate2D
        if let last = items.last {
            origin = CLLocationCoordinate2D(latitude: last.latitude, longitude: last.longitude)
        } else {
            origin = LayoverViewModel.shared.userCoordinate
        }

        // Use provided travelSeconds if non-zero, otherwise fetch from Routes API
        if travelSeconds > 0 {
            insertItem(place: place, travelSeconds: travelSeconds, stayMinutes: stayMinutes)
        } else {
            routesService.fetchTravelSeconds(from: origin, to: destination) { [weak self] seconds in
                Task { @MainActor [weak self] in
                    self?.insertItem(place: place, travelSeconds: seconds, stayMinutes: stayMinutes)
                }
            }
        }
    }

    private func insertItem(place: PlaceRow, travelSeconds: Int, stayMinutes: Int) {
        guard !items.contains(where: { $0.placeId == place.id }) else { return }
        let item = ItineraryItem(
            id: UUID(),
            placeId: place.id,
            name: place.name,
            address: place.address,
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude,
            durationSeconds: stayMinutes * 60,
            travelSeconds: travelSeconds,
            sortOrder: items.count
        )
        items.append(item)
        save()
    }


    func removeItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        reindex()
        save()
    }

    func removeItem(id: UUID) {
        items.removeAll { $0.id == id }
        reindex()
        save()
    }


    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        reindex()
        save()
    }


    func updateDuration(id: UUID, minutes: Int) {
        if let idx = items.firstIndex(where: { $0.id == id }) {
            items[idx].durationSeconds = minutes * 60
            save()
        }
    }


    func clearAll() {
        items.removeAll()
        save()
    }


    func shareText(departureTime: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MMM d, h:mm a"

        var text = "✈️ \(itineraryName)\n"
        text += "Departure: \(df.string(from: departureTime))\n"
        text += "───────────────\n"

        var currentTime = Date()
        for (i, item) in items.enumerated() {
            if item.travelSeconds > 0 {
                text += " \(item.travelMinutes) min drive\n"
                currentTime = currentTime.addingTimeInterval(Double(item.travelSeconds))
            }
            let tf = DateFormatter()
            tf.dateFormat = "h:mm a"
            text += "\(i + 1). \(item.name)"
            if let addr = item.address { text += "\n   📍 \(addr)" }
            text += "\n   ⏱ \(item.durationMinutes) min stay\n\n"
            currentTime = currentTime.addingTimeInterval(Double(item.durationSeconds))
        }

        if returnToAirportMinutes > 0 {
            text += " \(returnToAirportMinutes) min drive back to airport\n"
        }

        text += "───────────────\n"
        text += "Total: \(totalMinutes) min (\(totalTravelMinutes) min travel + \(totalStayMinutes) min visiting)\n"
        text += "Made with Layover ✈️"
        return text
    }


    func scheduleDepartureReminder(departureTime: Date, bufferMinutes: Int = 90) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            center.removePendingNotificationRequests(withIdentifiers: ["layover-leave", "layover-board"])

            let leaveTime = departureTime.addingTimeInterval(-Double(bufferMinutes) * 60)
            if leaveTime > Date() {
                let content = UNMutableNotificationContent()
                content.title = "Time to Head Back ✈️"
                content.body = "Your flight departs in \(bufferMinutes) minutes. Start heading to the airport!"
                content.sound = .default
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: leaveTime),
                    repeats: false
                )
                center.add(UNNotificationRequest(identifier: "layover-leave", content: content, trigger: trigger))
            }

            let headsUpTime = leaveTime.addingTimeInterval(-15 * 60)
            if headsUpTime > Date() {
                let content = UNMutableNotificationContent()
                content.title = "Heads Up! 🛫"
                content.body = "You should start wrapping up — need to leave in 15 minutes."
                content.sound = .default
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: headsUpTime),
                    repeats: false
                )
                center.add(UNNotificationRequest(identifier: "layover-board", content: content, trigger: trigger))
            }

            Task { @MainActor in self.remindersEnabled = true }
        }
    }

    func cancelNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["layover-leave", "layover-board"])
        remindersEnabled = false
    }

    func toggleReminders(departureTime: Date, bufferMinutes: Int) {
        if remindersEnabled {
            cancelNotifications()
        } else {
            scheduleDepartureReminder(departureTime: departureTime, bufferMinutes: bufferMinutes)
        }
    }


    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([ItineraryItem].self, from: data)
        else { return }
        items = saved
    }

    private func reindex() {
        for i in items.indices { items[i].sortOrder = i }
    }
}
