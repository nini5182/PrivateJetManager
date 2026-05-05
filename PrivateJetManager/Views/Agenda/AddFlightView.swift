import SwiftUI

struct AddFlightView: View {
    @EnvironmentObject var dataManager: FlightDataManager
    @Environment(\.dismiss) private var dismiss

    // MARK: - Dates
    @State private var departureDate = Date()
    @State private var arrivalDate = Calendar.current.date(
        byAdding: .hour, value: 1, to: Date()
    ) ?? Date()

    // MARK: - Flight info
    @State private var departure = "LFQA"
    @State private var arrival = "LFQA"
    @State private var aircraft = "PA12"
    @State private var registration = "N7972H"
    @State private var picName: String = "CHA"
    @State private var remarks = ""
    @State private var remarkTag: RemarkTag = .none
    @State private var fuel: Int = 0
    @State private var isCompleted = false
    @State private var syncWithGoogle = true

    // MARK: - Horamètre
    @State private var hobsDepart: Double = 0.0
    @State private var hobsArrivee: Double = 0.0

    // MARK: - Computed flight time from hobs
    private var hobsFlightTime: Double {
        max(hobsArrivee - hobsDepart, 0)
    }

    private var hobsFlightTimeFormatted: String {
        guard hobsFlightTime > 0 else { return "--" }
        let h = Int(hobsFlightTime)
        let m = Int((hobsFlightTime - Double(h)) * 60)
        return "\(h)h\(String(format: "%02d", m))"
    }

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Horaires
                Section(header: Text("Horaires")) {
                    DatePicker(
                        "Départ",
                        selection: $departureDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .onChange(of: departureDate) { _, newDep in
                        // Garder l'heure d'arrivée mais forcer le même jour
                        let depComps = Calendar.current.dateComponents([.year, .month, .day], from: newDep)
                        let arrComps = Calendar.current.dateComponents([.hour, .minute], from: arrivalDate)
                        if let updated = Calendar.current.date(from: DateComponents(
                            year: depComps.year, month: depComps.month, day: depComps.day,
                            hour: arrComps.hour, minute: arrComps.minute
                        )) {
                            arrivalDate = updated > newDep ? updated : newDep.addingTimeInterval(3600)
                        }
                        // Mettre à jour l'horamètre de départ si vol complété
                        if isCompleted {
                            hobsDepart = previousHobsArrivee(before: newDep)
                        }
                    }

                    DatePicker(
                        "Arrivée",
                        selection: $arrivalDate,
                        in: departureDate...endOfDay(departureDate),
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    Text("Durée : \(previewFlight.durationFormatted)")
                        .foregroundColor(.secondary)
                }

                // MARK: - Horamètre (uniquement si vol complété)
                if isCompleted {
                    Section(header: Text("Horamètre")) {
                        HStack {
                            Text("Départ")
                            Spacer()
                            TextField("0000.0", value: $hobsDepart, format: .number.precision(.fractionLength(1)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                            Text("h")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Arrivée")
                            Spacer()
                            TextField("0000.0", value: $hobsArrivee, format: .number.precision(.fractionLength(1)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                            Text("h")
                                .foregroundColor(.secondary)
                        }
                        .onChange(of: hobsArrivee) { _, newVal in
                            let ft = max(newVal - hobsDepart, 0)
                            if ft > 0 {
                                arrivalDate = departureDate.addingTimeInterval(ft * 3600)
                            }
                        }

                        if hobsFlightTime > 0 {
                            HStack {
                                Text("Temps de vol")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(String(format: "%.1f", hobsFlightTime)) h  (\(hobsFlightTimeFormatted))")
                                    .foregroundColor(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }

                // MARK: - Itinéraire
                Section(header: Text("Itinéraire")) {
                    TextField("Départ (ICAO)", text: $departure)
                        .textInputAutocapitalization(.characters)
                    TextField("Arrivée (ICAO)", text: $arrival)
                        .textInputAutocapitalization(.characters)
                }

                // MARK: - Appareil
                Section(header: Text("Appareil")) {
                    TextField("Modèle", text: $aircraft)
                    TextField("Immatriculation", text: $registration)
                        .textInputAutocapitalization(.characters)
                }

                // MARK: - Détails
                Section(header: Text("Détails du vol")) {
                    Picker("Commandant de bord", selection: $picName) {
                        ForEach(["CHA", "LOZ"], id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    .tint(.blue)
                    Toggle("Vol complété", isOn: $isCompleted)
                        .onChange(of: isCompleted) { _, completed in
                            if completed {
                                hobsDepart = previousHobsArrivee(before: departureDate)
                            }
                        }
                }

                // MARK: - Carburant
                Section(header: Text("Carburant")) {
                    Picker("Carburant", selection: $fuel) {
                        ForEach(0...100, id: \.self) { value in
                            Text("\(value) L").tag(value)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // MARK: - Remarques
                Section(header: Text("Remarques")) {
                    TextEditor(text: $remarks)
                        .frame(height: 100)
                    RemarkTagPicker(selectedTag: $remarkTag)
                }

                // MARK: - Google Sync
                if APIConfig.isConfigured {
                    Section {
                        Toggle("Synchroniser avec Google Agenda", isOn: $syncWithGoogle)
                    }
                }
            }
            .navigationTitle("Nouveau vol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { saveFlight() }
                        .disabled(!isFormValid)
                }
            }
        }
    }

    // MARK: - Helpers

    /// Fin de journée du jour de départ (23h59) pour limiter l'arrivée au même jour
    private func endOfDay(_ date: Date) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        comps.hour = 23
        comps.minute = 59
        return Calendar.current.date(from: comps) ?? date.addingTimeInterval(86399)
    }

    /// Horamètre d'arrivée du vol complété le plus récent AVANT la date donnée.
    /// Si aucun vol trouvé (ou aucun avec hobs renseigné), renvoie la valeur initiale 1773.0
    private func previousHobsArrivee(before date: Date) -> Double {
        let previous = dataManager.flights
            .filter { $0.isCompleted && $0.departureDate < date && $0.hobsArrivee != nil }
            .sorted { $0.departureDate > $1.departureDate }
            .first
        return previous?.hobsArrivee ?? 1773.0
    }

    // MARK: - Preview Flight (pour la durée)
    private var previewFlight: Flight {
        Flight(
            departureDate: departureDate,
            arrivalDate: arrivalDate,
            departure: departure,
            arrival: arrival,
            aircraft: aircraft,
            registration: registration,
            picName: picName,
            remarks: remarks,
            remarkTag: remarkTag,
            fuel: fuel,
            isCompleted: isCompleted,
            googleEventId: nil,
            lastSyncDate: nil
        )
    }

    // MARK: - Validation
    private var isFormValid: Bool {
        !departure.isEmpty && !arrival.isEmpty && arrivalDate >= departureDate
    }

    // MARK: - Save
    private func saveFlight() {
        // Si les hobs sont renseignés, l'heure d'arrivée est recalculée depuis l'horamètre
        let ft = isCompleted && hobsFlightTime > 0 ? hobsFlightTime : nil
        let computedArrival = ft != nil
            ? departureDate.addingTimeInterval(hobsFlightTime * 3600)
            : arrivalDate

        let newFlight = Flight(
            departureDate: departureDate,
            arrivalDate: computedArrival,
            departure: departure.uppercased(),
            arrival: arrival.uppercased(),
            aircraft: aircraft,
            registration: registration.uppercased(),
            picName: picName,
            remarks: remarks,
            remarkTag: remarkTag,
            fuel: fuel,
            isCompleted: isCompleted,
            googleEventId: nil,
            lastSyncDate: nil,
            flightTime: ft,
            hobsDepart: isCompleted ? hobsDepart : nil,
            hobsArrivee: isCompleted ? hobsArrivee : nil
        )

        dataManager.addFlight(newFlight)

        if syncWithGoogle && APIConfig.isConfigured {
            Task { await dataManager.syncFlight(newFlight) }
        }

        dismiss()
    }
}
