//
//  ElectricityUsageView.swift
//  Home Lab
//
//  Created by Dale Hassinger on 2/15/26.
//

import SwiftUI
import SwiftData

struct ElectricityUsageView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShellyDevice.name) private var shellyDevices: [ShellyDevice]
    
    var enabledDevices: [ShellyDevice] {
        shellyDevices.filter { $0.isEnabled }
    }
    
    var body: some View {
#if os(iOS)
        ZStack {
            Color.black.ignoresSafeArea()
            
            if enabledDevices.isEmpty {
                // Empty state with glass
                VStack(spacing: 20) {
                    Image(systemName: "bolt.slash")
                        .font(.system(size: 64))
                        .foregroundStyle(.white.opacity(0.5))
                    
                    VStack(spacing: 8) {
                        Text("No Shelly Devices")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        
                        Text("Add Shelly devices in Settings to monitor electricity usage.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(40)
                .glassEffect(.regular, in: .rect(cornerRadius: 24))
                .padding(20)
            } else {
                ScrollView {
                    GlassEffectContainer(spacing: 20.0) {
                        LazyVStack(spacing: 16) {
                            ForEach(enabledDevices) { device in
                                ShellyDeviceRow(device: device)
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .navigationTitle("Electricity Usage")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
#else
        // macOS version - keep List style
        List {
            if shellyDevices.isEmpty {
                ContentUnavailableView {
                    Label("No Shelly Devices", systemImage: "bolt.slash")
                } description: {
                    Text("Add Shelly devices in Settings to monitor electricity usage.")
                }
            } else {
                ForEach(shellyDevices) { device in
                    if device.isEnabled {
                        ShellyDeviceRow(device: device)
                    }
                }
            }
        }
        .navigationTitle("Electricity Usage")
#endif
    }
}

struct ShellyDeviceRow: View {
    let device: ShellyDevice
    @State private var powerData: ShellyPowerData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastUpdateTime: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 8) {
                        Label(device.ipAddress, systemImage: "network")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        
                        if let lastUpdate = lastUpdateTime {
                            Text("•")
                                .foregroundStyle(.white.opacity(0.5))
                            Text(lastUpdate, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .tint(.yellow)
                } else {
                    Button {
                        Task { await fetchPowerData() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.callout)
                    }
                    .buttonStyle(.glass)
                }
            }
            
            if let error = errorMessage {
                // Error state with glass
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                        Spacer()
                    }
                    
                    Button {
                        Task { await fetchPowerData() }
                    } label: {
                        Label("Retry Connection", systemImage: "arrow.clockwise")
                            .font(.subheadline)
                    }
                    .buttonStyle(.glass)
                    .frame(maxWidth: .infinity)
                }
                .padding(12)
                .glassEffect(.regular.tint(.orange.opacity(0.2)), in: .rect(cornerRadius: 12))
                
            } else if let data = powerData {
                // Power data with glass styling
                VStack(spacing: 12) {
                    // Current power - prominent
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(String(format: "%.1f", data.watts)) W")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Text("Current Power")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .glassEffect(.regular.tint(.yellow.opacity(0.3)), in: .rect(cornerRadius: 12))
                    
                    // Additional metrics
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: "%.1f V", data.volts))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            Text("Voltage")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .glassEffect(.regular, in: .rect(cornerRadius: 8))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: "%.2f A", data.amps))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            Text("Current")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .glassEffect(.regular, in: .rect(cornerRadius: 8))
                    }
                }
            } else {
                // Initial loading state
                VStack(spacing: 8) {
                    Text("Connecting to device...")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .glassEffect(.regular, in: .rect(cornerRadius: 12))
            }
        }
        .padding(16)
        .glassEffect(.regular.tint(.yellow.opacity(0.1)).interactive(), in: .rect(cornerRadius: 20))
        .task {
            await fetchPowerData()
        }
    }
    
    @MainActor
    private func fetchPowerData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let client = ShellyClient(ipAddress: device.ipAddress)
            powerData = try await client.fetchPowerData()
            lastUpdateTime = Date()
            errorMessage = nil
        } catch let shellyError as ShellyError {
            errorMessage = shellyError.localizedDescription
            print("🔌 Shelly error for \(device.name): \(shellyError.localizedDescription)")
        } catch {
            errorMessage = "Connection failed"
            print("🔌 Error fetching Shelly data: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Shelly Client

struct ShellyPowerData {
    let watts: Double
    let volts: Double
    let amps: Double
}

enum ShellyError: LocalizedError {
    case networkTimeout
    case deviceUnreachable
    case invalidResponse
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .networkTimeout:
            return "Device not responding (timeout)"
        case .deviceUnreachable:
            return "Cannot reach device on network"
        case .invalidResponse:
            return "Invalid response from device"
        case .parsingError:
            return "Cannot parse device data"
        }
    }
}

struct ShellyClient {
    let ipAddress: String
    
    // Create a URLSession with shorter timeout
    private var urlSession: URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5.0  // 5 seconds instead of 60
        config.timeoutIntervalForResource = 10.0
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }
    
    func fetchPowerData() async throws -> ShellyPowerData {
        let urlString = "http://\(ipAddress)/rpc/Switch.GetStatus?id=0"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        print("🔌 Fetching Shelly data from: \(urlString)")
        
        do {
            let (data, response) = try await urlSession.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ShellyError.invalidResponse
            }
            
            print("🔌 Response status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                throw ShellyError.invalidResponse
            }
            
            // Print raw JSON for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔌 Raw JSON response: \(jsonString)")
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw ShellyError.parsingError
            }
            
            // Parse RPC API response
            let watts = json["apower"] as? Double ?? 0.0
            let volts = json["voltage"] as? Double ?? 120.0
            let amps = json["current"] as? Double ?? (watts / volts)
            
            print("🔌 Parsed data - Watts: \(watts), Volts: \(volts), Amps: \(amps)")
            return ShellyPowerData(watts: watts, volts: volts, amps: amps)
            
        } catch let urlError as URLError {
            // Handle specific network errors
            switch urlError.code {
            case .timedOut:
                print("🔌 Timeout connecting to \(ipAddress)")
                throw ShellyError.networkTimeout
            case .cannotConnectToHost, .cannotFindHost, .networkConnectionLost:
                print("🔌 Cannot reach device at \(ipAddress)")
                throw ShellyError.deviceUnreachable
            default:
                print("🔌 Network error: \(urlError.localizedDescription)")
                throw ShellyError.deviceUnreachable
            }
        } catch {
            print("🔌 Error: \(error.localizedDescription)")
            throw error
        }
    }
}

#Preview {
    NavigationStack {
        ElectricityUsageView()
            .modelContainer(for: ShellyDevice.self, inMemory: true)
    }
}
