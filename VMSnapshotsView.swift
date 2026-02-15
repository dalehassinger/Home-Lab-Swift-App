//
//  VMSnapshotsView.swift
//  Home Lab
//
//  Created by Assistant on 2/6/26.
//

import SwiftUI

fileprivate enum ISO8601Helper {
    static func parse(_ dateString: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: dateString) { return date }
        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.date(from: dateString)
    }
}

/// Represents a VM with its snapshot information
struct VMWithSnapshots: Identifiable {
    let vm: VCenterVM
    let snapshots: [VCenterVMSnapshot]
    
    var id: String { vm.id }
}

struct VMSnapshotsView: View {
    let viewModel: VCenterViewModel
    
    @State private var vmsWithSnapshots: [VMWithSnapshots] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastUpdated: Date? = nil
    @State private var isRefreshing: Bool = false
    
    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading VMs with Snapshots...")
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
                    Button {
                        Task { await loadVMsWithSnapshots() }
                    } label: {
                        Label("Retry", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vmsWithSnapshots.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "camera.on.rectangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No VMs with Snapshots")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("None of your VMs currently have snapshots")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(vmsWithSnapshots) { vmWithSnapshots in
                            VMSnapshotCard(
                                vm: vmWithSnapshots.vm,
                                snapshots: vmWithSnapshots.snapshots,
                                client: viewModel.client
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("VMs with Snapshots")
        .task {
            await loadVMsWithSnapshots()
        }
        .refreshable {
            isRefreshing = true
            await loadVMsWithSnapshots()
            lastUpdated = Date()
            isRefreshing = false
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack(spacing: 12) {
                if let lastUpdated {
                    Text("Updated " + lastUpdated.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(0.7)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.15))
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        isRefreshing = true
                        await loadVMsWithSnapshots()
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
    
    private func loadVMsWithSnapshots() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            vmsWithSnapshots = []
        }
        do {
            let filteredVMs = await MainActor.run { viewModel.vms.filter { !$0.name.hasPrefix("vCLS-") } }
            var results: [VMWithSnapshots] = []
            try await withThrowingTaskGroup(of: VMWithSnapshots?.self) { group in
                for vm in filteredVMs {
                    group.addTask {
                        do {
                            let snapshots = try await viewModel.client.fetchVMSnapshots(id: vm.id)
                            return snapshots.isEmpty ? nil : VMWithSnapshots(vm: vm, snapshots: snapshots)
                        } catch {
                            print("⚠️ Could not fetch snapshots for VM \(vm.name): \(error)")
                            return nil
                        }
                    }
                }
                for try await item in group {
                    if let item { results.append(item) }
                }
            }
            let sorted = results.sorted { $0.vm.name.localizedCaseInsensitiveCompare($1.vm.name) == .orderedAscending }
            await MainActor.run { vmsWithSnapshots = sorted }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
            print("🔴 Error loading VMs with snapshots: \(error)")
        }
        await MainActor.run { isLoading = false }
    }
}

struct VMSnapshotCard: View {
    let vm: VCenterVM
    let snapshots: [VCenterVMSnapshot]
    let client: VCenterClient
    
    var body: some View {
        NavigationLink {
            VMDetailView(vm: vm, client: client)
        } label: {
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    // VM Header
                    HStack {
                        Image(systemName: vm.power_state?.uppercased() == "POWERED_ON" ? "power.circle.fill" : "power.circle")
                            .foregroundStyle(vm.power_state?.uppercased() == "POWERED_ON" ? .green : .secondary)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "camera.fill")
                                    .font(.caption)
                                Text("\(snapshots.count) snapshot\(snapshots.count == 1 ? "" : "s")")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    Divider()
                    
                    // Snapshots List
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(snapshots.prefix(3)) { snapshot in
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.caption)
                                    .foregroundStyle(.cyan)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(snapshot.name)
                                        .font(.subheadline)
                                        .lineLimit(1)
                                    
                                    HStack(spacing: 4) {
                                        if let createTime = snapshot.create_time {
                                            Text(formattedDate(createTime))
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            
                                            Text("•")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                            
                                            Text(snapshotAge(createTime))
                                                .font(.caption2)
                                                .foregroundStyle(snapshotAgeColor(createTime))
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                        
                        if snapshots.count > 3 {
                            HStack {
                                Image(systemName: "ellipsis")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 20)
                                
                                Text("and \(snapshots.count - 3) more")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(8)
            } label: {
                Label("VM Information", systemImage: "desktopcomputer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
    
    private func formattedDate(_ dateString: String) -> String {
        if let date = ISO8601Helper.parse(dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
    
    private func snapshotAge(_ dateString: String) -> String {
        guard let snapshotDate = ISO8601Helper.parse(dateString) else { return "unknown age" }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour], from: snapshotDate, to: now)
        
        if let days = components.day {
            if days == 0 {
                if let hours = components.hour {
                    if hours == 0 {
                        return "just now"
                    } else if hours == 1 {
                        return "1 hour ago"
                    } else {
                        return "\(hours) hours ago"
                    }
                }
                return "today"
            } else if days == 1 {
                return "1 day old"
            } else if days < 30 {
                return "\(days) days old"
            } else if days < 365 {
                let months = days / 30
                if months == 1 {
                    return "1 month old"
                } else {
                    return "\(months) months old"
                }
            } else {
                let years = days / 365
                if years == 1 {
                    return "1 year old"
                } else {
                    return "\(years) years old"
                }
            }
        }
        
        return "unknown age"
    }
    
    private func snapshotAgeColor(_ dateString: String) -> Color {
        guard let snapshotDate = ISO8601Helper.parse(dateString) else { return .secondary }
        
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: snapshotDate, to: now)
        
        if let days = components.day {
            switch days {
            case 0...7:
                return .green  // Less than a week old
            case 8...30:
                return .yellow  // 1 week to 1 month
            case 31...90:
                return .orange  // 1-3 months
            default:
                return .red  // Older than 3 months
            }
        }
        
        return .secondary
    }
}

#Preview {
    NavigationStack {
        VMSnapshotsView(viewModel: VCenterViewModel(serverURL: URL(string: "https://example.com")!, username: "u", password: "p"))
    }
}
