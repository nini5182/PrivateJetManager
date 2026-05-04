//
//  Agenda.swift
//  PrivateJetManager
//
//  Created by charles chauve on 16/01/2026.
//

import SwiftUI

struct AgendaView: View {
    @EnvironmentObject var dataManager: FlightDataManager
    @State private var showingAddFlight = false
    @State private var showSyncAlert = false
    @State private var syncAlertMessage = ""
    @State private var syncSuccess = false
    
    var body: some View {
        NavigationView {
            List {
                if dataManager.upcomingFlights.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Aucun vol prévu")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                } else {
                    ForEach(dataManager.upcomingFlights) { flight in
                        NavigationLink(destination: FlightDetailView(flight: flight)) {
                            FlightRowView(flight: flight)
                        }
                    }
                    .onDelete { indexSet in
                        let flightsToDelete = indexSet.map { dataManager.upcomingFlights[$0] }
                        let idsToDelete = flightsToDelete.map { $0.id }
                        dataManager.deleteFlights(ids: idsToDelete)
                    }
                }
            }
            .navigationTitle("Agenda des vols")
            .toolbar {
                // ✅ Bouton sync Google Calendar à gauche
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            await performSync()
                        }
                    }) {
                        if dataManager.isSyncing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                    .disabled(dataManager.isSyncing || !APIConfig.isConfigured)
                }
                
                // Bouton ajouter à droite
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddFlight = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFlight) {
                AddFlightView()
            }
            // ✅ Alerte de résultat de synchronisation
            .alert(syncSuccess ? "Synchronisation réussie" : "Erreur de synchronisation",
                   isPresented: $showSyncAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(syncAlertMessage)
            }
        }
    }
    
    // ✅ Fonction de synchronisation avec gestion des alertes
    @MainActor
    private func performSync() async {
        // Réinitialiser les états
        syncAlertMessage = ""
        syncSuccess = false
        
        // Lancer la synchronisation
        await dataManager.syncBidirectional()
        
        // Afficher le résultat
        if let error = dataManager.syncError {
            syncSuccess = false
            syncAlertMessage = error
        } else {
            syncSuccess = true
            syncAlertMessage = "Vos vols ont été synchronisés avec Google Calendar"
        }
        
        showSyncAlert = true
    }
}
