import SwiftUI

struct EditFlightView: View {
    @EnvironmentObject var dataManager: FlightDataManager
    @Environment(\.dismiss) private var dismiss

    let flight: Flight

    // MARK: - Dates
    @State private var departureDate: Date
    @State private var arrivalDate: Date

    // MARK: - Flight info
    @State private var departure: String
    @State private var arrival: String
    @State private var aircraft: String
    @State private var registration: String
    @State private var picName: String
    @State private var fuel: Int
    @State private var remarks: String
    @State private var remarkTag: RemarkTag
    @State private var isCompleted: Bool

    // MARK: - Horamètre
    @State private var hobsDepart: Double
    @State private var hobsArrivee: Double

    // MARK: - Init
    init(flight: Flight) {
        self.flight = flight

        _departureDate = State(initialValue: flight.departureDate)
        _arrivalDate   = State(initialValue: flight.arrivalDate)

        _departure    = State(initialValue: flight.departure)
        _arrival      = State(initialValue: flight.arrival)
        _aircraft     = State(initialValue: flight.aircraft)
        _registration = State(initialValue: flight.registration)
        _picName      = State(initialValue: flight.picName)
        _remarks      = State(initialValue: flight.remarks)
        _remarkTag    = State(initialValue: flight.remarkTag)
        _fuel         = State(initialValue: flight.fuel)
        _isCompleted  = State(initialValue: flight.isCompleted)

        _hobsDepart  = State(initialValue: flight.hobsDepart  ?? 0.0)
        _hobsArrivee = State(initialValue: flight.hobsArrivee ?? 0.0)
    }

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

    // MARK: - Duration (fallback si pas de hobs)
    private var durationFormatted: String {
        let interval = arrivalDate.timeIntervalSince(departureDate)
        guard interval > 0 else { return "--" }
        let totalMinutes = Int(interval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h\(String(format: "%02d", minutes))"
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
                        // Forcer l'arrivée sur le même jour
                        let depComps = Calendar.current.dateComponents([.year, .month, .day], from: newDep)
                        let arrComps = Calendar.current.dateComponents([.hour, .minute], from: arrivalDate)
                        if let updated = Calendar.current.date(from: DateComponents(
                            year: depComps.year, month: depComps.month, day: depComps.day,
                            hour: arrComps.hour, minute: arrComps.minute
                        )) {
                            arrivalDate = updated > newDep ? updated : newDep.addingTimeInterval(3600)
                        }
                        // Recharger l'horamètre de départ selon la nouvelle date
                        if isCompleted && flight.hobsDepart == nil {
                            hobsDepart = previousHobsArrivee(before: newDep, excludingId: flight.id)
                        }
                    }

                    DatePicker(
                        "Arrivée",
                        selection: $arrivalDate,
                        in: departureDate...endOfDay(departureDate),
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    Text("Durée : \(durationFormatted)")
                        .foregroundColor(.primary)
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
                Section(header: Text("Détails")) {
                    Picker("Commandant de bord", selection: $picName) {
                        ForEach(["CHA", "LOZ"], id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                    Toggle("Vol complété", isOn: $isCompleted)
                        .onChange(of: isCompleted) { _, completed in
                            if completed && hobsDepart == 0 {
                                hobsDepart = previousHobsArrivee(before: departureDate, excludingId: flight.id)
                            }
                        }
                }

                // MARK: - Carburant
                HStack {
                    Text("Carburant")
                    Spacer()
                    Picker("Quantité", selection: $fuel) {
                        ForEach(0...100, id: \.self) { Text("\($0) L") }
                    }
                }

                // MARK: - Remarques
                Section(header: Text("Remarques")) {
                    TextEditor(text: $remarks)
                        .frame(height: 100)
                    RemarkTagPicker(selectedTag: $remarkTag)
                }
            }
            .navigationTitle("Modifier le vol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { updateFlight() }
                        .disabled(!isFormValid)
                }
            }
        }
    }

    // MARK: - Helpers

    private func endOfDay(_ date: Date) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        comps.hour = 23
        comps.minute = 59
        return Calendar.current.date(from: comps) ?? date.addingTimeInterval(86399)
    }

    /// Horamètre d'arrivée du vol complété le plus récent AVANT la date donnée,
    /// en excluant le vol en cours d'édition.
    private func previousHobsArrivee(before date: Date, excludingId: UUID) -> Double {
        let previous = dataManager.flights
            .filter {
                $0.id != excludingId &&
                $0.isCompleted &&
                $0.departureDate < date &&
                $0.hobsArrivee != nil
            }
            .sorted { $0.departureDate > $1.departureDate }
            .first
        return previous?.hobsArrivee ?? 1773.0
    }

    // MARK: - Validation
    private var isFormValid: Bool {
        !departure.isEmpty && !arrival.isEmpty && arrivalDate >= departureDate
    }

    // MARK: - Update
    private func updateFlight() {
        let ft = isCompleted && hobsFlightTime > 0 ? hobsFlightTime : flight.flightTime
        let computedArrival = isCompleted && hobsFlightTime > 0
            ? departureDate.addingTimeInterval(hobsFlightTime * 3600)
            : arrivalDate

        let updatedFlight = Flight(
            id: flight.id,
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
            googleEventId: flight.googleEventId,
            lastSyncDate: flight.lastSyncDate,
            flightTime: ft,
            hobsDepart: isCompleted ? hobsDepart : nil,
            hobsArrivee: isCompleted ? hobsArrivee : nil
        )

        dataManager.updateFlight(updatedFlight)

        if updatedFlight.googleEventId != nil && APIConfig.isConfigured {
            Task { await dataManager.syncFlight(updatedFlight) }
        }

        dismiss()
    }
}
