import SwiftUI
import Observation

struct VMListView: View {
    @Bindable var viewModel: VCenterViewModel
    @State private var showPoweredOnOnly = false
    @State private var searchText = ""
    @State private var lastUpdated: Date? = nil
    @State private var isRefreshing = false
    
    /// Filters out vCLS (vSphere Cluster Services) VMs and optionally filters by power state and search text
    private var filteredVMs: [VCenterVM] {
        var filtered = viewModel.vms.filter { !$0.name.hasPrefix("vCLS-") }
        
        // Filter by power state
        if showPoweredOnOnly {
            filtered = filtered.filter { $0.power_state?.uppercased() == "POWERED_ON" }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return filtered
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter buttons
            HStack(spacing: 12) {
                Button {
                    showPoweredOnOnly = false
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.grid.2x2")
                            .font(.caption)
                        Text("Show All")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(showPoweredOnOnly ? Color.gray.opacity(0.3) : Color.blue)
                    )
                    .foregroundColor(showPoweredOnOnly ? .primary : .white)
                }
                .buttonStyle(.plain)
                
                Button {
                    showPoweredOnOnly = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "power.circle.fill")
                            .font(.caption)
                        Text("Powered On")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(showPoweredOnOnly ? Color.green : Color.gray.opacity(0.3))
                    )
                    .foregroundColor(showPoweredOnOnly ? .white : .primary)
                }
                .buttonStyle(.plain)
                
                // Search field
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("Search VMs", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.caption)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
#if os(iOS)
                        .fill(Color(UIColor.systemBackground))
#else
                        .fill(Color(NSColor.textBackgroundColor))
#endif
                )
                .frame(maxWidth: 200)
                
                Spacer()
                
                if let lastUpdated {
                    Text("Updated " + lastUpdated.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Text("\(filteredVMs.count) VMs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.2))
            
            List {
                if filteredVMs.isEmpty {
                    Text(showPoweredOnOnly ? "No powered on VMs" : "No VMs loaded yet.")
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
        }
        .onAppear {
            print("🔵 VMListView appeared - showing \(filteredVMs.count) VMs (filtered from \(viewModel.vms.count) total)")
            if let first = filteredVMs.first {
                print("🔵 First VM in view: \(first.name) (vm=\(first.vm))")
            }
        }
        .navigationTitle("Virtual Machines")
        .refreshable {
            isRefreshing = true
            await viewModel.loadVMs()
            lastUpdated = Date()
            isRefreshing = false
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        isRefreshing = true
                        await viewModel.loadVMs()
                        lastUpdated = Date()
                        isRefreshing = false
                    }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(isRefreshing)
            }
        }
    }
}

#Preview {
    NavigationStack {
        VMListView(viewModel: VCenterViewModel(serverURL: URL(string: "https://example.com")!, username: "u", password: "p"))
    }
}
