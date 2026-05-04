// PrivateJetApp.swift - App complète en un seul fichier

import SwiftUI

@main
struct PrivateJetManagerApp: App {
    @StateObject private var dataManager = FlightDataManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .task {
                    await performInitialSync()
                }
        }
    }
    
    @MainActor
    private func performInitialSync() async {
        // Vérifier que l'API est configurée
        guard APIConfig.isConfigured else {
            print("⚠️ API non configurée, pas de sync auto")
            return
        }
        
        // Vérifier qu'on n'a pas déjà sync récemment (éviter de sync à chaque ouverture)
        if let lastSync = dataManager.lastSyncDate {
            let timeSinceLastSync = Date().timeIntervalSince(lastSync)
            // Ne sync que si la dernière sync date de plus de 5 minutes
            if timeSinceLastSync < 300 {
                print("ℹ️ Sync récente (\(Int(timeSinceLastSync))s), pas de nouvelle sync")
                return
            }
        }
        
        print("🔄 Synchronisation automatique avec Google Agenda...")
        await dataManager.syncBidirectional()
        
        if let error = dataManager.syncError {
            print("❌ Erreur sync auto: \(error)")
        } else {
            print("✅ Synchronisation automatique terminée")
        }
    }
}
