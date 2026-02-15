import Foundation
import Observation

@Observable
final class VCenterViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }
    
    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case failed(String)
    }

    var vmState: State = .idle
    var hostState: State = .idle
    var connectionState: ConnectionState = .disconnected
    private(set) var vms: [VCenterVM] = [] {
        didSet {
            print("📝 viewModel.vms was SET to \(vms.count) items")
            if let first = vms.first {
                print("📝 First VM: name=\(first.name), vm=\(first.vm), powerState=\(first.power_state ?? "nil")")
            }
        }
    }
    private(set) var hosts: [VCenterHost] = [] {
        didSet {
            print("📝 viewModel.hosts was SET to \(hosts.count) items")
            if let first = hosts.first {
                print("📝 First Host: name=\(first.name ?? "nil"), host=\(first.host)")
            }
        }
    }
    private(set) var vmsWithSnapshotsCount: Int = 0

    let client: VCenterClient
    private var isLoadingVMs = false
    private var isLoadingHosts = false

    init(serverURL: URL, username: String, password: String) {
        self.client = VCenterClient(baseURL: serverURL, username: username, password: password)
    }

    func loadVMs() async {
        await MainActor.run {
            vmState = .loading
            if connectionState == .disconnected { connectionState = .connecting }
        }
        if isLoadingVMs { return }
        isLoadingVMs = true
        defer { isLoadingVMs = false }
        do {
            let list = try await client.fetchVMs()
            let sorted = list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            await MainActor.run {
                vms = sorted
                vmState = .loaded
                connectionState = .connected
            }
            await testMetricsAPI()
        } catch {
            await MainActor.run {
                vmState = .error(error.localizedDescription)
                connectionState = .failed(error.localizedDescription)
            }
        }
    }

    func loadHosts() async {
        await MainActor.run { hostState = .loading }
        if isLoadingHosts { return }
        isLoadingHosts = true
        defer { isLoadingHosts = false }
        do {
            let list = try await client.fetchHosts()
            let sorted = list.sorted { ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending }
            await MainActor.run {
                hosts = sorted
                hostState = .loaded
            }
        } catch {
            await MainActor.run { hostState = .error(error.localizedDescription) }
        }
    }
    
    func loadVMsWithSnapshotsCount() async {
        var count = 0
        let filteredVMs = await MainActor.run { vms.filter { !$0.name.hasPrefix("vCLS-") } }
        for vm in filteredVMs {
            do {
                let snapshots = try await client.fetchVMSnapshots(id: vm.id)
                if !snapshots.isEmpty { count += 1 }
            } catch {
                print("⚠️ Could not fetch snapshots for VM \(vm.name): \(error)")
            }
        }
        await MainActor.run { vmsWithSnapshotsCount = count }
    }
    
    func testMetricsAPI() async {
        print("📊 Testing metrics API...")
        do {
            let metrics = try await client.fetchAvailableMetrics()
            print("📊 ========== AVAILABLE METRICS ==========")
            print("📊 Total metrics available: \(metrics.count)")
            for metric in metrics.prefix(20) {
                print("📊 - ID: \(metric.id)")
                if let name = metric.name {
                    print("📊   Name: \(name)")
                }
                if let description = metric.description {
                    print("📊   Description: \(description)")
                }
                if let units = metric.units {
                    print("📊   Units: \(units)")
                }
                print("📊")
            }
            if metrics.count > 20 {
                print("📊 ... and \(metrics.count - 20) more metrics")
            }
            print("📊 ========================================")
        } catch {
            print("🔴 Error fetching metrics: \(error)")
        }
    }
}

