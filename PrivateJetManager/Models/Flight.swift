//Flight.swift

import Foundation

struct Flight: Identifiable, Codable {
    var id : UUID = UUID()

    var departureDate: Date
    var arrivalDate: Date

    var departure: String
    var arrival: String

    var aircraft: String
    var registration: String

    var picName: String
    var remarks: String
    var remarkTag: RemarkTag = .none
    var isRemarkDismissed: Bool = false
    var fuel: Int

    var isCompleted: Bool
    var googleEventId: String?
    var lastSyncDate: Date?
    
    var flightTime: Double?
}
