import SwiftUI

struct LogbookView: View {
    @EnvironmentObject var dataManager: FlightDataManager
    
    @State private var isSyncing = false
    @State private var showSyncResult = false
    @State private var syncMessage: String = ""
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("Avance carburant LOZ")
                            .font(.headline)
                        Spacer()
                        Text("\(String(format: "%.1f", dataManager.avanceCarburantLOZ)) L")
                            .font(.headline)
                            .foregroundColor(dataManager.avanceCarburantLOZ >= 0 ? .green : .red)
                                    }
                                }
                
                Section(header: Text("Total: \(String(format: "%.1f", dataManager.totalFlightHours))h")) {
                    ForEach(dataManager.completedFlights) { flight in
                        NavigationLink(destination: FlightDetailView(flight: flight)) {
                            LogbookRowView(flight: flight)
                        }
                    }
                    .onDelete { indexSet in
                        let flightsToDelete = indexSet.map { dataManager.completedFlights[$0] }
                        let idsToDelete = flightsToDelete.map { $0.id }
                        dataManager.deleteFlights(ids: idsToDelete)
                    }
                }
            }
            .navigationTitle("Carnet de vol")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            Task {
                                await syncToSheets()
                            }
                        } label: {
                            Label("Exporter vers Sheets", systemImage: "icloud.and.arrow.up")
                        }
                        .disabled(isSyncing)
                        
                        Button {
                            Task {
                                await loadFromSheets()
                            }
                        } label: {
                            Label("Importer depuis Sheets", systemImage: "icloud.and.arrow.down")
                        }
                        .disabled(isSyncing)
                        
                        Divider()
                        
                        Button {
                            Task {
                                await syncBidirectional()
                            }
                        } label: {
                            Label("Synchronisation bidirectionnelle", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .disabled(isSyncing)
                        
                    } label: {
                        if isSyncing {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath.circle")
                        }
                    }
                }
            }
            .alert("Synchronisation", isPresented: $showSyncResult) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(syncMessage)
            }
        }
    }
    
    // MARK: - Import FROM Sheets
    @MainActor
    private func loadFromSheets() async {
        isSyncing = true
        
        do {
            let sheetFlights = try await BackendService.shared.fetchLogbook()
            dataManager.mergeFlights(from: sheetFlights)
            
            syncMessage = "✅ \(sheetFlights.count) vol(s) importé(s) depuis Google Sheets"
            showSyncResult = true
            
        } catch {
            syncMessage = "❌ Erreur import: \(error.localizedDescription)"
            showSyncResult = true
            print("❌ Erreur sync Sheets -> App:", error)
        }
        
        isSyncing = false
    }
    
    // MARK: - Export TO Sheets
    @MainActor
    private func syncToSheets() async {
        isSyncing = true
        
        do {
            try await BackendService.shared.syncLogbook(
                flights: dataManager.completedFlights // ✅ Seulement les vols complétés
            )
            
            syncMessage = "✅ \(dataManager.completedFlights.count) vol(s) complété(s) exporté(s) vers Google Sheets"
            showSyncResult = true
            
        } catch {
            syncMessage = "❌ Erreur export: \(error.localizedDescription)"
            showSyncResult = true
        }
        
        isSyncing = false
    }
    
    // MARK: - Sync bidirectionnelle
    @MainActor
    private func syncBidirectional() async {
        isSyncing = true
        
        // 1. Importer depuis Sheets
        do {
            let sheetFlights = try await BackendService.shared.fetchLogbook()
            dataManager.mergeFlights(from: sheetFlights)
        } catch {
            syncMessage = "❌ Erreur import: \(error.localizedDescription)"
            showSyncResult = true
            isSyncing = false
            return
        }
        
        // 2. Exporter vers Sheets (seulement les vols complétés)
        do {
            try await BackendService.shared.syncLogbook(flights: dataManager.completedFlights)
            syncMessage = "✅ Synchronisation bidirectionnelle réussie"
            showSyncResult = true
        } catch {
            syncMessage = "⚠️ Import OK, mais erreur export: \(error.localizedDescription)"
            showSyncResult = true
        }
        
        isSyncing = false
    }
}

