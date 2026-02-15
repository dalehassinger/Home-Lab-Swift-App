//
//  OperationsHostsView.swift
//  Home Lab
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI
#if os(macOS)
import AppKit
import ObjectiveC.runtime
#endif
import OSLog

struct OperationsHostsView: View {
    let operationsServer: OperationsServer
    
    @State private var hosts: [OperationsHost] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedHost: OperationsHost?
#if os(macOS)
    @State private var openWindows: [NSWindow] = []
#endif
    
    private var client: OperationsClient {
        guard let url = URL(string: operationsServer.url) else {
            fatalError("Invalid Operations URL")
        }
        return OperationsClient(
            baseURL: url,
            username: operationsServer.username,
            password: operationsServer.password
        )
    }
    
    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading ESXi Hosts from Operations...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text("Error Loading Data")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button {
                        Task { await loadHosts() }
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if hosts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No ESXi Hosts")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("No hosts found in Operations")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(hosts) { host in
                        HostRowView(host: host, onTap: {
                            openDetailWindow(for: host)
                        })
                    }
                }
            }
        }
        .navigationTitle("Operations ESXi Hosts")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .task {
            await loadHosts()
        }
        .refreshable {
            await loadHosts()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await loadHosts() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
        .sheet(item: $selectedHost) { host in
            NavigationStack {
                OperationsHostDetailView(host: host, client: client)
                    .navigationTitle(host.name)
#if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
#endif
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                selectedHost = nil
                            }
                        }
                    }
            }
        }
    }
    
    @MainActor
    private func loadHosts() async {
        isLoading = true
        errorMessage = nil
        hosts = []
        
        do {
            hosts = try await client.fetchESXiHosts()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func openDetailWindow(for host: OperationsHost) {
#if os(macOS)
        let detailView = OperationsHostDetailView(host: host, client: client)
        let hostingController = NSHostingController(rootView: detailView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = host.name
        window.setContentSize(NSSize(width: 800, height: 600))
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        window.center()
        
        // Set delegate to remove from array when closed
        let delegate = WindowDelegate {
            if let index = openWindows.firstIndex(of: window) {
                openWindows.remove(at: index)
            }
        }
        window.delegate = delegate
        objc_setAssociatedObject(window, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        openWindows.append(window)
#else
        selectedHost = host
#endif
    }
    
    // Helper function to convert color string to Color
    private func colorForHealth(_ colorName: String) -> Color {
        switch colorName {
        case "green": return .green
        case "mint": return .mint
        case "orange": return .orange
        case "red": return .red
        case "gray": return .gray
        default: return .gray
        }
    }
}

// MARK: - Host Row View

private struct HostRowView: View {
    let host: OperationsHost
    let onTap: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Health Icon
            Image(systemName: host.healthStatus.icon)
                .font(.title2)
                .foregroundStyle(colorForHealth(host.healthStatus.color))
                .frame(width: 30)
            
            // Host Information
            VStack(alignment: .leading, spacing: 4) {
                Text(host.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    // Health Score
                    if let healthValue = host.resourceHealthValue ?? host.healthScore {
                        HStack(spacing: 4) {
                            Text("\(Int(healthValue))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(host.healthStatus.text)
                                .font(.subheadline)
                        }
                        .foregroundStyle(colorForHealth(host.healthStatus.color))
                    } else {
                        Text("No health data")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    // Resource Kind
                    if let resourceKind = host.resourceKey.resourceKindKey {
                        Text(resourceKind)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Adapter Kind
                if let adapterKind = host.resourceKey.adapterKindKey {
                    HStack(spacing: 4) {
                        Image(systemName: "puzzlepiece.extension.fill")
                            .font(.caption2)
                        Text(adapterKind)
                            .font(.caption)
                    }
                    .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Health Badge
            if let healthValue = host.resourceHealthValue ?? host.healthScore {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorForHealth(host.healthStatus.color).opacity(0.2))
                    Text("\(Int(healthValue))")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(colorForHealth(host.healthStatus.color))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .fixedSize()
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private func colorForHealth(_ colorName: String) -> Color {
        switch colorName {
        case "green": return .green
        case "mint": return .mint
        case "orange": return .orange
        case "red": return .red
        case "gray": return .gray
        default: return .gray
        }
    }
}

// MARK: - Window Delegate

#if os(macOS)
class WindowDelegate: NSObject, NSWindowDelegate {
    let onClose: () -> Void
    
    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
#endif

// MARK: - Preview

#Preview {
    let sampleServer = OperationsServer(
        name: "Operations Dev",
        url: "https://192.168.6.199",
        username: "admin",
        password: "password"
    )
    
    NavigationStack {
        OperationsHostsView(operationsServer: sampleServer)
    }
}
