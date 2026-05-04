//
//  RunwayView.swift
//  PrivateJetManager
//
//  Created by charles chauve on 20/01/2026.
//

import Foundation
import SwiftUI

func bestRunway(
    station: String,
    windDirection: Int
) -> Runway? {

    guard let runways = AirportRunways.data[station] else {
        return nil
    }

    func angleDiff(_ a: Int, _ b: Int) -> Int {
        let diff = abs(a - b)
        return min(diff, 360 - diff)
    }

    return runways.min {
        angleDiff($0.heading, windDirection)
        < angleDiff($1.heading, windDirection)
    }
}

struct RunwayWindView: View {
    let runway: Runway
    let windDirection: Int

    var body: some View {
        ZStack {
            // flèche vent
            Image(systemName: "arrow.up")
                .font(.title2)
                .foregroundColor(.blue)
                .rotationEffect(.degrees(Double(windDirection + 180)))
                .offset(y: -35)

            // texte
            VStack {
                Spacer()
                Text("Piste conseillée : \(runway.name)")
                    .font(.headline)
                    .padding(.top, 8)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 20)
    }
}

