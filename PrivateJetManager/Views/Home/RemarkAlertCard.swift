//
//  RemarkAlertCard.swift
//  PrivateJetManager
//
//  Created by charles chauve on 25/01/2026.
//

import SwiftUI

struct RemarkAlertCard: View {
    let flight: Flight
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icône du tag
            Image(systemName: flight.remarkTag.icon)
                .font(.title2)
                .foregroundColor(flight.remarkTag.color)
            
            // Contenu
            VStack(alignment: .leading, spacing: 6) {
                // En-tête : Tag + route
                HStack {
                    Text(flight.remarkTag.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(flight.remarkTag.color)
                }

                // Date du vol
                Text(formatDate(flight.departureDate))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Texte de la remarque
            Text(flight.remarks)
                .font(.subheadline)
                .foregroundColor(flight.remarkTag.color)
                .lineLimit(3)
            Spacer()
            
            // Bouton fermer
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(flight.remarkTag.color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(flight.remarkTag.color.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}

// Section pour afficher toutes les remarques actives
struct RemarksSection: View {
    @EnvironmentObject var dataManager: FlightDataManager
    
    // Remarques à afficher : non-dismissed, avec tag important/danger/info
    var activeRemarks: [Flight] {
        dataManager.completedFlights.filter { flight in
            !flight.isRemarkDismissed &&
            !flight.remarks.isEmpty &&
            flight.remarkTag != .none
        }
        .sorted { $0.departureDate > $1.departureDate } // Plus récentes en premier
    }
    
    var body: some View {
        if !activeRemarks.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.bubble.fill")
                        .foregroundColor(.orange)
                    Text("Infos Importantes")
                        .font(.headline)
                }
                .padding(.horizontal)
                
                ForEach(activeRemarks) { flight in
                    RemarkAlertCard(flight: flight) {
                        dismissRemark(flight)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func dismissRemark(_ flight: Flight) {
        if let index = dataManager.flights.firstIndex(where: { $0.id == flight.id }) {
            dataManager.flights[index].isRemarkDismissed = true
            dataManager.saveFlights()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        RemarkAlertCard(
            flight: Flight(
                departureDate: Date(),
                arrivalDate: Date().addingTimeInterval(3600),
                departure: "LFPG",
                arrival: "EGLL",
                aircraft: "Citation",
                registration: "F-HXYZ",
                picName: "LOZ",
                remarks: "Problème moteur gauche détecté en vol de croisière",
                remarkTag: .danger,
                fuel: 50,
                isCompleted: true,
                googleEventId: nil,
                lastSyncDate: nil
            )
        ) {
            print("Dismissed")
        }
        
        RemarkAlertCard(
            flight: Flight(
                departureDate: Date(),
                arrivalDate: Date().addingTimeInterval(3600),
                departure: "LFPO",
                arrival: "LFML",
                aircraft: "Citation",
                registration: "F-HXYZ",
                picName: "CHA",
                remarks: "Vérifier la pression des pneus avant prochain vol",
                remarkTag: .important,
                fuel: 30,
                isCompleted: true,
                googleEventId: nil,
                lastSyncDate: nil
            )
        ) {
            print("Dismissed")
        }
    }
    .padding()
}
