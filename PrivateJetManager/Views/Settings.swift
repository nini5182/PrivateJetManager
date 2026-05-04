//
//  Settings.swift
//  PrivateJetManager
//
//  Created by charles chauve on 16/01/2026.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var dataManager: FlightDataManager
    @State private var backendURL = APIConfig.backendURL
    @State private var connectionTestResult: Bool?
    @State private var isTestingConnection = false
    @State private var showCleanupAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Configuration Backend"),
                        footer: Text("URL serveur Docker Synology")) {
                    TextField("URL du backend", text: $backendURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                    
                    Button(action: {
                        APIConfig.setBackendURL(backendURL)
                    }) {
                        Text("Enregistrer")
                    }
                    .disabled(backendURL.isEmpty)
                    
                    Button(action: testConnection) {
                        HStack {
                            if isTestingConnection {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("Tester la connexion")
                        }
                    }
                    .disabled(!APIConfig.isConfigured || isTestingConnection)
                    
                    if let result = connectionTestResult {
                        HStack {
                            Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result ? .green : .red)
                            Text(result ? "Connexion réussie" : "Connexion échouée")
                        }
                    }
                }
                
                Section(header: Text("Synchronisation Google Calendar")) {
                    if let lastSync = dataManager.lastSyncDate {
                        HStack {
                            Text("Dernière sync")
                            Spacer()
                            Text(relativeDateString(from: lastSync))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if APIConfig.isConfigured {
                        Button(action: {
                            Task {
                                await dataManager.importFromGoogleCalendar()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                Text("Importer depuis Google Calendar")
                                Spacer()
                                if dataManager.isSyncing {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(dataManager.isSyncing)
                        
                        Button(action: {
                            Task {
                                await dataManager.syncBidirectional()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Synchronisation bidirectionnelle")
                                Spacer()
                                if dataManager.isSyncing {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(dataManager.isSyncing)
                        
                        Button(action: {
                            Task {
                                await dataManager.syncAllFlights()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.circle.fill")
                                Text("Synchroniser tous les vols")
                                Spacer()
                                if dataManager.isSyncing {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(dataManager.isSyncing)
                        
                        if let error = dataManager.syncError {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    } else {
                        Text("Configuration Google Calendar non trouvée")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Informations")) {
                    HStack {
                        Text("Vols enregistrés")
                        Spacer()
                        Text("\(dataManager.flights.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Vols synchronisés")
                        Spacer()
                        Text("\(dataManager.flights.filter { $0.googleEventId != nil }.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                // ✅ NOUVELLE SECTION : Maintenance
                Section(header: Text("Maintenance")) {
                    Button(action: {
                        showCleanupAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.circle.fill")
                                .foregroundColor(.orange)
                            Text("Supprimer les doublons")
                        }
                    }
                }
            }
            .navigationTitle("Réglages")
            .alert("Supprimer les doublons", isPresented: $showCleanupAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Debug: Afficher tous les vols") {
                    print("\n🔍 === DEBUG VOLS ===")
                    for (index, flight) in dataManager.flights.enumerated() {
                        print("\(index+1). \(flight.departure)→\(flight.arrival)")
                        print("   📅 \(flight.departureDate)")
                        print("   🆔 FlightID: \(flight.id)")
                        print("   📆 EventID: \(flight.googleEventId ?? "nil")")
                        print("   ✅ Completed: \(flight.isCompleted)")
                        print("")
                    }
                    print("Total: \(dataManager.flights.count) vols\n")
                }
                Button("Supprimer", role: .destructive) {
                    dataManager.removeDuplicateFlights()
                }
            } message: {
                Text("Cette action va supprimer les vols en double (même date/heure/route). Cette action est irréversible.")
            }
        }
    }
    
    func testConnection() {
        isTestingConnection = true
        connectionTestResult = nil
        
        Task {
            do {
                let result = try await GoogleCalendarService.shared.testConnection()
                await MainActor.run {
                    connectionTestResult = result
                    isTestingConnection = false
                }
            } catch {
                await MainActor.run {
                    connectionTestResult = false
                    isTestingConnection = false
                }
            }
        }
    }
    
    func relativeDateString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
