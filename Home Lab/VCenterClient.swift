import Foundation

// Simple VMware vCenter REST client for demo purposes.
// NOTE: This implementation accepts any TLS certificate. Do NOT ship to production.
struct VCenterVM: Codable, Identifiable {
    let vm: String
    let name: String
    let power_state: String?

    var id: String { vm }
}

struct VCenterHost: Codable, Identifiable {
    let host: String
    let name: String?
    let connection_state: String?
    let power_state: String?
    var id: String { host }
}

struct VCenterHostDetail: Codable {
    let cpu_count: Int?
    let memory_size_MiB: Int?
    let storage_total_bytes: Int64?
    let storage_used_bytes: Int64?
    let ip_address: String?
    let fqdn: String?
}
struct VCenterHostCPU: Codable { let count: Int? }
struct VCenterHostMemory: Codable { let size_MiB: Int? }

struct VCenterVMDetail: Codable {
    let cpu_count: Int?
    let memory_size_MiB: Int?
}

struct VCenterVMCPU: Codable { let count: Int? }
struct VCenterVMMemory: Codable { let size_MiB: Int? }

struct VCenterVMDisk: Codable, Identifiable {
    // Some vCenter versions use `key` (Int), others use `disk` (String) as the identifier
    let key: Int?
    let disk: String?
    var label: String?
    var capacity: Int64?

    var id: String { disk ?? String(key ?? -1) }

    enum CodingKeys: String, CodingKey {
        case key, disk, label, capacity
    }
}

struct VCenterVMDiskDetail: Codable {
    let label: String?
    let capacity: Int64?
    let backing: Backing?

    struct Backing: Codable {
        let vmdk_file: String?
        let file: String?
    }
}

struct VCenterVMSnapshot: Codable, Identifiable {
    let snapshot: String
    let name: String
    let description: String?
    let create_time: String?
    let state: String?
    
    var id: String { snapshot }
}

struct VCenterVMSnapshotInfo: Codable {
    let current_snapshot: String?
}

struct VCenterMetric: Codable, Identifiable {
    let metric: String
    let name: String?
    let description: String?
    let type: String?
    let units: String?
    
    var id: String { metric }
}

struct VCenterMetricValue: Codable {
    let metric: String
    let value: String?
    let timestamp: String?
}

struct VCenterVMStats: Codable {
    let cpu_usage: Double?
    let memory_usage: Double?
    let storage_committed: Int64?
    let storage_uncommitted: Int64?
    let storage_unshared: Int64?
    
    var storage_total: Int64? {
        if let committed = storage_committed {
            return committed + (storage_uncommitted ?? 0)
        }
        return nil
    }
    
    var storage_usage_percent: Double? {
        guard let committed = storage_committed,
              let total = storage_total,
              total > 0 else { return nil }
        return (Double(committed) / Double(total)) * 100.0
    }
}

private struct VCenterListResponse<T: Codable>: Codable {
    let value: T
}

final class VCenterClient: NSObject, URLSessionDelegate {
    private let baseURL: URL
    private let username: String
    private let password: String
    private var soapSessionCookie: String?
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieStorage = HTTPCookieStorage.shared
        config.httpCookieAcceptPolicy = .always
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    init(baseURL: URL, username: String, password: String) {
        self.baseURL = baseURL
        self.username = username
        self.password = password
        super.init()
    }

    // Accept all server certificates (self-signed). For development only.
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    @discardableResult
    func login() async throws -> String {
        let loginURL = baseURL.appendingPathComponent("rest/com/vmware/cis/session")
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        let auth = "\(username):\(password)"
        guard let authData = auth.data(using: .utf8) else { throw URLError(.badURL) }
        let authValue = "Basic \(authData.base64EncodedString())"
        request.setValue(authValue, forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "VCenterClient", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Login failed (\(http.statusCode)): \(body)"])
        }
        let decoded = try JSONDecoder().decode(VCenterListResponse<String>.self, from: data)
        return decoded.value
    }
    
