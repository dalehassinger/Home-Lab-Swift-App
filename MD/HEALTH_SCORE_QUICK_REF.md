# Health Score Quick Reference

## 🎯 What You Get

Health scores from VMware Aria Operations displayed on each ESXi host.

---

## 📱 Visual Display

### Excellent Health (80-100)
```
┌────────────────────────────────┐
│  ✅    esxi-host-01.local      │
│  95    ❤️ Excellent            │
│        • HostSystem            │
└────────────────────────────────┘
```
- **Color:** Green
- **Icon:** Checkmark (filled circle)
- **Meaning:** Host is healthy

### Good Health (60-79)
```
┌────────────────────────────────┐
│  ✓     esxi-host-02.local      │
│  72    ❤️ Good                 │
│        • HostSystem            │
└────────────────────────────────┘
```
- **Color:** Mint
- **Icon:** Checkmark (outline circle)
- **Meaning:** Host is performing well

### Warning (40-59)
```
┌────────────────────────────────┐
│  ⚠️    esxi-host-03.local      │
│  55    ❤️ Warning              │
│        • HostSystem            │
└────────────────────────────────┘
```
- **Color:** Orange
- **Icon:** Warning triangle
- **Meaning:** Issues detected

### Critical (0-39)
```
┌────────────────────────────────┐
│  ❌    esxi-host-04.local      │
│  25    ❤️ Critical             │
│        • HostSystem            │
└────────────────────────────────┘
```
- **Color:** Red
- **Icon:** X mark (filled circle)
- **Meaning:** Serious problems

### Unknown
```
┌────────────────────────────────┐
│  ❓    esxi-host-05.local      │
│  --    ❤️ Unknown              │
│        • HostSystem            │
└────────────────────────────────┘
```
- **Color:** Gray
- **Icon:** Question mark
- **Meaning:** Health data unavailable

---

## 🎨 Health Score Scale

```
0────20────40────60────80────100
│ Critical │Warning│Good│Excellent│
   ❌        ⚠️     ✓     ✅
   Red      Orange  Mint  Green
```

---

## 📊 Quick Reference Table

| Score | Status | Icon | Color | Action |
|-------|--------|------|-------|--------|
| 80-100 | ✅ Excellent | checkmark.circle.fill | Green | No action needed |
| 60-79 | ✓ Good | checkmark.circle | Mint | Monitor |
| 40-59 | ⚠️ Warning | exclamationmark.triangle.fill | Orange | Investigate |
| 0-39 | ❌ Critical | xmark.circle.fill | Red | Urgent action |
| null | ❓ Unknown | questionmark.circle | Gray | Check Operations |

---

## 🔍 What Each Element Shows

```
┌────────────────────────────────────────┐
│  [A]   [B]                             │
│  [C]   [D] [E] • [F]                   │
│        [G] [H]                         │
└────────────────────────────────────────┘

A = Health Icon (✅/⚠️/❌/❓)
B = Host Name
C = Numeric Score (0-100)
D = Heart Icon (❤️)
E = Status Text
F = Resource Type
G = Adapter Icon (🧩)
H = Adapter Name
```

---

## 💻 Console Output

When loading hosts, you'll see:
```bash
🟢 Fetching ESXi hosts from Operations...
🟢 Decoded 5 ESXi hosts from Operations
🟢 Fetching health score for resource: abc-123
🟢 Health score for esxi-host-01.local: 95.0
🟢 Fetching health score for resource: def-456
🟢 Health score for esxi-host-02.local: 72.0
🟢 Fetching health score for resource: ghi-789
🟢 Health score for esxi-host-03.local: 55.0
🟢 Loaded 5 ESXi hosts from Operations
```

---

## 🚨 Priority Actions

### Critical Hosts (Red)
**Immediate attention required**
- Check Operations for details
- Review alerts and recommendations
- Address issues ASAP

### Warning Hosts (Orange)
**Monitor and investigate**
- Check for trends
- Review metrics
- Plan maintenance if needed

### Good/Excellent Hosts (Mint/Green)
**Healthy - no action needed**
- Continue monitoring
- Use as baseline

---

## 🧪 Testing Checklist

1. [ ] Open Operations ESXi Hosts screen
2. [ ] See loading indicator
3. [ ] Hosts load with health scores
4. [ ] Each host shows:
   - [ ] Health icon (left side)
   - [ ] Numeric score
   - [ ] Status text with heart icon
   - [ ] Correct color coding
5. [ ] Pull to refresh works
6. [ ] Console shows health score logs

---

## 🔧 API Endpoint Used

```
GET /suite-api/api/resources/{resourceId}/stats/latest
    ?statKey=badge|health

Headers:
  Authorization: vRealizeOpsToken {token}
  Accept: application/json

Response:
{
  "values": [{
    "stat_key": { "key": "badge|health" },
    "data": [85.0]
  }]
}
```

---

## 📝 Code Files Changed

1. **OperationsClient.swift**
   - Added `healthScore` property to `OperationsHost`
   - Added `HealthStatus` enum
   - Added `fetchHealthScore()` method
   - Updated `fetchESXiHosts()` to fetch health scores

2. **OperationsHostsView.swift**
   - Updated UI to display health badges
   - Added health status indicators
   - Added color helper function

---

## 🎉 Summary

**Before:**
- Hosts listed by name only
- No health visibility

**After:**
- Health scores displayed prominently
- Color-coded status indicators
- Numeric scores for precision
- Icons for quick identification
- At-a-glance health assessment

**Result:** Instant visibility into host health! 🚀
