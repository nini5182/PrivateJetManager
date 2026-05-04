//
//  Stats.swift
//  PrivateJetManager
//
//  Created by charles chauve on 16/01/2026.
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var dataManager: FlightDataManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    StatCardView(
                        title: "Heures totales Cellule",
                        value: String(format: "%.1f h", dataManager.totalFlightHours + 842),
                        icon: "clock.fill",
                        color: .blue
                    )
                    
                    StatCardView(
                        title: "Vols complétés",
                        value: "\(dataManager.completedFlights.count)",
                        icon: "airplane.circle.fill",
                        color: .green
                    )
                    
                    StatCardView(
                        title: "Vols prévus",
                        value: "\(dataManager.upcomingFlights.count)",
                        icon: "calendar.circle.fill",
                        color: .orange
                    )
                    
                    if !dataManager.completedFlights.isEmpty {
                        StatCardView(
                            title: "Durée moyenne",
                            value: String(format: "%.1f h", dataManager.totalFlightHours / Double(dataManager.completedFlights.count)),
                            icon: "gauge.medium",
                            color: .purple
                        )
                    }
                    
                    SyncStatusCard()
                }
                .padding()
            }
            .navigationTitle("Statistiques")
        }
    }
}
