//
//  RemarkTag.swift
//  PrivateJetManager
//
//  Created by charles chauve on 25/01/2026.
//

import Foundation
import SwiftUI

enum RemarkTag: String, Codable, CaseIterable {
    case danger = "Danger"
    case important = "Important"
    case info = "Info"
    case none = "Aucun"
    
    var color: Color {
        switch self {
        case .danger:
            return .red
        case .important:
            return .orange
        case .info:
            return .blue
        case .none:
            return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .danger:
            return "exclamationmark.triangle.fill"
        case .important:
            return "exclamationmark.circle.fill"
        case .info:
            return "info.circle.fill"
        case .none:
            return "minus.circle"
        }
    }
}
