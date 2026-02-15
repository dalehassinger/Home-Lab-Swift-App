//
//  ShellyClient.swift
//  Home Lab
//
//  Created by Assistant on 2/15/26.
//

import Foundation

// Shelly device status response
struct ShellyStatus: Codable {
    let wifi_sta: WiFiStatus?
    let cloud: CloudStatus?
    let mqtt: MQTTStatus?
    let update: UpdateStatus?
    let ram_total: Int?
    let ram_free: Int?
    let fs_size: Int?
    let fs_free: Int?
    let uptime: Int?
    
    struct WiFiStatus: Codable {
        let connected: Bool?
        let ssid: String?
        let ip: String?
        let rssi: Int?
    }
    
    struct CloudStatus: Codable {
        let enabled: Bool?
        let connected: Bool?
    }
    
    struct MQTTStatus: Codable {
        let connected: Bool?
    }
    
    struct UpdateStatus: Codable {
        let status: String?
        let has_update: Bool?
        let new_version: String?
        let old_version: String?
    }
}

// Shelly EM (Energy Monitor) status
struct ShellyEMStatus: Codable {
    let emeters: [EMeter]?
    
    struct EMeter: Codable, Identifiable {
        let power: Double?           // Current power in Watts
        let reactive: Double?        // Reactive power
        let voltage: Double?         // Voltage in Volts
        let is_valid: Bool?
        let total: Double?           // Total energy consumed in Wh
        let total_returned: Double?  // Total energy returned in Wh
        
        var id: String {
            "\(power ?? 0)-\(voltage ?? 0)"
        }
    }
}

// Shelly Plug/Switch meter status
struct ShellyMeterStatus: Codable {
    let meters: [Meter]?
    
    struct Meter: Codable, Identifiable {
        let power: Double?           // Current power in Watts
        let overpower: Double?       // Overpower value in Watts
        let is_valid: Bool?
        let total: Double?           // Total energy consumed in Wh
        let counters: [Double]?      // Energy counter values
        
        var id: String {
            "\(power ?? 0)"
        }
    }
}

// Combined energy data
struct ShellyEnergyData: Identifiable {
    let id = UUID()
    let deviceName: String
    let ipAddress: String
    let power: Double           // Current power in Watts
    let voltage: Double?        // Voltage (if available)
    let totalEnergy: Double     // Total energy in Wh
    let isValid: Bool
    let uptime: Int?            // Uptime in seconds
    
    var powerInKW: Double {
        power / 1000.0
    }
    
    var totalEnergyInKWh: Double {
        totalEnergy / 1000.0
    }
    
    var uptimeFormatted: String? {
        guard let uptime = uptime else { return nil }
        let hours = uptime / 3600
        let minutes = (uptime % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

final class ShellyClient: NSObject, URLSessionDelegate {
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 20
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    // Accept all server certificates (for local network devices)
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    // Fetch general device status
    func fetchStatus(ipAddress: String) async throws -> ShellyStatus {
        let urlString = "http://\(ipAddress)/status"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "ShellyClient", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch status"])
        }
        
        return try JSONDecoder().decode(ShellyStatus.self, from: data)
    }
    
    // Fetch energy meter data (for Shelly EM)
    func fetchEMStatus(ipAddress: String) async throws -> ShellyEMStatus {
        let urlString = "http://\(ipAddress)/status"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "ShellyClient", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch EM status"])
        }
        
        return try JSONDecoder().decode(ShellyEMStatus.self, from: data)
    }
    
    // Fetch meter data (for Shelly Plug/Switch)
    func fetchMeterStatus(ipAddress: String) async throws -> ShellyMeterStatus {
        let urlString = "http://\(ipAddress)/status"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "ShellyClient", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch meter status"])
        }
        
        return try JSONDecoder().decode(ShellyMeterStatus.self, from: data)
    }
    
    // Fetch combined energy data (tries EM first, then falls back to regular meters)
    func fetchEnergyData(device: ShellyDevice) async throws -> ShellyEnergyData {
        let status = try await fetchStatus(ipAddress: device.ipAddress)
        
        // Try EM status first
        do {
            let emStatus = try await fetchEMStatus(ipAddress: device.ipAddress)
            if let emeter = emStatus.emeters?.first {
                return ShellyEnergyData(
                    deviceName: device.name,
                    ipAddress: device.ipAddress,
                    power: emeter.power ?? 0,
                    voltage: emeter.voltage,
                    totalEnergy: emeter.total ?? 0,
                    isValid: emeter.is_valid ?? false,
                    uptime: status.uptime
                )
            }
        } catch {
            // Fall back to regular meter status
            print("⚡️ EM not available, trying regular meter for \(device.name)")
        }
        
        // Try regular meter status
        let meterStatus = try await fetchMeterStatus(ipAddress: device.ipAddress)
        if let meter = meterStatus.meters?.first {
            return ShellyEnergyData(
                deviceName: device.name,
                ipAddress: device.ipAddress,
                power: meter.power ?? 0,
                voltage: nil,
                totalEnergy: meter.total ?? 0,
                isValid: meter.is_valid ?? false,
                uptime: status.uptime
            )
        }
        
        throw NSError(domain: "ShellyClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "No energy data available"])
    }
}
