//
//  Wight & Balance.swift
//  PrivateJetManager
//
//  Created by charles chauve on 20/01/2026.
//

import Foundation
import SwiftUI

// MARK: - Weight & Balance Models
struct WeightBalanceConfig: Codable {
    var emptyWeight: Double // kg
    var emptyArm: Double // pouces depuis le datum
    var maxWeight: Double // kg
    var cgLimitForward: Double // pouces
    var cgLimitAft: Double // pouces
    var fuelCapacity: Double // litres
    var fuelDensity: Double // kg/litre (0.72 pour avgas)
    
    static let piperPA12Default = WeightBalanceConfig(
        emptyWeight: 381, // kg (840 lbs - valeur typique PA-12)
        emptyArm: 78.5, // pouces (199 cm)
        maxWeight: 794, // kg (1750 lbs MTOW certifié)
        cgLimitForward: 73.0, // pouces (185 cm)
        cgLimitAft: 88.5, // pouces (225 cm)
        fuelCapacity: 144, // litres (38 gallons US)
        fuelDensity: 0.72
    )
}

struct WeightStation: Identifiable, Codable {
    var id = UUID()
    var name: String
    var arm: Double // pouces depuis datum (bord d'attaque de l'aile)
    var weight: Double // kg
    var isEnabled: Bool
    
    var moment: Double {
        weight * arm
    }
}

class WeightBalanceCalculator: ObservableObject {
    @Published var config: WeightBalanceConfig
    @Published var stations: [WeightStation]
    @Published var fuelQuantity: Double // litres
    @Published var useMetric: Bool = true // true = cm/kg, false = in/lbs
    
    init() {
        self.config = WeightBalanceConfig.piperPA12Default
        self.fuelQuantity = 100 // litres par défaut
        // PA-12 Super Cruiser : 2 places EN TANDEM SEULEMENT
        self.stations = [
            WeightStation(name: "Pilote (avant)", arm: 80.5, weight: 80, isEnabled: true),
            WeightStation(name: "Passager (arrière)", arm: 118.0, weight: 0, isEnabled: false),
            WeightStation(name: "Bagages", arm: 142.0, weight: 0, isEnabled: false)
        ]
        loadConfig()
    }
    
    var fuelWeight: Double {
        fuelQuantity * config.fuelDensity
    }
    
    var fuelArm: Double {
        82.0 // pouces (position réservoir principal PA-12)
    }
    
    var totalWeight: Double {
        config.emptyWeight +
        fuelWeight +
        stations.filter(\.isEnabled).reduce(0) { $0 + $1.weight }
    }
    
    var totalMoment: Double {
        (config.emptyWeight * config.emptyArm) +
        (fuelWeight * fuelArm) +
        stations.filter(\.isEnabled).reduce(0) { $0 + $1.moment }
    }
    
    var centerOfGravity: Double {
        guard totalWeight > 0 else { return 0 }
        return totalMoment / totalWeight
    }
    
    var isWithinLimits: Bool {
        totalWeight <= config.maxWeight &&
        centerOfGravity >= config.cgLimitForward &&
        centerOfGravity <= config.cgLimitAft
    }
    
    var weightMargin: Double {
        config.maxWeight - totalWeight
    }
    
    var cgStatus: CGStatus {
        let cg = centerOfGravity
        if cg < config.cgLimitForward {
            return .tooForward
        } else if cg > config.cgLimitAft {
            return .tooAft
        } else {
            return .ok
        }
    }
    
    enum CGStatus {
        case ok, tooForward, tooAft
        
        var color: Color {
            switch self {
            case .ok: return .green
            case .tooForward, .tooAft: return .red
            }
        }
        
        var message: String {
            switch self {
            case .ok: return "✅ Centrage OK"
            case .tooForward: return "⚠️ Centrage trop AVANT"
            case .tooAft: return "⚠️ Centrage trop ARRIÈRE"
            }
        }
    }
    
    // Conversions
    func toInches(_ cm: Double) -> Double {
        cm / 2.54
    }
    
    func toCm(_ inches: Double) -> Double {
        inches * 2.54
    }
    
    func toLbs(_ kg: Double) -> Double {
        kg * 2.20462
    }
    
    func toKg(_ lbs: Double) -> Double {
        lbs / 2.20462
    }
    
    func loadConfig() {
        if let data = UserDefaults.standard.data(forKey: "weightBalanceConfig"),
           let decoded = try? JSONDecoder().decode(WeightBalanceConfig.self, from: data) {
            config = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: "weightBalanceStations"),
           let decoded = try? JSONDecoder().decode([WeightStation].self, from: data) {
            stations = decoded
        }
        
        fuelQuantity = UserDefaults.standard.double(forKey: "fuelQuantity")
        if fuelQuantity == 0 {
            fuelQuantity = 100
        }
        
        useMetric = UserDefaults.standard.bool(forKey: "useMetric")
    }
    
    func saveConfig() {
        if let encoded = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(encoded, forKey: "weightBalanceConfig")
        }
        
        if let encoded = try? JSONEncoder().encode(stations) {
            UserDefaults.standard.set(encoded, forKey: "weightBalanceStations")
        }
        
        UserDefaults.standard.set(fuelQuantity, forKey: "fuelQuantity")
        UserDefaults.standard.set(useMetric, forKey: "useMetric")
    }
    
    func reset() {
        fuelQuantity = 100
        for i in stations.indices {
            stations[i].weight = i == 0 ? 80 : 0
            stations[i].isEnabled = i == 0
        }
    }
}
