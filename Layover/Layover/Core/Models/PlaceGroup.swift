//
//  PlaceGroup.swift
//  Layover
//
//  Created by Maxwell Hu on 4/17/26.
//

import SwiftUI

/// Grouping bucket for results: best / tight / too far.
enum PlaceGroup: String, CaseIterable {
    case bestOptions  = "Best Options"
    case tightTiming  = "Tight Timing"
    case tooFar       = "Too Far"

    var icon: String {
        switch self {
        case .bestOptions:  return "checkmark.circle.fill"
        case .tightTiming:  return "exclamationmark.triangle.fill"
        case .tooFar:       return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .bestOptions:  return AppTheme.success
        case .tightTiming:  return AppTheme.warning
        case .tooFar:       return AppTheme.danger
        }
    }
}
