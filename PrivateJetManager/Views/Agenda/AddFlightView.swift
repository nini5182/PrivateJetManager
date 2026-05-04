import SwiftUI

struct AddFlightView: View {
    @EnvironmentObject var dataManager: FlightDataManager
    @Environment(\.dismiss) private var dismiss

    // MARK: - Dates
    @State private var departureDate = Date()
    @State private var arrivalDate = Calendar.current.date(
        byAdding: .hour,
        value: 1,
        to: Date()
    ) ?? Date()

    // MARK: - Flight info
    @State private var departure = "LFQA"
    @State private var arrival = "LFQA"
    @State private var aircraft = "PA12"
    @State private var registration = "N7972H"
    @State private var picName: String = "Commandant de bord"
    let options = ["CHA", "LOZ"]
    @State private var remarks = ""
    @State private var remarkTag: RemarkTag = .none
    @State private var fuel : Int = 0
    @State private var isCompleted = false
    @State private var syncWithGoogle = true

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

                    Text("Durée : \(previewFlight.durationFormatted)")
                        .foregroundColor(.secondary)
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
                }
                
                //MARK: - Carburant
Section(header: Text("Carburant")) {
    Picker("Carburant", selection: $fuel) {
        ForEach(0...100, id: \.self) { value in
            Text("\(value) L")
            .tag(value)
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
                    Button("Annuler") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        saveFlight()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
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
        !departure.isEmpty &&
        !arrival.isEmpty &&
        arrivalDate >= departureDate
    }

    // MARK: - Save
    private func saveFlight() {
        let newFlight = Flight(
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
            googleEventId: nil,
            lastSyncDate: nil
        )

        dataManager.addFlight(newFlight)

        if syncWithGoogle && APIConfig.isConfigured {
            Task {
                await dataManager.syncFlight(newFlight)
            }
        }

        dismiss()
    }
}
