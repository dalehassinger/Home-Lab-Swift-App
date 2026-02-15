//
//  ElectricityUsageView.swift
//  Home Lab
//
//  Created by Assistant on 2/15/26.
//

import SwiftUI
import SwiftData

struct ElectricityUsageView: View {
    @Query(filter: #Predicate<ShellyDevice> { $0.isEnabled }) 
    private var devices: [ShellyDevice]
    
    @State private var deviceData: [ShellyDeviceData] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastUpdate: Date?
    
    private let client = ShellyClient()
    
    // Calculate totals
    private var totalWatts: Double {
        deviceData.reduce(0) { $0 + $1.watts }
    }
    
    private var totalCurrent: Double {
        deviceData.reduce(0) { $0 + $1.current }
    }
    
    private var totalBTU: Double {
        deviceData.reduce(0) { $0 + $1.btu }
    }
    
    private var averageVoltage: Double {
        guard !deviceData.isEmpty else { return 0 }
        return deviceData.reduce(0) { $0 + $1.voltage } / Double(deviceData.count)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Card
                if !deviceData.isEmpty {
                    GroupBox {
                        VStack(spacing: 16) {
                            Text("Total Power Usage")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            // Main metrics grid
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                MetricCard(
                                    title: "Total Power",
                                    value: String(format: "%.1f", totalWatts),
                                    unit: "W",
                                    icon: "bolt.fill",
                                    color: .yellow
                                )
                                
                                MetricCard(
                                    title: "Total Current",
                                    value: String(format: "%.2f", totalCurrent),
                                    unit: "A",
                                    icon: "wave.3.right",
                                    color: .orange
                                )
                                
                                MetricCard(
                                    title: "Avg Voltage",
                                    value: String(format: "%.1f", averageVoltage),
                                    unit: "V",
                                    icon: "powerplug.fill",
                                    color: .blue
                                )
                                
                                MetricCard(
                                    title: "Heat Output",
                                    value: String(format: "%.0f", totalBTU),
                                    unit: "BTU/hr",
                                    icon: "flame.fill",
                                    color: .red
                                )
                            }
                            
                            if let lastUpdate {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.caption2)
                                    Text("Updated \(lastUpdate, style: .relative) ago")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                }
                
                // Loading State
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading device data...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
                
                // Error State
                if let errorMessage, !isLoading {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange)
                        Text("Error Loading Data")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button {
                            Task { await loadDeviceData() }
                        } label: {
                            Label("Retry", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
                
                // Device List
                if !deviceData.isEmpty {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Devices")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Text("\(deviceData.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(deviceData) { device in
                                DeviceCard(device: device)
                            }
                        }
                        .padding(.horizontal)
                    }
                } else if !isLoading && errorMessage == nil {
                    // Empty State
                    VStack(spacing: 16) {
                        Image(systemName: "powerplug.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No Devices Configured")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Add Shelly devices in Settings to monitor power usage")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 40)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Electricity Usage")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .task {
            await loadDeviceData()
        }
        .refreshable {
            await loadDeviceData()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await loadDeviceData() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
    }
    
    @MainActor
    private func loadDeviceData() async {
        guard !devices.isEmpty else {
            errorMessage = nil
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let data = await client.fetchMultipleDevices(devices: devices)
            deviceData = data
            lastUpdate = Date()
            
            if deviceData.isEmpty && !devices.isEmpty {
                errorMessage = "Could not connect to any devices. Check network and IP addresses."
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading device data: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Device Card

struct DeviceCard: View {
    let device: ShellyDeviceData
    
    var body: some View {
        GroupBox {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(device.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: device.isOn ? "power.circle.fill" : "power.circle")
                                .foregroundStyle(device.isOn ? .green : .secondary)
                                .font(.caption)
                            Text(device.isOn ? "On" : "Off")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("•")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            
                            Text(device.ipAddress)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // WiFi Signal
                    VStack(alignment: .trailing, spacing: 2) {
                        Image(systemName: wifiIcon(for: device.signalStrength))
                            .foregroundStyle(wifiColor(for: device.signalStrength))
                        Text(device.signalQuality)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Divider()
                
                // Metrics
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    CompactMetric(label: "Voltage", value: String(format: "%.1f V", device.voltage), color: .blue)
                    CompactMetric(label: "Current", value: String(format: "%.2f A", device.current), color: .orange)
                    CompactMetric(label: "Power", value: String(format: "%.1f W", device.watts), color: .yellow)
                    CompactMetric(label: "Heat", value: String(format: "%.0f BTU/hr", device.btu), color: .red)
                }
                
                Divider()
                
                // Additional Info
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Energy")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.2f kWh", device.energyKWh))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Temperature")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1f°F", device.temperature))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(temperatureColor(device.temperature))
                    }
                }
            }
            .padding()
        }
    }
    
    private func wifiIcon(for rssi: Int) -> String {
        switch rssi {
        case -30...0: return "wifi"
        case -50..<(-30): return "wifi"
        case -60..<(-50): return "wifi"
        default: return "wifi.slash"
        }
    }
    
    private func wifiColor(for rssi: Int) -> Color {
        switch rssi {
        case -30...0: return .green
        case -50..<(-30): return .green
        case -60..<(-50): return .orange
        default: return .red
        }
    }
    
    private func temperatureColor(_ temp: Double) -> Color {
        switch temp {
        case 0..<100: return .green
        case 100..<110: return .orange
        default: return .red
        }
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Compact Metric

struct CompactMetric: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ElectricityUsageView()
            .modelContainer(for: ShellyDevice.self, inMemory: true)
    }
}
