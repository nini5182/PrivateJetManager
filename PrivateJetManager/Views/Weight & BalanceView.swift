//
//  Weight & BalanceView.swift
//  PrivateJetManager
//
//  Created by charles chauve on 20/01/2026.
//

import Foundation
import SwiftUI

// MARK: - Weight & Balance View
struct WeightBalanceView: View {
    @StateObject private var calculator = WeightBalanceCalculator()
    @State private var showingConfig = false
    @FocusState private var focusedField: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Avertissement
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("IMPORTANT")
                                .font(.caption)
                                .fontWeight(.bold)
                            Text("Utilisez les données de VOTRE fiche de pesée")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Résumé
                    SummaryCard(calculator: calculator)
                    
                    // Carburant
                    FuelCard(calculator: calculator)
                    
                    // Stations de charge (2 places + bagages)
                    VStack(spacing: 12) {
                        ForEach($calculator.stations) { $station in
                            StationRow(station: $station, useMetric: calculator.useMetric, focusedField: _focusedField)
                        }
                    }
                    
                    // Graphique CG
                    CGEnvelopeView(calculator: calculator)
                    
                    // Info PA-12
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Piper PA-12 Super Cruiser")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Configuration: 2 places en TANDEM")
                            Text("• MTOW: 794 kg (1750 lbs)")
                            Text("• Carburant: 144 L (38 gal)")
                            Text("• Datum: Bord d'attaque de l'aile")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Boutons
                    HStack(spacing: 15) {
                        Button(action: {
                            focusedField = false
                            calculator.reset()
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Réinitialiser")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            focusedField = false
                            calculator.saveConfig()
                        }) {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("Sauvegarder")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .onTapGesture {
                focusedField = false
            }
            .navigationTitle("Masse & Centrage PA-12")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingConfig = true }) {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Terminé") {
                        focusedField = false
                    }
                }
            }
            .sheet(isPresented: $showingConfig) {
                ConfigView(calculator: calculator)
            }
        }
    }
}

// MARK: - Summary Card (identique)
struct SummaryCard: View {
    @ObservedObject var calculator: WeightBalanceCalculator
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Masse totale")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", calculator.totalWeight))
                            .font(.title)
                            .fontWeight(.bold)
                        Text("kg")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("(\(String(format: "%.0f", calculator.toLbs(calculator.totalWeight))) lbs)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Marge")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", calculator.weightMargin))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(calculator.weightMargin >= 0 ? .green : .red)
                        Text("kg")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Centre de gravité")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", calculator.centerOfGravity))
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("in")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("(\(String(format: "%.0f", calculator.toCm(calculator.centerOfGravity))) cm)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(calculator.cgStatus.message)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(calculator.cgStatus.color)
                }
            }
            
            // Barre de progression du centrage
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Fond - zone interdite avant
                    Rectangle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: geometry.size.width * CGFloat((calculator.config.cgLimitForward - 70) / (95 - 70)))
                    
                    // Zone verte (limites OK)
                    Rectangle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: geometry.size.width * CGFloat((calculator.config.cgLimitAft - calculator.config.cgLimitForward) / (95 - 70)))
                        .offset(x: geometry.size.width * CGFloat((calculator.config.cgLimitForward - 70) / (95 - 70)))
                    
                    // Zone interdite arrière
                    Rectangle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: geometry.size.width * CGFloat((95 - calculator.config.cgLimitAft) / (95 - 70)))
                        .offset(x: geometry.size.width * CGFloat((calculator.config.cgLimitAft - 70) / (95 - 70)))
                    
                    // Position actuelle du CG
                    Circle()
                        .fill(calculator.isWithinLimits ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                        .offset(x: geometry.size.width * CGFloat((calculator.centerOfGravity - 70) / (95 - 70)) - 6)
                }
            }
            .frame(height: 20)
            .cornerRadius(10)
            
            // Légende
            HStack {
                Text("70\"")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1f\"", calculator.config.cgLimitForward))
                    .font(.caption2)
                    .foregroundColor(.green)
                Spacer()
                Text(String(format: "%.1f\"", calculator.config.cgLimitAft))
                    .font(.caption2)
                    .foregroundColor(.green)
                Spacer()
                Text("95\"")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Fuel Card (identique)
