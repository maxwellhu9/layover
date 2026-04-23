//
//  RootTabView.swift
//  Layover
//
//  Created by Maxwell Hu on 4/17/26.
//

import MapKit
import SwiftUI

struct RootTabView: View {
    @ObservedObject var vm: LayoverViewModel
    @ObservedObject var itinerary: ItineraryService = .shared
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ExploreView(vm: vm, selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "magnifyingglass" : "magnifyingglass")
                    Text("Explore")
                }
                .tag(0)

            FullMapView(vm: vm)
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "map.fill" : "map")
                    Text("Map")
                }
                .tag(1)

            ItineraryView(vm: vm)
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "suitcase.fill" : "suitcase")
                    Text("Trips")
                }
                .tag(2)
                .badge(itinerary.items.count > 0 ? itinerary.items.count : 0)

            SavedView(vm: vm)
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "heart.fill" : "heart")
                    Text("Saved")
                }
                .tag(3)

            ProfileView(vm: vm)
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(4)
        }
        .tint(AppTheme.primary)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = .systemBackground
            appearance.shadowImage = UIImage()
            appearance.backgroundImage = UIImage()
            
            let lineView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 0.5))
            lineView.backgroundColor = UIColor.separator
            UIGraphicsBeginImageContext(lineView.bounds.size)
            lineView.layer.render(in: UIGraphicsGetCurrentContext()!)
            appearance.shadowImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}


struct FullMapView: View {
    @ObservedObject var vm: LayoverViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var nearbyPlaces: [Place] = []
    @State private var isLoading = false
    @State private var selectedPlace: Place?
    
    private let placesService = PlacesService()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $cameraPosition) {
                    // User location pin
                    Annotation("You", coordinate: vm.userCoordinate) {
                        ZStack {
                            Circle().fill(AppTheme.primary.opacity(0.1)).frame(width: 48, height: 48)
                            Circle().fill(.white).frame(width: 24, height: 24)
                                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                            Circle().fill(AppTheme.primary).frame(width: 12, height: 12)
                        }
                    }
                    
                    // Nearby places pins
                    ForEach(nearbyPlaces, id: \.id) { place in
                        Annotation(place.name, coordinate: place.coordinate) {
                            Button {
                                selectedPlace = place
                            } label: {
                                ZStack {
                                    Circle().fill(.white).frame(width: 36, height: 36)
                                        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
                                    Image(systemName: vm.selectedCategory.icon)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(AppTheme.primary)
                                }
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))

                // Bottom info bar
                VStack(spacing: 0) {
                    // Category indicator
                    HStack(spacing: 10) {
                        Image(systemName: vm.selectedCategory.icon)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.primary)
                        
                        Text(isLoading ? "Finding \(vm.selectedCategory.rawValue.lowercased())..." : "\(nearbyPlaces.count) \(vm.selectedCategory.rawValue.lowercased()) nearby")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.textPrimary)
                        
                        Spacer()
                        
                        if isLoading {
                            ProgressView().scaleEffect(0.8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial)
                }
            }
            .overlay(alignment: .topTrailing) {
                VStack(spacing: 10) {
                    // Re-center button
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            cameraPosition = .region(MKCoordinateRegion(
                                center: vm.userCoordinate,
                                latitudinalMeters: 3000,
                                longitudinalMeters: 3000
                            ))
                        }
                    } label: {
                        Image(systemName: "location")
                            .font(.body.weight(.medium))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    }
                    
                    // Refresh button
                    Button {
                        loadNearbyPlaces()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.body.weight(.medium))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(width: 44, height: 44)
                            .background(.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    }
                }
                .padding(.trailing, 16)
                .padding(.top, 60)
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                cameraPosition = .region(MKCoordinateRegion(
                    center: vm.userCoordinate,
                    latitudinalMeters: 3000,
                    longitudinalMeters: 3000
                ))
                loadNearbyPlaces()
            }
            .onChange(of: vm.selectedCategory) { _, _ in
                loadNearbyPlaces()
            }
            .sheet(item: $selectedPlace) { place in
                MapPlaceDetailSheet(place: place, vm: vm)
                    .presentationDetents([.medium])
            }
        }
    }
    
    private func loadNearbyPlaces() {
        isLoading = true
        placesService.fetchNearbyPlaces(
            coordinate: vm.userCoordinate,
            radiusMeters: 5000,
            type: vm.selectedCategory.apiType  // Use the default category from profile
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                if case .success(let places) = result {
                    nearbyPlaces = places
                }
            }
        }
    }
}


struct MapPlaceDetailSheet: View {
    let place: Place
    @ObservedObject var vm: LayoverViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with photo
            if let photoURL = place.photoURL {
                AsyncImage(url: photoURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Rectangle().fill(Color(.systemGray5))
                    }
                }
                .frame(height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(place.name)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.textPrimary)
                
                if !place.address.isEmpty {
                    Text(place.address)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                
                if let rating = place.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(AppTheme.warning)
                        Text(String(format: "%.1f", rating))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
            }
            
            // Action button
            Button {
                // Convert Place to PlaceRow for ItineraryService
                let placeRow = PlaceRow(
                    id: place.id,
                    name: place.name,
                    address: place.address,
                    rating: place.rating,
                    coordinate: place.coordinate,
                    durationText: "—",
                    distanceText: "—",
                    durationSeconds: 0,
                    fits: true,
                    photoURL: place.photoURL
                )
                ItineraryService.shared.addPlace(placeRow, travelSeconds: 0, stayMinutes: vm.visitMinutes)
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add to Trip")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 12))
            }
            
            Spacer()
        }
        .padding(20)
    }
}

#Preview { RootTabView(vm: LayoverViewModel.shared) }
