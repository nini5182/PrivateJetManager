//
//  SheetFlight.swift
//  PrivateJetManager
//
//  Created by charles chauve on 23/01/2026.
//

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
        guard let tagString = remarkTag else { return.none }
        return RemarkTag(rawValue: tagString) ?? .none
    }

}
