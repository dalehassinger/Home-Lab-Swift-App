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
    var vms: [VCenterVM] = [] {
        didSet {
            print("📝 viewModel.vms was SET to \(vms.count) items")
            if let first = vms.first {
                print("📝 First VM: name=\(first.name), vm=\(first.vm), powerState=\(first.power_state ?? "nil")")
            }
        }
    }
    var hosts: [VCenterHost] = [] {
        didSet {
            print("📝 viewModel.hosts was SET to \(hosts.count) items")
            if let first = hosts.first {
                print("📝 First Host: name=\(first.name ?? "nil"), host=\(first.host)")
            }
        }
    }
    var vmsWithSnapshotsCount: Int = 0

    let client: VCenterClient

    init(serverURL: URL, username: String, password: String) {
        self.client = VCenterClient(baseURL: serverURL, username: username, password: password)
    }

    @MainActor
    func loadVMs() async {
        vmState = .loading
        print("🔵 Loading VMs...")
        
        // Update connection state
        if connectionState == .disconnected {
            connectionState = .connecting
        }
        
        do {
            let list = try await client.fetchVMs()
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            vms = list
            print("🔵 Loaded \(vms.count) VMs into viewModel.vms")
            if let first = vms.first {
                print("🔵 First VM: \(first.name) (ID: \(first.id))")
            }
            vmState = .loaded
            connectionState = .connected
            
            // Test metrics API (only once when first connected)
            await testMetricsAPI()
        } catch {
            print("🔴 Error loading VMs: \(error)")
            vmState = .error(error.localizedDescription)
            connectionState = .failed(error.localizedDescription)
        }
    }

    @MainActor
    func loadHosts() async {
        hostState = .loading
        print("🟠 Loading Hosts...")
        do {
            let list = try await client.fetchHosts()
                .sorted { ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending }
            hosts = list
            print("🟠 Loaded \(hosts.count) Hosts into viewModel.hosts")
            if let first = hosts.first {
                print("🟠 First Host: \(first.name ?? "unnamed") (ID: \(first.id))")
            }
            hostState = .loaded
        } catch {
            print("🔴 Error loading Hosts: \(error)")
            hostState = .error(error.localizedDescription)
        }
    }
    
    @MainActor
    func loadVMsWithSnapshotsCount() async {
        print("📸 Loading VMs with snapshots count...")
        var count = 0
        
        // Filter out vCLS VMs
        let filteredVMs = vms.filter { !$0.name.hasPrefix("vCLS-") }
        
        for vm in filteredVMs {
            do {
                let snapshots = try await client.fetchVMSnapshots(id: vm.id)
                if !snapshots.isEmpty {
                    count += 1
                }
            } catch {
                // Continue counting even if one VM fails
                print("⚠️ Could not fetch snapshots for VM \(vm.name): \(error)")
            }
        }
        
        vmsWithSnapshotsCount = count
        print("📸 Found \(count) VMs with snapshots")
    }
    
    @MainActor
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

