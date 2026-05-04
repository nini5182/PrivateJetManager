//
//  FlightDataManager.swift
//  PrivateJetManager
//
//  Created by charles chauve on 16/01/2026.
//

import Foundation
import SwiftUI

@MainActor
final class FlightDataManager: ObservableObject {
    @Published var flights: [Flight] = []
    @Published var isSyncing = false
    @Published var syncError: String?
    @Published var lastSyncDate: Date?
    
    init() {
        loadFlights()
        loadLastSyncDate()
    }
    
    func loadFlights() {
        if let data = UserDefaults.standard.data(forKey: "flights"),
           let decoded = try? JSONDecoder().decode([Flight].self, from: data) {
            flights = decoded
        } else {
            // Données d'exemple avec le bon initialiseur
            flights = [
                Flight(
                    id: UUID(),
                    departureDate: Date().addingTimeInterval(-86400 * 5),
                    arrivalDate: Date().addingTimeInterval(-86400 * 5 + 4320), // +1.2h
                    departure: "LFPG",
                    arrival: "EGLL",
                    aircraft: "Citation CJ3",
                    registration: "F-HXYZ",
                    picName: "Jean Dupont",
                    remarks: "Vol commercial",
                    fuel: 0,
                    isCompleted: true,
                    googleEventId: nil,
                    lastSyncDate: nil
                )
            ]
        }
    }
    
    func saveFlights() {
        if let encoded = try? JSONEncoder().encode(flights) {
            UserDefaults.standard.set(encoded, forKey: "flights")
        }
    }
    
