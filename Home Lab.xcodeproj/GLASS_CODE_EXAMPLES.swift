// GLASS_CODE_EXAMPLES.swift
// Code snippets for modernizing remaining views with Liquid Glass
// iOS 26.3 Ready - Copy and adapt these patterns

import SwiftUI

// MARK: - Example 1: List Item with Glass Effect

struct GlassListItem: View {
    let title: String
    let subtitle: String
    let icon: String
    let tintColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tintColor)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(16)
        .glassEffect(.regular.tint(tintColor.opacity(0.3)).interactive(), in: .rect(cornerRadius: 16))
    }
}

// MARK: - Example 2: Detail Card with Glass

struct GlassDetailCard: View {
    let title: String
    let content: [KeyValuePair]
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Label(title, systemImage: "info.circle")
                .font(.headline)
                .foregroundStyle(accentColor)
            
            // Content grid
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                ForEach(content) { item in
                    GridRow {
                        Text(item.key)
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(item.value)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
        }
        .padding(20)
        .glassEffect(.regular.tint(accentColor.opacity(0.15)), in: .rect(cornerRadius: 16))
    }
}

struct KeyValuePair: Identifiable {
    let id = UUID()
    let key: String
    let value: String
}

// MARK: - Example 3: Status Badge with Glass

struct GlassStatusBadge: View {
    let text: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
            
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassEffect(.regular.tint(color), in: .capsule)
    }
}

// MARK: - Example 4: VM Card with Glass (for VMListView)

struct GlassVMCard: View {
    let vmName: String
    let powerState: String
    let cpuCount: Int
    let memoryGB: Int
    
    var powerColor: Color {
        powerState == "POWERED_ON" ? .green : .gray
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "rectangle.stack.fill")
                    .font(.title3)
                    .foregroundStyle(.teal)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(vmName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(powerColor)
                            .frame(width: 8, height: 8)
                        
                        Text(powerState)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                
                Spacer()
            }
            
            // Specs
            HStack(spacing: 16) {
                Label("\(cpuCount) CPU", systemImage: "cpu")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                
                Label("\(memoryGB) GB", systemImage: "memorychip")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(16)
        .glassEffect(.regular.tint(.teal.opacity(0.2)).interactive(), in: .rect(cornerRadius: 16))
    }
}

// MARK: - Example 5: Host Card with Glass (for HostListView)

struct GlassHostCard: View {
    let hostName: String
    let connectionState: String
    let cpuCores: Int
    let memoryGB: Int
    
    var connectionColor: Color {
        connectionState == "CONNECTED" ? .green : .red
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "server.rack")
                    .font(.title3)
                    .foregroundStyle(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(hostName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 8) {
                        Image(systemName: connectionState == "CONNECTED" ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(connectionColor)
                        
                        Text(connectionState)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                
                Spacer()
            }
            
            // Hardware specs
            HStack(spacing: 16) {
                Label("\(cpuCores) Cores", systemImage: "cpu")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                
                Label("\(memoryGB) GB", systemImage: "memorychip")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(16)
        .glassEffect(.regular.tint(.orange.opacity(0.2)).interactive(), in: .rect(cornerRadius: 16))
    }
}

// MARK: - Example 6: Operations Host Card with Health (for OperationsHostsView)

struct GlassOperationsHostCard: View {
    let hostName: String
    let healthScore: Double
    let cluster: String?
    
    var healthColor: Color {
        switch healthScore {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
    
    var healthStatus: String {
        switch healthScore {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Warning"
        default: return "Critical"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with health
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(hostName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    if let cluster = cluster {
                        Text(cluster)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Health score badge
                VStack(spacing: 4) {
                    Text("\(Int(healthScore))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(healthColor)
                    
                    Text(healthStatus)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassEffect(.regular.tint(healthColor.opacity(0.3)), in: .rect(cornerRadius: 8))
            }
        }
        .padding(16)
        .glassEffect(.regular.tint(.green.opacity(0.15)).interactive(), in: .rect(cornerRadius: 16))
    }
}

// MARK: - Example 7: Snapshot Card with Glass (for VMSnapshotsView)

struct GlassSnapshotCard: View {
    let vmName: String
    let snapshotCount: Int
    let latestSnapshot: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "camera.on.rectangle.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(vmName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text("\(snapshotCount) snapshot\(snapshotCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Warning badge
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                    .font(.title3)
            }
            
            // Latest snapshot time
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                
                Text("Latest: \(latestSnapshot, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(16)
        .glassEffect(.regular.tint(.red.opacity(0.2)).interactive(), in: .rect(cornerRadius: 16))
    }
}

// MARK: - Example 8: Electricity Usage Card with Glass (for ElectricityUsageView)

struct GlassElectricityCard: View {
    let deviceName: String
    let currentWatts: Double
    let totalKWh: Double
    let voltage: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(deviceName)
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text("Smart Monitor")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            // Current power usage - prominent
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(currentWatts)) W")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Current Power")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular.tint(.yellow.opacity(0.3)), in: .rect(cornerRadius: 12))
            
            // Additional metrics
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.2f kWh", totalKWh))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                    Text("Total Energy")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if let voltage = voltage {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(voltage)) V")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        
                        Text("Voltage")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(20)
        .glassEffect(.regular.tint(.yellow.opacity(0.15)).interactive(), in: .rect(cornerRadius: 20))
    }
}

// MARK: - Example 9: Settings Server Card with Glass (for SettingsView)

struct GlassServerCard: View {
    let serverName: String
    let serverURL: String
    let username: String
    let isDefault: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(serverName)
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        if isDefault {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .glassEffect(.regular.tint(.green), in: .capsule)
                        }
                    }
                    
                    Text(serverURL)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Text("User: \(username)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
    }
}

// MARK: - Example 10: Metric Graph Card with Glass

struct GlassMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let percentage: Double? // 0-100 for progress bar
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.9))
                
                Spacer()
            }
            
            // Value
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            // Optional progress bar
            if let percentage = percentage {
                ProgressView(value: percentage, total: 100)
                    .tint(color)
            }
        }
        .padding(16)
        .glassEffect(.regular.tint(color.opacity(0.15)), in: .rect(cornerRadius: 16))
    }
}

