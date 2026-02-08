//
//  SettingsView.swift
//  Home Lab
//
//  Created by Dale Hassinger on 2/6/26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \VCenterServer.name) private var servers: [VCenterServer]
    @Query(sort: \OperationsServer.name) private var operationsServers: [OperationsServer]
    
    @State private var showingAddServer = false
    @State private var editingServer: VCenterServer?
    @State private var showingAddOperationsServer = false
    @State private var editingOperationsServer: OperationsServer?
    
    // Button visibility settings
    @AppStorage("showVirtualMachinesButton") private var showVirtualMachinesButton = true
    @AppStorage("showHostsButton") private var showHostsButton = true
    @AppStorage("showVMSnapshotsButton") private var showVMSnapshotsButton = true
    @AppStorage("showOperationsHostsButton") private var showOperationsHostsButton = true
    
    var body: some View {
        NavigationStack {
            Group {
                if servers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No vCenter Servers")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Add a vCenter server to get started")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Tap the + button above")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        
                        Button {
                            showingAddServer = true
                        } label: {
                            Label("Add Server", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        Section {
                            ForEach(servers) { server in
                                HStack(spacing: 0) {
                                    Button {
                                        editingServer = server
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                HStack {
                                                    Text(server.name)
                                                        .font(.headline)
                                                    if server.isDefault {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundStyle(.green)
                                                            .font(.caption)
                                                    }
                                                }
                                                Text(server.url)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                Text("User: \(server.username)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    
#if os(macOS)
                                    Button(role: .destructive) {
                                        deleteServer(server)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.borderless)
                                    .help("Delete this server")
#endif
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteServer(server)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteServer(server)
                                    } label: {
                                        Label("Delete Server", systemImage: "trash")
                                    }
                                }
                            }
                            .onDelete(perform: deleteServers)
                        } header: {
                            Text("vCenter Servers (\(servers.count))")
                        } footer: {
#if os(macOS)
                            Text("Click the trash icon to delete • Right-click for more options")
                                .font(.caption2)
#else
                            Text("Swipe left to delete • Long press for options")
                                .font(.caption2)
#endif
                        }
                        
                        // Operations Servers Section
                        Section {
                            ForEach(operationsServers) { server in
                                HStack(spacing: 0) {
                                    Button {
                                        editingOperationsServer = server
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                HStack {
                                                    Text(server.name)
                                                        .font(.headline)
                                                    if server.isDefault {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .foregroundStyle(.green)
                                                            .font(.caption)
                                                    }
                                                }
                                                Text(server.url)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                Text("User: \(server.username)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    
#if os(macOS)
                                    Button(role: .destructive) {
                                        deleteOperationsServer(server)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.borderless)
                                    .help("Delete this server")
#endif
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteOperationsServer(server)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteOperationsServer(server)
                                    } label: {
                                        Label("Delete Server", systemImage: "trash")
                                    }
                                }
                            }
                            .onDelete(perform: deleteOperationsServers)
                            
                            Button {
                                showingAddOperationsServer = true
                            } label: {
                                Label("Add Operations Server", systemImage: "plus.circle")
                            }
                        } header: {
                            Text("VMware Aria Operations Servers (\(operationsServers.count))")
                        } footer: {
#if os(macOS)
                            Text("Click the trash icon to delete • Right-click for more options")
                                .font(.caption2)
#else
                            Text("Swipe left to delete • Long press for options")
                                .font(.caption2)
#endif
                        }
                        
                        // Display Options Section
                        Section {
                            Toggle(isOn: $showVirtualMachinesButton) {
                                Label("Virtual Machines", systemImage: "rectangle.stack.fill")
                            }
                            .tint(.teal)
                            
                            Toggle(isOn: $showHostsButton) {
                                Label("Hosts", systemImage: "server.rack")
                            }
                            .tint(.orange)
                            
                            Toggle(isOn: $showVMSnapshotsButton) {
                                Label("VMs with Snapshots", systemImage: "camera.on.rectangle.fill")
                            }
                            .tint(.red)
                            
                            Toggle(isOn: $showOperationsHostsButton) {
                                Label("Operations ESXi Hosts", systemImage: "chart.bar.fill")
                            }
                            .tint(.green)
                        } header: {
                            Text("Main Screen Buttons")
                        } footer: {
                            Text("Control which buttons appear on the main screen")
                                .font(.caption2)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddServer = true
                    } label: {
                        Label("Add Server", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddServer) {
                AddServerView()
            }
            .sheet(item: $editingServer) { server in
                EditServerView(server: server)
            }
            .sheet(isPresented: $showingAddOperationsServer) {
                AddOperationsServerView()
            }
            .sheet(item: $editingOperationsServer) { server in
                EditOperationsServerView(server: server)
            }
        }
#if os(macOS)
        .frame(minWidth: 600, minHeight: 400)
#endif
    }
    
    private func deleteServers(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(servers[index])
            }
        }
    }
    
    private func deleteServer(_ server: VCenterServer) {
        withAnimation {
            modelContext.delete(server)
        }
    }
    
    private func deleteOperationsServers(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(operationsServers[index])
            }
        }
    }
    
    private func deleteOperationsServer(_ server: OperationsServer) {
        withAnimation {
            modelContext.delete(server)
        }
    }
}

