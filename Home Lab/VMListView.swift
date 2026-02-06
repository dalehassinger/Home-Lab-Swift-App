import SwiftUI
import Observation

struct VMListView: View {
    @Bindable var viewModel: VCenterViewModel

    var body: some View {
        List {
            if viewModel.vms.isEmpty {
                Text("No VMs loaded yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.vms) { vm in
                    NavigationLink {
                        VMDetailView(vm: vm, client: viewModel.client)
                    } label: {
                        HStack {
                            Image(systemName: (vm.power_state?.uppercased() == "POWERED_ON") ? "power.circle.fill" : "power.circle")
                                .foregroundStyle((vm.power_state?.uppercased() == "POWERED_ON") ? .green : .secondary)
                            VStack(alignment: .leading) {
                                Text(vm.name).font(.headline)
                                Text("ID: \(vm.id)").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .onAppear {
            print("🔵 VMListView appeared - showing \(viewModel.vms.count) VMs")
            if let first = viewModel.vms.first {
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
