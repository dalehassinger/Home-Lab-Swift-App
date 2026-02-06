import SwiftUI

struct HostDetailView: View {
    let host: VCenterHost
    let client: VCenterClient
    
    @State private var cpuCount: Int?
    @State private var memoryMiB: Int?
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
                        Label("Connection State", systemImage: "network")
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
                        Label("Power State", systemImage: "power")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(host.power_state ?? "Unknown")
                            .font(.headline)
                            .foregroundStyle(host.power_state == "POWERED_ON" ? .green : .secondary)
                    }
                    
                    Divider()
                    
                    HStack {
                        Label("Host ID", systemImage: "number")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(host.id)
                            .font(.system(.headline, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(8)
            } label: {
                Label("Host Information", systemImage: "server.rack")
                    .font(.headline)
            }
            
            // Hardware Details
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("Loading hardware details...")
                                .foregroundStyle(.secondary)
                        }
                    } else if let errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Error loading hardware details", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                                .font(.subheadline)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack(spacing: 32) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CPU Cores")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let cpuCount {
                                    Text("\(cpuCount)")
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundStyle(.blue)
                                } else {
                                    Text("—")
                                        .font(.title)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Memory")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let memoryMiB {
                                    let memoryGB = Double(memoryMiB) / 1024.0
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(String(format: "%.1f", memoryGB))
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundStyle(.green)
                                        Text("GB")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                } else {
                                    Text("—")
                                        .font(.title)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding(8)
            } label: {
                Label("Hardware Details", systemImage: "cpu")
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
        } catch {
            print("🔴 Error loading host hardware details: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

#Preview {
    let sample = VCenterHost(host: "host-123", name: "esxi-01.local", connection_state: "CONNECTED", power_state: "POWERED_ON")
    let dummy = VCenterClient(baseURL: URL(string: "https://example.com")!, username: "u", password: "p")
    NavigationStack { HostDetailView(host: sample, client: dummy) }
}
