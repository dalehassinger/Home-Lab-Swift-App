# Debugging Health Score "Unknown" Issue

## 🔍 Troubleshooting Steps

### Step 1: Check Console Logs

When you load the Operations Hosts screen, look for these log messages:

#### Expected Success Flow:
```
🟢 Fetching ESXi hosts from Operations...
🟢 Decoded 5 ESXi hosts from Operations
🟢 Fetching health score for resource: abc-123-def-456
🟢 Health score URL: https://192.168.6.199/suite-api/api/resources/abc-123-def-456/stats/latest?statKey=badge|health
🟢 Health score response (200): {"values":[...]}
🟢 Found health score: 85.0
🟢 Health score for esxi-host-01.local: 85.0
```

#### What to Look For:

**1. Missing Resource Identifier:**
```
⚠️ No identifier for host: esxi-host-01.local
```
**Problem:** Host object doesn't have an `identifier` field
**Solution:** The API response might not include identifiers

**2. HTTP Error:**
```
⚠️ Health score fetch failed (404): {"message":"Resource not found"}
```
**Problem:** Resource ID is invalid or health metric not available
**Solution:** Check resource exists in Operations

**3. Empty Response:**
```
🟢 Health score response (200): {"values":[]}
⚠️ No health data in response
```
**Problem:** Health metric exists but has no data
**Solution:** Health might not be calculated yet

**4. Wrong Stat Key:**
```
🟢 Health score response (200): {"values":[{"stat_key":{"key":"some|other|stat"}...}]}
⚠️ No health data in response
```
**Problem:** Response has data but not the `badge|health` stat
**Solution:** Operations might use different stat key

---

## 🔧 Enhanced Debugging Added

I've updated the code with:

### 1. Detailed Console Logging
- Prints the URL being called
- Prints the HTTP status code
- Prints the raw JSON response
- Indicates which method is being tried

### 2. Alternative Health Fetch Method
If `badge|health` doesn't work, the code now tries:
- `/suite-api/api/resources/{id}/properties` endpoint
- Looks for any property containing "health" in the name

### 3. Better Error Messages
Each failure point now explains what went wrong

---

## 📋 What to Check Now

### 1. Run the App and Check Console

```bash
# In Xcode, open the Console (Cmd+Shift+Y)
# Navigate to Operations Hosts screen
# Look for these patterns:
```

**Pattern A: No Identifier**
```
🟢 Decoded 5 ESXi hosts from Operations
⚠️ No identifier for host: esxi-host-01.local
⚠️ No identifier for host: esxi-host-02.local
```
→ **Issue:** Hosts don't have `identifier` field in API response

**Pattern B: Health API Fails**
```
🟢 Fetching health score for resource: abc-123
🟢 Health score URL: https://...
🟢 Health score response (404): {"message":"..."}
⚠️ Health score fetch failed (404): ...
```
→ **Issue:** Health stat not available for this resource

**Pattern C: Wrong Stat Key**
```
🟢 Health score response (200): {"values":[...]}
⚠️ No health data in response
🟢 Trying alternative health fetch for resource: abc-123
```
→ **Issue:** Stat key might be different

---

## 🛠️ Manual API Testing

### Test 1: Check Resources API Response

Open a terminal and run:

```bash
# Replace with your Operations server details
SERVER="https://192.168.6.199"
TOKEN="<your-token-here>"

curl -k -X GET "$SERVER/suite-api/api/resources?resourceKind=HostSystem" \
  -H "Authorization: vRealizeOpsToken $TOKEN" \
  -H "Accept: application/json" | jq .
```

**Look for:**
1. Does each resource have an `identifier` field?
2. Copy one of the identifiers for the next test

**Example Response:**
```json
{
  "resourceList": [
    {
      "identifier": "abc-123-def-456",  ← This is what we need
      "resourceKey": {
        "name": "esxi-host-01.local"
      }
    }
  ]
}
```

### Test 2: Check Health Stat API

Using an identifier from Test 1:

```bash
RESOURCE_ID="abc-123-def-456"  # Replace with actual ID

curl -k -X GET "$SERVER/suite-api/api/resources/$RESOURCE_ID/stats/latest?statKey=badge|health" \
  -H "Authorization: vRealizeOpsToken $TOKEN" \
  -H "Accept: application/json" | jq .
```

**Expected Response:**
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

**If Empty:**
```json
{
  "values": []
}
```
→ Health stat not available

**If Different Stat:**
```json
{
  "values": [
    {
      "stat_key": {
        "key": "summary|health"  ← Different key name
      }
    }
  ]
}
```
→ Need to use different stat key

### Test 3: List Available Stats

```bash
curl -k -X GET "$SERVER/suite-api/api/resources/$RESOURCE_ID/stats" \
  -H "Authorization: vRealizeOpsToken $TOKEN" \
  -H "Accept: application/json" | jq '.stat_key | .[] | select(.key | contains("health"))'
```

This shows all health-related stats available for the resource.

---

## 🔍 Common Issues & Solutions

### Issue 1: No `identifier` Field

**Problem:** The resource doesn't have an `identifier` field

**Check:** Look at the console output when hosts load:
```
🟢 Operations Response from https://...:
{"resourceList":[{"resourceKey":{"name":"host1"},"identifier":"..."}]}
```

If no `identifier` shown, the API response is missing it.

**Solution:** Update the code to use `resourceKey.name` as ID or fetch resources differently.

**Quick Fix:**
```swift
// In OperationsClient.swift, change:
if let identifier = hosts[index].identifier {
    
// To use resourceKey instead:
let resourceId = hosts[index].resourceKey.name
```

### Issue 2: Wrong Operations API Version

**Problem:** Your Operations might use a different API version

**Solution:** Check your Operations version:
- VMware Aria Operations 8.x uses `/suite-api/api/`
- Older vRealize Operations might use different paths

**Alternative Endpoint:**
Try changing the stat key from `badge|health` to:
- `summary|health`
- `health`
- `Badge|Health` (case sensitive)

### Issue 3: Health Not Calculated Yet

**Problem:** Operations hasn't calculated health for hosts yet

**Check in Operations UI:**
1. Log into Operations web interface
2. Navigate to Environment → Inventory
3. Find a host
4. Check if Health score is shown

If not shown in UI, it won't be available via API.

**Solution:** Wait for Operations to collect data (usually 5-10 minutes).

### Issue 4: Permissions Issue

**Problem:** API token doesn't have permission to read stats

**Check:** Look for 403 or 401 errors in console

**Solution:** 
1. Check user permissions in Operations
2. Ensure user has "View" permissions on resources
3. Try with admin account to verify

---

## 🚀 Quick Test Commands

### Get Token (replace with your creds):
```bash
SERVER="https://192.168.6.199"
curl -k -X POST "$SERVER/suite-api/api/auth/token/acquire" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"your-password"}' | jq -r .token
```

### Get First Host ID:
```bash
curl -k -X GET "$SERVER/suite-api/api/resources?resourceKind=HostSystem" \
  -H "Authorization: vRealizeOpsToken $TOKEN" \
  -H "Accept: application/json" | jq -r '.resourceList[0].identifier'
```

### Get Health Score:
```bash
HOST_ID="<id-from-above>"
curl -k -X GET "$SERVER/suite-api/api/resources/$HOST_ID/stats/latest?statKey=badge|health" \
  -H "Authorization: vRealizeOpsToken $TOKEN" \
  -H "Accept: application/json" | jq .
```

---

## 📝 Next Steps

1. **Check Console Logs** - Run the app and see what's printed
2. **Share Console Output** - Copy the relevant log lines
3. **Test API Manually** - Try the curl commands above
4. **Verify in Operations UI** - Check if health is shown in web interface

Once you identify which issue it is, we can fix the code accordingly!

---

## 🆘 If You Need Help

Share these items:
1. Console log output (especially lines with 🟢 and ⚠️)
2. Operations version (e.g., VMware Aria Operations 8.14)
3. Result of Test 1 (resources list)
4. Result of Test 2 (health stat)
5. Screenshot of host in Operations UI showing health

This will help us pinpoint exactly what's wrong and fix it!