struct AddServerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingServers: [VCenterServer]
    
    @State private var name = ""
    @State private var url = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isDefault = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textContentType(.organizationName)
                    TextField("URL", text: $url)
                        .textContentType(.URL)
#if os(iOS)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
#endif
                } header: {
                    Text("Server Information")
                } footer: {
                    Text("Example: https://vcenter.example.com")
                }
                
                Section {
                    TextField("Username", text: $username)
                        .textContentType(.username)
#if os(iOS)
                        .autocapitalization(.none)
#endif
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                } header: {
                    Text("Credentials")
                }
                
                Section {
                    Toggle("Set as Default", isOn: $isDefault)
                } footer: {
                    Text("The default server will be used when the app launches")
                }
            }
            .navigationTitle("Add vCenter Server")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveServer()
                    }
                    .disabled(name.isEmpty || url.isEmpty || username.isEmpty || password.isEmpty)
                }
            }
        }
    }
    
    private func saveServer() {
        // If this is set as default, unset all other defaults
        if isDefault {
            for server in existingServers {
                server.isDefault = false
            }
        }
        
        let newServer = VCenterServer(
            name: name,
            url: url,
            username: username,
            password: password,
            isDefault: isDefault || existingServers.isEmpty // First server is always default
        )
        
        modelContext.insert(newServer)
        dismiss()
    }
}

struct EditServerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allServers: [VCenterServer]
    
    var server: VCenterServer
    
    @State private var name: String = ""
    @State private var url: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isDefault: Bool = false
    @State private var hasLoaded: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name, prompt: Text("Enter server name"))
                    TextField("URL", text: $url, prompt: Text("https://vcenter.example.com"))
#if os(iOS)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
#endif
                } header: {
                    Text("Server Information")
                }
                
                Section {
                    TextField("Username", text: $username, prompt: Text("administrator@vsphere.local"))
#if os(iOS)
                        .autocapitalization(.none)
#endif
                    SecureField("Password", text: $password, prompt: Text("Enter password"))
                } header: {
                    Text("Credentials")
                }
                
                Section {
                    Toggle("Set as Default", isOn: $isDefault)
                } footer: {
                    Text("The default server will be used when the app launches")
                }
            }
            .navigationTitle("Edit Server")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty || url.isEmpty || username.isEmpty || password.isEmpty)
#if os(macOS)
                    .keyboardShortcut(.defaultAction)
