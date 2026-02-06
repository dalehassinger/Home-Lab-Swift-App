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
        
        let memoryMiB = memoryBytes.map { $0 / (1024 * 1024) }
        
        print("🟠 Parsed SOAP - CPU Cores: \(cpuCount ?? -1), Memory MiB: \(memoryMiB ?? -1)")
        
        return VCenterHostDetail(cpu_count: cpuCount, memory_size_MiB: memoryMiB)
    }
}

