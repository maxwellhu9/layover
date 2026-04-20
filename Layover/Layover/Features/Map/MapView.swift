//
//  MapView.swift
//  Layover
//
//  Created by Maxwell Hu on 4/16/26.
//

import MapKit
import SwiftUI

struct MapView: View {
    @ObservedObject var vm: LayoverViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                airportAnnotation
                ForEach(vm.rows) { row in placeAnnotation(for: row) }
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))

            legendBar
        }
        .overlay(alignment: .topTrailing) { recenterButton }
        .onAppear {
            if !vm.rows.isEmpty { withAnimation { cameraPosition = .automatic } }
        }
    }

    // MARK: - Annotations

    private var airportAnnotation: some MapContent {
        Annotation("You", coordinate: vm.userCoordinate) {
            ZStack {
                Circle().fill(AppTheme.primary.opacity(0.15)).frame(width: 48, height: 48)
                Circle().fill(AppTheme.primary).frame(width: 30, height: 30)
                    .shadow(color: AppTheme.primary.opacity(0.3), radius: 4, y: 2)
                Image(systemName: "airplane")
                    .font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
            }
        }
    }

    private func placeAnnotation(for row: PlaceRow) -> some MapContent {
        Annotation(row.name, coordinate: row.coordinate, anchor: .bottom) {
            Button { vm.selectedPlace = row } label: {
                VStack(spacing: 0) {
                    ZStack {
                        Circle().fill(pinColor(for: row)).frame(width: 34, height: 34)
                            .shadow(color: pinColor(for: row).opacity(0.4), radius: 4, y: 2)
                        Image(systemName: pinIcon(for: row))
                            .font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                    }
                    Triangle().fill(pinColor(for: row)).frame(width: 12, height: 6)
                }
            }
        }
    }

    // MARK: - Legend

    private var legendBar: some View {
        HStack(spacing: 16) {
            legendDot(color: AppTheme.success, label: "Best",    count: vm.bestOptions.count)
            legendDot(color: AppTheme.warning, label: "Tight",   count: vm.tightTiming.count)
            legendDot(color: AppTheme.danger,  label: "Too far", count: vm.tooFar.count)
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.bottom, 16)
    }

    private var recenterButton: some View {
        Button {
            withAnimation { cameraPosition = .automatic }
        } label: {
            Image(systemName: "scope")
                .font(.body.weight(.medium)).foregroundStyle(AppTheme.primary)
                .padding(10).background(.ultraThinMaterial, in: Circle())
        }
        .padding(.trailing, 12).padding(.top, 8)
    }

    // MARK: - Helpers

    private func pinColor(for row: PlaceRow) -> Color {
        guard row.fits else { return AppTheme.danger }
        let ratio = Double(row.durationSeconds * 2 + 1800) / Double(max(1, vm.playWindowSeconds))
        return ratio < 0.65 ? AppTheme.success : AppTheme.warning
    }

    private func pinIcon(for row: PlaceRow) -> String {
        guard row.fits else { return "xmark" }
        let ratio = Double(row.durationSeconds * 2 + 1800) / Double(max(1, vm.playWindowSeconds))
        return ratio < 0.65 ? "checkmark" : "exclamationmark"
    }

    private func legendDot(color: Color, label: String, count: Int) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(label) (\(count))").font(.caption2.weight(.medium)).foregroundStyle(.primary)
        }
    }
}

#Preview {
    MapView(vm: LayoverViewModel.shared)
}
