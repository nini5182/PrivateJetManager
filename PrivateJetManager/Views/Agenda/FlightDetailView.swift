import SwiftUI

struct FlightDetailView: View {
    @EnvironmentObject var dataManager: FlightDataManager
    @State private var showEdit = false

    let flight: Flight

    var body: some View {
        Form {
            Section(header: Text("Horaires")) {
                Text("Départ : \(flight.departureDate.formatted(date: .abbreviated, time: .shortened))")
                Text("Arrivée : \(flight.arrivalDate.formatted(date: .abbreviated, time: .shortened))")
            }

            Section(header: Text("Itinéraire")) {
                Text("\(flight.departure) → \(flight.arrival)")
            }

            Section(header: Text("Appareil")) {
                Text(flight.aircraft)
                Text(flight.registration)
            }

            Section(header: Text("Détails du Vol")) {
                Text("CdB : \(flight.picName)")
                Text("Avitaillement: \(flight.fuel) L")
                Text(flight.isCompleted ? "Vol effectué" : "Vol prévu")
            }

            if !flight.remarks.isEmpty {
                Section(header: Text("Remarques")) {
                    Text(flight.remarks)
                        .foregroundColor(flight.remarkTag.color)
                }
            }
        }
        .navigationTitle("Détail du vol")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Éditer") {
                    showEdit = true
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            EditFlightView(flight: flight)
                .environmentObject(dataManager)
        }
    }
}
