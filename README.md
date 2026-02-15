# Home Lab

A SwiftUI-based management application for VMware vCenter and VMware Aria Operations, designed for home lab environments. Monitor and manage your virtual infrastructure from both iOS and macOS.

## Features

### vCenter Integration
- **Virtual Machine Management**: View and monitor all VMs in your vCenter environment
  - VM power state tracking
  - CPU and memory allocation details
  - Disk configuration and capacity information
  - VM snapshot detection and management
  
- **ESXi Host Monitoring**: Track the health and status of your ESXi hosts
  - Connection state and power state
  - CPU core count and model information
  - Memory capacity monitoring
  - Storage capacity and usage tracking
  - Host IP address and FQDN information

- **Snapshot Management**: Dedicated view for VMs with snapshots
  - Quick identification of VMs with active snapshots
  - Snapshot details including creation time and state
  - Helps maintain snapshot hygiene in your environment

### VMware Aria Operations Integration
- **Operations Host Monitoring**: View ESXi hosts through VMware Aria Operations
  - Health score tracking (0-100 scale)
  - Visual health indicators (Excellent, Good, Warning, Critical)
  - Detailed host properties:
    - ESXi version and build number
    - CPU model and core count
    - Memory capacity
    - Management IP address
    - Parent cluster and datacenter
    - Connection and power states
    - Hardware vendor and model information
    - BIOS version
    - Maintenance mode status
    - HyperThreading status

### Electricity Usage Monitoring
- **Shelly Smart Switch Integration**: Monitor electricity usage from Shelly devices
  - Current power consumption in Watts
  - Total energy usage in kWh
  - Voltage monitoring (where available)
  - Device uptime tracking
  - Support for Shelly EM and Shelly Plug devices
  - Real-time data refresh
  - Multiple device monitoring
  - Enable/disable individual devices

### Multi-Server Management
- **vCenter Servers**: Support for multiple vCenter servers
  - Add, edit, and delete server configurations
  - Set a default server for automatic connection
  - Secure credential storage
  
- **Operations Servers**: Support for multiple VMware Aria Operations servers
  - Independent management from vCenter servers
  - Dedicated authentication per server
  - Default server selection

- **Shelly Devices**: Support for multiple Shelly smart switches
  - Add, edit, and delete device configurations
  - Enable/disable monitoring per device
  - Local network communication (HTTP)

### User Interface
- **Liquid Glass Design**: Modern Apple design language with dynamic materials
  - Interactive glass effects with real-time blur and transparency
  - Touch-responsive materials that react to user interaction
  - Dynamic light and color reflection from surrounding content
  - Smooth morphing transitions between UI states
  - Glass effect containers and buttons throughout the interface
  
- **Dual Platform Support**: Native SwiftUI UI for both iOS and macOS
  - iOS: Card-based tile interface with Liquid Glass styling
  - macOS: Traditional sidebar navigation with split view
  
- **Dark Mode Design**: Elegant dark theme with gradient backgrounds
  - Custom color schemes for different resource types
  - Visual health indicators with color coding

- **Connection Status Monitoring**: Real-time connection status indicators
  - Visual status icons (connected, connecting, disconnected, failed)
  - Color-coded status display (green, orange, gray, red)
  - Manual reconnection capability
  - Separate status tracking for vCenter and Operations connections

- **Customizable Interface**: Control which sections appear on the main screen
  - Toggle visibility of Virtual Machines button
  - Toggle visibility of Hosts button
  - Toggle visibility of VMs with Snapshots button
  - Toggle visibility of Operations Hosts button
  - Toggle visibility of Electricity Usage button

### Data Persistence
- **SwiftData Integration**: Modern data persistence using SwiftData
  - Server configurations stored locally
  - Persistent settings across app launches
  - Support for model versioning and migration

## Technical Details

### Architecture
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Apple's data persistence framework for model management
- **Swift Concurrency**: Async/await patterns for API calls
- **REST API Integration**: Direct communication with vCenter and Operations APIs
- **Multi-platform**: Shared codebase for iOS and macOS with platform-specific optimizations

### API Support
- **vCenter REST API**: Comprehensive integration with vCenter Server REST API
  - VM management and monitoring
  - Host information retrieval
  - Snapshot enumeration
  - Metrics and statistics collection
  
- **VMware Aria Operations REST API**: Integration with Operations Manager
  - Resource discovery and monitoring
  - Health score retrieval
  - Property and metric collection
  - Advanced filtering and querying

- **Shelly Device HTTP API**: Local network integration with Shelly smart switches
  - Real-time energy monitoring
  - Power consumption tracking
  - Status and health checking
  - Support for multiple device types (EM, Plug, Switch)

