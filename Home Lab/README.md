# Home Lab

A native iOS and macOS application for monitoring and managing VMware vCenter infrastructure, built with SwiftUI and SwiftData.

![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS-lightgrey.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-blue.svg)

## Overview

Home Lab provides a clean, intuitive interface for monitoring your VMware vCenter environment. View real-time information about your ESXi hosts and virtual machines with a modern, card-based design optimized for iOS and macOS. Monitor resource usage with color-coded metrics and customize your interface to match your workflow.

## Features

### vCenter Server Management
- 📡 Connect to multiple vCenter servers
- 🔐 Secure credential storage with SwiftData
- 🔄 Automatic session management with REST and SOAP APIs
- ✅ Real-time connection state monitoring
- ⚙️ Easy server editing and management
- 🎯 Set default server for quick access

### Virtual Machine Management
- 💻 **VM Overview**
  - Power state indicators with color-coded icons
  - Quick VM identification
  - Clean list view with vCLS system VM filtering
  - Refreshable list with pull-to-refresh

- 📊 **VM Details** (Scrollable)
  - **VM Information Card**
    - VM name with protected spacing
    - Power state with visual indicators
  
  - **Hardware Details Card**
    - 🔵 **CPU**: Core count with usage percentage and progress bar
    - 🟢 **Memory**: Capacity with usage percentage and progress bar
    - 🟣 **Storage**: Used/Total capacity with usage percentage and progress bar
    - Color-coded metrics (green → yellow → orange → red)
  
  - **Storage Devices**
    - Individual disk capacities
    - Disk labels and identifiers
  
  - **Snapshots**
    - Snapshot names and descriptions
    - Creation timestamps
    - Formatted date display

### ESXi Host Monitoring
- 🖥️ **Host Information**
  - Connection and power state
  - FQDN and IP address
  - Real-time status indicators

- ⚙️ **Hardware Details**
  - CPU core count
  - Memory capacity (with thousands separator formatting)
  - Total storage capacity
  - Used storage metrics
  - All storage values displayed in GB

### Customization & Settings
- 🎨 **Display Options**
  - Toggle Virtual Machines button visibility
  - Toggle Hosts button visibility
  - Customize main screen layout
  - Settings persist across app launches

- 🔧 **User Preferences**
  - Set default vCenter server
  - Manage multiple server connections
  - Clean, production-ready settings interface

## Design Philosophy

The app features a modern, professional UI with:
- **Card-based layouts** using GroupBox for organized information
- **Scrollable content** prevents text overlap on any screen size
- **Icon-driven design** with color-coded sections:
  - 🔵 Blue for CPU metrics
  - 🟢 Green for memory information
  - 🟣 Purple for storage
  - 🟠 Orange for hosts
  - 🔷 Teal for virtual machines
- **Progress bars** with color-coded thresholds:
  - CPU: Green (0-50%) → Yellow (50-75%) → Orange (75-90%) → Red (90%+)
  - Memory: Green (0-60%) → Yellow (60-80%) → Orange (80-90%) → Red (90%+)
  - Storage: Green (0-70%) → Yellow (70-85%) → Orange (85-95%) → Red (95%+)
- **Divided sections** within cards for clear data separation
- **Consistent labeling** with professional formatting
- **Inline navigation** for compact, non-overlapping titles
- **Smart filtering** automatically hides vCLS system VMs
- **Cross-platform support** with iOS and macOS optimized layouts

## Technical Stack

- **Language**: Swift 6.0+
- **UI Framework**: SwiftUI with NavigationSplitView
- **Data Persistence**: SwiftData
- **Settings Storage**: AppStorage with UserDefaults
- **Platforms**: iOS 17.0+ and macOS 14.0+
- **API Integration**: 
  - VMware vCenter REST API for VM and host data
  - VMware vSphere SOAP API for performance metrics and hardware details
- **Concurrency**: Swift Concurrency (async/await)

## Requirements

- iOS 17.0+ or macOS 14.0 (Sonoma) or later
- Xcode 15.0+
- VMware vCenter Server 7.0 or later
- Network access to your vCenter server

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/home-lab.git
   ```

2. Open the project in Xcode:
   ```bash
   cd home-lab
   open Home\ Lab.xcodeproj
   ```

3. Build and run the application:
   - iOS: Select an iOS device or simulator and press ⌘R
   - macOS: Select "My Mac" and press ⌘R

## Usage

### First Time Setup

1. Launch the application
2. Tap/click the settings gear icon ⚙️
3. Tap/click "Add vCenter Server" (+)
4. Enter your vCenter credentials:
   - Server name (e.g., "Production vCenter")
   - Server URL (e.g., `https://vcenter.example.com`)
   - Username (e.g., `administrator@vsphere.local`)
   - Password
   - Optional: Set as default server
5. Save the configuration

### Customizing the Main Screen

1. Open Settings
2. Scroll to "Main Screen Buttons"
3. Toggle buttons on/off:
   - Virtual Machines
   - Hosts
4. Changes apply immediately

### Managing Virtual Machines

1. Tap/click the "Virtual Machines" card
2. View all VMs with power state indicators
3. Pull to refresh on iOS or click refresh on macOS
4. Tap/click any VM to view:
   - VM name and power state
   - CPU usage percentage with progress bar
   - Memory usage percentage with progress bar
   - Storage usage percentage with progress bar
   - Individual disk capacities
   - Snapshots with timestamps

### Monitoring Hosts

1. Tap/click the "Hosts" card
2. View all ESXi hosts
3. Tap/click on any host to view detailed information:
   - Network configuration (IP, FQDN)
   - Hardware specifications (CPU, Memory, Storage)
   - Storage capacity and usage