struct FuelCard: View {
    @ObservedObject var calculator: WeightBalanceCalculator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "fuelpump.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("Carburant (Avgas 100LL)")
                    .font(.headline)
                Spacer()
                Text("\(String(format: "%.1f", calculator.fuelWeight)) kg")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text("\(String(format: "%.0f", calculator.fuelQuantity)) L")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("(\(String(format: "%.1f", calculator.fuelQuantity * 0.264172)) gal)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(calculator.fuelQuantity / calculator.config.fuelCapacity * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $calculator.fuelQuantity, in: 0...calculator.config.fuelCapacity, step: 5)
                .accentColor(.blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Station Row (avec unités)
struct StationRow: View {
    @Binding var station: WeightStation
    let useMetric: Bool
    @FocusState var focusedField: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Toggle(isOn: $station.isEnabled) {
                    HStack {
                        Image(systemName: station.isEnabled ? "person.fill" : "person")
                            .foregroundColor(station.isEnabled ? .blue : .gray)
                        Text(station.name)
                            .fontWeight(station.isEnabled ? .semibold : .regular)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
            
            if station.isEnabled {
                HStack {
                    Text("Masse:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    TextField("kg", value: $station.weight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .padding(8)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                        .focused($focusedField)
                    Text("kg")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Bras de levier:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.1f\"", station.arm))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("(\(String(format: "%.0f", station.arm * 2.54)) cm)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Moment:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.0f", station.moment))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(station.isEnabled ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture {
            focusedField = false
        }
    }
}

// MARK: - CG Envelope View (ajusté aux vraies limites PA-12)
struct CGEnvelopeView: View {
    @ObservedObject var calculator: WeightBalanceCalculator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Enveloppe de centrage")
                .font(.headline)
            
            GeometryReader { geometry in
                ZStack {
                    // Grille
                    Path { path in
                        for i in 0...6 {
                            let x = geometry.size.width * CGFloat(i) / 6
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                        }
                        for i in 0...5 {
                            let y = geometry.size.height * CGFloat(i) / 5
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        }
                    }
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    
                    // Enveloppe PA-12 (rectangle simplifié)
                    Path { path in
                        let minWeight = 400.0
                        let maxWeight = calculator.config.maxWeight
                        let minCG = calculator.config.cgLimitForward
                        let maxCG = calculator.config.cgLimitAft
                        
                        let x1 = cgToX(minCG, width: geometry.size.width)
                        let x2 = cgToX(maxCG, width: geometry.size.width)
                        let y1 = weightToY(maxWeight, height: geometry.size.height)
                        let y2 = weightToY(minWeight, height: geometry.size.height)
                        
                        path.move(to: CGPoint(x: x1, y: y1))
                        path.addLine(to: CGPoint(x: x2, y: y1))
                        path.addLine(to: CGPoint(x: x2, y: y2))
                        path.addLine(to: CGPoint(x: x1, y: y2))
                        path.closeSubpath()
                    }
                    .fill(Color.green.opacity(0.2))
                    .stroke(Color.green, lineWidth: 2)
                    
                    // Point actuel
                    Circle()
                        .fill(calculator.isWithinLimits ? Color.blue : Color.red)
                        .frame(width: 16, height: 16)
                        .position(
                            x: cgToX(calculator.centerOfGravity, width: geometry.size.width),
                            y: weightToY(calculator.totalWeight, height: geometry.size.height)
                        )
                }
            }
            .frame(height: 250)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Position actuelle", systemImage: "circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Label("Enveloppe autorisée", systemImage: "square.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    func cgToX(_ cg: Double, width: CGFloat) -> CGFloat {
        let minCG = 70.0
        let maxCG = 95.0
        return width * CGFloat((cg - minCG) / (maxCG - minCG))
    }
    
    func weightToY(_ weight: Double, height: CGFloat) -> CGFloat {
        let minWeight = 300.0
        let maxWeight = 900.0
        return height * CGFloat(1.0 - (weight - minWeight) / (maxWeight - minWeight))
    }
}

// MARK: - Config View (ajusté)
struct ConfigView: View {
    @ObservedObject var calculator: WeightBalanceCalculator
    @Environment(\.presentationMode) var presentationMode
    @FocusState private var focusedField: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("⚠️ IMPORTANT"),
                        footer: Text("Utilisez les valeurs de votre fiche de pesée officielle et du manuel de vol")) {
                    Text("Ces valeurs sont indicatives pour un PA-12 typique")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Section(header: Text("Masse à vide")) {
                    HStack {
                        Text("Masse à vide")
                        Spacer()
                        TextField("kg", value: $calculator.config.emptyWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .focused($focusedField)
                        Text("kg")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Bras de levier")
                        Spacer()
                        TextField("in", value: $calculator.config.emptyArm, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .focused($focusedField)
                        Text("in")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Limites")) {
                    HStack {
                        Text("Masse max (MTOW)")
                        Spacer()
                        TextField("kg", value: $calculator.config.maxWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .focused($focusedField)
                        Text("kg")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("CG limite avant")
                        Spacer()
                        TextField("in", value: $calculator.config.cgLimitForward, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .focused($focusedField)
                        Text("in")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("CG limite arrière")
                        Spacer()
                        TextField("in", value: $calculator.config.cgLimitAft, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .focused($focusedField)
                        Text("in")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Carburant")) {
                    HStack {
                        Text("Capacité totale")
                        Spacer()
                        TextField("L", value: $calculator.config.fuelCapacity, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .focused($focusedField)
                        Text("L")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Densité Avgas")
                        Spacer()
                        TextField("kg/L", value: $calculator.config.fuelDensity, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .focused($focusedField)
                        Text("kg/L")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Stations de charge (2 places TANDEM)")) {
                    ForEach($calculator.stations) { $station in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Nom", text: $station.name)
                                .focused($focusedField)
                            HStack {
                                Text("Bras de levier:")
                                Spacer()
                                TextField("in", value: $station.arm, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .focused($focusedField)
                                Text("in")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Configuration PA-12")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        focusedField = false
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        focusedField = false
                        calculator.saveConfig()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Terminé") {
                        focusedField = false
                    }
                }
            }
        }
    }
}