#endif
                }
            }
            .task {
                loadData()
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        name = server.name
        url = server.url
        username = server.username
        password = server.password
        isDefault = server.isDefault
        hasLoaded = true
    }
    
    private func saveChanges() {
        // If this is set as default, unset all other defaults
        if isDefault && !server.isDefault {
            for otherServer in allServers where otherServer.id != server.id {
                otherServer.isDefault = false
            }
        }
        
        // Update the server object
        server.name = name
        server.url = url
        server.username = username
        server.password = password
        server.isDefault = isDefault
        
        // Explicitly save the context
        do {
            try modelContext.save()
        } catch {
            // Handle error silently or show alert in production
        }
        
        dismiss()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: VCenterServer.self, inMemory: true)
}
// MARK: - Operations Server Management

struct AddOperationsServerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var existingServers: [OperationsServer]
    
    @State private var name = ""
    @State private var url = ""
    @State private var username = ""
    @State private var password = ""
    @State private var isDefault = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textContentType(.organizationName)
                    TextField("URL", text: $url)
                        .textContentType(.URL)
#if os(iOS)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
#endif
                } header: {
                    Text("Server Information")
                } footer: {
                    Text("Example: https://192.168.6.199")
                }
                
                Section {
                    TextField("Username", text: $username)
                        .textContentType(.username)
#if os(iOS)
                        .autocapitalization(.none)
#endif
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                } header: {
                    Text("Credentials")
                }
                
                Section {
                    Toggle("Set as Default", isOn: $isDefault)
                } footer: {
                    Text("The default Operations server will be used when the app launches")
                }
            }
            .navigationTitle("Add Operations Server")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveServer()
                    }
                    .disabled(name.isEmpty || url.isEmpty || username.isEmpty || password.isEmpty)
                }
            }
        }
    }
    
    private func saveServer() {
        // If this is set as default, unset all other defaults
        if isDefault {
            for server in existingServers {
                server.isDefault = false
            }
        }
        
        let newServer = OperationsServer(
            name: name,
            url: url,
            username: username,
            password: password,
            isDefault: isDefault || existingServers.isEmpty // First server is always default
        )
        
        modelContext.insert(newServer)
        dismiss()
    }
}

struct EditOperationsServerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allServers: [OperationsServer]
    
    var server: OperationsServer
    
    @State private var name: String = ""
    @State private var url: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isDefault: Bool = false
    @State private var hasLoaded: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name, prompt: Text("Enter server name"))
                    TextField("URL", text: $url, prompt: Text("https://192.168.6.199"))
#if os(iOS)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
#endif
                } header: {
                    Text("Server Information")
                }
                
                Section {
                    TextField("Username", text: $username, prompt: Text("admin"))
#if os(iOS)
                        .autocapitalization(.none)
#endif
                    SecureField("Password", text: $password, prompt: Text("Enter password"))
                } header: {
                    Text("Credentials")
                }
                
                Section {
                    Toggle("Set as Default", isOn: $isDefault)
                } footer: {
                    Text("The default Operations server will be used when the app launches")
                }
            }
            .navigationTitle("Edit Operations Server")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty || url.isEmpty || username.isEmpty || password.isEmpty)
#if os(macOS)
                    .keyboardShortcut(.defaultAction)
#endif
                }
            }
            .task {
                loadData()
            }
            .onAppear {
                loadData()
            }
        }
    }
    
    private func loadData() {
        name = server.name
        url = server.url
        username = server.username
        password = server.password
        isDefault = server.isDefault
        hasLoaded = true
    }
    
    private func saveChanges() {
        // If this is set as default, unset all other defaults
        if isDefault && !server.isDefault {
            for otherServer in allServers where otherServer.id != server.id {
                otherServer.isDefault = false
            }
        }
        
        // Update the server object
        server.name = name
        server.url = url
        server.username = username
        server.password = password
        server.isDefault = isDefault
        
        // Explicitly save the context
        do {
            try modelContext.save()
        } catch {
            // Handle error silently or show alert in production
        }
        
        dismiss()
    }
}


