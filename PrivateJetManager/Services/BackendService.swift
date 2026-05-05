//
//  BackendService.swift
//  PrivateJetManager
//
//  Created by charles chauve on 22/01/2026.
//

import Foundation

final class BackendService {
    static let shared = BackendService()
    private init() {}

    private var baseURL: String {
        APIConfig.backendURL
    }

    func fetchLogbook() async throws -> [SheetFlight] {
        guard let url = URL(string: "\(APIConfig.backendURL)/api/sheets/get-logbook") else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let result = try decoder.decode(SheetLogbookResponse.self, from: data)
        return result.flights
    }

    struct SheetLogbookResponse: Decodable {
        let flights: [SheetFlight]
    }

    func syncLogbook(flights: [Flight]) async throws {
        guard APIConfig.isConfigured else {
            throw URLError(.badURL)
        }

        guard let url = URL(string: "\(baseURL)/api/sheets/sync-logbook") else {
            throw URLError(.badURL)
        }

        let syncFlights = flights.map { flight in

            // Calcul automatique de la durée en heures
            let durationHours: Double = {
                if let ft = flight.flightTime, ft > 0 {
                    return ft
                } else {
                    let seconds = flight.arrivalDate.timeIntervalSince(flight.departureDate)
                    return max(0, seconds / 3600)
                }
            }()

            return SyncFlight(
                id: flight.id.uuidString,
                date: flight.departureDate,
                arrivalDate: flight.arrivalDate,
                departure: flight.departure,
                arrival: flight.arrival,
                aircraft: flight.aircraft,
                registration: flight.registration,
                flightTime: durationHours,
                picName: flight.picName,
                remarks: flight.remarks,
                remarkTag: flight.remarkTag.rawValue,
                isRemarkDismissed: flight.isRemarkDismissed,
                fuel: flight.fuel,
                isCompleted: flight.isCompleted,
                hobsDepart: flight.hobsDepart,    // ← transmis au backend
                hobsArrivee: flight.hobsArrivee   // ← transmis au backend
            )
        }

        let body = SyncLogbookRequest(flights: syncFlights)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
}

struct SyncLogbookRequest: Codable {
    let flights: [SyncFlight]
}

struct SyncFlight: Codable {
    let id: String
    let date: Date
    let arrivalDate: Date
    let departure: String
    let arrival: String
    let aircraft: String
    let registration: String
    let flightTime: Double
    let picName: String
    let remarks: String
    let remarkTag: String
    let isRemarkDismissed: Bool
    let fuel: Int
    let isCompleted: Bool
    let hobsDepart: Double?    // ← nouveau
    let hobsArrivee: Double?   // ← nouveau
}
