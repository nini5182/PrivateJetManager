//
//  FlightRowView.swift
//  PrivateJetManager
//
//  Created by charles chauve on 16/01/2026.
//

import SwiftUI

func picNameColor(for name: String) -> Color {
    switch name {
    case "CHA":
        return .purple
    case "LOZ":
        return .orange
    default:
        return .secondary
    }
}

struct FlightRowView: View {
    let flight: Flight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(flight.departureDate, style: .date)
                    .font(.headline)
                Spacer()
                
                if flight.googleEventId != nil {
                    Image(systemName: "cloud.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                
                Text(flight.departureDate, style: .time)
                    .font(.headline)
            }
            
            HStack {
                Text("Résa")
                    .fontWeight(.semibold)
                Text(flight.picName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(picNameColor(for: flight.picName))
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                            .padding(-4)
                    )
            }
                        
            HStack {
                Text(flight.departure)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Image(systemName: "arrow.right")
                    .foregroundColor(.blue)
                Text(flight.arrival)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(flight.aircraft)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(flight.registration)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(flight.durationFormatted)
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
    
}