### Security Considerations
⚠️ **Important**: This is a development/home lab tool that accepts any TLS certificate. Do NOT use in production environments without implementing proper certificate validation.

## Requirements

- **iOS**: iOS 17.0 or later
- **macOS**: macOS 14.0 or later
- **vCenter Server**: vCenter 7.0 or later (REST API enabled)
- **VMware Aria Operations**: Operations 8.0 or later (REST API enabled)

## Setup

1. Launch the Home Lab app
2. Tap the gear icon to access Settings
3. Add your vCenter server:
   - Enter server name (e.g., "Production vCenter")
   - Enter server URL (e.g., "https://vcenter.example.com")
   - Enter username and password
   - Optionally set as default server
4. Add your VMware Aria Operations server (optional):
   - Enter server name
   - Enter server URL (e.g., "https://192.168.6.199")
   - Enter username and password
   - Optionally set as default server
5. Add your Shelly devices (optional):
   - Enter device name (e.g., "Lab Power Monitor")
   - Enter IP address (e.g., "192.168.1.100")
   - Enable monitoring
6. Return to the main screen to view your infrastructure

## Usage

### Viewing Resources
- Tap any tile/button on the main screen to view detailed information
- Swipe to refresh data in list views
- Use the reconnect button in the status section to manually refresh connections

### Managing Servers
- Access Settings from the gear icon
- Swipe left on servers (iOS) or click the trash icon (macOS) to delete
- Long press (iOS) or right-click (macOS) for additional options
- Edit server details by tapping the server entry

### Customizing the Interface
- In Settings, use the "Main Screen Buttons" section to show/hide features
- Changes take effect immediately on the main screen
- Settings persist across app launches

## Project Structure

```
Home Lab/
├── Home_LabApp.swift          # App entry point with SwiftData configuration
├── ContentView.swift           # Main view with navigation and tiles
├── SettingsView.swift          # Server management and preferences
├── VCenterClient.swift         # vCenter REST API client
├── OperationsClient.swift      # Operations REST API client
├── ShellyClient.swift          # Shelly device HTTP API client
├── Models/                     # Data models
│   ├── VCenterServer.swift
│   ├── OperationsServer.swift
│   ├── ShellyDevice.swift
│   └── Item.swift
└── Views/                      # Feature-specific views
    ├── VMListView.swift
    ├── HostListView.swift
    ├── VMSnapshotsView.swift
    ├── OperationsHostsView.swift
    ├── OperationsHostDetailView.swift
    └── ElectricityUsageView.swift
```

## Recent Changes

### February 2026
- **Liquid Glass Design**: Complete UI overhaul with Apple's modern Liquid Glass design language
  - Interactive glass effects with blur and transparency
  - Dynamic light and color reflection from surrounding content
  - Touch-responsive glass materials throughout the interface
  - Glass effect containers for grouped content
  - Glass button styles with interactive feedback
  - Smooth transitions and morphing between UI states
  - Enhanced visual depth with layered glass surfaces
- **Electricity usage monitoring**: Added support for Shelly smart switches
- **Energy tracking**: Monitor power consumption and total energy usage
- **Multi-device support**: Manage multiple Shelly devices simultaneously
- **Multi-server support**: Added ability to manage multiple vCenter and Operations servers
- **Default server selection**: Set preferred servers for automatic connection
- **VMware Aria Operations integration**: Full support for Operations Manager API
- **Operations host monitoring**: View ESXi hosts with health scores and detailed properties
- **Enhanced UI customization**: Toggle visibility of main screen buttons
- **Improved connection status**: Real-time status monitoring with manual reconnection
- **Platform-specific UI**: Optimized interfaces for both iOS and macOS
- **SwiftData migration**: Modern data persistence with SwiftData framework
- **Dark mode refinement**: Enhanced gradient backgrounds and color schemes
- **Snapshot view**: Dedicated section for VMs with snapshots
- **Health indicators**: Visual health status with color-coded badges
- **Extended host details**: CPU, memory, storage, and hardware information

## Known Limitations

- TLS certificate validation is disabled (suitable for home lab only)
- Read-only operations (no VM power management or configuration changes)
- Credentials stored locally (use strong device security)
- Requires network access to vCenter and Operations servers

## Future Enhancements

- VM power operations (start, stop, restart)
- Advanced filtering and search capabilities
- Historical metrics and charts
- Push notifications for critical alerts
- Widget support for quick status views
- Apple Watch companion app
- Export capabilities for reports

## License

Created by Dale Hassinger, 2026

---

**For Home Lab Use Only** - Not intended for production environments
