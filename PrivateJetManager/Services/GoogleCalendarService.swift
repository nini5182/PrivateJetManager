//
//  GoogleCalendarService.swift
//  PrivateJetManager
//
//  Created by charles chauve on 16/01/2026.
//
import Foundation

enum FlightDescriptionKey {
    static let departure = "Départ:"
    static let arrival   = "Arrivée:"
    static let fuel      = "Carburant:"
    static let registration = "Immatriculation:"
    static let flightId  = "FlightID:"
}

enum APIError: Error {
    case notConfigured
    case invalidRequest
    case invalidResponse
    case serverError
    case authenticationFailed
    case networkError
    
    var localizedDescription: String {
        switch self {
        case .notConfigured:
            return "L'API n'est pas configurée"
        case .invalidRequest:
            return "Requête invalide"
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .serverError:
            return "Erreur du serveur"
        case .authenticationFailed:
            return "Échec de l'authentification"
        case .networkError:
            return "Erreur réseau"
        }
    }
}

class GoogleCalendarService {
    static let shared = GoogleCalendarService()
    private init() {}
    
    func syncLogbook(flights: [Flight]) async throws {
        
    }
    
    func syncFlight(_ flight: Flight) async throws -> String {
        guard APIConfig.isConfigured else {
            throw APIError.notConfigured
        }
        
        let endpoint = flight.googleEventId == nil ? "create-event" : "update-event"
        let url = URL(string: "\(APIConfig.backendURL)/api/calendar/\(endpoint)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let duration = flight.arrivalDate.timeIntervalSince(flight.departureDate)
        let durationHours = max(duration / 3600, 0)
        
        // ✅ FlightID TOTALEMENT CACHÉ dans extendedProperties
        let eventData: [String: Any] = [
            "id": flight.googleEventId ?? "",
            "summary": "Résa \(flight.picName)",
            "description": """
                \(FlightDescriptionKey.departure) \(flight.departure)
                \(FlightDescriptionKey.arrival) \(flight.arrival)
                \(FlightDescriptionKey.fuel) \(flight.fuel)L
                Appareil: \(flight.aircraft)
                Immatriculation: \(flight.registration)
                Commandant: \(flight.picName)
                Durée: \(String(format: "%.1f", durationHours))h
                Remarques: \(flight.remarks)
                """,
            "start": ISO8601DateFormatter().string(from: flight.departureDate),
            "end": ISO8601DateFormatter().string(from: flight.arrivalDate),
            "location": "\(flight.departure) - \(flight.arrival)",
            "extendedProperties": [
                "private": [
                    "flightId": flight.id.uuidString
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: eventData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
        
        let result = try JSONDecoder().decode(CalendarResponse.self, from: data)
        return result.eventId
    }
    
    func deleteFlight(_ flight: Flight) async throws {
        guard APIConfig.isConfigured,
              let eventId = flight.googleEventId else {
            return
        }
        
        let url = URL(string: "\(APIConfig.backendURL)/api/calendar/delete-event")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let deleteData: [String: String] = ["id": eventId]
        request.httpBody = try JSONSerialization.data(withJSONObject: deleteData)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
    }
    
    func testConnection() async throws -> Bool {
        guard APIConfig.isConfigured else {
            throw APIError.notConfigured
        }
        
        let url = URL(string: "\(APIConfig.backendURL)/api/health")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return false
        }
        
        return true
    }
    
    // Récupérer une valeur depuis la description
    private func extractValue(
        from description: String,
        prefix: String
    ) -> String? {
        description
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { $0.lowercased().hasPrefix(prefix.lowercased()) }
            .map {
                $0
                    .dropFirst(prefix.count)
                    .trimmingCharacters(in: .whitespaces)
            }
    }

    func fetchFlights(from startDate: Date, to endDate: Date) async throws -> [Flight] {
        guard APIConfig.isConfigured else {
            throw APIError.notConfigured
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let timeMin = dateFormatter.string(from: startDate)
        let timeMax = dateFormatter.string(from: endDate)
        
        let urlString = "\(APIConfig.backendURL)/api/calendar/list-events?timeMin=\(timeMin)&timeMax=\(timeMax)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidRequest
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
        
        let calendarResponse = try JSONDecoder().decode(CalendarEventsResponse.self, from: data)
        
        var flights: [Flight] = []
        
        for item in calendarResponse.items {
            guard let summary = item.summary,
                  ["Résa CHA", "Résa LOZ"].contains(summary),
                  let startDateTime = item.start.dateTime,
                  let endDateTime = item.end.dateTime else {
                continue
            }

            var picName = summary.replacingOccurrences(of: "Résa ", with: "")
            var aircraft = ""
            var registration = ""
            var remarks = ""
            var fuel: Int = 0
            var flightId: UUID? = nil

            // ✅ 1. D'abord chercher dans extendedProperties (PRIORITÉ)
            if let privateProps = item.extendedProperties?.private,
               let flightIdString = privateProps["flightId"] {
                flightId = UUID(uuidString: flightIdString)
                print("🔍 FlightID trouvé (extendedProperties): \(flightIdString)")
            }

            if let description = item.description {
                let lines = description.components(separatedBy: "\n")
                
                for line in lines {
                    if line.contains("Appareil:") {
                        aircraft = line
                            .replacingOccurrences(of: "Appareil:", with: "")
                            .trimmingCharacters(in: .whitespaces)
                    } else if line.contains("Immatriculation:") {
                        registration = line
                            .replacingOccurrences(of: "Immatriculation:", with: "")
                            .trimmingCharacters(in: .whitespaces)
                    } else if line.contains("Commandant:") {
                        picName = line
                            .replacingOccurrences(of: "Commandant:", with: "")
                            .trimmingCharacters(in: .whitespaces)
                    } else if line.contains("Carburant") {
                        let cleaned = line
                            .replacingOccurrences(of: "Carburant:", with: "")
                            .replacingOccurrences(of: "L", with: "")
                            .trimmingCharacters(in: .whitespaces)
                        fuel = Int(cleaned) ?? 0
                    } else if line.contains("Remarques:") {
                        remarks = line
                            .replacingOccurrences(of: "Remarques:", with: "")
                            .trimmingCharacters(in: .whitespaces)
                    }
                }
                
                // ✅ 2. Fallback : chercher dans description (anciens événements)
                if flightId == nil, let range = description.range(of: "\\[FlightID:([a-fA-F0-9\\-]+)\\]", options: .regularExpression) {
                    let match = String(description[range])
                    let idString = match
                        .replacingOccurrences(of: "[FlightID:", with: "")
                        .replacingOccurrences(of: "]", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    flightId = UUID(uuidString: idString)
                    print("🔍 FlightID trouvé (fallback description): \(idString)")
                }
            }

            let descriptionText = item.description ?? ""
            let departure = extractValue(from: descriptionText, prefix: FlightDescriptionKey.departure)
            let arrival = extractValue(from: descriptionText, prefix: FlightDescriptionKey.arrival)
            
            let finalDeparture = departure ?? "----"
            let finalArrival   = arrival ?? "----"

            // ✅ CORRECTION : Utiliser le FlightID si disponible, sinon créer nouveau UUID
            let flight = Flight(
                id: flightId ?? UUID(), // ✅ Utilise l'ID existant ou crée un nouveau
                departureDate: startDateTime,
                arrivalDate: endDateTime,
                departure: finalDeparture,
                arrival: finalArrival,
                aircraft: aircraft,
                registration: registration,
                picName: picName,
                remarks: remarks,
                fuel: fuel,
                isCompleted: endDateTime < Date(),
                googleEventId: item.id,
                lastSyncDate: Date()
            )

            flights.append(flight)
        }

        return flights
    }
    
    // Structures pour décoder la réponse de Google Calendar
    struct CalendarEventsResponse: Codable {
        let items: [CalendarEvent]
    }
    
    struct CalendarEvent: Codable {
        let id: String
        let summary: String?
        let description: String?
        let start: EventDateTime
        let end: EventDateTime
        let extendedProperties: ExtendedProperties?
    }
    
    struct ExtendedProperties: Codable {
        let `private`: [String: String]?
        
        enum CodingKeys: String, CodingKey {
            case `private`
        }
    }
    
    struct EventDateTime: Codable {
        let dateTime: Date?
        let timeZone: String?
        
        enum CodingKeys: String, CodingKey {
            case dateTime, timeZone
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            timeZone = try container.decodeIfPresent(String.self, forKey: .timeZone)
            
            if let dateTimeString = try container.decodeIfPresent(String.self, forKey: .dateTime) {
                let formatter = ISO8601DateFormatter()
                dateTime = formatter.date(from: dateTimeString)
            } else {
                dateTime = nil
            }
        }
    }
    
    struct CalendarResponse: Codable {
        let eventId: String
    }
}
