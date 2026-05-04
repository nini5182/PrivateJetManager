//
//  METAR.swift
//  PrivateJetManager
//
//  Created by charles chauve on 16/01/2026.
//

import SwiftUI

struct METARResponse: Codable {
    let meta: METARMeta?
    let altimeter: METARValue?
    let clouds: [Cloud]?
    let flight_rules: String?
    let other: [String]?
    let sanitized: String?
    let visibility: METARValue?
    let wind_direction: METARValue?
    let wind_speed: METARValue?
    let wx_codes: [WXCode]?
    let raw: String?
    let station: String?
    let time: METARTime?
    let remarks: String?
    let dewpoint: METARValue?
    let temperature: METARValue?
    let wind_gust: METARValue?
}

struct METARMeta: Codable {
    let timestamp: String?
}

struct METARValue: Codable {
    let repr: String?
    let value: Double?
    let spoken: String?
}

struct Cloud: Codable {
    let repr: String?
    let type: String?
    let altitude: Int?
    let modifier: String?
}

struct WXCode: Codable {
    let repr: String?
    let value: String?
}

struct METARTime: Codable {
    let repr: String?
    let dt: String?
}

struct AWCMETARResponse: Codable {
    let data: [AWCMETARData]?
}

struct AWCMETARData: Codable {
    let icaoId: String?
    let receiptTime: String?
    let obsTime: Int?
    let reportTime: String?
    let temp: Double?
    let dewp: Double?
    let wdir: Double?
    let wspd: Double?
    let wgst: Double?
    let visib: String?
    let altim: Double?
    let slp: Double?
    let qcField: Int?
    let wxString: String?
    let presTend: Int?
    let maxT: Double?
    let minT: Double?
    let maxT24: Double?
    let minT24: Double?
    let precip: Double?
    let pcp3hr: Double?
    let pcp6hr: Double?
    let pcp24hr: Double?
    let snow: Double?
    let vertVis: Double?
    let metarType: String?
    let rawOb: String?
    let mostRecent: Int?
    let lat: Double?
    let lon: Double?
    let elev: Double?
    let prior: Int?
    let name: String?
    let cover: String?
    let clouds: [AWCCloud]?
    let fltCat: String?
}

struct AWCCloud: Codable {
    let cover: String?
    let base: Double?
}

