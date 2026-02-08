# Health Score Feature for Operations ESXi Hosts

## ✅ Implementation Complete

I've added health score display to the Operations ESXi Hosts screen. The health scores are fetched from the VMware Aria Operations API and displayed with color-coded indicators.

---

## 🎯 What Was Added

### 1. Health Score Model
**Location:** `OperationsClient.swift`

Added to `OperationsHost` struct:
- `healthScore: Double?` - Stores the health score value (0-100)
- `healthStatus` - Computed property that categorizes health
- `HealthStatus` enum with:
  - `excellent` (80-100) - Green checkmark
  - `good` (60-79) - Mint checkmark
  - `warning` (40-59) - Orange warning triangle
  - `critical` (0-39) - Red X
  - `unknown` - Gray question mark

### 2. API Integration
**Location:** `OperationsClient.swift`

New method: `fetchHealthScore(for resourceID: String)`
- Fetches health score for individual host
- API endpoint: `/suite-api/api/resources/{resourceId}/stats/latest?statKey=badge|health`
- Returns health score as `Double` (0-100)

Updated: `fetchESXiHosts()`
- Now fetches health scores for all hosts after initial load
- Handles errors gracefully (shows "Unknown" if health can't be fetched)

### 3. UI Display
**Location:** `OperationsHostsView.swift`

Each host row now shows:
- **Health Badge** (left side):
  - Icon (checkmark/warning/X)
  - Numeric score (e.g., "85")
  - Color-coded based on health status
  
- **Health Status Text**:
  - "Excellent", "Good", "Warning", "Critical", or "Unknown"
  - Heart icon with color
  
---

## 🎨 Visual Layout

### Host Row Display

```
┌─────────────────────────────────────────────────┐
│  ✅    esxi-host-01.local                       │
│  95    ❤️ Excellent • HostSystem               │
│        🧩 VMWARE                                │
├─────────────────────────────────────────────────┤
│  ⚠️    esxi-host-02.local                       │
│  55    ❤️ Warning • HostSystem                  │
│        🧩 VMWARE                                │
├─────────────────────────────────────────────────┤
│  ❌    esxi-host-03.local                       │
│  25    ❤️ Critical • HostSystem                 │
│        🧩 VMWARE                                │
└─────────────────────────────────────────────────┘
```

---

## 📊 Health Status Categories

| Score Range | Status | Icon | Color | Description |
|-------------|--------|------|-------|-------------|
| 80-100 | Excellent | ✅ checkmark.circle.fill | Green | Host is healthy |
| 60-79 | Good | ✓ checkmark.circle | Mint | Host is performing well |
| 40-59 | Warning | ⚠️ exclamationmark.triangle.fill | Orange | Issues detected |
| 0-39 | Critical | ❌ xmark.circle.fill | Red | Serious problems |
| null | Unknown | ❓ questionmark.circle | Gray | Health unavailable |

---

## 🔧 API Details

### Health Score Endpoint

**Request:**
```http
GET /suite-api/api/resources/{resourceId}/stats/latest?statKey=badge|health
Authorization: vRealizeOpsToken {token}
Accept: application/json
```

**Response:**
```json
{
  "values": [
    {
      "stat_key": {
        "key": "badge|health"
      },
      "data": [85.0],
      "timestamps": [1707350400000]
    }
  ]
}
```

**Parsed Health Score:** `85.0` (Excellent)

---

## 💻 Code Changes Summary

### OperationsClient.swift

**New Models:**
```swift
// Added to OperationsHost
var healthScore: Double?
var healthStatus: HealthStatus { ... }

enum HealthStatus {
    case excellent, good, warning, critical, unknown
    var color: String { ... }
    var icon: String { ... }
    var text: String { ... }
}

// New response model
struct OperationsStatsResponse: Codable {
    let values: [StatValue]?
}
```

**New Method:**
```swift
func fetchHealthScore(for resourceID: String) async throws -> Double? {
    // Fetches badge|health stat from Operations API
    // Returns health score 0-100 or nil if unavailable
}
```

**Updated Method:**
```swift
func fetchESXiHosts() async throws -> [OperationsHost] {
    // 1. Fetch all hosts
    // 2. For each host, fetch health score
    // 3. Update host.healthScore
    // 4. Return hosts with health data
}
```

### OperationsHostsView.swift

**Updated UI:**
```swift
// Each row now shows:
HStack {
    // Health Badge (left)
    VStack {
        Image(systemName: host.healthStatus.icon)
        Text("\(Int(score))")  // Numeric score
    }
    
    // Host Info (center)
    VStack {
        Text(host.name)  // Host name
        HStack {
            // Health status with heart icon
            Image(systemName: "heart.fill")
            Text(host.healthStatus.text)
        }
        // Resource type and adapter
    }
}
```

**New Helper:**
```swift
private func colorForHealth(_ colorName: String) -> Color {
    // Converts string color name to SwiftUI Color
}
```

---

## 🧪 Testing

### Expected Behavior

1. **Load Hosts Screen**
   - Shows "Loading ESXi Hosts from Operations..."
   - Progress indicator visible

2. **After Loading**
   - Each host displays with health badge
   - Health score shown numerically (0-100)
   - Icon and color match health status
   - Text shows status ("Excellent", "Good", etc.)

3. **Console Output**
   ```
   🟢 Fetching ESXi hosts from Operations...
   🟢 Decoded 5 ESXi hosts from Operations
   🟢 Fetching health score for resource: abc-123-def
   🟢 Health score for esxi-host-01.local: 85.0
   🟢 Fetching health score for resource: xyz-456-ghi
   🟢 Health score for esxi-host-02.local: 55.0
   ...
   🟢 Loaded 5 ESXi hosts from Operations
   ```

4. **Error Handling**
   - If health score fetch fails, shows "Unknown" with gray color
   - Host still displays, just without health data
   - Console shows: `⚠️ Could not fetch health score for {host}: {error}`

---

## 🚀 How It Works

### Data Flow

```
User Opens Operations Hosts Screen
    ↓
OperationsHostsView.loadHosts()
    ↓
OperationsClient.fetchESXiHosts()
    ↓
1. Fetch all hosts from /suite-api/api/resources
    ↓
2. For each host:
    ↓
   fetchHealthScore(resourceID)
    ↓
   GET /suite-api/api/resources/{id}/stats/latest?statKey=badge|health
    ↓
   Parse health score from response
    ↓
   Update host.healthScore
    ↓
3. Return all hosts with health scores
    ↓
UI Updates with Health Badges and Scores
```

### Performance Considerations

- **Serial Requests**: Health scores fetched one at a time
- **Timeout Handling**: Individual health fetch failures don't block others
- **Graceful Degradation**: Missing health scores show as "Unknown"
- **Caching**: Token cached to avoid re-authentication

**Future Optimization:**
Could make health score requests parallel using `TaskGroup` for faster loading.

---

## 🎨 Design Details

### Color Scheme

**Excellent (Green):**
- Background: Green tint
- Icon: Solid green checkmark
- Text: Green

**Good (Mint):**
- Background: Mint tint
- Icon: Mint checkmark outline
- Text: Mint

**Warning (Orange):**
- Background: Orange tint
- Icon: Orange warning triangle
- Text: Orange

**Critical (Red):**
- Background: Red tint
- Icon: Red X mark
- Text: Red

**Unknown (Gray):**
- Background: Gray tint
- Icon: Gray question mark
- Text: Gray

### Layout

```
┌──────────────────────────────────────┐
│  [ICON]   Host Name                  │
│   [##]    ❤️ Status • Type           │
│           🧩 Adapter                 │
└──────────────────────────────────────┘

Where:
- ICON: Health status icon (✅/⚠️/❌/❓)
- ##: Numeric health score (0-100)
- ❤️: Heart icon for health
- Status: Text description
- Type: Resource type (HostSystem)
- Adapter: Adapter kind (VMWARE)
```

---

## 📋 API Reference

### VMware Aria Operations Health Score

**Stat Key:** `badge|health`
**Description:** Overall health score for a resource
**Range:** 0-100
**Type:** Double

**Related Stats:**
- `badge|risk` - Risk score
- `badge|efficiency` - Efficiency score
- `badge|workload` - Workload score

**Documentation:**
- VMware Aria Operations REST API Guide
- Metrics and Stats API section

---

## 🐛 Troubleshooting

### Health Scores Show "Unknown"

**Possible Causes:**
1. Resource doesn't have health metric
2. API permissions issue
3. Network timeout
4. Resource not monitored

**Check:**
- Console for error messages
- Operations UI to verify health is available
- API token has correct permissions

### Slow Loading

**Cause:** Health scores fetched serially

**Solutions:**
1. Reduce number of hosts
2. Implement parallel fetching
3. Cache health scores locally

### Wrong Colors Displayed

**Check:**
- Health score value is correct
- Health status computed property logic
- Color mapping in `colorForHealth()`

---

## ✅ Summary

### What Was Implemented

1. ✅ **Health Score API Integration**
   - Fetches health scores from Operations
   - Uses `/stats/latest` endpoint
   - Parses `badge|health` metric

2. ✅ **Health Status Categorization**
   - 5 levels: Excellent, Good, Warning, Critical, Unknown
   - Color-coded indicators
   - Icon-based visual feedback

3. ✅ **UI Display**
   - Health badge with icon and score
   - Status text with heart icon
   - Color-coded throughout

4. ✅ **Error Handling**
   - Graceful degradation
   - "Unknown" for missing data
   - Individual host failures don't affect others

### User Experience

- **Clear Visual Indicators**: Immediate health status visibility
- **Numeric Scores**: Precise health values displayed
- **Color Coding**: Quick identification of issues
- **Consistent Design**: Matches Operations UI patterns

### Technical Quality

- ✅ Async/await throughout
- ✅ Proper error handling
- ✅ Type-safe models
- ✅ Reusable health status enum
- ✅ SwiftUI best practices

---

## 🎉 Ready to Test!

Build and run the app:
1. Navigate to Operations ESXi Hosts
2. Watch health scores load
3. See color-coded health indicators
4. Identify critical hosts at a glance

**Health scores now provide actionable insights directly in your home lab app!** 🚀
