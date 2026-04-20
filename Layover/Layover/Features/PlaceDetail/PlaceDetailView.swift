//
//  PlaceDetailView.swift
//  Layover
//
//  Created by Maxwell Hu on 4/16/26.
//

import MapKit
import SwiftUI

struct PlaceDetailView: View {
    let place: PlaceRow
    @ObservedObject var vm: LayoverViewModel
    @ObservedObject var auth: AuthViewModel = .shared
    @ObservedObject var favService: FavoritesService = .shared
    @ObservedObject var reviewService: ReviewsService = .shared
    @Environment(\.dismiss) private var dismiss

    @State private var showReviewForm = false
    @State private var reviewRating = 4
    @State private var reviewText = ""

    private var totalTripSeconds: Int { place.durationSeconds * 2 + vm.visitMinutes * 60 }

    private var groupColor: Color {
        guard place.fits else { return AppTheme.danger }
        let ratio = Double(totalTripSeconds) / Double(max(1, vm.playWindowSeconds))
        return ratio < 0.65 ? AppTheme.success : AppTheme.warning
    }

    private var statusLabel: String {
        guard place.fits else { return "Too far to visit" }
        let ratio = Double(totalTripSeconds) / Double(max(1, vm.playWindowSeconds))
        return ratio < 0.65 ? "You've got time!" : "Tight, but doable"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    details.padding(20)
                }
            }
            .background(Color(red: 0.94, green: 0.98, blue: 0.96))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if auth.isSignedIn {
                        Button {
                            Task {
                                await favService.toggleFavorite(
                                    place: place,
                                    category: vm.selectedCategory.apiType
                                )
                            }
                        } label: {
                            Image(systemName: favService.isFavorite(place.id) ? "heart.fill" : "heart")
                                .font(.title3)
                                .foregroundStyle(favService.isFavorite(place.id) ? AppTheme.danger : AppTheme.textSecondary)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3).symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .task { await reviewService.fetchReviews(placeId: place.id) }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Hero Section (photo or map)

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            if let url = place.photoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        mapFallback
                    }
                }
                .frame(height: 220)
                .clipped()
                .overlay(
                    LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .center, endPoint: .bottom)
                )
            } else {
                mapFallback
            }

            // Overlay name
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
                if let rating = place.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").font(.caption).foregroundStyle(AppTheme.warning)
                        Text(String(format: "%.1f", rating)).font(.caption.weight(.bold)).foregroundStyle(.white)
                    }
                }
            }
            .padding(20)
        }
    }

    private var mapFallback: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: place.coordinate,
            latitudinalMeters: 1500, longitudinalMeters: 1500
        ))) {
            Marker(place.name, coordinate: place.coordinate).tint(groupColor)
        }
        .frame(height: 220)
        .allowsHitTesting(false)
    }

    // MARK: - Details

    private var details: some View {
        VStack(alignment: .leading, spacing: 20) {
            statusBanner
            addToItineraryButton
            tripBreakdown
            infoSection
            reviewsSection
            actionButtons
        }
    }

    // MARK: - Status Banner

    private var statusBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: place.fits ? "checkmark.seal.fill" : "xmark.seal.fill").font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(statusLabel).font(.subheadline.weight(.semibold))
                Text("\(totalTripSeconds / 60) min total trip · \(vm.playWindowShort) available")
                    .font(.caption).opacity(0.8)
            }
            Spacer()
        }
        .foregroundStyle(groupColor)
        .padding(14)
        .background(groupColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Add to Trip

    private var addToItineraryButton: some View {
        Button {
            ItineraryService.shared.addPlace(place, travelSeconds: place.durationSeconds, stayMinutes: vm.visitMinutes)
            dismiss()
        } label: {
            Label("Add to Trip", systemImage: "plus.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.primaryLight, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Trip Breakdown

    private var tripBreakdown: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Trip Breakdown").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.textSecondary)

            VStack(spacing: 0) {
                timelineRow(icon: "arrow.right.circle.fill", label: "Drive there",     value: place.durationText, color: AppTheme.primary, showLine: true)
                timelineRow(icon: "mappin.circle.fill",      label: "Time at location", value: "\(vm.visitMinutes) mins",         color: groupColor,       showLine: true)
                timelineRow(icon: "arrow.left.circle.fill",  label: "Drive back",       value: place.durationText, color: AppTheme.primary, showLine: true)
                timelineRow(icon: "shield.checkered",        label: "Boarding buffer",   value: "\(vm.boardingBufferMinutes) mins",         color: AppTheme.textMuted, showLine: false)
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func timelineRow(icon: String, label: String, value: String, color: Color, showLine: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Image(systemName: icon).font(.body).foregroundStyle(color).frame(width: 24, height: 24)
                if showLine {
                    Rectangle().fill(AppTheme.textMuted.opacity(0.3)).frame(width: 1.5, height: 20)
                }
            }
            HStack {
                Text(label).font(.subheadline).foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Text(value).font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.top, 2)
        }
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Details").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.textSecondary)
            infoRow(icon: "mappin.and.ellipse",   text: place.address)
            infoRow(icon: "arrow.left.and.right", text: place.distanceText)

            if let rating = place.rating {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill").foregroundStyle(AppTheme.warning).frame(width: 22)
                    HStack(spacing: 2) {
                        ForEach(0..<5) { i in
                            Image(systemName: Double(i) < rating ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundStyle(Double(i) < rating ? AppTheme.warning : AppTheme.warning.opacity(0.25))
                        }
                    }
                    Text(String(format: "%.1f", rating)).font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(AppTheme.primary).frame(width: 22)
            Text(text).font(.subheadline).foregroundStyle(AppTheme.textPrimary)
        }
    }

    // MARK: - Reviews Section

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Reviews").font(.caption.weight(.semibold)).foregroundStyle(AppTheme.textSecondary)
                Spacer()
                if let avg = reviewService.averageRating {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill").font(.caption2).foregroundStyle(AppTheme.warning)
                        Text(String(format: "%.1f", avg)).font(.caption.weight(.semibold)).foregroundStyle(AppTheme.textPrimary)
                        Text("(\(reviewService.reviews.count))").font(.caption2).foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }

            if auth.isSignedIn {
                if showReviewForm {
                    reviewForm
                } else {
                    Button {
                        withAnimation { showReviewForm = true }
                    } label: {
                        Label("Write a Review", systemImage: "square.and.pencil")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(AppTheme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppTheme.primaryLight, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            } else {
                Text("Sign in to leave a review")
                    .font(.caption).foregroundStyle(AppTheme.textMuted)
            }

            if reviewService.isLoading {
                ProgressView().tint(AppTheme.primary).frame(maxWidth: .infinity)
            } else if reviewService.reviews.isEmpty {
                Text("No reviews yet. Be the first!")
                    .font(.caption).foregroundStyle(AppTheme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                ForEach(reviewService.reviews) { review in
                    reviewCard(review)
                }
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - Review Form

    private var reviewForm: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { star in
                    Button { reviewRating = star } label: {
                        Image(systemName: star <= reviewRating ? "star.fill" : "star")
                            .font(.title3)
                            .foregroundStyle(star <= reviewRating ? AppTheme.warning : AppTheme.warning.opacity(0.3))
                    }
                }
            }

            TextField("Share your experience…", text: $reviewText, axis: .vertical)
                .lineLimit(3...6)
                .padding(10)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))

            HStack(spacing: 10) {
                Button("Cancel") {
                    withAnimation {
                        showReviewForm = false
                        reviewText = ""
                        reviewRating = 4
                    }
                }
                .font(.subheadline).foregroundStyle(AppTheme.textSecondary)

                Spacer()

                Button {
                    Task {
                        let success = await reviewService.submitReview(
                            placeId: place.id,
                            rating: reviewRating,
                            text: reviewText
                        )
                        if success {
                            withAnimation {
                                showReviewForm = false
                                reviewText = ""
                                reviewRating = 4
                            }
                        }
                    }
                } label: {
                    Text("Submit")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20).padding(.vertical, 8)
                        .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 8))
                }
                .disabled(reviewText.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(reviewText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
            }
        }
        .padding(12)
        .background(AppTheme.primaryLight.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Review Card

    private func reviewCard(_ review: Review) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(review.userName ?? "Anonymous")
                    .font(.caption.weight(.semibold)).foregroundStyle(AppTheme.textPrimary)
                Spacer()
                HStack(spacing: 2) {
                    ForEach(0..<5) { i in
                        Image(systemName: i < review.rating ? "star.fill" : "star")
                            .font(.system(size: 8))
                            .foregroundStyle(i < review.rating ? AppTheme.warning : AppTheme.warning.opacity(0.25))
                    }
                }
            }

            Text(review.text)
                .font(.caption).foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if let date = review.createdAt {
                Text(date, style: .relative).font(.caption2).foregroundStyle(AppTheme.textMuted)
            }
        }
        .padding(10)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                let item = MKMapItem(placemark: MKPlacemark(coordinate: place.coordinate))
                item.name = place.name
                item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
            } label: {
                Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(AppTheme.primary, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }

            Button {
                let item = MKMapItem(placemark: MKPlacemark(coordinate: place.coordinate))
                item.name = place.name
                item.openInMaps()
            } label: {
                Label("Open in Maps", systemImage: "map")
                    .font(.subheadline.weight(.medium)).frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(AppTheme.primaryLight, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(AppTheme.primary)
            }
        }
    }
}
