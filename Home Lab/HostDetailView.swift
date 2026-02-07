import SwiftUI

struct HostDetailView: View {
    let host: VCenterHost
    let client: VCenterClient
    
    @State private var cpuCount: Int?
    @State private var memoryMiB: Int?
    @State private var storageTotalBytes: Int64?
    @State private var storageUsedBytes: Int64?
    @State private var ipAddress: String?
    @State private var fqdn: String?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(host.name ?? host.id)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Show available host information
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Connection State:", systemImage: "network")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack {
                            Image(systemName: host.connection_state == "CONNECTED" ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(host.connection_state == "CONNECTED" ? .green : .red)
                            Text(host.connection_state ?? "Unknown")
                                .font(.headline)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Label("Power State:", systemImage: "power")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(host.power_state ?? "Unknown")
                            .font(.headline)
                            .foregroundStyle(host.power_state == "POWERED_ON" ? .green : .secondary)
                    }
                    
                    if let fqdn = fqdn {
                        Divider()
                        
                        HStack {
                            Label("FQDN:", systemImage: "globe")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(fqdn)
                                .font(.headline)
                        }
                    }
                    
                    if let ipAddress = ipAddress {
                        Divider()
                        
                        HStack {
                            Label("IP Address:", systemImage: "network.badge.shield.half.filled")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(ipAddress)
                                .font(.system(.headline, design: .monospaced))
                        }
                    }
                }
                .padding(8)
            } label: {
                Label("Host Information:", systemImage: "server.rack")
                    .font(.headline)
            }
            
            // Hardware Details
            GroupBox {
                VStack(alignment: .leading, spacing: 0) {
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("Loading hardware details...")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    } else if let errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Error loading hardware details", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                                .font(.subheadline)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    } else {
                        // CPU Section
                        HStack {
                            Image(systemName: "cpu.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CPU Cores:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if let cpuCount {
                                    Text("\(cpuCount)")
                                        .font(.title)
                                        .fontWeight(.semibold)
                                } else {
                                    Text("—")
                                        .font(.title)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        
                        Divider()
                        
                        // Memory Section
                        HStack {
                            Image(systemName: "memorychip.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Memory:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if let memoryMiB {
                                    let memoryGB = Double(memoryMiB) / 1024.0
                                    Text(formattedGB(memoryGB))
                                        .font(.title)
                                        .fontWeight(.semibold)
                                } else {
                                    Text("—")
                                        .font(.title)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        
                        Divider()
                        
                        // Storage Total Section
                        HStack {
                            Image(systemName: "internaldrive.fill")
                                .font(.title2)
                                .foregroundStyle(.purple)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Storage:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if let storageTotalBytes {
                                    Text(formattedBytes(storageTotalBytes))
                                        .font(.title)
                                        .fontWeight(.semibold)
                                } else {
                                    Text("—")
                                        .font(.title)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        
                        Divider()
                        
                        // Storage Used Section
                        HStack {
                            Image(systemName: "chart.pie.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Used Storage:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if let storageUsedBytes {
                                    Text(formattedBytes(storageUsedBytes))
                                        .font(.title)
                                        .fontWeight(.semibold)
                                } else {
                                    Text("—")
                                        .font(.title)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                    }
                }
            } label: {
                Label("Hardware Details:", systemImage: "cpu")
                    .font(.headline)
            }
            
            Spacer()
        }
        .padding()
        .task { await loadHardwareDetails() }
        .navigationTitle("Host Details")
    }
    
    @MainActor
    private func loadHardwareDetails() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let detail = try await client.fetchHostDetail(id: host.id)
            cpuCount = detail.cpu_count
            memoryMiB = detail.memory_size_MiB
            storageTotalBytes = detail.storage_total_bytes
            storageUsedBytes = detail.storage_used_bytes
            ipAddress = detail.ip_address
            fqdn = detail.fqdn
        } catch {
            print("🔴 Error loading host hardware details: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func formattedBytes(_ bytes: Int64) -> String {
        let gb = Double(bytes) / (1024.0 * 1024.0 * 1024.0)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.usesGroupingSeparator = true
        if let formattedNumber = formatter.string(from: NSNumber(value: gb)) {
            return "\(formattedNumber) GB"
        }
        return String(format: "%.1f GB", gb)
    }
    
    private func formattedGB(_ gb: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        formatter.usesGroupingSeparator = true
        if let formattedNumber = formatter.string(from: NSNumber(value: gb)) {
            return "\(formattedNumber) GB"
        }
        return String(format: "%.1f GB", gb)
    }
}

#Preview {
    let sample = VCenterHost(host: "host-123", name: "esxi-01.local", connection_state: "CONNECTED", power_state: "POWERED_ON")
    let dummy = VCenterClient(baseURL: URL(string: "https://example.com")!, username: "u", password: "p")
    NavigationStack { HostDetailView(host: sample, client: dummy) }
}
