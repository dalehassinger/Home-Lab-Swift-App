import SwiftUI
import Observation

struct VMListView: View {
    @Bindable var viewModel: VCenterViewModel
    
    /// Filters out vCLS (vSphere Cluster Services) VMs
    private var filteredVMs: [VCenterVM] {
        viewModel.vms.filter { !$0.name.hasPrefix("vCLS-") }
    }

    var body: some View {
        List {
            if filteredVMs.isEmpty {
                Text("No VMs loaded yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filteredVMs) { vm in
                    NavigationLink {
                        VMDetailView(vm: vm, client: viewModel.client)
                    } label: {
                        HStack {
                            Image(systemName: (vm.power_state?.uppercased() == "POWERED_ON") ? "power.circle.fill" : "power.circle")
                                .foregroundStyle((vm.power_state?.uppercased() == "POWERED_ON") ? .green : .secondary)
                            Text(vm.name).font(.headline)
                            Spacer()
                        }
                    }
                }
            }
        }
        .onAppear {
            print("🔵 VMListView appeared - showing \(filteredVMs.count) VMs (filtered from \(viewModel.vms.count) total)")
            if let first = filteredVMs.first {
                print("🔵 First VM in view: \(first.name) (vm=\(first.vm))")
            }
        }
        .navigationTitle("Virtual Machines")
        .task {
            await viewModel.loadVMs()
        }
        .refreshable {
            await viewModel.loadVMs()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.loadVMs() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        VMListView(viewModel: VCenterViewModel(serverURL: URL(string: "https://example.com")!, username: "u", password: "p"))
    }
}