    func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
    }
    
    func saveLastSyncDate() {
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
    }
    
    func addFlight(_ flight: Flight) {
        flights.append(flight)
        saveFlights()
    }
    
    func deleteFlight(at offsets: IndexSet) {
        print("⚠️ deleteFlight(at:) appelé - utiliser deleteFlights(ids:) à la place")
    }
    
    func deleteFlights(ids: [UUID]) {
        let flightsToDelete = flights.filter { ids.contains($0.id) }
        
        Task {
            for flight in flightsToDelete {
                if flight.googleEventId != nil {
                    try? await GoogleCalendarService.shared.deleteFlight(flight)
                }
            }
        }
        
        flights.removeAll { ids.contains($0.id) }
        saveFlights()
    }
    
    func deleteFlight(id: UUID) {
        deleteFlights(ids: [id])
    }
    
    func updateFlight(_ flight: Flight) {
        if let index = flights.firstIndex(where: { $0.id == flight.id }) {
            flights[index] = flight
            saveFlights()
        }
    }
    
    @MainActor
    func syncFlight(_ flight: Flight) async {
        isSyncing = true
        syncError = nil
        
        do {
            let eventId = try await GoogleCalendarService.shared.syncFlight(flight)
            
            if let index = flights.firstIndex(where: { $0.id == flight.id }) {
                flights[index].googleEventId = eventId
                flights[index].lastSyncDate = Date()
                saveFlights()
                saveLastSyncDate()
            }
        } catch {
            syncError = error.localizedDescription
        }
        
        isSyncing = false
    }
    
    @MainActor
    func syncAllFlights() async {
        isSyncing = true
        syncError = nil
        
        var syncedCount = 0
        var errorCount = 0
        
        for flight in flights {
            // ✅ 1. Ne synchroniser QUE les vols NON synchronisés ou modifiés
            let needsSync = flight.googleEventId == nil ||
                           (flight.lastSyncDate == nil) ||
                           (flight.lastSyncDate! < flight.departureDate)
            
            if !needsSync {
                print("⏭️ Vol déjà synchronisé: \(flight.departure)→\(flight.arrival)")
                continue
            }
            
            do {
                print("🔄 Sync vol: \(flight.departure)→\(flight.arrival) | EventID: \(flight.googleEventId ?? "nil")")
                let eventId = try await GoogleCalendarService.shared.syncFlight(flight)
                
                if let index = flights.firstIndex(where: { $0.id == flight.id }) {
                    flights[index].googleEventId = eventId
                    flights[index].lastSyncDate = Date()
                    syncedCount += 1
                    print("✅ Synced: \(flight.departure)→\(flight.arrival) | New EventID: \(eventId)")
                }
            } catch APIError.serverError {
                // Si erreur 404 (event supprimé), reset l'eventId et retry
                print("⚠️ Event 404 pour \(flight.departure)→\(flight.arrival), retry sans EventID...")
                if let index = flights.firstIndex(where: { $0.id == flight.id }) {
                    flights[index].googleEventId = nil
                    
                    do {
                        let eventId = try await GoogleCalendarService.shared.syncFlight(flights[index])
                        flights[index].googleEventId = eventId
                        flights[index].lastSyncDate = Date()
                        syncedCount += 1
                        print("✅ Recréé: \(flight.departure)→\(flight.arrival) | EventID: \(eventId)")
                    } catch {
                        errorCount += 1
                        print("❌ Erreur retry vol \(flight.departure)-\(flight.arrival): \(error)")
                    }
                }
            } catch {
                errorCount += 1
                print("❌ Erreur sync vol \(flight.departure)-\(flight.arrival): \(error)")
            }
        }
        
        saveFlights()
        saveLastSyncDate()
        
        if errorCount > 0 {
            syncError = "\(syncedCount) vol(s) synchronisé(s), \(errorCount) erreur(s)"
        } else if syncedCount == 0 {
            syncError = "Tous les vols sont déjà synchronisés"
        } else {
            syncError = nil
        }
        
        isSyncing = false
    }
    
    func importFromGoogleCalendar() async {
        isSyncing = true
        syncError = nil
        
        do {
            let startDate = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
            let endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
            
            let googleFlights = try await GoogleCalendarService.shared.fetchFlights(from: startDate, to: endDate)
            
            var importedCount = 0
            var updatedCount = 0
            
            for googleFlight in googleFlights {
                // ✅ CORRECTION : Chercher d'abord par Flight.id (dans description Calendar)
                if let existingIndex = flights.firstIndex(where: { $0.id == googleFlight.id }) {
                    // Vol trouvé par son ID → Mettre à jour sans écraser l'ID
                    flights[existingIndex].departureDate = googleFlight.departureDate
                    flights[existingIndex].arrivalDate = googleFlight.arrivalDate
                    flights[existingIndex].departure = googleFlight.departure
                    flights[existingIndex].arrival = googleFlight.arrival
                    flights[existingIndex].aircraft = googleFlight.aircraft
                    flights[existingIndex].registration = googleFlight.registration
                    flights[existingIndex].picName = googleFlight.picName
                    flights[existingIndex].remarks = googleFlight.remarks
                    flights[existingIndex].fuel = googleFlight.fuel
                    flights[existingIndex].isCompleted = googleFlight.isCompleted
                    flights[existingIndex].googleEventId = googleFlight.googleEventId
                    flights[existingIndex].lastSyncDate = Date()
                    updatedCount += 1
                }
                // Sinon chercher par googleEventId (ancien système)
                else if let existingIndex = flights.firstIndex(where: { $0.googleEventId == googleFlight.googleEventId }) {
                    // Vol trouvé par googleEventId → Mettre à jour SANS écraser l'ID local
                    flights[existingIndex].departureDate = googleFlight.departureDate
                    flights[existingIndex].arrivalDate = googleFlight.arrivalDate
                    flights[existingIndex].departure = googleFlight.departure
                    flights[existingIndex].arrival = googleFlight.arrival
                    flights[existingIndex].aircraft = googleFlight.aircraft
                    flights[existingIndex].registration = googleFlight.registration
                    flights[existingIndex].picName = googleFlight.picName
                    flights[existingIndex].remarks = googleFlight.remarks
                    flights[existingIndex].fuel = googleFlight.fuel
                    flights[existingIndex].isCompleted = googleFlight.isCompleted
                    flights[existingIndex].lastSyncDate = Date()
                    updatedCount += 1
                }
                // Sinon vérifier s'il y a un vol similaire (date + heure proche)
                else {
                    let similarFlight = flights.first { flight in
                        flight.googleEventId == nil &&
                        abs(flight.departureDate.timeIntervalSince(googleFlight.departureDate)) < 300 // 5 min
                    }
                    
                    if let similarIndex = flights.firstIndex(where: { $0.id == similarFlight?.id }) {
                        // Lier le vol existant à l'événement Google
                        flights[similarIndex].googleEventId = googleFlight.googleEventId
                        flights[similarIndex].lastSyncDate = Date()
                        updatedCount += 1
                    } else {
                        // ✅ Nouveau vol : ajouter tel quel
                        flights.append(googleFlight)
                        importedCount += 1
                    }
                }
            }
            
            saveFlights()
            saveLastSyncDate()
            
            if importedCount > 0 || updatedCount > 0 {
                syncError = nil
                print("✅ Importation réussie: \(importedCount) nouveaux vols, \(updatedCount) mis à jour")
            }
            
        } catch {
            syncError = "Erreur d'importation: \(error.localizedDescription)"
            print("❌ Erreur import: \(error)")
        }
        
        isSyncing = false
    }
    
    func syncBidirectional() async {
        await importFromGoogleCalendar()
        await syncAllFlights()
    }
    
    private func flight(from sheet: SheetFlight) -> Flight {
        let departureDate = sheet.parsedDepartureDate
        let arrivalDate = sheet.parsedArrivalDate
        
        return Flight(
            id: sheet.uuid,
            departureDate: departureDate,
            arrivalDate: arrivalDate,
            departure: sheet.departure,
            arrival: sheet.arrival,
            aircraft: sheet.aircraft,
            registration: sheet.registration,
            picName: sheet.picName,
            remarks: sheet.remarks,
            remarkTag: sheet.parsedRemarkTag,
            isRemarkDismissed: sheet.isRemarkDismissed ?? false, // ✅ Récupérer le statut dismissed
            fuel: sheet.fuel,
            isCompleted: sheet.isCompleted,
            googleEventId: nil,
            lastSyncDate: Date(),
            flightTime: sheet.flightTime
        )
    }
    
    func mergeFlights(from sheetFlights: [SheetFlight]) {
        for sheetFlight in sheetFlights {
            let flightUUID = sheetFlight.uuid
            
            if let index = flights.firstIndex(where: { $0.id == flightUUID }) {
                flights[index] = flight(from: sheetFlight)
            } else {
                flights.append(flight(from: sheetFlight))
            }
        }
        
        // ✅ Trier par date décroissante après import
        flights.sort { $0.departureDate > $1.departureDate }
        
        saveFlights()
    }
        
    var upcomingFlights: [Flight] {
        flights.filter { !$0.isCompleted && $0.departureDate >= Date(timeIntervalSinceNow: -43200) }
            .sorted { $0.departureDate < $1.departureDate }
    }
        
    var completedFlights: [Flight] {
        flights.filter { $0.isCompleted }
            .sorted { $0.departureDate > $1.departureDate }
    }
        
    var totalFlightHours: Double {
        completedFlights.reduce(0) { total, flight in
            let duration = flight.arrivalDate.timeIntervalSince(flight.departureDate)
            guard duration > 0 else { return total }
            return total + (duration / 3600)
        }
    }
    
    // ✅ Calcul avance carburant LOZ
    var avanceCarburantLOZ: Double {
        let lozFlights = completedFlights.filter { $0.picName.uppercased().contains("LOZ") }
        
        let totalFuelPaid = lozFlights.reduce(0.0) { total, flight in
            total + Double(flight.fuel)
        }
        
        let totalFuelConsumed = lozFlights.reduce(0.0) { total, flight in
            let duration = flight.arrivalDate.timeIntervalSince(flight.departureDate)
            let hours = max(0, duration / 3600)
            return total + (hours * 27.0)
        }
        
        return totalFuelPaid - totalFuelConsumed
    }
    
    // ✅ Fonction améliorée pour supprimer les doublons
    func removeDuplicateFlights() {
        print("🧹 Nettoyage des doublons...")
        print("📊 Avant: \(flights.count) vols")
        
        var uniqueFlights: [Flight] = []
        var seenIds: Set<UUID> = []
        var seenEventIds: Set<String> = []
        var seenSignatures: Set<String> = [] // date+heure+départ+arrivée
        
        for flight in flights.sorted(by: { $0.departureDate > $1.departureDate }) {
            let signature = "\(flight.departureDate.timeIntervalSince1970)-\(flight.departure)-\(flight.arrival)"
            
            var isDuplicate = false
            
            // Doublon par ID
            if seenIds.contains(flight.id) {
                print("🗑️ Doublon ID: \(flight.departure)→\(flight.arrival) (\(flight.id))")
                isDuplicate = true
            }
            // Doublon par EventID
            else if let eventId = flight.googleEventId, seenEventIds.contains(eventId) {
                print("🗑️ Doublon EventID: \(flight.departure)→\(flight.arrival) (\(eventId))")
                isDuplicate = true
            }
            // Doublon par signature (même date/heure + même route)
            else if seenSignatures.contains(signature) {
                print("🗑️ Doublon Signature: \(flight.departure)→\(flight.arrival) à \(flight.departureDate)")
                isDuplicate = true
            }
            
            if !isDuplicate {
                uniqueFlights.append(flight)
                seenIds.insert(flight.id)
                if let eventId = flight.googleEventId {
                    seenEventIds.insert(eventId)
                }
                seenSignatures.insert(signature)
            }
        }
        
        let removedCount = flights.count - uniqueFlights.count
        flights = uniqueFlights.sorted { $0.departureDate > $1.departureDate }
        saveFlights()
        
        print("📊 Après: \(flights.count) vols")
        print("✅ \(removedCount) doublon(s) supprimé(s)")
    }
}