    // SOAP API Login
    @discardableResult
    func soapLogin() async throws -> String {
        // Return existing session if we have one
        if let existingCookie = soapSessionCookie {
            return existingCookie
        }
        
        print("🟠 Performing SOAP login...")
        
        let soapBody = """
        <?xml version="1.0" encoding="UTF-8"?>
        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:vim25="urn:vim25">
          <soapenv:Body>
            <vim25:Login>
              <vim25:_this type="SessionManager">SessionManager</vim25:_this>
              <vim25:userName>\(username)</vim25:userName>
              <vim25:password>\(password)</vim25:password>
            </vim25:Login>
          </soapenv:Body>
        </soapenv:Envelope>
        """
        
        let soapURL = baseURL.appendingPathComponent("sdk")
        var request = URLRequest(url: soapURL)
        request.httpMethod = "POST"
        request.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("urn:vim25/8.0", forHTTPHeaderField: "SOAPAction")
        request.httpBody = soapBody.data(using: .utf8)
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("🔴 SOAP login failed: \(body)")
            throw NSError(domain: "VCenterClient", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "SOAP login failed"])
        }
        
        // Extract SOAP session cookie from response headers
        if let setCookies = http.value(forHTTPHeaderField: "Set-Cookie") {
            let cookies = setCookies.components(separatedBy: ",")
            for cookie in cookies {
                if cookie.contains("vmware_soap_session=") {
                    let sessionCookie = cookie.components(separatedBy: ";")[0].trimmingCharacters(in: .whitespaces)
                    soapSessionCookie = sessionCookie
                    print("🟠 SOAP login successful, got session cookie")
                    return sessionCookie
                }
            }
        }
        
        throw NSError(domain: "VCenterClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "SOAP session cookie not found"])
    }

    func fetchVMs() async throws -> [VCenterVM] {
        // Ensure we have a session cookie by attempting login first.
        _ = try? await login()
        let url = baseURL.appendingPathComponent("rest/vcenter/vm")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "VCenterClient", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Fetch VMs failed (\(http.statusCode)): \(body)"])
        }
        
        // Debug: Print the raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🔵 VM Response from \(url):\n\(jsonString)")
        }
        
        let decoded = try JSONDecoder().decode(VCenterListResponse<[VCenterVM]>.self, from: data)
        print("🔵 Decoded \(decoded.value.count) VMs")
        return decoded.value
    }

    func fetchVMDetail(id: String) async throws -> VCenterVMDetail {
        // Ensure session exists
        _ = try? await login()

        // CPU endpoint
        let cpuURL = baseURL.appendingPathComponent("rest/vcenter/vm/\(id)/hardware/cpu")
        var cpuRequest = URLRequest(url: cpuURL)
        cpuRequest.httpMethod = "GET"
        let (cpuData, cpuResponse) = try await session.data(for: cpuRequest)
        guard let cpuHTTP = cpuResponse as? HTTPURLResponse, (200..<300).contains(cpuHTTP.statusCode) else {
            let body = String(data: cpuData, encoding: .utf8) ?? ""
            throw NSError(domain: "VCenterClient", code: (cpuResponse as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Fetch VM CPU failed: \(body)"])
        }
        let cpuDecoded = try JSONDecoder().decode(VCenterListResponse<VCenterVMCPU>.self, from: cpuData)

        // Memory endpoint
        let memURL = baseURL.appendingPathComponent("rest/vcenter/vm/\(id)/hardware/memory")
        var memRequest = URLRequest(url: memURL)
        memRequest.httpMethod = "GET"
        let (memData, memResponse) = try await session.data(for: memRequest)
        guard let memHTTP = memResponse as? HTTPURLResponse, (200..<300).contains(memHTTP.statusCode) else {
            let body = String(data: memData, encoding: .utf8) ?? ""
            throw NSError(domain: "VCenterClient", code: (memResponse as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Fetch VM Memory failed: \(body)"])
        }
        let memDecoded = try JSONDecoder().decode(VCenterListResponse<VCenterVMMemory>.self, from: memData)

        return VCenterVMDetail(cpu_count: cpuDecoded.value.count, memory_size_MiB: memDecoded.value.size_MiB)
    }
    
    func fetchVMDiskList(id: String) async throws -> [VCenterVMDisk] {
        _ = try? await login()
        let listURL = baseURL.appendingPathComponent("rest/vcenter/vm/\(id)/hardware/disk")
        var listRequest = URLRequest(url: listURL)
        listRequest.httpMethod = "GET"
        let (listData, listResponse) = try await session.data(for: listRequest)
        guard let listHTTP = listResponse as? HTTPURLResponse, (200..<300).contains(listHTTP.statusCode) else {
            let body = String(data: listData, encoding: .utf8) ?? ""
            throw NSError(domain: "VCenterClient", code: (listResponse as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Fetch VM disks failed: \(body)"])
        }
        var disks = try JSONDecoder().decode(VCenterListResponse<[VCenterVMDisk]>.self, from: listData).value

        // Fetch per-disk details to populate capacity
        for i in disks.indices {
            let diskID = disks[i].disk ?? String(disks[i].key ?? -1)
            let detailURL = baseURL.appendingPathComponent("rest/vcenter/vm/\(id)/hardware/disk/\(diskID)")
            var detailRequest = URLRequest(url: detailURL)
            detailRequest.httpMethod = "GET"
            do {
                let (detailData, detailResponse) = try await session.data(for: detailRequest)
                guard let detailHTTP = detailResponse as? HTTPURLResponse, (200..<300).contains(detailHTTP.statusCode) else {
                    continue
                }
                let detail = try JSONDecoder().decode(VCenterListResponse<VCenterVMDiskDetail>.self, from: detailData)
                disks[i].capacity = detail.value.capacity
                if disks[i].label == nil || disks[i].label?.isEmpty == true {
                    disks[i].label = detail.value.label ?? detail.value.backing?.vmdk_file ?? detail.value.backing?.file
                }
            } catch {
                // Ignore detail errors per disk; continue
                continue
            }
        }
        return disks
    }
    
    func fetchVMSnapshots(id: String) async throws -> [VCenterVMSnapshot] {
        // First try REST API
        _ = try? await login()
        let url = baseURL.appendingPathComponent("rest/vcenter/vm/\(id)/snapshot")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        print("🔵 Fetching snapshots for VM: \(id) from \(url)")
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("🔵 Snapshot response status: \(http.statusCode)")
        
        // If REST API returns 404, try SOAP API instead
        if http.statusCode == 404 {
            print("🔵 REST API returned 404, trying SOAP API...")
            return try await fetchVMSnapshotsSOAP(id: id)
        }
        
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("🔴 Fetch snapshots failed: \(body)")
            // Try SOAP as fallback
            return try await fetchVMSnapshotsSOAP(id: id)
        }
        
        // Debug: Print the raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🔵 Snapshot Response:\n\(jsonString)")
        }
        
        // Try to decode as a list response
        do {
            let decoded = try JSONDecoder().decode(VCenterListResponse<[VCenterVMSnapshot]>.self, from: data)
            print("🔵 Successfully decoded \(decoded.value.count) snapshots")
            return decoded.value
        } catch {
            // If decoding fails, try SOAP
            print("🔴 Could not decode snapshots, trying SOAP: \(error)")
            return try await fetchVMSnapshotsSOAP(id: id)
        }
    }
    
    private func fetchVMSnapshotsSOAP(id: String) async throws -> [VCenterVMSnapshot] {
        let soapCookie = try await soapLogin()
        
        print("🟠 Fetching VM snapshots using SOAP API for \(id)")
        
        let soapBody = """
        <?xml version="1.0" encoding="UTF-8"?>
        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:vim25="urn:vim25">
          <soapenv:Body>
            <vim25:RetrievePropertiesEx>
              <vim25:_this type="PropertyCollector">propertyCollector</vim25:_this>
              <vim25:specSet>
                <vim25:propSet>
                  <vim25:type>VirtualMachine</vim25:type>
                  <vim25:pathSet>snapshot</vim25:pathSet>
                </vim25:propSet>
                <vim25:objectSet>
                  <vim25:obj type="VirtualMachine">\(id)</vim25:obj>
                </vim25:objectSet>
              </vim25:specSet>
              <vim25:options/>
            </vim25:RetrievePropertiesEx>
          </soapenv:Body>
        </soapenv:Envelope>
        """
        
        let soapURL = baseURL.appendingPathComponent("sdk")
        var soapRequest = URLRequest(url: soapURL)
        soapRequest.httpMethod = "POST"
        soapRequest.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        soapRequest.setValue("urn:vim25/8.0", forHTTPHeaderField: "SOAPAction")
        soapRequest.setValue(soapCookie, forHTTPHeaderField: "Cookie")
        soapRequest.httpBody = soapBody.data(using: .utf8)
        
        let (soapData, soapResponse) = try await session.data(for: soapRequest)
        guard let soapHttp = soapResponse as? HTTPURLResponse, (200..<300).contains(soapHttp.statusCode) else {
            let body = String(data: soapData, encoding: .utf8) ?? ""
            print("🔴 SOAP snapshot request failed: \(body)")
            return []
        }
        
        let xmlString = String(data: soapData, encoding: .utf8) ?? ""
        // Removed print line here as per instructions
        
        // Parse snapshot information from XML
        var snapshots: [VCenterVMSnapshot] = []
        
        // Look for snapshot references in the response
        // Pattern: <currentSnapshot type="VirtualMachineSnapshot">snapshot-XXX</currentSnapshot>
        // and <rootSnapshotList> entries
        
        // Extract snapshot names and IDs from rootSnapshotList
        let snapshotPattern = "<snapshot type=\"VirtualMachineSnapshot\">([^<]+)</snapshot>.*?<name>([^<]+)</name>.*?<createTime>([^<]+)</createTime>.*?(?:<description>([^<]*)</description>)?"
        
        let regex = try? NSRegularExpression(pattern: snapshotPattern, options: [])
        let nsString = xmlString as NSString
        let matches = regex?.matches(in: xmlString, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        for match in matches {
            var snapshotId = ""
            var snapshotName = ""
            var createTime = ""
            var description: String? = nil
            
            if match.numberOfRanges > 1 {
                snapshotId = nsString.substring(with: match.range(at: 1))
            }
            if match.numberOfRanges > 2 {
                snapshotName = nsString.substring(with: match.range(at: 2))
            }
            if match.numberOfRanges > 3 {
                createTime = nsString.substring(with: match.range(at: 3))
            }
            if match.numberOfRanges > 4 && match.range(at: 4).location != NSNotFound {
                description = nsString.substring(with: match.range(at: 4))
            }
            
            if !snapshotId.isEmpty && !snapshotName.isEmpty {
                let snapshot = VCenterVMSnapshot(
                    snapshot: snapshotId,
                    name: snapshotName,
                    description: description,
                    create_time: createTime,
                    state: "POWERED_OFF"
                )
                snapshots.append(snapshot)
                print("🟠 Found snapshot: \(snapshotName) (id: \(snapshotId))")
            }
        }
        
        print("🟠 SOAP API found \(snapshots.count) snapshots")
        return snapshots
    }
    
    func fetchAvailableMetrics() async throws -> [VCenterMetric] {
        _ = try? await login()
        let url = baseURL.appendingPathComponent("api/stats/metrics")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        print("📊 Fetching available metrics from \(url)")
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("📊 Metrics response status: \(http.statusCode)")
        
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("🔴 Fetch metrics failed: \(body)")
            throw NSError(domain: "VCenterClient", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Fetch metrics failed: \(body)"])
        }
        
        // Debug: Print the raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📊 Available Metrics Response:\n\(jsonString)")
        }
        
        // Try to decode
        do {
            let decoded = try JSONDecoder().decode([VCenterMetric].self, from: data)
            print("📊 Found \(decoded.count) available metrics")
            return decoded
        } catch {
            print("🔴 Could not decode metrics: \(error)")
            return []
        }
    }
    
    func fetchVMStats(id: String) async throws -> VCenterVMStats {
        // Use SOAP API to get VM performance statistics
        let soapCookie = try await soapLogin()
        
        print("📊 Fetching VM stats for \(id) using SOAP API")
        
        // Query for CPU, memory, and storage usage
        let soapBody = """
        <?xml version="1.0" encoding="UTF-8"?>
        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:vim25="urn:vim25">
          <soapenv:Body>
            <vim25:RetrievePropertiesEx>
              <vim25:_this type="PropertyCollector">propertyCollector</vim25:_this>
              <vim25:specSet>
                <vim25:propSet>
                  <vim25:type>VirtualMachine</vim25:type>
                  <vim25:pathSet>summary.quickStats.overallCpuUsage</vim25:pathSet>
                  <vim25:pathSet>summary.quickStats.hostMemoryUsage</vim25:pathSet>
                  <vim25:pathSet>summary.quickStats.guestMemoryUsage</vim25:pathSet>
                  <vim25:pathSet>config.hardware.numCPU</vim25:pathSet>
                  <vim25:pathSet>config.hardware.memoryMB</vim25:pathSet>
                  <vim25:pathSet>summary.storage.committed</vim25:pathSet>
                  <vim25:pathSet>summary.storage.uncommitted</vim25:pathSet>
                  <vim25:pathSet>summary.storage.unshared</vim25:pathSet>
                </vim25:propSet>
                <vim25:objectSet>
                  <vim25:obj type="VirtualMachine">\(id)</vim25:obj>
                </vim25:objectSet>
              </vim25:specSet>
              <vim25:options/>
            </vim25:RetrievePropertiesEx>
          </soapenv:Body>
        </soapenv:Envelope>
        """
        
        let soapURL = baseURL.appendingPathComponent("sdk")
        var request = URLRequest(url: soapURL)
        request.httpMethod = "POST"
        request.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("urn:vim25/8.0", forHTTPHeaderField: "SOAPAction")
        request.setValue(soapCookie, forHTTPHeaderField: "Cookie")
        request.httpBody = soapBody.data(using: .utf8)
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("🔴 SOAP stats request failed: \(body)")
            throw NSError(domain: "VCenterClient", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "SOAP stats request failed"])
        }
        
        let xmlString = String(data: data, encoding: .utf8) ?? ""
        print("📊 SOAP Stats Response snippet: \(String(xmlString.prefix(500)))")
        
        // Parse CPU and memory usage from response
        var cpuUsageMHz: Double? = nil
        var memoryUsageMB: Double? = nil
        var totalCPUs: Int? = nil
        var totalMemoryMB: Int? = nil
        
        // Extract overallCpuUsage (in MHz)
        if let cpuRange = xmlString.range(of: "<name>summary\\.quickStats\\.overallCpuUsage</name>.*?<val[^>]*>(\\d+)</val>", options: .regularExpression) {
            let cpuString = xmlString[cpuRange]
            if let valRange = cpuString.range(of: "<val[^>]*>(\\d+)</val>", options: .regularExpression) {
                let valText = cpuString[valRange].replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                cpuUsageMHz = Double(valText)
            }
        }
        
        // Extract hostMemoryUsage (in MB)
        if let memRange = xmlString.range(of: "<name>summary\\.quickStats\\.hostMemoryUsage</name>.*?<val[^>]*>(\\d+)</val>", options: .regularExpression) {
            let memString = xmlString[memRange]
            if let valRange = memString.range(of: "<val[^>]*>(\\d+)</val>", options: .regularExpression) {
                let valText = memString[valRange].replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                memoryUsageMB = Double(valText)
            }
        }
        
        // If hostMemoryUsage not available, try guestMemoryUsage
        if memoryUsageMB == nil {
            if let guestMemRange = xmlString.range(of: "<name>summary\\.quickStats\\.guestMemoryUsage</name>.*?<val[^>]*>(\\d+)</val>", options: .regularExpression) {
                let memString = xmlString[guestMemRange]
                if let valRange = memString.range(of: "<val[^>]*>(\\d+)</val>", options: .regularExpression) {
                    let valText = memString[valRange].replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                    memoryUsageMB = Double(valText)
                }
            }
        }
        
        // Extract total CPU count
        if let cpuCountRange = xmlString.range(of: "<name>config\\.hardware\\.numCPU</name>.*?<val[^>]*>(\\d+)</val>", options: .regularExpression) {
            let cpuString = xmlString[cpuCountRange]
            if let valRange = cpuString.range(of: "<val[^>]*>(\\d+)</val>", options: .regularExpression) {
                let valText = cpuString[valRange].replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                totalCPUs = Int(valText)
            }
        }
        
        // Extract total memory
        if let memTotalRange = xmlString.range(of: "<name>config\\.hardware\\.memoryMB</name>.*?<val[^>]*>(\\d+)</val>", options: .regularExpression) {
            let memString = xmlString[memTotalRange]
            if let valRange = memString.range(of: "<val[^>]*>(\\d+)</val>", options: .regularExpression) {
                let valText = memString[valRange].replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                totalMemoryMB = Int(valText)
            }
        }
        
        // Extract storage information (in bytes)
        var storageCommitted: Int64? = nil
        var storageUncommitted: Int64? = nil
        var storageUnshared: Int64? = nil
        
        if let committedRange = xmlString.range(of: "<name>summary\\.storage\\.committed</name>.*?<val[^>]*>(\\d+)</val>", options: .regularExpression) {
            let committedString = xmlString[committedRange]
            if let valRange = committedString.range(of: "<val[^>]*>(\\d+)</val>", options: .regularExpression) {
                let valText = committedString[valRange].replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                storageCommitted = Int64(valText)
            }
        }
        
        if let uncommittedRange = xmlString.range(of: "<name>summary\\.storage\\.uncommitted</name>.*?<val[^>]*>(\\d+)</val>", options: .regularExpression) {
            let uncommittedString = xmlString[uncommittedRange]
            if let valRange = uncommittedString.range(of: "<val[^>]*>(\\d+)</val>", options: .regularExpression) {
                let valText = uncommittedString[valRange].replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                storageUncommitted = Int64(valText)
            }
        }
        
        if let unsharedRange = xmlString.range(of: "<name>summary\\.storage\\.unshared</name>.*?<val[^>]*>(\\d+)</val>", options: .regularExpression) {
            let unsharedString = xmlString[unsharedRange]
            if let valRange = unsharedString.range(of: "<val[^>]*>(\\d+)</val>", options: .regularExpression) {
                let valText = unsharedString[valRange].replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                storageUnshared = Int64(valText)
            }
        }
        
        print("📊 Raw values - CPU: \(cpuUsageMHz ?? -1) MHz, Memory: \(memoryUsageMB ?? -1) MB, Total CPUs: \(totalCPUs ?? -1), Total Memory: \(totalMemoryMB ?? -1) MB")
        print("📊 Storage - Committed: \(storageCommitted ?? -1) bytes, Uncommitted: \(storageUncommitted ?? -1) bytes, Unshared: \(storageUnshared ?? -1) bytes")
        
        // Calculate percentages
        var cpuUsagePercent: Double? = nil
        var memoryUsagePercent: Double? = nil
        
        // For CPU: vCenter reports usage in MHz, but we need percentage
        // We'll estimate based on typical CPU speeds (assume ~2000 MHz per core as baseline)
        // Alternatively, we can fetch the host CPU speed, but for simplicity we'll use the reported value as-is
        // Since overallCpuUsage is already a good indicator, we can use it directly
        // Actually, overallCpuUsage from quickStats is already in percentage in some versions
        // Let's check if the value makes sense as a percentage
        if let cpuMHz = cpuUsageMHz, let cpus = totalCPUs, cpus > 0 {
            // If the value is less than 100, it's likely already a percentage
            if cpuMHz <= 100 {
                cpuUsagePercent = cpuMHz
            } else {
                // Otherwise assume it's MHz and estimate percentage
                // Typical modern CPUs run at ~2000-3000 MHz per core
                // This is a rough estimate
                let estimatedMaxMHz = Double(cpus) * 2000.0
                cpuUsagePercent = (cpuMHz / estimatedMaxMHz) * 100.0
                cpuUsagePercent = min(cpuUsagePercent ?? 0, 100.0) // Cap at 100%
            }
        }
        
        // For memory: calculate percentage
        if let memUsed = memoryUsageMB, let memTotal = totalMemoryMB, memTotal > 0 {
            memoryUsagePercent = (memUsed / Double(memTotal)) * 100.0
        }
        
        print("📊 Calculated percentages - CPU: \(cpuUsagePercent ?? -1)%, Memory: \(memoryUsagePercent ?? -1)%")
        
        return VCenterVMStats(
            cpu_usage: cpuUsagePercent,
            memory_usage: memoryUsagePercent,
            storage_committed: storageCommitted,
            storage_uncommitted: storageUncommitted,
            storage_unshared: storageUnshared
        )
    }
    
    func fetchHosts() async throws -> [VCenterHost] {
        _ = try? await login()
        let url = baseURL.appendingPathComponent("rest/vcenter/host")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "VCenterClient", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "Fetch hosts failed: \(body)"])
        }
        
        // Debug: Print the raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🟠 Host Response from \(url):\n\(jsonString)")
        }
        
        let decoded = try JSONDecoder().decode(VCenterListResponse<[VCenterHost]>.self, from: data)
        print("🟠 Decoded \(decoded.value.count) Hosts")
        return decoded.value
    }
    
    func fetchHostDetail(id: String) async throws -> VCenterHostDetail {
        // Login to SOAP API first
        let soapCookie = try await soapLogin()

        print("🟠 Fetching host details for \(id) using SOAP API")
        
        // Use SOAP API to get host hardware details
        let soapBody = """
        <?xml version="1.0" encoding="UTF-8"?>
        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:vim25="urn:vim25">
          <soapenv:Body>
            <vim25:RetrievePropertiesEx>
              <vim25:_this type="PropertyCollector">propertyCollector</vim25:_this>
              <vim25:specSet>
                <vim25:propSet>
                  <vim25:type>HostSystem</vim25:type>
                  <vim25:pathSet>hardware.cpuInfo.numCpuCores</vim25:pathSet>
                  <vim25:pathSet>hardware.memorySize</vim25:pathSet>
                  <vim25:pathSet>datastore</vim25:pathSet>
                  <vim25:pathSet>config.network.vnic</vim25:pathSet>
                  <vim25:pathSet>name</vim25:pathSet>
                </vim25:propSet>
                <vim25:objectSet>
                  <vim25:obj type="HostSystem">\(id)</vim25:obj>
                </vim25:objectSet>
              </vim25:specSet>
              <vim25:options/>
            </vim25:RetrievePropertiesEx>
          </soapenv:Body>
        </soapenv:Envelope>
        """
        
        let soapURL = baseURL.appendingPathComponent("sdk")
        var request = URLRequest(url: soapURL)
        request.httpMethod = "POST"
        request.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("urn:vim25/8.0", forHTTPHeaderField: "SOAPAction")
        request.setValue(soapCookie, forHTTPHeaderField: "Cookie")
        request.httpBody = soapBody.data(using: .utf8)
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("🔴 SOAP request failed: \(body)")
            throw NSError(domain: "VCenterClient", code: (response as? HTTPURLResponse)?.statusCode ?? -1, userInfo: [NSLocalizedDescriptionKey: "SOAP request failed"])
        }
        
        let xmlString = String(data: data, encoding: .utf8) ?? ""
        print("🟠 SOAP Response: \(xmlString)")
        
        // Parse the SOAP XML response
        var cpuCount: Int? = nil
        var memoryBytes: Int? = nil
        var datastoreRefs: [String] = []
        var ipAddress: String? = nil
        var fqdn: String? = nil
        
        // Simple XML parsing to extract values
        if let cpuCoresRange = xmlString.range(of: "<name>hardware.cpuInfo.numCpuCores</name>.*?<val[^>]*>(\\d+)</val>", options: .regularExpression),
           let cpuMatch = xmlString[cpuCoresRange].range(of: "<val[^>]*>(\\d+)</val>", options: .regularExpression) {
            let cpuText = xmlString[cpuMatch].replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            cpuCount = Int(cpuText)
        }
        
        if let memoryRange = xmlString.range(of: "<name>hardware.memorySize</name>.*?<val[^>]*>(\\d+)</val>", options: .regularExpression),
           let memMatch = xmlString[memoryRange].range(of: "<val[^>]*>(\\d+)</val>", options: .regularExpression) {
            let memText = xmlString[memMatch].replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            if let bytes = Int(memText) {
                memoryBytes = bytes
            }
        }
        
        // Extract host name (FQDN)
        if let nameRange = xmlString.range(of: "<name>name</name>.*?<val[^>]*>([^<]+)</val>", options: .regularExpression) {
            let nameString = xmlString[nameRange]
            if let valRange = nameString.range(of: "<val[^>]*>([^<]+)</val>", options: .regularExpression) {
                let nameText = nameString[valRange].replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                fqdn = nameText
            }
        }
        
        // Extract IP address from vnic configuration
        // Look for the management network adapter IP
        let ipPattern = "<spec>.*?<ip>.*?<ipAddress>([0-9.]+)</ipAddress>.*?</ip>.*?</spec>"
        if let ipRange = xmlString.range(of: ipPattern, options: [.regularExpression]) {
            let ipString = xmlString[ipRange]
            if let addressRange = ipString.range(of: "<ipAddress>([0-9.]+)</ipAddress>", options: .regularExpression) {
                let addressText = ipString[addressRange].replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                ipAddress = addressText
            }
        }
        
        // Extract datastore references
        let datastorePattern = "<ManagedObjectReference type=\"Datastore\"[^>]*>([^<]+)</ManagedObjectReference>"
        let regex = try? NSRegularExpression(pattern: datastorePattern, options: [])
        let nsString = xmlString as NSString
        let matches = regex?.matches(in: xmlString, options: [], range: NSRange(location: 0, length: nsString.length)) ?? []
        
        for match in matches {
            if match.numberOfRanges > 1 {
                let range = match.range(at: 1)
                let datastoreRef = nsString.substring(with: range)
                datastoreRefs.append(datastoreRef)
            }
        }
        
        let memoryMiB = memoryBytes.map { $0 / (1024 * 1024) }
        
        print("🟠 Parsed SOAP - CPU Cores: \(cpuCount ?? -1), Memory MiB: \(memoryMiB ?? -1), Datastores: \(datastoreRefs), FQDN: \(fqdn ?? "none"), IP: \(ipAddress ?? "none")")
        
        // Fetch datastore information if we have references
        var totalStorage: Int64 = 0
        var usedStorage: Int64 = 0
        
        if !datastoreRefs.isEmpty {
            do {
                let datastoreSoapBody = """
                <?xml version="1.0" encoding="UTF-8"?>
                <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:vim25="urn:vim25">
                  <soapenv:Body>
                    <vim25:RetrievePropertiesEx>
                      <vim25:_this type="PropertyCollector">propertyCollector</vim25:_this>
                      <vim25:specSet>
                        <vim25:propSet>
                          <vim25:type>Datastore</vim25:type>
                          <vim25:pathSet>summary.capacity</vim25:pathSet>
                          <vim25:pathSet>summary.freeSpace</vim25:pathSet>
                        </vim25:propSet>
                        \(datastoreRefs.map { "<vim25:objectSet><vim25:obj type=\"Datastore\">\($0)</vim25:obj></vim25:objectSet>" }.joined(separator: "\n"))
                      </vim25:specSet>
                      <vim25:options/>
                    </vim25:RetrievePropertiesEx>
                  </soapenv:Body>
                </soapenv:Envelope>
                """
                
                var dsRequest = URLRequest(url: soapURL)
                dsRequest.httpMethod = "POST"
                dsRequest.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
                dsRequest.setValue("urn:vim25/8.0", forHTTPHeaderField: "SOAPAction")
                dsRequest.setValue(soapCookie, forHTTPHeaderField: "Cookie")
                dsRequest.httpBody = datastoreSoapBody.data(using: .utf8)
                
                let (dsData, dsResponse) = try await session.data(for: dsRequest)
                if let dsHttp = dsResponse as? HTTPURLResponse, (200..<300).contains(dsHttp.statusCode) {
                    let dsXmlString = String(data: dsData, encoding: .utf8) ?? ""
                    print("🟠 Datastore SOAP Response: \(dsXmlString)")
                    
                    // Parse capacity values
                    let capacityPattern = "<name>summary\\.capacity</name>.*?<val[^>]*>(\\d+)</val>"
                    let freeSpacePattern = "<name>summary\\.freeSpace</name>.*?<val[^>]*>(\\d+)</val>"
                    
                    let capacityRegex = try? NSRegularExpression(pattern: capacityPattern, options: [])
                    let freeSpaceRegex = try? NSRegularExpression(pattern: freeSpacePattern, options: [])
                    
                    let dsNsString = dsXmlString as NSString
                    let capacityMatches = capacityRegex?.matches(in: dsXmlString, options: [], range: NSRange(location: 0, length: dsNsString.length)) ?? []
                    let freeSpaceMatches = freeSpaceRegex?.matches(in: dsXmlString, options: [], range: NSRange(location: 0, length: dsNsString.length)) ?? []
                    
                    for capacityMatch in capacityMatches {
                        let matchString = dsNsString.substring(with: capacityMatch.range)
                        if let valRange = matchString.range(of: "<val[^>]*>(\\d+)</val>", options: .regularExpression) {
                            let valText = matchString[valRange].replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                            if let bytes = Int64(valText) {
                                totalStorage += bytes
                            }
                        }
                    }
                    
                    for freeMatch in freeSpaceMatches {
                        let matchString = dsNsString.substring(with: freeMatch.range)
                        if let valRange = matchString.range(of: "<val[^>]*>(\\d+)</val>", options: .regularExpression) {
                            let valText = matchString[valRange].replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                            if let bytes = Int64(valText) {
                                usedStorage += (totalStorage - bytes)
                            }
                        }
                    }
                    
                    // Recalculate used storage properly
                    usedStorage = 0
                    var tempTotal: Int64 = 0
                    for i in 0..<capacityMatches.count {
                        if i < freeSpaceMatches.count {
                            let capMatch = capacityMatches[i]
                            let freeMatch = freeSpaceMatches[i]
                            
                            let capString = dsNsString.substring(with: capMatch.range)
                            let freeString = dsNsString.substring(with: freeMatch.range)
                            
                            if let capRange = capString.range(of: "<val[^>]*>(\\d+)</val>", options: .regularExpression),
                               let freeRange = freeString.range(of: "<val[^>]*>(\\d+)</val>", options: .regularExpression) {
                                let capText = capString[capRange].replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                                let freeText = freeString[freeRange].replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                                
                                if let capacity = Int64(capText), let free = Int64(freeText) {
                                    tempTotal += capacity
                                    usedStorage += (capacity - free)
                                }
                            }
                        }
                    }
                    totalStorage = tempTotal
                    
                    print("🟠 Total Storage: \(totalStorage) bytes, Used: \(usedStorage) bytes")
                }
            } catch {
                print("🔴 Error fetching datastore info: \(error)")
            }
        }
        
        return VCenterHostDetail(
            cpu_count: cpuCount,
            memory_size_MiB: memoryMiB,
            storage_total_bytes: totalStorage > 0 ? totalStorage : nil,
            storage_used_bytes: usedStorage > 0 ? usedStorage : nil,
            ip_address: ipAddress,
            fqdn: fqdn
        )
    }
}

