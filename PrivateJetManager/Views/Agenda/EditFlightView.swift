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
    @State private var picName: String = "Comandant de bord"
    let options = ["CHA", "LOZ"]
    @State private var fuel: Int
    @State private var remarks: String
    @State private var remarkTag: RemarkTag = .none
    @State private var isCompleted: Bool

    // MARK: - Init
    init(flight: Flight) {
        self.flight = flight

        _departureDate = State(initialValue: flight.departureDate)
        _arrivalDate = State(initialValue: flight.arrivalDate)

        _departure = State(initialValue: flight.departure)
        _arrival = State(initialValue: flight.arrival)
        _aircraft = State(initialValue: flight.aircraft)
        _registration = State(initialValue: flight.registration)
        _picName = State(initialValue: flight.picName)
        _remarks = State(initialValue: flight.remarks)
        _remarkTag = State(initialValue: flight.remarkTag)
        _fuel = State(initialValue: flight.fuel)
        _isCompleted = State(initialValue: flight.isCompleted)
    }

    // MARK: - Duration
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

                    DatePicker(
                        "Arrivée",
                        selection: $arrivalDate,
                        in: departureDate...,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    Text("Durée : \(durationFormatted)")
                        .foregroundColor(.primary)
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
                }
                
                //MARK: - Carburant
                HStack {
                    Text("Carburant")
                    Spacer()
                    Picker("Quantité", selection: $fuel) {
                        ForEach(0...100, id: \.self) {
                            Text("\($0) L")
                        }
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
                    Button("Annuler") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        updateFlight()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }

    // MARK: - Validation
    private var isFormValid: Bool {
        !departure.isEmpty && !arrival.isEmpty && arrivalDate >= departureDate
    }

    // MARK: - Update
    private func updateFlight() {
        let updatedFlight = Flight(
            id: flight.id,
            departureDate: departureDate,
            arrivalDate: arrivalDate,
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
            lastSyncDate: flight.lastSyncDate
        )

        dataManager.updateFlight(updatedFlight)

        if updatedFlight.googleEventId != nil && APIConfig.isConfigured {
            Task {
                await dataManager.syncFlight(updatedFlight)
            }
        }

        dismiss()
    }
}