## API Integration

### REST API
Used for:
- Listing virtual machines
- Retrieving VM hardware configuration
- Fetching VM disk information
- Host enumeration

### SOAP API
Used for:
- **VM Performance Metrics**:
  - CPU usage percentage (from quickStats)
  - Memory usage percentage
  - Storage committed, uncommitted, and total
- **ESXi Host Details**:
  - CPU core count
  - Memory capacity
  - Storage capacity and usage via datastore queries
  - Network configuration (IP, FQDN)
- **Snapshot Information**:
  - Snapshot names and IDs
  - Creation timestamps
  - Snapshot descriptions

## Key Features Explained

### Smart VM Filtering
The app automatically filters out vSphere Cluster Services (vCLS) VMs:
- vCLS VMs are system VMs created by vSphere to maintain cluster services
- They start with the prefix "vCLS-"
- Automatically hidden from the VM list for a cleaner interface
- Matches VMware's vSphere Client behavior

### Real-Time Performance Monitoring
Resource usage is displayed with intelligent color coding:
- **CPU Usage**:
  - Green: 0-50% (optimal)
  - Yellow: 50-75% (moderate)
  - Orange: 75-90% (high)
  - Red: 90%+ (critical)
- **Memory Usage**:
  - Green: 0-60% (optimal)
  - Yellow: 60-80% (moderate)
  - Orange: 80-90% (high)
  - Red: 90%+ (critical)
- **Storage Usage**:
  - Green: 0-70% (optimal)
  - Yellow: 70-85% (moderate)
  - Orange: 85-95% (high)
  - Red: 95%+ (critical)

### Responsive Design
- **iOS**: Card-based tiles with gradient backgrounds
- **macOS**: Sidebar navigation with detailed views
- **Scrollable content**: Prevents text overlap on all screen sizes
- **Inline navigation titles**: Compact headers that don't interfere with content

## Future Enhancements

Potential features for future releases:
- [ ] VM power operations (start, stop, restart)
- [ ] Historical performance charts
- [ ] Advanced snapshot management (create, delete, revert)
- [ ] Resource pool monitoring
- [ ] Cluster overview and statistics
- [ ] Real-time event monitoring
- [ ] Export reports to PDF/CSV
- [ ] Custom alert thresholds
- [ ] iPad-optimized layout
- [ ] Widget support for quick stats
- [ ] Network usage metrics
- [ ] Datastore browser

## Screenshots

### iOS
- Card-based home screen with gradient tiles
- Scrollable VM details with performance metrics
- Clean list views with power state indicators

### macOS
- Sidebar navigation with resource counts
- Detailed view panels
- Native macOS toolbar integration

## Data Privacy & Security

### Local Storage
All data is stored locally on your device:
- vCenter server configurations
- Connection credentials (encrypted by SwiftData)
- User preferences and settings
- No data is transmitted to third parties
- No analytics or tracking

### Network Security
⚠️ **Development Notice**: The current implementation accepts self-signed TLS certificates for development purposes. This is **not recommended for production use**. 

For production deployment:
- Implement proper certificate validation
- Use certificate pinning
- Enable additional security measures
- Consider VPN connectivity for remote access

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines
- Follow Swift naming conventions
- Use SwiftUI best practices
- Maintain async/await patterns for API calls
- Add comments for complex logic
- Test on both iOS and macOS when applicable
- Update README for new features

## Frequently Asked Questions

### Q: Why are some VMs not showing up?
A: The app automatically filters out vCLS (vSphere Cluster Services) VMs, which are system VMs that start with "vCLS-". This matches VMware's vSphere Client behavior.

### Q: Can I hide buttons I don't use?
A: Yes! Go to Settings → Main Screen Buttons and toggle any buttons on or off. Changes apply immediately.

### Q: Why do I see "—" instead of metrics?
A: This can happen if:
- The VM is powered off
- Performance data is not available yet
- The vCenter connection was interrupted
Try refreshing the data or checking the VM's power state.

### Q: Does this work with vSphere 8.0?
A: Yes! The app works with vCenter Server 7.0 and later, including vSphere 8.0.

### Q: Is my vCenter password stored securely?
A: Yes, credentials are stored using SwiftData with encryption. However, for maximum security, consider using a read-only vCenter account.

## Troubleshooting

### Connection Issues
- Verify the vCenter URL is correct (include `https://`)
- Check network connectivity to vCenter
- Ensure credentials are valid
- Check firewall settings allow connections

### Performance Data Not Showing
- Ensure VM is powered on
- Wait a few moments for vCenter to collect stats
- Try refreshing the view
- Check vCenter performance statistics settings

### App Crashes or Errors
- Check Xcode console for error messages
- Verify vCenter API compatibility
- Try reconnecting to vCenter
- Clear app data and reconfigure if needed

## Version History

### Current Version
- ✅ Multi-platform support (iOS & macOS)
- ✅ Real-time performance monitoring
- ✅ Storage usage metrics
- ✅ Customizable interface
- ✅ vCLS VM filtering
- ✅ Snapshot viewing
- ✅ Scrollable layouts

## License

This project is available for personal and educational use.

## Acknowledgments

- Built with SwiftUI and SwiftData
- Integrates with VMware vCenter Server REST and SOAP APIs
- Icons from SF Symbols
- Gradient designs inspired by modern iOS applications
- Community feedback and testing

## Author

Created for home lab and development environment management.

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check the FAQ section above
- Review the troubleshooting guide

---

**Note**: This application is designed for home lab and development environments. Always ensure proper security measures when connecting to production vCenter servers. Consider using read-only accounts and VPN connectivity for enhanced security.

**Made with ❤️ for the home lab community**

