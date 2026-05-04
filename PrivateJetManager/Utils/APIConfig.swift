//
//  APIConfig.swift
//  PrivateJetManager
//
//  Created by charles chauve on 16/01/2026.
//

import Foundation

struct APIConfig {
    static var backendURL: String {
        UserDefaults.standard.string(forKey: "backendURL") ?? "http://86.249.54.48:5050"
    }
    
    static func setBackendURL(_ url: String) {
        UserDefaults.standard.set(url, forKey: "backendURL")
    }
    
    static var isConfigured: Bool {
        !backendURL.isEmpty
    }
}
