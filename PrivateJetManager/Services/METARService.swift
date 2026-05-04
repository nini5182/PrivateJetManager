//
//  METARService.swift
//  PrivateJetManager
//
//  Created by charles chauve on 16/01/2026.
//

import Foundation
import SwiftUI

class METARService {
    static let shared = METARService()
    private init() {}
    
    func fetchMETAR(for station: String) async throws -> METARResponse {
        let urlString = "https://aviationweather.gov/api/data/metar?ids=\(station)&format=json"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        
        print("📡 Fetching METAR for \(station) from Aviation Weather API")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response")
            throw URLError(.badServerResponse)
        }
        
        print("📊 Response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Server returned status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            throw URLError(.badServerResponse)
        }
        
        // Afficher la réponse brute
        if let responseString = String(data: data, encoding: .utf8) {
            print("✅ Raw JSON response: \(responseString.prefix(500))...")
        }
        
        // Décoder la réponse JSON
        let decoder = JSONDecoder()
        let awcResponse = try decoder.decode([AWCMETARData].self, from: data)
        
        guard let metarData = awcResponse.first else {
            print("❌ No METAR data in response")
            throw URLError(.cannotParseResponse)
        }
        
        print("✅ Successfully parsed METAR for \(metarData.icaoId ?? station)")
        
        // Convertir en notre format
        return convertAWCToMETAR(awcData: metarData)
    }
    
    private func convertAWCToMETAR(awcData: AWCMETARData) -> METARResponse {

        // Helpers

        func parseVisibility(from visib: String) -> Double? {
            let cleaned = visib
                .replacingOccurrences(of: "+", with: "")
                .trimmingCharacters(in: .whitespaces)

            guard let miles = Double(cleaned) else { return nil }
            return miles * 1609.34
        }

        func formatMETARTime(from unix: Int) -> String {
            let date = Date(timeIntervalSince1970: TimeInterval(unix))
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(abbreviation: "UTC")
            formatter.dateFormat = "ddHHmm'Z'"
            return formatter.string(from: date)
        }

        func formatISOTime(from unix: Int) -> String {
            let date = Date(timeIntervalSince1970: TimeInterval(unix))
            let formatter = ISO8601DateFormatter()
            return formatter.string(from: date)
        }

        // Flight Rules

        var flightRules = awcData.fltCat ?? "VFR"

        if awcData.fltCat == nil {

            // Visibilité en mètres
            let visMeters = awcData.visib
                .flatMap { parseVisibility(from: $0) }
                ?? Double.greatestFiniteMagnitude

            // Plafond le plus bas BKN / OVC
            let ceilingFeet: Double = {
                guard let clouds = awcData.clouds else {
                    return Double.greatestFiniteMagnitude
                }

                let ceilings = clouds.compactMap { cloud -> Double? in
                    guard let cover = cloud.cover,
                          let base = cloud.base,
                          ["BKN", "OVC"].contains(cover) else {
                        return nil
                    }
                    return base
                }

                return ceilings.min() ?? Double.greatestFiniteMagnitude
            }()

            switch (visMeters, ceilingFeet) {
            case (_, let c) where visMeters < 1609 || c < 500:
                flightRules = "LIFR"

            case (_, let c) where visMeters < 4828 || c < 1000:
                flightRules = "IFR"

            case (_, let c) where visMeters < 8046 || c < 3000:
                flightRules = "MVFR"

            default:
                flightRules = "VFR"
            }
        }

        //Visibility

        let visibilityValue = awcData.visib.flatMap {
            parseVisibility(from: $0)
        }

        let visibility = METARValue(
            repr: awcData.visib.map { "\($0) mi" },
            value: visibilityValue,
            spoken: nil
        )


        //Wind

        let windDir = awcData.wdir.map {
            METARValue(repr: "\(Int($0))", value: $0, spoken: nil)
        }

        let windSpeed = awcData.wspd.map {
            METARValue(repr: "\(Int($0))", value: $0, spoken: nil)
        }

        let windGust = awcData.wgst.map {
            METARValue(repr: "\(Int($0))", value: $0, spoken: nil)
        }

        // Temp / Dewpoint

        let temperature = awcData.temp.map {
            METARValue(repr: "\(Int($0))", value: $0, spoken: nil)
        }

        let dewpoint = awcData.dewp.map {
            METARValue(repr: "\(Int($0))", value: $0, spoken: nil)
        }

        //Altimeter (QNH hPa)

        let altimeter = awcData.altim.map {
            METARValue(repr: "Q\(Int($0))", value: $0, spoken: nil)
        }

        //Clouds

        let clouds: [Cloud]? = awcData.clouds?.compactMap { cloud in
            guard let cover = cloud.cover else { return nil }
            let altitude = cloud.base.map { Int($0) }
            let repr = altitude != nil
                ? "\(cover)\(String(format: "%03d", altitude! / 100))"
                : cover

            return Cloud(
                repr: repr,
                type: cover,
                altitude: altitude,
                modifier: nil
            )
        }

        //Weather phenomena

        let wxCodes = awcData.wxString.map {
            [WXCode(repr: $0, value: $0)]
        }

        //Time

        let time = awcData.obsTime.map {
            METARTime(
                repr: formatMETARTime(from: $0),
                dt: formatISOTime(from: $0)
            )
        }

        // MARK: - Final METAR

        return METARResponse(
            meta: METARMeta(timestamp: awcData.receiptTime),
            altimeter: altimeter,
            clouds: clouds,
            flight_rules: flightRules,
            other: nil,
            sanitized: awcData.rawOb,
            visibility: visibility,
            wind_direction: windDir,
            wind_speed: windSpeed,
            wx_codes: wxCodes,
            raw: awcData.rawOb,
            station: awcData.icaoId,
            time: time,
            remarks: nil,
            dewpoint: dewpoint,
            temperature: temperature,
            wind_gust: windGust
        )
    }

}

