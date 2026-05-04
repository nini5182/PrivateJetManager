import SwiftUI

struct LogbookRowView: View {
    let flight: Flight

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(flight.departureDate, style: .date)
                        .fontWeight(.semibold)
                
                Text(flight.picName)
                    .fontWeight(.semibold)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.2))
                            .padding(-4)
                    )
                
                HStack {
                    Text(flight.departure)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                    Text(flight.arrival)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(flight.aircraft)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(flight.registration)
                        .font(.caption)
                        .foregroundColor(.secondary)}
            }
            
            if !flight.remarks.isEmpty {
                HStack(spacing: 6) {
                    if flight.remarkTag != .none {
                        Image(systemName: flight.remarkTag.icon)
                            .font(.body)
                            .foregroundColor(flight.remarkTag.color)
                    }
                    
                    Spacer()

                }
            }
            Spacer()

            VStack(alignment: .trailing, spacing: 12) {
                    Text(flight.durationFormatted)
                    .font(.headline)
                    .foregroundColor(.blue)
                
                VStack(alignment: .trailing) {
                    if flight.fuel == 0 {
                        Image(systemName: "fuelpump.fill")
                            .foregroundColor(.red)
                            .fontWeight(.semibold)
                    }
                    if flight.fuel != 0 {
                        Image(systemName: "fuelpump.fill")
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                        Text(" \(flight.fuel) L")
                            .fontWeight(.semibold)
                    }
                }
                
                
                if flight.googleEventId != nil {
                    Image(systemName: "cloud.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
        }
    }
}
