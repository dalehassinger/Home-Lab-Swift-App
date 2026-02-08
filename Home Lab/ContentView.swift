//
//  ContentView.swift
//  Home Lab
//
//  Created by Dale Hassinger on 2/6/26.
//

import SwiftUI
import SwiftData
import Observation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var servers: [VCenterServer]
    @Query private var operationsServers: [OperationsServer]
    private let darkBackground = LinearGradient(gradient: Gradient(colors: [Color.black, Color(hue: 0.6, saturation: 0.2, brightness: 0.15)]), startPoint: .topLeading, endPoint: .bottomTrailing)

    @State private var viewModel: VCenterViewModel?
    @State private var operationsViewModel: OperationsViewModel?
    @State private var showingSettings = false
    @State private var selectedServer: VCenterServer?
    
    // Button visibility settings
    @AppStorage("showVirtualMachinesButton") private var showVirtualMachinesButton = true
    @AppStorage("showHostsButton") private var showHostsButton = true
    @AppStorage("showVMSnapshotsButton") private var showVMSnapshotsButton = true
    @AppStorage("showOperationsHostsButton") private var showOperationsHostsButton = true
    
    // Computed property to get default server
    private var defaultServer: VCenterServer? {
        let server = servers.first(where: { $0.isDefault }) ?? servers.first
        if let server = server {
            print("🔍 Default server: \(server.name) - isDefault: \(server.isDefault)")
        } else {
            print("🔍 No default server found - servers count: \(servers.count)")
        }
        return server
    }
    
    // Computed property to get default Operations server
    private var defaultOperationsServer: OperationsServer? {
        let server = operationsServers.first(where: { $0.isDefault }) ?? operationsServers.first
        if let server = server {
            print("🔍 Default Operations server: \(server.name) - isDefault: \(server.isDefault)")
        } else {
            print("🔍 No default Operations server found - servers count: \(operationsServers.count)")
        }
        return server
    }

    var body: some View {
        NavigationSplitView {
            List {
#if os(iOS)
                // Header section
                Section {
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Home Lab")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                Text("Management Servers Defined:")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            Spacer()
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                        }
                        
                        // Server info
                        VStack(spacing: 4) {
                            if let server = selectedServer ?? defaultServer {
                                HStack {
                                    Image(systemName: "server.rack")
                                        .foregroundStyle(.white.opacity(0.7))
                                        .font(.caption2)
                                    Text("vCenter: \(server.name)")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                    Spacer()
                                }
                            }
                            
                            if let opsServer = defaultOperationsServer {
                                HStack {
                                    Image(systemName: "chart.bar.fill")
                                        .foregroundStyle(.white.opacity(0.7))
                                        .font(.caption2)
                                    Text("Operations: \(opsServer.name)")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                // iOS: Card-style tiles
                if let vm = viewModel {
                    if showVirtualMachinesButton {
                        NavigationLink {
                            print("🔵🔵🔵 iOS VM NavigationLink activated")
                            return VMListView(viewModel: vm)
                        } label: {
                            CardTile(title: "vCenter VMs", count: vm.vms.count, systemImage: "rectangle.stack.fill", colors: [Color.teal.opacity(0.9), Color.blue.opacity(0.8)])
                                .padding(.vertical, 8)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .buttonStyle(PlainButtonStyle())
                    }

                    if showHostsButton {
                        NavigationLink {
                            print("🟠🟠🟠 iOS Host NavigationLink activated")
                            return HostListView(viewModel: vm)
                        } label: {
                            CardTile(title: "vCenter Hosts", count: vm.hosts.count, systemImage: "server.rack", colors: [Color.orange.opacity(0.9), Color.red.opacity(0.8)])
                                .padding(.vertical, 8)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if showVMSnapshotsButton {
                        NavigationLink {
                            print("📸📸📸 iOS VM Snapshots NavigationLink activated")
                            return VMSnapshotsView(viewModel: vm)
                        } label: {
                            CardTile(title: "VMs with Snapshots", count: vm.vmsWithSnapshotsCount, systemImage: "camera.on.rectangle.fill", colors: [Color.red.opacity(0.9), Color.pink.opacity(0.8)])
                                .padding(.vertical, 8)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Operations section - independent of vCenter
                if showOperationsHostsButton, let opsServer = defaultOperationsServer {
                    if let opsVM = operationsViewModel {
                        NavigationLink {
                            print("🟢🟢🟢 iOS Operations Hosts NavigationLink activated")
                            return OperationsHostsView(operationsServer: opsServer)
                        } label: {
                            CardTile(title: "Operations Hosts", count: opsVM.hosts.count, systemImage: "chart.bar.fill", colors: [Color.green.opacity(0.9), Color.mint.opacity(0.8)])
                                .padding(.vertical, 8)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        NavigationLink {
                            print("🟢🟢🟢 iOS Operations Hosts NavigationLink activated")
                            return OperationsHostsView(operationsServer: opsServer)
                        } label: {
                            CardTile(title: "Operations Hosts", count: 0, systemImage: "chart.bar.fill", colors: [Color.green.opacity(0.9), Color.mint.opacity(0.8)])
                                .padding(.vertical, 8)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                if viewModel == nil {
                    VStack(spacing: 12) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No vCenter Server")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Button {
                            showingSettings = true
                        } label: {
                            Label("Add Server", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
#else
                // macOS: Header
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Home Lab")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Management Servers Defined:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let server = selectedServer ?? defaultServer {
                                HStack {
                                    Image(systemName: "server.rack")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(server.name)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        Spacer()
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 8)
                }
                
                // macOS: Sidebar-style list items
                if let vm = viewModel {
                    Section("vCenter Resources") {
                        if showVirtualMachinesButton {
                            NavigationLink {
                                print("🔵🔵🔵 macOS VM NavigationLink activated")
                                return VMListView(viewModel: vm)
                            } label: {
                                Label {
                                    HStack {
                                        Text("vCenter VMs")
                                        Spacer()
                                        Text("\(vm.vms.count)")
                                            .foregroundStyle(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: "rectangle.stack.fill")
                                        .foregroundStyle(.teal)
                                }
                            }
                        }
                        
                        if showHostsButton {
                            NavigationLink {
                                print("🟠🟠🟠 macOS Host NavigationLink activated")
                                return HostListView(viewModel: vm)
                            } label: {
                                Label {
                                    HStack {
                                        Text("Hosts")
                                        Spacer()
                                        Text("\(vm.hosts.count)")
                                            .foregroundStyle(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: "server.rack")
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                        
                        if showVMSnapshotsButton {
                            NavigationLink {
                                print("📸📸📸 macOS VM Snapshots NavigationLink activated")
                                return VMSnapshotsView(viewModel: vm)
                            } label: {
                                Label {
                                    HStack {
                                        Text("VMs with Snapshots")
                                        Spacer()
                                        Text("\(vm.vmsWithSnapshotsCount)")
                                            .foregroundStyle(.secondary)
                                    }
                                } icon: {
                                    Image(systemName: "camera.on.rectangle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                }
                
                // Operations section - independent of vCenter
                if showOperationsHostsButton, let opsServer = defaultOperationsServer {
                    Section("VMware Aria Operations") {
                        NavigationLink {
                            print("🟢🟢🟢 macOS Operations Hosts NavigationLink activated")
                            return OperationsHostsView(operationsServer: opsServer)
                        } label: {
                            Label {
                                HStack {
                                    Text("Operations Hosts")
                                    Spacer()
                                    if let opsVM = operationsViewModel {
                                        Text("\(opsVM.hosts.count)")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            } icon: {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
                
                if viewModel == nil {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "server.rack")
                                .font(.system(size: 36))
                                .foregroundStyle(.secondary)
                            Text("No vCenter Server")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button {
                                showingSettings = true
                            } label: {
                                Label("Add Server", systemImage: "plus.circle")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                }
#endif
                
                Section {
                    HStack {
                        Image(systemName: connectionStatusIcon)
                            .foregroundStyle(connectionStatusColor)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("vCenter Connection")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if let server = selectedServer ?? defaultServer {
                                Text(server.name)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .fontWeight(.medium)
                            }
                            Text(connectionStatusText)
                                .font(.caption)
                                .foregroundStyle(connectionStatusColor)
                        }
                        Spacer()
                        Button {
                            Task {
                                await initializeViewModel()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .help("Reconnect to vCenter")
                    }
                    .padding(.vertical, 4)
                    
                    // Operations connection status
                    if let opsServer = defaultOperationsServer {
                        HStack {
                            Image(systemName: operationsConnectionStatusIcon)
                                .foregroundStyle(operationsConnectionStatusColor)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Operations Connection")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(opsServer.name)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                                    .fontWeight(.medium)
                                Text(operationsConnectionStatusText)
                                    .font(.caption)
                                    .foregroundStyle(operationsConnectionStatusColor)
                            }
                            Spacer()
                            Button {
                                Task {
                                    await initializeOperationsViewModel()
                                }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                            .help("Reconnect to Operations")
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Status")
                }
            }
            .scrollContentBackground(.hidden)
            .background(
                darkBackground
            )
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
#endif
        } detail: {
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Choose a tile to view data")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(
                    darkBackground
                )
                .scrollContentBackground(.hidden)
            }
        }
        .tint(Color.green)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .task(id: selectedServer?.id ?? defaultServer?.id) {
            await initializeViewModel()
        }
        .task(id: defaultOperationsServer?.id) {
            await initializeOperationsViewModel()
        }
    }
    
    @MainActor
    private func initializeViewModel() async {
        print("🔄 initializeViewModel called")
        print("   Selected server: \(selectedServer?.name ?? "none")")
        print("   Default server: \(defaultServer?.name ?? "none")")
        print("   Servers count: \(servers.count)")
        
        guard let server = selectedServer ?? defaultServer else {
            print("❌ No server available")
            viewModel = nil
            return
        }
        
        guard let url = URL(string: server.url) else {
            print("❌ Invalid URL: \(server.url)")
            viewModel = nil
            return
        }
        
        print("✅ Creating ViewModel for: \(server.name)")
        print("   URL: \(url)")
        print("   Username: \(server.username)")
        
        let vm = VCenterViewModel(
            serverURL: url,
            username: server.username,
            password: server.password
        )
        
        viewModel = vm
        
        print("🔵 Loading VMs...")
        await vm.loadVMs()
        print("🟠 Loading Hosts...")
        await vm.loadHosts()
        print("📸 Loading VM Snapshots count...")
        await vm.loadVMsWithSnapshotsCount()
        print("✅ Connection attempt complete")
    }
    
    @MainActor
    private func initializeOperationsViewModel() async {
        print("🔄 initializeOperationsViewModel called")
        print("   Default Operations server: \(defaultOperationsServer?.name ?? "none")")
        print("   Operations servers count: \(operationsServers.count)")
        
        guard let server = defaultOperationsServer else {
            print("❌ No Operations server available")
            operationsViewModel = nil
            return
        }
        
        guard let url = URL(string: server.url) else {
            print("❌ Invalid Operations URL: \(server.url)")
            operationsViewModel = nil
            return
        }
        
        print("✅ Creating Operations ViewModel for: \(server.name)")
        print("   URL: \(url)")
        print("   Username: \(server.username)")
        
        let opsVM = OperationsViewModel(
            serverURL: url,
            username: server.username,
            password: server.password
        )
        
        operationsViewModel = opsVM
        
        print("🟢 Loading Operations Hosts...")
        await opsVM.loadHosts()
        print("✅ Operations connection attempt complete")
    }
    
    // Connection status computed properties
    private var connectionStatusIcon: String {
        guard let viewModel else { return "circle.fill" }
        switch viewModel.connectionState {
        case .disconnected:
            return "circle.fill"
        case .connecting:
            return "circle.dotted"
        case .connected:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
    
    private var connectionStatusColor: Color {
        guard let viewModel else { return .gray }
        switch viewModel.connectionState {
        case .disconnected:
            return .gray
        case .connecting:
            return .orange
        case .connected:
            return .green
        case .failed:
            return .red
        }
    }
    
    private var connectionStatusText: String {
        guard let viewModel else { return "No Server" }
        switch viewModel.connectionState {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .failed(let error):
            return "Failed: \(error)"
        }
    }
    
    // Operations connection status computed properties
    private var operationsConnectionStatusIcon: String {
        guard let operationsViewModel else { return "circle.fill" }
        switch operationsViewModel.connectionState {
        case .disconnected:
            return "circle.fill"
        case .connecting:
            return "circle.dotted"
        case .connected:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
    
    private var operationsConnectionStatusColor: Color {
        guard let operationsViewModel else { return .gray }
        switch operationsViewModel.connectionState {
        case .disconnected:
            return .gray
        case .connecting:
            return .orange
        case .connected:
            return .green
        case .failed:
            return .red
        }
    }
    
    private var operationsConnectionStatusText: String {
        guard let operationsViewModel else { return "No Server" }
        switch operationsViewModel.connectionState {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .failed(let error):
            return "Failed: \(error)"
        }
    }
}

struct CardTile: View {
    let title: String
    let count: Int
    let systemImage: String
    let colors: [Color]

    init(title: String, count: Int, systemImage: String, colors: [Color]) {
        self.title = title
        self.count = count
        self.systemImage = systemImage
        self.colors = colors
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient(gradient: Gradient(colors: colors), startPoint: .topLeading, endPoint: .bottomTrailing))
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: systemImage)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(count)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Tap to view")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(16)
        }
        .frame(height: 120)
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Item.self, VCenterServer.self], inMemory: true)
}

