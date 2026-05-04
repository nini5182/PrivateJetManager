//
//  StatCardView.swift
//  PrivateJetManager
//
//  Created by charles chauve on 16/01/2026.
//

import SwiftUI

struct SyncStatusCard: View {
    @EnvironmentObject var dataManager: FlightDataManager
    
    var syncedCount: Int {
        dataManager.flights.filter { $0.googleEventId != nil }.count
    }
    
    var body: some View {
        HStack {
            Image(systemName: "cloud.fill")
                .font(.system(size: 40))
                .foregroundColor(APIConfig.isConfigured ? .blue : .gray)
                .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Synchronisation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if APIConfig.isConfigured {
                    Text("\(syncedCount)/\(dataManager.flights.count) vols")
                        .font(.title)
                        .fontWeight(.bold)
                } else {
                    Text("Non configuré")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
