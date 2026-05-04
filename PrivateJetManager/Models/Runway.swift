//
//  Runway.swift
//  PrivateJetManager
//
//  Created by charles chauve on 20/01/2026.
//

import Foundation
import SwiftUI

struct Runway {
    let name: String
    let heading: Int
}

enum AirportRunways {
    static let data: [String: [Runway]] = [
        "LFQA": [
            Runway(name: "07", heading: 70),
            Runway(name: "25", heading: 250)
        ],
        "LFPG": [
            Runway(name: "08", heading: 80),
            Runway(name: "26", heading: 260)
        ],
        "LFOK": [
            Runway(name: "10", heading: 100),
            Runway(name: "28", heading: 280)
        ]
    ]
}

