//
//  ShellyClient.swift
//  Home Lab
//
//  Created by Assistant on 2/15/26.
//

import Foundation

// MARK: - Shelly Models

struct ShellyStatus: Codable, Identifiable {
    let switchData: SwitchData
    let sys: SystemInfo
    let wifi: WiFiInfo
    
    // Computed ID based on MAC address
    var id: String { sys.mac }
    
    enum CodingKeys: String, CodingKey {
        case switchData = "switch:0"
        case sys
        case wifi
    }
    
    struct SwitchData: Codable {
        let id: Int
        let source: String?
        let output: Bool
        let apower: Double  // Active power in watts
        let voltage: Double // Voltage in volts
        let current: Double // Current in amps
        let aenergy: EnergyData
        let temperature: Temperature
        
        struct EnergyData: Codable {
            let total: Double
            let byMinute: [Double]
            let minuteTs: Int
            
            enum CodingKeys: String, CodingKey {
                case total
                case byMinute = "by_minute"
                case minuteTs = "minute_ts"
            }
        }
        
        struct Temperature: Codable {
            let tC: Double  // Temperature Celsius
            let tF: Double  // Temperature Fahrenheit
        }
    }
    
    struct SystemInfo: Codable {
        let mac: String
        let time: String
        let unixtime: Int
        let uptime: Int
    }
    
    struct WiFiInfo: Codable {
        let staIp: String
        let status: String
        let ssid: String
        let rssi: Int  // Signal strength
        
        enum CodingKeys: String, CodingKey {
            case staIp = "sta_ip"
            case status
            case ssid
            case rssi
        }
    }
}

// Display model for UI
struct ShellyDeviceData: Identifiable {
    let id: String
    let name: String
    let ipAddress: String
    let voltage: Double
    let current: Double
    let watts: Double
    let btu: Double  // BTU/hr calculated from watts
    let totalEnergy: Double  // Total kWh
    let temperature: Double  // °F
    let signalStrength: Int
    let isOn: Bool
    let lastUpdate: Date
    
    // Calculate BTU/hr from watts (1 watt = 3.412 BTU/hr)
    static func calculateBTU(watts: Double) -> Double {
        return watts * 3.412
    }
    
    // Format energy as kWh
    var energyKWh: Double {
        return totalEnergy / 1000.0
    }
    
    // Signal quality
    var signalQuality: String {
        switch signalStrength {
        case -30...0:
            return "Excellent"
        case -50..<(-30):
            return "Good"
        case -60..<(-50):
            return "Fair"
        case -70..<(-60):
            return "Weak"
        default:
            return "Poor"
        }
    }
}

// MARK: - Shelly Client

final class ShellyClient: NSObject, URLSessionDelegate {
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 10
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
    
    deinit {
        session.invalidateAndCancel()
    }
    
    /// Fetch status from a Shelly device
    func fetchStatus(from ipAddress: String, deviceName: String) async throws -> ShellyDeviceData {
        // Clean up IP address (remove http:// if present)
        let cleanIP = ipAddress
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "/", with: "")
        
        guard let url = URL(string: "http://\(cleanIP)/rpc/Shelly.GetStatus") else {
            throw ShellyError.invalidURL
        }
        
        print("🔌 Fetching Shelly status from: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("❌ Shelly request failed (\(http.statusCode)): \(body)")
            throw ShellyError.httpError(statusCode: http.statusCode, message: body)
        }
        
        // Debug: Print response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🔌 Shelly response (first 500 chars): \(String(jsonString.prefix(500)))")
        }
        
        // Decode the response
        let decoder = JSONDecoder()
        let status = try decoder.decode(ShellyStatus.self, from: data)
        
        // Convert to display model
        let deviceData = ShellyDeviceData(
            id: status.sys.mac,
            name: deviceName,
            ipAddress: cleanIP,
            voltage: status.switchData.voltage,
            current: status.switchData.current,
            watts: status.switchData.apower,
            btu: ShellyDeviceData.calculateBTU(watts: status.switchData.apower),
            totalEnergy: status.switchData.aenergy.total,
            temperature: status.switchData.temperature.tF,
            signalStrength: status.wifi.rssi,
            isOn: status.switchData.output,
            lastUpdate: Date()
        )
        
        print("✅ Successfully fetched Shelly data: \(deviceName)")
        print("   Power: \(deviceData.watts)W, Voltage: \(deviceData.voltage)V, Current: \(deviceData.current)A")
        
        return deviceData
    }
    
    /// Fetch status from multiple devices
    func fetchMultipleDevices(devices: [ShellyDevice]) async -> [ShellyDeviceData] {
        var results: [ShellyDeviceData] = []
        
        await withTaskGroup(of: ShellyDeviceData?.self) { group in
            for device in devices {
                group.addTask {
                    do {
                        return try await self.fetchStatus(from: device.ipAddress, deviceName: device.name)
                    } catch {
                        print("⚠️ Failed to fetch data from \(device.name): \(error)")
                        return nil
                    }
                }
            }
            
            for await result in group {
                if let data = result {
                    results.append(data)
                }
            }
        }
        
        return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

// MARK: - Errors

enum ShellyError: LocalizedError {
    case invalidURL
    case httpError(statusCode: Int, message: String)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid device IP address"
        case .httpError(let code, let message):
            return "HTTP Error \(code): \(message)"
        case .decodingError:
            return "Failed to decode device response"
        }
    }
}
