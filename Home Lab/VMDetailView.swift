import SwiftUI

struct VMDetailView: View {
    let vm: VCenterVM
    @State private var cpuCount: Int?
    @State private var memoryMiB: Int?
    @State private var cpuUsagePercent: Double?
    @State private var memoryUsagePercent: Double?
    @State private var storageCommitted: Int64?
    @State private var storageTotal: Int64?
    @State private var storageUsagePercent: Double?
    @State private var disks: [VCenterVMDisk] = []
    @State private var snapshots: [VCenterVMSnapshot] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    let client: VCenterClient

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // VM Name and Properties Card
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        // VM Name
                        HStack {
                            Label("VM Name:", systemImage: "server.rack")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(vm.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    
                    Divider()
                    
                    // Power State
                    HStack {
                        Label("Power State:", systemImage: "power")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: vm.power_state?.uppercased() == "POWERED_ON" ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(vm.power_state?.uppercased() == "POWERED_ON" ? .green : .red)
                            Text(vm.power_state ?? "Unknown")
                                .font(.headline)
                        }
                    }
                }
                .padding(8)
            } label: {
                Label("VM Information", systemImage: "info.circle")
                    .font(.headline)
            }
            
            // Hardware Details Card
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
                                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                                        Text("\(cpuCount)")
                                            .font(.title)
                                            .fontWeight(.semibold)
                                        
                                        if let cpuUsagePercent {
                                            Text("(\(String(format: "%.1f", cpuUsagePercent))% used)")
                                                .font(.subheadline)
                                                .foregroundStyle(cpuUsageColor(cpuUsagePercent))
                                        }
                                    }
                                } else {
                                    Text("—")
                                        .font(.title)
                                        .foregroundStyle(.secondary)
                                }
                                
                                // CPU usage progress bar
                                if let cpuUsagePercent {
                                    VStack(alignment: .leading, spacing: 2) {
                                        ProgressView(value: cpuUsagePercent, total: 100)
                                            .tint(cpuUsageColor(cpuUsagePercent))
                                    }
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
                                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                                        Text(formattedGB(memoryGB))
                                            .font(.title)
                                            .fontWeight(.semibold)
                                        
                                        if let memoryUsagePercent {
                                            Text("(\(String(format: "%.1f", memoryUsagePercent))% used)")
                                                .font(.subheadline)
                                                .foregroundStyle(memoryUsageColor(memoryUsagePercent))
                                        }
                                    }
                                } else {
                                    Text("—")
                                        .font(.title)
                                        .foregroundStyle(.secondary)
                                }
                                
                                // Memory usage progress bar
                                if let memoryUsagePercent {
                                    VStack(alignment: .leading, spacing: 2) {
                                        ProgressView(value: memoryUsagePercent, total: 100)
                                            .tint(memoryUsageColor(memoryUsagePercent))
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                        
                        Divider()
                        
                        // Storage Section
                        HStack {
                            Image(systemName: "internaldrive.fill")
                                .font(.title2)
                                .foregroundStyle(.purple)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Storage:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if let storageCommitted, let storageTotal {
                                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                                        Text(formattedBytes(storageCommitted))
                                            .font(.title)
                                            .fontWeight(.semibold)
                                        Text("of \(formattedBytes(storageTotal))")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        
                                        if let storageUsagePercent {
                                            Text("(\(String(format: "%.1f", storageUsagePercent))% used)")
                                                .font(.subheadline)
                                                .foregroundStyle(storageUsageColor(storageUsagePercent))
                                        }
                                    }
                                } else {
                                    Text("—")
                                        .font(.title)
                                        .foregroundStyle(.secondary)
                                }
                                
                                // Storage usage progress bar
                                if let storageUsagePercent {
                                    VStack(alignment: .leading, spacing: 2) {
                                        ProgressView(value: storageUsagePercent, total: 100)
                                            .tint(storageUsageColor(storageUsagePercent))
                                    }
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
            
            // Storage Card
            if !disks.isEmpty {
                GroupBox {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(disks.enumerated()), id: \.element.id) { index, disk in
                            HStack {
                                Image(systemName: "internaldrive.fill")
                                    .font(.title2)
                                    .foregroundStyle(.purple)
                                    .frame(width: 40)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(disk.label ?? "Disk \(index + 1)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text(formattedCapacity(disk.capacity))
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            
                            if index < disks.count - 1 {
                                Divider()
                            }
                        }
                    }
                } label: {
                    Label("Storage:", systemImage: "internaldrive")
                        .font(.headline)
                }
            }
            
            // Snapshots Card
            if !snapshots.isEmpty {
                GroupBox {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(snapshots.enumerated()), id: \.element.id) { index, snapshot in
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundStyle(.cyan)
                                    .frame(width: 40)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(snapshot.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    if let description = snapshot.description, !description.isEmpty {
                                        Text(description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(2)
                                    }
                                    if let createTime = snapshot.create_time {
                                        Text(formattedDate(createTime))
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding()
                            
                            if index < snapshots.count - 1 {
                                Divider()
                            }
                        }
                    }
                } label: {
                    Label("Snapshots:", systemImage: "camera.on.rectangle")
                        .font(.headline)
                }
            }
            }
            .padding()
        }
        .navigationTitle("Virtual Machine")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let detail = try await client.fetchVMDetail(id: vm.id)
            cpuCount = detail.cpu_count
            memoryMiB = detail.memory_size_MiB
            
            // Fetch performance stats
            do {
                let stats = try await client.fetchVMStats(id: vm.id)
                cpuUsagePercent = stats.cpu_usage
                memoryUsagePercent = stats.memory_usage
                storageCommitted = stats.storage_committed
                storageTotal = stats.storage_total
                storageUsagePercent = stats.storage_usage_percent
            } catch {
                print("⚠️ Could not fetch VM stats: \(error)")
                // Continue without stats, don't fail the entire load
            }
            
            disks = try await client.fetchVMDiskList(id: vm.id)
            snapshots = try await client.fetchVMSnapshots(id: vm.id)
            print("🔵 Loaded \(snapshots.count) snapshots for VM: \(vm.name)")
            if !snapshots.isEmpty {
                for snapshot in snapshots {
                    print("🔵   - Snapshot: \(snapshot.name)")
                }
            }
        } catch {
            print("🔴 Error loading VM details: \(error)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func formattedCapacity(_ bytes: Int64?) -> String {
        guard let bytes = bytes else { return "-" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .decimal
        return formatter.string(fromByteCount: bytes)
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
    
    private func formattedDate(_ dateString: String) -> String {
        // vCenter typically returns ISO 8601 format: 2024-02-06T18:30:00.000Z
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        // Fallback: try without fractional seconds
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    private func cpuUsageColor(_ percent: Double) -> Color {
        switch percent {
        case 0..<50:
            return .green
        case 50..<75:
            return .yellow
        case 75..<90:
            return .orange
        default:
            return .red
        }
    }
    
    private func memoryUsageColor(_ percent: Double) -> Color {
        switch percent {
        case 0..<60:
            return .green
        case 60..<80:
            return .yellow
        case 80..<90:
            return .orange
        default:
            return .red
        }
    }
    
    private func storageUsageColor(_ percent: Double) -> Color {
        switch percent {
        case 0..<70:
            return .green
        case 70..<85:
            return .yellow
        case 85..<95:
            return .orange
        default:
            return .red
        }
    }
    
    private func formattedBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useTB]
        formatter.countStyle = .decimal
        formatter.includesUnit = true
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    let sample = VCenterVM(vm: "vm-123", name: "Demo VM", power_state: "POWERED_ON")
    let dummy = VCenterClient(baseURL: URL(string: "https://example.com")!, username: "u", password: "p")
    return NavigationStack { VMDetailView(vm: sample, client: dummy) }
}
