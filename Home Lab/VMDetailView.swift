import SwiftUI

struct VMDetailView: View {
    let vm: VCenterVM
    @State private var cpuCount: Int?
    @State private var memoryMiB: Int?
    @State private var disks: [VCenterVMDisk] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    let client: VCenterClient

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(vm.name)
                .font(.largeTitle)
            if isLoading {
                ProgressView()
            }
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
            HStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text("CPU Cores")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(cpuCount.map(String.init) ?? "-")
                        .font(.title2)
                }
                VStack(alignment: .leading) {
                    Text("Memory (GB)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let memoryMiB {
                        let memoryGB = Double(memoryMiB) / 1024.0
                        Text(String(format: "%.1f", memoryGB))
                            .font(.title2)
                    } else {
                        Text("-")
                            .font(.title2)
                    }
                }
            }
            if !disks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Storage")
                        .font(.title3)
                    ForEach(disks) { disk in
                        HStack {
                            Text(disk.label ?? "Disk")
                            Spacer()
                            Text(formattedCapacity(disk.capacity))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Spacer()
        }
        .padding()
        .task {
            await load()
        }
        .navigationTitle("VM Details")
    }

    @MainActor
    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let detail = try await client.fetchVMDetail(id: vm.id)
            cpuCount = detail.cpu_count
            memoryMiB = detail.memory_size_MiB
            disks = try await client.fetchVMDiskList(id: vm.id)
        } catch {
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
}

#Preview {
    let sample = VCenterVM(vm: "vm-123", name: "Demo VM", power_state: "POWERED_ON")
    let dummy = VCenterClient(baseURL: URL(string: "https://example.com")!, username: "u", password: "p")
    return NavigationStack { VMDetailView(vm: sample, client: dummy) }
}
