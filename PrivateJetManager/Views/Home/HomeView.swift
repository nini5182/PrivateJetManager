//
//  HomeView.swift
//  PrivateJetManager
//
//  Created by charles chauve on 16/01/2026.
//

import SwiftUI

struct HomeView: View {
    @State private var metar: METARResponse?
    @State private var isLoadingMETAR = false
    @State private var metarError: String?
    @State private var selectedStation = "LFQA" // par défaut
    @State private var showStationPicker = false
    @EnvironmentObject var dataManager: FlightDataManager
    
    let commonStations = [
        ("LFQA", "Reims Prunay"),
        ("LFPG", "Paris CDG"),
        ("LFPO", "Paris Orly"),
        ("LFOK", "Vatry")
    ]
    
    private var remainingFuel: Int {
        var fuel: Double = FuelConfig.initialFuel

        let completedFlights = dataManager.flights
            .filter { $0.isCompleted }
            .sorted { $0.departureDate < $1.departureDate }

        for flight in completedFlights {
            fuel += Double(flight.fuel)      // carburant ajouté au logbook
            fuel -= flight.fuelConsumed      // carburant consommé
            fuel = max(fuel, 0)
        }

        return Int(fuel.rounded(.down))
    }

    private var fuelColor: Color {
        switch remainingFuel {
        case 0..<30:
            return .red
        case 30..<60:
            return .orange
        default:
            return .green
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Photo de l'avion en pleine largeur
                    ZStack(alignment: .bottom) {
                        Image("piper-photo")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.55, green: 0.08, blue: 0.22), Color(red: 0.86, green: 0.08, blue: 0.24)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(.white.opacity(0.3))
                        
                        // Overlay avec le nom de l'app
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Piper PA-12")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Manager")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .frame(height: 250)
                    .clipped()
                    
                    // Contenu
                    VStack(spacing: 20) {
                        //Carburant
                        HStack(spacing: 8) {
                            Image(systemName: "fuelpump.fill")
                                .foregroundColor(fuelColor)
                                .font(.title2)

                            Text("Carburant restant : \(remainingFuel) L")
                                .font(.headline)
                        }
                        .padding(.top)
                        RemarksSection()

                        // Sélecteur d'aéroport
                        Button(action: { showStationPicker.toggle() }) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                Text(commonStations.first(where: { $0.0 == selectedStation })?.1 ?? selectedStation)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(selectedStation)
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .sheet(isPresented: $showStationPicker) {
                            NavigationView {
                                List(commonStations, id: \.0) { station in
                                    Button(action: {
                                        selectedStation = station.0
                                        showStationPicker = false
                                        Task {
                                            await loadMETAR()
                                        }
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(station.1)
                                                    .fontWeight(.semibold)
                                                Text(station.0)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            if selectedStation == station.0 {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                }
                                .navigationTitle("Choisir un aéroport")
                                .navigationBarTitleDisplayMode(.inline)
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button("Fermer") {
                                            showStationPicker = false
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Widget METAR
                        if isLoadingMETAR {
                            ProgressView("Chargement METAR...")
                                .frame(maxWidth: .infinity)
                                .padding(40)
                        } else if metarError != nil {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.orange)
                                Text("error")
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                Button("Réessayer") {
                                    Task {
                                        await loadMETAR()
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(30)
                            .onAppear {
                                print("🧩 Vue parente affichée")
                            }
                        } else if let metar = metar {
                            METARWidget(metar: metar, station: selectedStation)
                        }
                        
                        // Bouton actualiser
                        Button(action: {
                            Task {
                                await loadMETAR()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Actualiser")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isLoadingMETAR)
                    }
                    .padding()
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("")
                }
            }
        }
        .task {
            await loadMETAR()
        }
    }
    
    func loadMETAR() async {
        isLoadingMETAR = true
        metarError = nil
        
        print("🚀 START: Loading METAR for \(selectedStation)")
        
        do {
            print("⏳ Calling METARService...")
            metar = try await METARService.shared.fetchMETAR(for: selectedStation)
            print("✅ SUCCESS: METAR loaded!")
            if let raw = metar?.raw {
                print("📄 METAR: \(raw)")
            }
        } catch let error as URLError {
            print("❌ URLError: \(error.localizedDescription)")
            print("❌ Code: \(error.code)")
            print("❌ URL: \(error.failingURL?.absoluteString ?? "unknown")")
            metarError = "Erreur réseau: \(error.localizedDescription)"
        } catch {
            print("❌ ERROR: \(error.localizedDescription)")
            print("❌ Type: \(type(of: error))")
            metarError = "Erreur: \(error.localizedDescription)"
        }
        
        isLoadingMETAR = false
        print("🏁 END: Loading complete")
    }
}
