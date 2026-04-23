//
//  TravelResult.swift
//  Layover
//
//  Created by Maxwell Hu on 4/6/26.
//

import Foundation

struct TravelResult {
    let durationSeconds: Int   // one-way seconds
    let durationText: String   // e.g. "15 mins"
    let distanceText: String   // e.g. "9.0 km"
    let fitsInWindow: Bool     // round-trip + stay ≤ play window
}
