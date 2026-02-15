//
//  OperationsHostDetailView.swift
//  Home Lab
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI
import OSLog

struct OperationsHostDetailView: View {
    let host: OperationsHost
    let client: OperationsClient
    
    @State private var stats: HostStats?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let logger = Logger(subsystem: "com.homelab.app", category: "OperationsHostDetailView")
    
    init(host: OperationsHost, client: OperationsClient) {
        self.host = host
        self.client = client
    }
    
    var body: some View {
        ZStack {
#if os(iOS)
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
#else
            Color(NSColor.windowBackgroundColor)
                .ignoresSafeArea()
#endif
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: host.healthStatus.icon)
                                .font(.title)
                                .foregroundStyle(colorForHealth(host.healthStatus.color))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(host.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                
                                if let healthValue = host.resourceHealthValue ?? host.healthScore {
                                    HStack(spacing: 8) {
                                        Text("Health: \(Int(healthValue))")
                                            .font(.subheadline)
                                            .foregroundStyle(colorForHealth(host.healthStatus.color))
                                        Text("•")
                                            .foregroundStyle(.secondary)
                                        Text(host.healthStatus.text)
                                            .font(.subheadline)
                                            .foregroundStyle(colorForHealth(host.healthStatus.color))
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                    )
                
                if isLoading {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading host statistics...")
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 40)
                } else if let errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange)
                        Text("Error Loading Statistics")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                        Text(errorMessage)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button {
                            Task { await loadStats() }
                        } label: {
                            Label("Retry", systemImage: "arrow.clockwise")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding(40)
                    .frame(maxWidth: .infinity)
                } else if let stats {
                    // CPU Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("CPU", systemImage: "cpu")
                            .font(.headline)
                            .foregroundStyle(.blue)
                        
                        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                            GridRow {
                                Text("Usage:")
                                    .foregroundStyle(.secondary)
                                if let usage = stats.cpuUsagePercent {
                                    HStack {
                                        Text("\(String(format: "%.1f", usage))%")
                                            .fontWeight(.medium)
                                        ProgressView(value: usage, total: 100)
                                            .frame(width: 100)
                                    }
                                } else {
                                    Text("N/A")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            
                            GridRow {
                                Text("Total Capacity:")
                                    .foregroundStyle(.secondary)
                                if let capacity = stats.cpuTotalCapacityMHz {
                                    Text("\(Int(capacity)) MHz")
                                        .fontWeight(.medium)
                                } else {
                                    Text("N/A")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            
                            GridRow {
                                Text("Usage:")
                                    .foregroundStyle(.secondary)
                                if let usage = stats.cpuUsageMHz {
                                    Text("\(Int(usage)) MHz")
                                        .fontWeight(.medium)
                                } else {
                                    Text("N/A")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            
                            GridRow {
                                Text("CPU Cores:")
                                    .foregroundStyle(.secondary)
                                if let cores = stats.cpuCores {
                                    Text("\(cores) cores")
                                        .fontWeight(.medium)
                                } else {
                                    Text("N/A")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            
                            GridRow {
                                Text("vCPUs Allocated:")
                                    .foregroundStyle(.secondary)
                                if let vcpus = stats.cpuVCPUsAllocated {
                                    Text("\(vcpus) vCPUs")
                                        .fontWeight(.medium)
                                } else {
                                    Text("N/A")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            
                            GridRow {
                                Text("Running VMs:")
                                    .foregroundStyle(.secondary)
                                if let vms = stats.runningVMs {
                                    Text("\(vms) VMs")
                                        .fontWeight(.medium)
                                } else {
                                    Text("N/A")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                        )
                    }
                    
                    // Memory Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Memory", systemImage: "memorychip")
                            .font(.headline)
                            .foregroundStyle(.purple)
                        
                        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                            GridRow {
                                Text("Usage:")
                                    .foregroundStyle(.secondary)
                                if let usage = stats.memUsagePercent {
                                    HStack {
                                        Text("\(String(format: "%.1f", usage))%")
                                            .fontWeight(.medium)
                                        ProgressView(value: usage, total: 100)
                                            .frame(width: 100)
                                    }
                                } else {
                                    Text("N/A")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            
                            GridRow {
                                Text("Total Capacity:")
                                    .foregroundStyle(.secondary)
                                if let capacity = stats.memTotalCapacityGB {
                                    Text("\(String(format: "%.1f", capacity)) GB")
                                        .fontWeight(.medium)
                                } else {
                                    Text("N/A")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            
                            GridRow {
                                Text("Consumed:")
                                    .foregroundStyle(.secondary)
                                if let consumed = stats.memConsumedGB {
                                    Text("\(String(format: "%.1f", consumed)) GB")
                                        .fontWeight(.medium)
                                } else {
                                    Text("N/A")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            
                            GridRow {
                                Text("Active:")
                                    .foregroundStyle(.secondary)
                                if let active = stats.memActiveGB {
                                    Text("\(String(format: "%.1f", active)) GB")
                                        .fontWeight(.medium)
                                } else {
                                    Text("N/A")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            
                            GridRow {
                                Text("Granted:")
                                    .foregroundStyle(.secondary)
                                if let granted = stats.memGrantedGB {
                                    Text("\(String(format: "%.1f", granted)) GB")
                                        .fontWeight(.medium)
                                } else {
                                    Text("N/A")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            
                            GridRow {
                                Text("Memory Allocated:")
                                    .foregroundStyle(.secondary)
                                if let allocated = stats.memAllocatedToVMsGB {
                                    Text("\(String(format: "%.1f", allocated)) GB")
                                        .fontWeight(.medium)
                                } else {
                                    Text("N/A")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                        )
                    }
                    
                    // CPU and Memory Usage Gauges
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Performance Gauges", systemImage: "speedometer")
                            .font(.headline)
                            .foregroundStyle(.blue)
                        
                        VStack(spacing: 40) {
                            // CPU Gauge
                            VStack(spacing: 16) {
                                Text("CPU")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                ZStack {
                                    // Background circles for speedometer effect
                                    Circle()
#if os(iOS)
                                        .stroke(Color(UIColor.systemGray4), lineWidth: 8)
#else
                                        .stroke(Color(NSColor.systemGray), lineWidth: 8)
#endif
                                        .frame(width: 160, height: 160)
                                    
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                                        .frame(width: 140, height: 140)
                                    
                                    // Main gauge
                                    Gauge(value: stats.cpuUsagePercent ?? 0, in: 0...100) {
                                        Text("")
                                    } currentValueLabel: {
                                        VStack(spacing: 2) {
                                            Text("\(Int(stats.cpuUsagePercent ?? 0))")
                                                .font(.system(size: 32, weight: .bold))
                                                .foregroundColor(.white)
                                            Text("%")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    } minimumValueLabel: {
                                        Text("0")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.5))
                                    } maximumValueLabel: {
                                        Text("100")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .gaugeStyle(.accessoryCircularCapacity)
                                    .tint(gaugeColor(for: stats.cpuUsagePercent ?? 0))
                                    .scaleEffect(1.8)
                                }
                                .frame(width: 180, height: 180)
                            }
                            
                            // Memory Gauge
                            VStack(spacing: 16) {
                                Text("Memory")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                ZStack {
                                    // Background circles for speedometer effect
                                    Circle()
#if os(iOS)
                                        .stroke(Color(UIColor.systemGray4), lineWidth: 8)
#else
                                        .stroke(Color(NSColor.systemGray), lineWidth: 8)
#endif
                                        .frame(width: 160, height: 160)
                                    
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                                        .frame(width: 140, height: 140)
                                    
                                    // Main gauge
                                    Gauge(value: stats.memUsagePercent ?? 0, in: 0...100) {
                                        Text("")
                                    } currentValueLabel: {
                                        VStack(spacing: 2) {
                                            Text("\(Int(stats.memUsagePercent ?? 0))")
                                                .font(.system(size: 32, weight: .bold))
                                                .foregroundColor(.white)
                                            Text("%")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    } minimumValueLabel: {
                                        Text("0")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.5))
                                    } maximumValueLabel: {
                                        Text("100")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .gaugeStyle(.accessoryCircularCapacity)
                                    .tint(gaugeColor(for: stats.memUsagePercent ?? 0))
                                    .scaleEffect(1.8)
                                }
                                .frame(width: 180, height: 180)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                        )
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        }
#if os(macOS)
        .frame(minWidth: 700, minHeight: 500)
#endif
        .onAppear {
        }
        .task {
            await loadStats()
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await loadStats() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
    }
    
    @MainActor
    private func loadStats() async {
        guard let resourceID = host.identifier else {
            errorMessage = "No resource ID available"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedStats = try await client.fetchStats(for: resourceID)
            stats = fetchedStats
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func colorForHealth(_ colorName: String) -> Color {
        switch colorName {
        case "green": return .green
        case "mint": return .mint
        case "orange": return .orange
        case "red": return .red
        case "gray": return .gray
        default: return .gray
        }
    }
    
    private func gaugeColor(for percentage: Double) -> Color {
        switch percentage {
        case 0..<70:
            return .green
        case 70..<80:
            return .yellow
        case 80..<90:
            return .orange
        case 90...100:
            return .red
        default:
            return .green
        }
    }
}

// MARK: - Host Stats Model

struct HostStats {
    // CPU Stats
    var cpuUsagePercent: Double?
    var cpuTotalCapacityMHz: Double?
    var cpuUsageMHz: Double?
    var cpuCores: Int?
    var cpuVCPUsAllocated: Int?
    var runningVMs: Int?
    
    // Memory Stats
    var memUsagePercent: Double?
    var memTotalCapacityGB: Double?
    var memConsumedGB: Double?
    var memActiveGB: Double?
    var memGrantedGB: Double?
    var memAllocatedToVMsGB: Double?
}

