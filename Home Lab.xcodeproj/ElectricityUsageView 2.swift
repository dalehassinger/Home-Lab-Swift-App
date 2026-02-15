//
//  ElectricityUsageView.swift
//  Home Lab
//
//  Created by Assistant on 2/15/26.
//

import SwiftUI
import SwiftData

struct ElectricityUsageView: View {
    @Query(filter: #Predicate<ShellyDevice> { $0.isEnabled }, sort: \ShellyDevice.name) private var devices: [ShellyDevice]
    @State private var energyData: [ShellyEnergyData] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let client = ShellyClient()
    
    var totalPower: Double {
        energyData.reduce(0) { $0 + $1.power }
    }
    
    var totalEnergy: Double {
        energyData.reduce(0) { $0 + $1.totalEnergy }
    }
    
    var body: some View {
        List {
            if devices.isEmpty {
                ContentUnavailableView(
                    "No Shelly Devices",
                    systemImage: "bolt.slash",
                    description: Text("Add Shelly devices in Settings to monitor electricity usage")
                )
            } else {
                // Summary section
                Section {
                    VStack(spacing: 16) {
                        HStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Current Power", systemImage: "bolt.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.2f W", totalPower))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.yellow)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Total Energy", systemImage: "chart.bar.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(String(format: "%.2f kWh", totalEnergy / 1000.0))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.green)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
                
                // Individual device data
                Section {
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("Loading device data...")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    } else if let error = errorMessage {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        ForEach(energyData) { data in
                            DeviceEnergyRow(data: data)
                        }
                    }
                } header: {
                    Text("Devices (\(devices.count))")
                }
            }
        }
        .navigationTitle("Electricity Usage")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        await loadEnergyData()
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .refreshable {
            await loadEnergyData()
        }
        .task {
            await loadEnergyData()
        }
    }
    
    @MainActor
    private func loadEnergyData() async {
        guard !devices.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        var newData: [ShellyEnergyData] = []
        var errors: [String] = []
        
        for device in devices {
            do {
                let data = try await client.fetchEnergyData(device: device)
                newData.append(data)
                print("⚡️ Loaded energy data for \(device.name): \(data.power)W")
            } catch {
                print("⚡️ Error loading energy data for \(device.name): \(error)")
                errors.append("\(device.name): \(error.localizedDescription)")
            }
        }
        
        energyData = newData
        
        if !errors.isEmpty && newData.isEmpty {
            errorMessage = "Failed to load data from all devices"
        } else if !errors.isEmpty {
            errorMessage = "Some devices failed to load"
        }
        
        isLoading = false
    }
}

struct DeviceEnergyRow: View {
    let data: ShellyEnergyData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Device name
            HStack {
                Image(systemName: "bolt.circle.fill")
                    .foregroundStyle(.yellow)
                Text(data.deviceName)
                    .font(.headline)
                Spacer()
                if data.isValid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
            
            // IP Address
            HStack {
                Image(systemName: "network")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(data.ipAddress)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let uptime = data.uptimeFormatted {
                    Text("Uptime: \(uptime)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Divider()
            
            // Energy metrics
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Power")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f W", data.power))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                
                if let voltage = data.voltage {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Voltage")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.1f V", voltage))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Energy")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.2f kWh", data.totalEnergyInKWh))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ElectricityUsageView()
            .modelContainer(for: ShellyDevice.self, inMemory: true)
    }
}
