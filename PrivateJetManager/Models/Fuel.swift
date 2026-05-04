//
//  Fuel.swift
//  PrivateJetManager
//
//  Created by charles chauve on 20/01/2026.
//

import Foundation
import SwiftUI

enum FuelConfig {
    static let initialFuel: Double = 140
    static let consumptionPerHour: Double = 23
    static let maxFuel: Double = 140 // optionnel
}

func computeFuelState(for flights: [Flight]) -> [UUID: Int] {

    let sortedFlights = flights.sorted { $0.departureDate < $1.departureDate }

    var currentFuel = FuelConfig.initialFuel
    var result: [UUID: Int] = [:]

    for flight in sortedFlights {

        // 1️⃣ Ajouter le carburant du logbook
        currentFuel += Double(flight.fuel)

        // (optionnel) plafonner à la capacité max
        currentFuel = min(currentFuel, FuelConfig.maxFuel)

        // 2️⃣ Retirer la consommation
        currentFuel -= flight.fuelConsumed

        // éviter valeurs négatives
        currentFuel = max(currentFuel, 0)

        // 3️⃣ Sauvegarde du carburant APRÈS le vol
        result[flight.id] = Int(currentFuel.rounded())
    }

    return result
}

