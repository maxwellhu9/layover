//
//  ItineraryView.swift
//  Layover
//
//  Created by Maxwell Hu on 4/19/26.
//

import SwiftUI

struct ItineraryView: View {
    @ObservedObject var vm: LayoverViewModel
    @ObservedObject var itinerary: ItineraryService = .shared
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if itinerary.isEmpty {
                    emptyState
                } else {
                    itineraryContent
                }
            }
            .background(AppTheme.backgroundPrimary)
            .navigationTitle("My Trip")
            .toolbar {
                if !itinerary.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 12) {
                            Button {
                                showShareSheet = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.body).foregroundStyle(AppTheme.primary)
                            }

                            Button {
                                withAnimation { itinerary.clearAll() }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.body).foregroundStyle(AppTheme.danger)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                let text = itinerary.shareText(departureTime: vm.departureTime)
                ActivityView(items: [text])
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle().fill(AppTheme.primaryLight).frame(width: 100, height: 100)
                Image(systemName: "suitcase")
                    .font(.system(size: 40)).foregroundStyle(AppTheme.primary.opacity(0.5))
            }
            Text("No trip planned yet")
                .font(.title3.weight(.bold)).foregroundStyle(AppTheme.textPrimary)
            Text("Search for places and tap\n\"Add to Trip build your plan")
                .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Content

    private var itineraryContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCard
                timelineSection
                notificationCard
                Spacer(minLength: 100)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(itinerary.itineraryName)
                        .font(.title3.weight(.bold)).foregroundStyle(AppTheme.textPrimary)
                    Text("\(itinerary.items.count) \(itinerary.items.count == 1 ? "stop" : "stops") · \(itinerary.totalMinutes) min total")
                        .font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                timeRing
            }

            HStack(spacing: 0) {
                statPill(icon: "car.fill", label: "Travel", value: "\(itinerary.totalTravelMinutes) min", color: AppTheme.primary)
                statPill(icon: "mappin.circle.fill", label: "Visiting", value: "\(itinerary.totalStayMinutes) min", color: AppTheme.accent)
                statPill(icon: "clock.fill", label: "Available", value: vm.playWindowShort, color: fitsColor)
            }
        }
        .cardStyle(padding: 16)
        .padding(.horizontal, 20)
    }

    private var fitsColor: Color {
        let totalWithBuffer = (itinerary.totalMinutes + vm.boardingBufferMinutes) * 60
        if totalWithBuffer < vm.playWindowSeconds { return AppTheme.success }
        if Double(totalWithBuffer) < Double(vm.playWindowSeconds) * 1.1 { return AppTheme.warning }
        return AppTheme.danger
    }

    private var timeRing: some View {
        let fraction = min(1.0, Double(itinerary.totalMinutes * 60) / Double(max(1, vm.playWindowSeconds)))
        return ZStack {
            Circle().stroke(AppTheme.primaryLight, lineWidth: 5).frame(width: 52, height: 52)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(fitsColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 52, height: 52)
                .rotationEffect(.degrees(-90))
            Text("\(Int(fraction * 100))%")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(fitsColor)
        }
    }

    private func statPill(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(color)
            Text(value).font(.caption.weight(.bold)).foregroundStyle(AppTheme.textPrimary)
            Text(label).font(.system(size: 9)).foregroundStyle(AppTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Start: Airport
            timelineNode(
                icon: "airplane.departure",
                color: AppTheme.primary,
                title: "Airport",
                subtitle: "Start your layover",
                isFirst: true,
                isLast: false
            )

            ForEach(Array(itinerary.items.enumerated()), id: \.element.id) { index, item in
                // Travel connector from previous point to this stop
                travelConnector(minutes: item.travelMinutes)
                // Place stop card
                timelineStop(item: item, index: index)
            }

            // Travel connector back to airport (use the same return estimate as the summary)
            travelConnector(minutes: itinerary.returnToAirportMinutes)

            // End: Return to airport
            timelineNode(
                icon: "airplane.arrival",
                color: AppTheme.primary,
                title: "Back to Airport",
                subtitle: "\(vm.boardingBufferMinutes) min boarding buffer",
                isFirst: false,
                isLast: true
            )
        }
        .padding(.horizontal, 20)
    }

    private func timelineNode(icon: String, color: Color, title: String, subtitle: String, isFirst: Bool, isLast: Bool) -> some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle().fill(color.opacity(0.25)).frame(width: 2, height: 8)
                }
                ZStack {
                    Circle().fill(color.opacity(0.12)).frame(width: 36, height: 36)
                    Image(systemName: icon).font(.system(size: 14)).foregroundStyle(color)
                }
                if !isLast {
                    Rectangle().fill(color.opacity(0.25)).frame(width: 2, height: 8)
                }
            }
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.textPrimary)
                Text(subtitle).font(.caption).foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
        }
    }

    private func travelConnector(minutes: Int) -> some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(AppTheme.primary.opacity(0.2))
                .frame(width: 2)
                .frame(width: 36, height: 36)

            HStack(spacing: 6) {
                Image(systemName: "car.fill").font(.system(size: 11)).foregroundStyle(AppTheme.textMuted)
                Text(minutes > 0 ? "\(minutes) min drive" : "Walking distance")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.textMuted)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemGray6), in: Capsule())

            Spacer()
        }
    }

    private func timelineStop(item: ItineraryItem, index: Int) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Left rail
            VStack(spacing: 0) {
                Rectangle().fill(AppTheme.accent.opacity(0.25)).frame(width: 2, height: 8)
                ZStack {
                    Circle().fill(AppTheme.accent.opacity(0.15)).frame(width: 36, height: 36)
                    Text("\(index + 1)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.accent)
                }
                Rectangle().fill(AppTheme.accent.opacity(0.25)).frame(width: 2, height: 8)
            }
            .frame(width: 36)

            // Stop card
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                if let addr = item.address, !addr.isEmpty {
                    Text(addr)
                        .font(.caption).foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                }

                HStack(spacing: 12) {
                    Label("\(item.durationMinutes) min visit", systemImage: "clock")
                }
                .font(.caption2).foregroundStyle(AppTheme.textMuted)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.06), radius: 6, y: 2)

            // Remove button
            Button {
                withAnimation(.easeInOut) { itinerary.removeItem(id: item.id) }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title3).foregroundStyle(AppTheme.danger.opacity(0.8))
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Notification Card

    private var notificationCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: itinerary.remindersEnabled ? "bell.fill" : "bell.badge.fill")
                    .font(.title3)
                    .foregroundStyle(itinerary.remindersEnabled ? AppTheme.primary : AppTheme.warning)
                VStack(alignment: .leading, spacing: 2) {
                    Text(itinerary.remindersEnabled ? "Reminders Enabled" : "Set Departure Reminder")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.textPrimary)
                    Text(itinerary.remindersEnabled
                         ? "You'll be notified before your flight"
                         : "Get notified \(vm.boardingBufferMinutes) minutes before your flight")
                        .font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
            }

            Button {
                itinerary.toggleReminders(departureTime: vm.departureTime, bufferMinutes: vm.boardingBufferMinutes)
            } label: {
                Text(itinerary.remindersEnabled ? "Disable Reminders" : "Enable Reminders")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        itinerary.remindersEnabled ? AppTheme.danger : AppTheme.warning,
                        in: RoundedRectangle(cornerRadius: 10)
                    )
            }
        }
        .cardStyle(padding: 14)
        .padding(.horizontal, 20)
    }
}

// MARK: - UIKit Share Sheet wrapper

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview { ItineraryView(vm: LayoverViewModel.shared) }
