//
//  METARWidget.swift
//  PrivateJetManager
//
//  Created by charles chauve on 16/01/2026.
//

import SwiftUI

struct METARWidget: View {
    let metar: METARResponse
    let station: String
    
    var flightRulesColor: Color {
        switch metar.flight_rules?.uppercased() {
        case "VFR": return .green
        case "MVFR": return .blue
        case "IFR": return .orange
        case "LIFR": return .red
        default: return .gray
        }
    }
    
    var flightRulesText: String {
        switch metar.flight_rules?.uppercased() {
        case "VFR": return "VFR"
        case "MVFR": return "MVFR"
        case "IFR": return "IFR"
        case "LIFR": return "LIFR"
        default: return "N/A"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // En-tête
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("METAR")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(station)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                // Flight Rules Badge
                Text(flightRulesText)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(flightRulesColor)
                    .cornerRadius(20)
            }
            
            Divider()
            
            // Vent
            if let windDir = metar.wind_direction?.value,
               let windSpeed = metar.wind_speed?.value {
                HStack {
                    Image(systemName: "wind")
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Vent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 4) {
                            Text("\(Int(windDir))°")
                                .fontWeight(.semibold)
                            Text("à")
                                .foregroundColor(.secondary)
                            Text("\(Int(windSpeed)) kt")
                                .fontWeight(.semibold)
                            if let gust = metar.wind_gust?.value {
                                Text("rafales \(Int(gust)) kt")
                                    .foregroundColor(.orange)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    Spacer()
                }
            }
            if let windDir = metar.wind_direction?.value.map(Int.init),
               let runway = bestRunway(
                    station: station,
                    windDirection: windDir
               ) {

                RunwayWindView(
                    runway: runway,
                    windDirection: windDir
                )
            }
            
            // Visibilité
            if let visibility = metar.visibility {
                HStack {
                    Image(systemName: "eye")
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Visibilité")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let value = visibility.value {
                            let km = value / 1000
                            Text(km >= 10 ? "> 10 km" : String(format: "%.1f km", km))

                                .fontWeight(.semibold)
                        } else if let repr = visibility.repr {
                            Text(repr)
                                .fontWeight(.semibold)
                        }
                    }
                    Spacer()
                }
            }
            
            // Température / Point de rosée
            HStack(spacing: 20) {
                if let temp = metar.temperature?.value {
                    HStack {
                        Image(systemName: "thermometer")
                            .foregroundColor(.red)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Temp.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(temp))°C")
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                if let dewpoint = metar.dewpoint?.value {
                    HStack {
                        Image(systemName: "drop")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rosée")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(dewpoint))°C")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            
            // QNH
            if let altimeter = metar.altimeter?.value {
                HStack {
                    Image(systemName: "gauge")
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("QNH")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.0f", altimeter)) hPa")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            
            // Nuages
            if let clouds = metar.clouds, !clouds.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "cloud")
                            .foregroundColor(.gray)
                            .frame(width: 30)
                        Text("Nuages")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(clouds.indices, id: \.self) { index in
                        if let cloud = clouds[index].repr {
                            HStack(spacing: 8) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text(cloud)
                                    .font(.subheadline)
                                if let alt = clouds[index].altitude {
                                    Text("à \(alt) ft")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.leading, 38)
                        }
                    }
                }
            }
            
            // Phénomènes météo
            if let wxCodes = metar.wx_codes, !wxCodes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "cloud.rain")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        Text("Phénomènes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ForEach(wxCodes.indices, id: \.self) { index in
                        if let wx = wxCodes[index].value {
                            HStack(spacing: 8) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text(wx)
                                    .font(.subheadline)
                            }
                            .padding(.leading, 38)
                        }
                    }
                }
            }
            
            Divider()
            
            // METAR brut
            if let raw = metar.raw {
                VStack(alignment: .leading, spacing: 8) {
                    Text("METAR brut")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(raw)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            
            // Heure de mise à jour
            if let time = metar.time?.repr {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("Observation : \(time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}
