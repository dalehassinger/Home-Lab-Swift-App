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

    @State private var viewModel: VCenterViewModel?
    @State private var operationsViewModel: OperationsViewModel?
    @State private var showingSettings = false
    @State private var selectedServer: VCenterServer?
    
    // Button visibility settings
    @AppStorage("showVirtualMachinesButton") private var showVirtualMachinesButton = true
    @AppStorage("showHostsButton") private var showHostsButton = true
    @AppStorage("showVMSnapshotsButton") private var showVMSnapshotsButton = true
    @AppStorage("showOperationsHostsButton") private var showOperationsHostsButton = true
    @AppStorage("showElectricityUsageButton") private var showElectricityUsageButton = true
    
    // Computed property to get default server
    private var defaultServer: VCenterServer? {
        let server = servers.first(where: { $0.isDefault }) ?? servers.first
        return server
    }
    
    // Computed property to get default Operations server
    private var defaultOperationsServer: OperationsServer? {
        let server = operationsServers.first(where: { $0.isDefault }) ?? operationsServers.first
        return server
    }

    var body: some View {
#if os(iOS)
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header section with Liquid Glass effect
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Home Lab")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                Text("Management Servers Defined:")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                            Spacer()
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.glass)
                        }
                        
                        // Server info with glass background
                        VStack(spacing: 8) {
                            if let server = selectedServer ?? defaultServer {
                                HStack {
                                    Image(systemName: "server.rack")
                                        .foregroundStyle(.white.opacity(0.8))
                                        .font(.caption2)
                                    Text("vCenter: \(server.name)")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.9))
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .glassEffect(.regular, in: .capsule)
                            }
                            
                            if let opsServer = defaultOperationsServer {
                                HStack {
                                    Image(systemName: "chart.bar.fill")
                                        .foregroundStyle(.white.opacity(0.8))
                                        .font(.caption2)
                                    Text("Operations: \(opsServer.name)")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.9))
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .glassEffect(.regular, in: .capsule)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    
                    // Grid tiles with Liquid Glass container
                    GlassEffectContainer(spacing: 20.0) {
                        GridTilesView(
                            viewModel: viewModel,
                            operationsViewModel: operationsViewModel,
                            defaultOperationsServer: defaultOperationsServer,
                            showVirtualMachinesButton: showVirtualMachinesButton,
                            showHostsButton: showHostsButton,
                            showVMSnapshotsButton: showVMSnapshotsButton,
                            showOperationsHostsButton: showOperationsHostsButton,
                            showElectricityUsageButton: showElectricityUsageButton
                        )
                        .padding(.horizontal, 16)
                    }
                    
                    // Status section with glass effects
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Status")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 16)
                        
                        GlassEffectContainer(spacing: 16.0) {
                            VStack(spacing: 12) {
                                // vCenter status row with glass effect
                                HStack {
                                    Image(systemName: connectionStatusIcon)
                                        .foregroundStyle(connectionStatusColor)
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("vCenter Connection")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.white)
                                        if let server = selectedServer ?? defaultServer {
                                            Text(server.name)
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.8))
                                        }
                                        Text(connectionStatusText)
                                            .font(.caption)
                                            .foregroundStyle(connectionStatusColor)
                                    }
                                    Spacer()
                                    Button {
                                        Task { await initializeViewModel() }
                                    } label: {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.callout)
                                    }
                                    .buttonStyle(.glass)
                                }
                                .padding(16)
                                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                                
                                // Operations status row with glass effect
                                if let opsServer = defaultOperationsServer {
                                    HStack {
                                        Image(systemName: operationsConnectionStatusIcon)
                                            .foregroundStyle(operationsConnectionStatusColor)
                                            .font(.title3)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Operations Connection")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.white)
                                            Text(opsServer.name)
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.8))
                                            Text(operationsConnectionStatusText)
                                                .font(.caption)
                                                .foregroundStyle(operationsConnectionStatusColor)
                                        }
                                        Spacer()
                                        Button {
                                            Task { await initializeOperationsViewModel() }
                                        } label: {
                                            Image(systemName: "arrow.clockwise")
                                                .font(.callout)
                                        }
                                        .buttonStyle(.glass)
                                    }
                                    .padding(16)
                                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    
                    // Empty state when no vCenter server
                    if viewModel == nil {
                        VStack(spacing: 16) {
                            Image(systemName: "server.rack")
                                .font(.system(size: 56))
                                .foregroundStyle(.white.opacity(0.6))
                            Text("No vCenter Server")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.9))
                            Button {
                                showingSettings = true
                            } label: {
                                Label("Add Server", systemImage: "plus.circle.fill")
                            }
                            .buttonStyle(.glassProminent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .padding(.horizontal, 16)
                        .glassEffect(.regular, in: .rect(cornerRadius: 20))
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
            .background(Color.black.ignoresSafeArea())
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
#else
        // macOS: Use NavigationStack instead of NavigationSplitView
        NavigationStack {
            List {
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
                                VMListView(viewModel: vm)
                                    .id("vmlist")
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
                            .tag("vmlist")
                        }
                        
                        if showHostsButton {
                            NavigationLink {
                                HostListView(viewModel: vm)
                                    .id("hostlist")
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
                            .tag("hostlist")
                        }
                        
                        if showVMSnapshotsButton {
                            NavigationLink {
                                VMSnapshotsView(viewModel: vm)
                                    .id("snapshots")
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
                            .tag("snapshots")
                        }
                    }
                }
                
                // Operations section - independent of vCenter
                if showOperationsHostsButton, let opsServer = defaultOperationsServer {
                    Section("VMware Aria Operations") {
                        NavigationLink {
                            OperationsHostsView(operationsServer: opsServer)
                                .id("operations")
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
                        .tag("operations")
                    }
                }
                
                // Electricity Usage section - independent
                if showElectricityUsageButton {
                    Section("Energy Monitoring") {
                        NavigationLink {
                            ElectricityUsageView()
                                .id("electricity")
                        } label: {
                            Label {
                                Text("Electricity Usage")
                            } icon: {
                                Image(systemName: "bolt.fill")
                                    .foregroundStyle(.yellow)
                            }
                        }
                        .tag("electricity")
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
            .background(Color.black)
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
#endif
    }
    
    @MainActor
    private func initializeViewModel() async {
        guard let server = selectedServer ?? defaultServer else {
            viewModel = nil
            return
        }
        
        guard let url = URL(string: server.url) else {
            viewModel = nil
            return
        }
        
        let vm = VCenterViewModel(
            serverURL: url,
            username: server.username,
            password: server.password
        )
        
        viewModel = vm
        
        await vm.loadVMs()
        await vm.loadHosts()
        await vm.loadVMsWithSnapshotsCount()
    }
    
    @MainActor
    private func initializeOperationsViewModel() async {
        guard let server = defaultOperationsServer else {
            operationsViewModel = nil
            return
        }
        
        guard let url = URL(string: server.url) else {
            operationsViewModel = nil
            return
        }
        
        let opsVM = OperationsViewModel(
            serverURL: url,
            username: server.username,
            password: server.password
        )
        
        operationsViewModel = opsVM
        
        await opsVM.loadHosts()
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

// MARK: - Grid Tiles View for iOS

struct GridTilesView: View {
    let viewModel: VCenterViewModel?
    let operationsViewModel: OperationsViewModel?
    let defaultOperationsServer: OperationsServer?
    let showVirtualMachinesButton: Bool
    let showHostsButton: Bool
    let showVMSnapshotsButton: Bool
    let showOperationsHostsButton: Bool
    let showElectricityUsageButton: Bool
    
    // Define all possible tiles
    private var visibleTiles: [TileData] {
        var tiles: [TileData] = []
        
        if let vm = viewModel {
            if showVirtualMachinesButton {
                tiles.append(TileData(
                    id: "vms",
                    title: "vCenter VMs",
                    count: vm.vms.count,
                    systemImage: "rectangle.stack.fill",
                    colors: [Color.teal.opacity(0.9), Color.blue.opacity(0.8)],
                    destination: .vmList(vm)
                ))
            }
            
            if showHostsButton {
                tiles.append(TileData(
                    id: "hosts",
                    title: "vCenter Hosts",
                    count: vm.hosts.count,
                    systemImage: "server.rack",
                    colors: [Color.orange.opacity(0.9), Color.red.opacity(0.8)],
                    destination: .hostList(vm)
                ))
            }
            
            if showVMSnapshotsButton {
                tiles.append(TileData(
                    id: "snapshots",
                    title: "VM Snapshots",
                    count: vm.vmsWithSnapshotsCount,
                    systemImage: "camera.on.rectangle.fill",
                    colors: [Color.red.opacity(0.9), Color.pink.opacity(0.8)],
                    destination: .vmSnapshots(vm)
                ))
            }
        }
        
        if showOperationsHostsButton, let opsServer = defaultOperationsServer {
            let count = operationsViewModel?.hosts.count ?? 0
            tiles.append(TileData(
                id: "operations",
                title: "Operations Hosts",
                count: count,
                systemImage: "chart.bar.fill",
                colors: [Color.green.opacity(0.9), Color.mint.opacity(0.8)],
                destination: .operationsHosts(opsServer)
            ))
        }
        
        if showElectricityUsageButton {
            tiles.append(TileData(
                id: "electricity",
                title: "Electricity Usage",
                count: 0, // Count not applicable for this tile
                systemImage: "bolt.fill",
                colors: [Color.yellow.opacity(0.9), Color.orange.opacity(0.8)],
                destination: .electricityUsage
            ))
        }
        
        return tiles
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(visibleTiles) { tile in
                NavigationLink {
                    tile.destination.view
                        .id(tile.id)
                } label: {
                    CompactCardTile(
                        title: tile.title,
                        count: tile.count,
                        systemImage: tile.systemImage,
                        colors: tile.colors
                    )
                    .contentShape(Rectangle())
                }
            }
        }
    }
}

// MARK: - Tile Data Model

struct TileData: Identifiable {
    let id: String
    let title: String
    let count: Int
    let systemImage: String
    let colors: [Color]
    let destination: TileDestination
}

enum TileDestination {
    case vmList(VCenterViewModel)
    case hostList(VCenterViewModel)
    case vmSnapshots(VCenterViewModel)
    case operationsHosts(OperationsServer)
    case electricityUsage
    
    @ViewBuilder
    var view: some View {
        switch self {
        case .vmList(let vm):
            VMListView(viewModel: vm)
                .id("vmlist")
        case .hostList(let vm):
            HostListView(viewModel: vm)
                .id("hostlist")
        case .vmSnapshots(let vm):
            VMSnapshotsView(viewModel: vm)
                .id("snapshots")
        case .operationsHosts(let server):
            OperationsHostsView(operationsServer: server)
                .id("operations")
        case .electricityUsage:
            ElectricityUsageView()
                .id("electricity")
        }
    }
}

// MARK: - Compact Card Tile (for Grid) with Liquid Glass

struct CompactCardTile: View {
    let title: String
    let count: Int
    let systemImage: String
    let colors: [Color]
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            Image(systemName: systemImage)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.white)
                .frame(height: 40)
                .shadow(color: colors[0].opacity(0.5), radius: 8, x: 0, y: 2)
            
            // Count badge (only show if count > 0)
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .glassEffect(.regular, in: .capsule)
            } else {
                // Spacer to maintain consistent height when no count
                Color.clear
                    .frame(height: 40)
            }
            
            // Title
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .padding(16)
        .glassEffect(.regular.tint(colors[0]).interactive(), in: .rect(cornerRadius: 20))
    }
}

// MARK: - Original Full-Width Card Tile (kept for macOS if needed)

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