// MARK: - Example 11: Grouped Glass Cards with Container

struct GlassCardGroup: View {
    var body: some View {
        GlassEffectContainer(spacing: 20.0) {
            VStack(spacing: 12) {
                GlassMetricCard(
                    title: "CPU Usage",
                    value: "42%",
                    subtitle: "8 cores active",
                    icon: "cpu",
                    color: .blue,
                    percentage: 42
                )
                
                GlassMetricCard(
                    title: "Memory Usage",
                    value: "24.5 GB",
                    subtitle: "of 32 GB",
                    icon: "memorychip",
                    color: .purple,
                    percentage: 76.5
                )
                
                GlassMetricCard(
                    title: "Storage",
                    value: "1.2 TB",
                    subtitle: "of 2 TB used",
                    icon: "internaldrive",
                    color: .orange,
                    percentage: 60
                )
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Example 12: Empty State with Glass

struct GlassEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: action) {
                Label(actionTitle, systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.glassProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
        .padding(20)
    }
}

// MARK: - Example 13: Loading State with Glass

struct GlassLoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text(message)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
        .padding(20)
    }
}

// MARK: - Example 14: Error State with Glass

struct GlassErrorView: View {
    let errorMessage: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
            
            VStack(spacing: 8) {
                Text("Error Occurred")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: retryAction) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline)
            }
            .buttonStyle(.glassProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
        .glassEffect(.regular.tint(.orange.opacity(0.15)), in: .rect(cornerRadius: 24))
        .padding(20)
    }
}

// MARK: - Usage Examples in Views

/*
 
 // In VMListView.swift:
 ScrollView {
     LazyVStack(spacing: 12) {
         ForEach(vms) { vm in
             GlassVMCard(
                 vmName: vm.name,
                 powerState: vm.powerState,
                 cpuCount: vm.cpuCount,
                 memoryGB: vm.memoryMB / 1024
             )
         }
     }
     .padding()
 }
 .background(Color.black)
 
 // In HostListView.swift:
 ScrollView {
     LazyVStack(spacing: 12) {
         ForEach(hosts) { host in
             GlassHostCard(
                 hostName: host.name,
                 connectionState: host.connectionState,
                 cpuCores: host.cpuCores,
                 memoryGB: host.memoryGB
             )
         }
     }
     .padding()
 }
 .background(Color.black)
 
 // In OperationsHostsView.swift:
 GlassEffectContainer(spacing: 20.0) {
     ScrollView {
         LazyVStack(spacing: 12) {
             ForEach(hosts) { host in
                 GlassOperationsHostCard(
                     hostName: host.name,
                     healthScore: host.healthScore,
                     cluster: host.cluster
                 )
             }
         }
         .padding()
     }
 }
 .background(Color.black)
 
 // In SettingsView.swift:
 ScrollView {
     VStack(spacing: 16) {
         ForEach(servers) { server in
             GlassServerCard(
                 serverName: server.name,
                 serverURL: server.url,
                 username: server.username,
                 isDefault: server.isDefault,
                 action: { editServer(server) }
             )
         }
     }
     .padding()
 }
 .background(Color.black)
 
 */

// MARK: - Tips & Best Practices

/*
 
 1. **Always wrap multiple glass cards in GlassEffectContainer**
    - Improves performance
    - Enables fluid merging effects
    - Set spacing to 16-24 points for optimal effect
 
 2. **Use appropriate corner radii**
    - Small elements (badges, tags): 8-12pt
    - Medium cards: 16pt
    - Large cards/containers: 20-24pt
 
 3. **Apply tints thoughtfully**
    - Use semantic colors (red for errors, green for health, etc.)
    - Keep opacity around 0.1-0.3 for subtle effects
    - Match tint to icon color for consistency
 
 4. **Make interactive elements .interactive()**
    - Buttons, cards, tiles should respond to touch
    - Provides excellent tactile feedback
    - Enhances perceived quality
 
 5. **Use proper text opacity**
    - Primary text: 100% white
    - Secondary text: 80-90% white
    - Tertiary/hints: 60-70% white
 
 6. **Consistent spacing**
    - Between cards: 12-16pt
    - Inside cards: 12-20pt
    - Section spacing: 20-24pt
 
 7. **Test on device**
    - Glass effects look different on real hardware
    - Check performance on older devices
    - Verify blur and reflection effects work well
 
 8. **Dark background is key**
    - Pure black (.black) or very dark colors
    - Lets glass effects show through properly
    - Creates depth and contrast
 
 */
