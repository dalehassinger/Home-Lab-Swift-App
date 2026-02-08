# VMware Aria Operations Integration

## Overview
This integration adds support for VMware Aria Operations to your Home Lab app, allowing you to view ESXi hosts from your Operations server alongside your vCenter data.

## New Files Created

### 1. OperationsClient.swift
Implements the REST API client for VMware Aria Operations:
- **Token Acquisition**: `acquireToken()` - Authenticates and gets auth token
- **Fetch Hosts**: `fetchESXiHosts()` - Retrieves ESXi hosts from Operations
- **Security**: Accepts self-signed certificates (development only)

**API Endpoints Used:**
- POST `/suite-api/api/auth/token/acquire` - Get authentication token
- GET `/suite-api/api/resources?resourceKind=HostSystem` - Get ESXi hosts

### 2. OperationsServer.swift
SwiftData model for storing Operations server credentials:
- Server name, URL, username, password
- Default server flag
- Persistent storage in SwiftData

### 3. OperationsHostsView.swift
SwiftUI view displaying ESXi hosts from Operations:
- List of hosts with names and metadata
- Loading states and error handling
- Pull-to-refresh support
- Compatible with iOS and macOS

## Modified Files

### Home_LabApp.swift
- Added `OperationsServer.self` to SwiftData schema
- Now persists both vCenter and Operations server configurations

### ContentView.swift
**Added:**
- Query for Operations servers
- `@AppStorage` for Operations button visibility
- New "Operations ESXi Hosts" button on main screen (iOS card tile, macOS sidebar)
- Computed property for default Operations server
- Green/mint gradient card for Operations button

**iOS Section:**
- New CardTile with chart.bar.fill icon

**macOS Section:**
- New sidebar item under "VMware Aria Operations" section

### SettingsView.swift
**Added:**
- Query for Operations servers
- State variables for add/edit Operations servers
- Toggle for Operations button visibility
- New section "VMware Aria Operations Servers"
- Management UI (add, edit, delete Operations servers)
- `AddOperationsServerView` - Form to add new Operations server
- `EditOperationsServerView` - Form to edit existing Operations server

## How It Works

### Authentication Flow
1. User adds Operations server in Settings (URL, username, password)
2. App calls `acquireToken()` which POSTs credentials to `/suite-api/api/auth/token/acquire`
3. Server responds with auth token
4. Token is stored in memory and used for subsequent requests
5. All API calls include `Authorization: vRealizeOpsToken {token}` header

### Data Flow
1. User taps "Operations ESXi Hosts" button
2. App navigates to `OperationsHostsView`
3. View creates `OperationsClient` with server credentials
4. Client fetches hosts via REST API
5. Hosts are displayed in a list with metadata

## PowerShell to Swift Conversion

**PowerShell:**
```powershell
$authBody = @{ username = $username; password = $password } | ConvertTo-Json
$tokenResponse = Invoke-RestMethod -Uri "https://$server/suite-api/api/auth/token/acquire" ...
$token = $tokenResponse.token
```

**Swift:**
```swift
let authBody: [String: String] = ["username": username, "password": password]
request.httpBody = try JSONEncoder().encode(authBody)
let tokenResponse = try JSONDecoder().decode(OperationsTokenResponse.self, from: data)
authToken = tokenResponse.token
```

## Settings Configuration

Users can now configure:
1. **vCenter Servers** - Existing functionality
2. **Operations Servers** - New section with:
   - Server name
   - Server URL (e.g., https://192.168.6.199)
   - Username (e.g., admin)
   - Password
   - Default server toggle
3. **Main Screen Buttons** - Toggle visibility including new Operations button

## Features

### Operations Server Management
- ✅ Add multiple Operations servers
- ✅ Edit server details
- ✅ Delete servers (swipe or context menu)
- ✅ Set default server
- ✅ Persistent storage with SwiftData

### ESXi Host Display
- ✅ List all hosts from Operations
- ✅ Show host names
- ✅ Display resource kind and adapter kind
- ✅ Refresh capability
- ✅ Error handling with retry
- ✅ Loading states

### Platform Support
- ✅ iOS (card-based UI)
- ✅ macOS (sidebar navigation)
- ✅ Dark mode optimized
- ✅ Native SwiftUI throughout

## Security Notes

⚠️ **For Development Only:**
- The code accepts self-signed TLS certificates via `URLSessionDelegate`
- In production, implement proper certificate validation
- Consider using Keychain for password storage

## Future Enhancements

Possible additions:
- Host detail view with metrics
- Performance data from Operations
- Alerts and recommendations
- Dashboard widgets
- Badge counts on Operations button

## Testing

To test the integration:
1. Open Settings
2. Scroll to "VMware Aria Operations Servers"
3. Tap "Add Operations Server"
4. Enter your server details (URL: https://192.168.6.199, username: admin, password)
5. Save and close Settings
6. Tap "Operations ESXi Hosts" on main screen
7. View your hosts!

## API Reference

**VMware Aria Operations REST API:**
- Base URL: `https://{server}/suite-api/api/`
- Auth: Token-based (vRealizeOpsToken)
- Response Format: JSON
- Resource Types: HostSystem, VirtualMachine, Datastore, etc.
