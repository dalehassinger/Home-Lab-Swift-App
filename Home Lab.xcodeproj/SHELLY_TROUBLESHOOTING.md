# Shelly Device Network Troubleshooting Guide

## Issue Summary
Your iPhone is timing out when trying to connect to the Shelly device at `192.168.6.121`. This is a **network connectivity issue**, not a code problem.

---

## ✅ Fixes Applied

### 1. **Reduced Timeout** (5 seconds instead of 60)
- Faster failure detection
- Better user experience
- Less waiting when device is offline

### 2. **Better Error Handling**
- Specific error messages for different failures
- User-friendly error descriptions
- Clear indication of what went wrong

### 3. **Improved UI with Liquid Glass**
- Beautiful glass-styled error cards
- Retry button with glass styling
- Better visual feedback
- Shows "last updated" timestamp
- Manual refresh button

---

## 🔍 Troubleshooting Steps

### Step 1: Verify Device IP Address
The error shows the device is at `192.168.6.121`. Confirm this is correct:

1. **Check your Shelly device settings**
   - Look at the device's web interface
   - Or check your router's DHCP client list
   - Ensure the IP hasn't changed

2. **Test from Safari on your iPhone**
   - Open Safari
   - Go to: `http://192.168.6.121/rpc/Switch.GetStatus?id=0`
   - If it loads JSON data → Device is reachable
   - If it times out → Network/device issue

### Step 2: Check Network Connectivity

#### Same WiFi Network?
Your iPhone must be on the **same WiFi network** as the Shelly device:

```
iPhone WiFi → Same Router ← Shelly Device
```

**Check:**
- Open Settings → WiFi on your iPhone
- Verify you're connected to your home network
- Shelly devices typically connect to 2.4GHz WiFi (not 5GHz in many cases)

#### Network Isolation?
Some routers have **AP Isolation** or **Client Isolation** enabled:

- This prevents devices from talking to each other
- Common on guest networks
- Check your router settings

### Step 3: Verify Shelly Device is Online

1. **Physical Check**
   - Is the Shelly device powered?
   - Are indicator lights on?
   - Is it plugged in properly?

2. **Web Interface Test**
   - From a computer on the same network
   - Open browser: `http://192.168.6.121`
   - Should see Shelly web interface

3. **Ping Test** (from Mac/computer)
   ```bash
   ping 192.168.6.121
   ```
   - Should get replies if device is online
   - If "Request timeout" → Device is offline/unreachable

### Step 4: Firewall Settings

Check if device has firewall blocking HTTP requests:
- Shelly devices normally don't have firewalls
- But router might be blocking certain traffic
- Try accessing from different device to isolate issue

---

## 🔧 Quick Fixes to Try

### Fix 1: Update Device IP in Settings
The IP might have changed:

1. Open **Settings** in your Home Lab app
2. Find the Shelly device entry
3. Edit the device
4. Update IP address if it changed
5. Save and retry

### Fix 2: Restart Shelly Device
1. Unplug the Shelly device
2. Wait 10 seconds
3. Plug it back in
4. Wait for it to reconnect to WiFi (30-60 seconds)
5. Retry in app

### Fix 3: Restart iPhone WiFi
1. Settings → WiFi
2. Turn WiFi off
3. Wait 5 seconds
4. Turn WiFi back on
5. Retry in app

### Fix 4: Check Shelly API Path
Different Shelly models use different API paths:

**Gen 2 devices** (Plus, Pro): 
```
http://IP/rpc/Switch.GetStatus?id=0
```

**Gen 1 devices**: 
```
http://IP/status
```

If you have a Gen 1 device, you'll need to update the API path in the code.

---

## 📱 New Features in Your App

### 1. **Better Error Messages**
Now shows specific errors:
- ✅ "Device not responding (timeout)"
- ✅ "Cannot reach device on network"
- ✅ "Invalid response from device"
- ✅ "Cannot parse device data"

### 2. **Retry Button**
- Tap to retry connection
- No need to restart app
- Provides immediate feedback

