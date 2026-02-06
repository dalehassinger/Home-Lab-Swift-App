import SwiftUI

struct HostListView: View {
    @Bindable var viewModel: VCenterViewModel

    var body: some View {
        List {
            if viewModel.hosts.isEmpty {
                Text("No hosts loaded yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.hosts) { host in
                    NavigationLink {
                        HostDetailView(host: host, client: viewModel.client)
                    } label: {
                        HStack {
                            // Connection state indicator
                            Image(systemName: host.connection_state == "CONNECTED" ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(host.connection_state == "CONNECTED" ? .green : .red)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(host.name ?? host.id)
                                    .font(.headline)
                                HStack(spacing: 12) {
                                    if let powerState = host.power_state {
                                        Label(powerState, systemImage: "power")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let connectionState = host.connection_state {
                                        Label(connectionState, systemImage: "network")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .onAppear {
            print("🟠 HostListView appeared - showing \(viewModel.hosts.count) Hosts")
            if let first = viewModel.hosts.first {
                print("🟠 First Host in view: \(first.name ?? "unnamed") (host=\(first.host))")
            }
        }
        .navigationTitle("Hosts")
        .task {
            if viewModel.hosts.isEmpty {
                await viewModel.loadHosts()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.loadHosts() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HostListView(viewModel: VCenterViewModel(serverURL: URL(string: "https://example.com")!, username: "u", password: "p"))
    }
}
