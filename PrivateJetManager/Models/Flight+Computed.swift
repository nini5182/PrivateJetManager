import Foundation

extension Flight {

    /// Durée du vol en secondes
    var duration: TimeInterval {
        max(arrivalDate.timeIntervalSince(departureDate), 0)
    }

    /// Durée du vol en heures décimales (ex: 1.5)
    var durationHours: Double {
        let interval = arrivalDate.timeIntervalSince(departureDate)
        return max(interval / 3600, flightTime ?? 0)
    }

    /// Durée formatée (ex: 1h25 / 45 min)
    var durationFormatted: String {
        let totalMinutes = Int(duration / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h\(String(format: "%02d", minutes))"
        } else {
            return "\(minutes) min"
        }
    }
    
    /// Valeur conso carburant
        var fuelConsumed: Double {
            durationHours * FuelConfig.consumptionPerHour
        }
}