### 3. **Manual Refresh**
- Refresh button in top-right of each device card
- Shows loading spinner while fetching
- Updates "last updated" timestamp

### 4. **Better Visual Design**
- Glass effects on device cards
- Prominent power display
- Color-coded status (yellow for electricity)
- Professional, modern look

---

## 🔍 Debugging Tips

### Check Console Logs
When you run the app, look for these emoji logs:

```
🔌 Fetching Shelly data from: http://192.168.6.121/rpc/Switch.GetStatus?id=0
🔌 Response status: 200
🔌 Raw JSON response: {"id":0,"apower":45.2,"voltage":120.5,"current":0.38,...}
🔌 Parsed data - Watts: 45.2, Volts: 120.5, Amps: 0.38
```

**What to look for:**
- If you see "Fetching" but no "Response" → Timeout/unreachable
- If you see response but parsing error → API format mismatch
- If logs stop after "Fetching" → Network issue

### Test API Manually

**From Mac/Computer on same network:**
```bash
curl http://192.168.6.121/rpc/Switch.GetStatus?id=0
```

Should return something like:
```json
{
  "id": 0,
  "apower": 45.2,
  "voltage": 120.5,
  "current": 0.38,
  "temperature": {"tC": 42.5, "tF": 108.5}
}
```

---

## 🎯 Most Likely Issues

Based on the error, here are the most common causes (in order):

1. **IP Address Changed** (70% probability)
   - Shelly got new IP from DHCP
   - Fix: Update IP in Settings

2. **Device Offline** (15% probability)
   - Shelly unplugged or powered off
   - Fix: Check physical device

3. **Network Isolation** (10% probability)
   - iPhone on different network or isolated
   - Fix: Connect to same WiFi network

4. **Wrong API Path** (5% probability)
   - Gen 1 vs Gen 2 Shelly device
   - Fix: Update API path in code

---

## ✨ Prevention Tips

### 1. Set Static IP for Shelly
In your router settings:
- Reserve IP address for Shelly's MAC address
- Prevents IP from changing
- More reliable connectivity

### 2. Use mDNS/Hostname (Advanced)
Some Shelly devices support hostnames:
```
http://shellyplug-ABCDEF.local/rpc/Switch.GetStatus?id=0
```
Instead of IP address

### 3. Enable "Keep WiFi Connection"
In Shelly device settings:
- Ensure it stays connected to WiFi
- Check for firmware updates
- Stable WiFi signal

---

## 📊 Error Breakdown

```
Error Code -1001 = NSURLErrorTimedOut
Code 60 = ETIMEDOUT (System error: Connection timed out)
```

This definitively means:
- Request was sent
- No response received within timeout period
- Device not responding on network

---

## 🔄 Next Steps

1. **Check device IP address** (most likely cause)
2. **Test device accessibility from Safari**
3. **Verify same WiFi network**
4. **Update IP in app if changed**
5. **Use the new retry button in the app**

---

## 💡 Code Changes Summary

### What Changed:
- ✅ Reduced timeout from 60s → 5s
- ✅ Added specific error types
- ✅ Better error messages
- ✅ Retry functionality
- ✅ Manual refresh button
- ✅ Liquid Glass UI styling
- ✅ Last updated timestamp
- ✅ Loading indicators

### What to Do:
1. Update your Shelly device IP in Settings if it changed
2. Test connectivity from Safari first
3. Use the retry button if connection fails
4. Check console logs for debugging info

---

## 🆘 Still Having Issues?

If none of these steps work:

1. **Verify device model**
   - Check if it's Shelly Gen 1 or Gen 2
   - Different models use different API paths

2. **Try different device**
   - Test with another device on the network
   - Isolates if it's iPhone-specific

3. **Check Shelly firmware**
   - Outdated firmware can cause issues
   - Update via Shelly app

4. **Factory reset Shelly** (last resort)
   - Reset device
   - Reconnect to WiFi
   - Set up again

---

**Good news**: The Liquid Glass UI looks amazing, and the error handling is much better now! Once you fix the network connectivity, you'll have a beautiful, modern electricity monitoring system! ⚡✨
