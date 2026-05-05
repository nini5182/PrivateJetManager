// SheetFlight.swift

import Foundation

struct SheetFlight: Codable {
    let id: String
    let departureDate: String
    let arrivalDate: String
    let date: String
    let departure: String
    let arrival: String
    let aircraft: String
    let registration: String
    let flightTime: Double
    let fuel: Int
    let picName: String
    let remarks: String
    let remarkTag: String?
    let isRemarkDismissed: Bool?
    let isCompleted: Bool

    // MARK: - Horamètre (optionnel — rétrocompatible avec anciens exports)
    let hobsDepart: Double?
    let hobsArrivee: Double?

    var uuid: UUID {
        UUID(uuidString: id) ?? UUID()
    }

    var parsedDepartureDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: departureDate) ?? Date()
    }

    var parsedArrivalDate: Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: arrivalDate) ?? Date()
    }

    var parsedRemarkTag: RemarkTag {
        guard let tagString = remarkTag else { return .none }
        return RemarkTag(rawValue: tagString) ?? .none
    }
}
