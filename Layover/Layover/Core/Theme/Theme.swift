//
//  Theme.swift
//  Layover
//
//  Created by Maxwell Hu on 4/17/26.
//

import SwiftUI

// MARK: - Color Palette

enum AppTheme {

    // Primary
    static let primary      = Color(red: 0.22, green: 0.65, blue: 0.53)  // #38A688
    static let primaryDark  = Color(red: 0.15, green: 0.50, blue: 0.40)  // #268066
    static let primaryLight = Color(red: 0.85, green: 0.96, blue: 0.92)  // #D9F5EB
    static let accent       = Color(red: 0.18, green: 0.58, blue: 0.48)  // #2E9479

    // Backgrounds
    static let backgroundPrimary = Color(red: 0.96, green: 0.98, blue: 0.97) // #F5FAF8
    static let cardBackground    = Color.white
    static let darkBg            = Color(red: 0.10, green: 0.22, blue: 0.18) // #1A382E

    // Text
    static let textPrimary   = Color(red: 0.12, green: 0.14, blue: 0.15)
    static let textSecondary = Color(red: 0.45, green: 0.50, blue: 0.52)
    static let textMuted     = Color(red: 0.68, green: 0.72, blue: 0.74)

    // Status
    static let success = Color(red: 0.22, green: 0.72, blue: 0.46)
    static let warning = Color(red: 0.95, green: 0.68, blue: 0.25)
    static let danger  = Color(red: 0.90, green: 0.32, blue: 0.32)

    // Gradients
    static let primaryGradient = LinearGradient(
        colors: [primary, primaryDark],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.12, green: 0.35, blue: 0.28),
            Color(red: 0.08, green: 0.22, blue: 0.18)
        ],
        startPoint: .top, endPoint: .bottom
    )

    // Card constants
    static let cardShadow: Color = .black.opacity(0.06)
    static let cardRadius: CGFloat = 18
    static let smallRadius: CGFloat = 12
}


struct CardStyle: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.cardRadius))
            .shadow(color: AppTheme.cardShadow, radius: 10, y: 4)
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        modifier(CardStyle(padding: padding))
    }
}


struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                AppTheme.primary.opacity(configuration.isPressed ? 0.8 : 1),
                in: RoundedRectangle(cornerRadius: 14)
            )
            .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
