import Foundation

// MARK: - Operations Models

struct OperationsHost: Codable, Identifiable {
    let resourceKey: ResourceKey
    let identifier: String?
    var healthScore: Double?
    let resourceStatusStates: [ResourceStatusState]?
    let resourceHealth: String?
    let resourceHealthValue: Double?
    var properties: HostProperties?
    
    var id: String { resourceKey.name }
    var name: String { resourceKey.name }
    
    struct ResourceKey: Codable {
        let name: String
        let resourceKindKey: String?
        let adapterKindKey: String?
    }
    
    struct ResourceStatusState: Codable {
        let resourceState: String?
        let statusName: String?
        let severity: String?
        let resourceStatus: String?
    }
    
    // Health status computed property
    var healthStatus: HealthStatus {
        // Try resourceHealthValue first, then healthScore
        let score = resourceHealthValue ?? healthScore
        guard let score = score else { return .unknown }
        switch score {
        case 80...100: return .excellent
        case 60..<80: return .good
        case 40..<60: return .warning
        case 0..<40: return .critical
        default: return .unknown
        }
    }
    
    enum HealthStatus {
        case excellent, good, warning, critical, unknown
        
        var color: String {
            switch self {
            case .excellent: return "green"
            case .good: return "mint"
            case .warning: return "orange"
            case .critical: return "red"
            case .unknown: return "gray"
            }
        }
        
        var icon: String {
            switch self {
            case .excellent: return "checkmark.circle.fill"
            case .good: return "checkmark.circle"
            case .warning: return "exclamationmark.triangle.fill"
            case .critical: return "xmark.circle.fill"
            case .unknown: return "questionmark.circle"
            }
        }
        
        var text: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .warning: return "Warning"
            case .critical: return "Critical"
            case .unknown: return "Unknown"
            }
        }
    }
}

// Host properties from the properties API
struct HostProperties: Codable {
    var version: String?
    var build: String?
    var cpuModel: String?
    var cpuCores: Int?
    var memorySize: String?
    var managementIP: String?
    var parentCluster: String?
    var parentDatacenter: String?
    var connectionState: String?
    var powerState: String?
    var vendor: String?
    var model: String?
    var biosVersion: String?
    var maintenanceState: String?
    var hyperThreadActive: Bool?
}

// Response for resource properties
struct OperationsPropertiesResponse: Codable {
    let resourceId: String?
    let property: [PropertyItem]?
    
    struct PropertyItem: Codable {
        let name: String
        let value: String
    }
}

// Response for resource details with health
struct OperationsResourceDetail: Codable {
    let identifier: String?
    let resourceKey: OperationsHost.ResourceKey?
    let resourceStatusStates: [OperationsHost.ResourceStatusState]?
    let resourceHealth: String?
    let resourceHealthValue: Double?
}

struct OperationsResourceList: Codable {
    let resourceList: [OperationsHost]?
}

struct OperationsTokenResponse: Codable {
    let token: String
}

// MARK: - Operations Client

final class OperationsClient: NSObject, URLSessionDelegate {
    private let baseURL: URL
    private let username: String
    private let password: String
    private var authToken: String?
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
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
    
    /// Acquire authentication token from VMware Aria Operations
    @discardableResult
    func acquireToken() async throws -> String {
        // Return existing token if we have one
        if let existingToken = authToken {
            return existingToken
        }
        
        print("🟢 Acquiring Operations auth token...")
        
        let tokenURL = baseURL.appendingPathComponent("suite-api/api/auth/token/acquire")
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create auth body
        let authBody: [String: String] = [
            "username": username,
            "password": password
        ]
        request.httpBody = try JSONEncoder().encode(authBody)
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(
                domain: "OperationsClient",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Token acquisition failed (\(http.statusCode)): \(body)"]
            )
        }
        
        let tokenResponse = try JSONDecoder().decode(OperationsTokenResponse.self, from: data)
        authToken = tokenResponse.token
        
        print("🟢 Successfully acquired Operations token")
        return tokenResponse.token
    }
    
    /// Fetch ESXi hosts from VMware Aria Operations
    func fetchESXiHosts() async throws -> [OperationsHost] {
        // Ensure we have a token
        let token = try await acquireToken()
        
        print("🟢 Fetching ESXi hosts from Operations...")
        
        // Build the API URL
        let apiURL = baseURL.appendingPathComponent("suite-api/api/resources")
            .appending(queryItems: [URLQueryItem(name: "resourceKind", value: "HostSystem")])
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "GET"
        request.setValue("vRealizeOpsToken \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(
                domain: "OperationsClient",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Fetch ESXi hosts failed (\(http.statusCode)): \(body)"]
            )
        }
        
        let resourceList = try JSONDecoder().decode(OperationsResourceList.self, from: data)
        var hosts = resourceList.resourceList ?? []
        
        print("🟢 Decoded \(hosts.count) ESXi hosts from Operations")
        
        // Debug: Print first host's identifier
        if let firstHost = hosts.first {
            print("📋 First host: \(firstHost.name)")
            print("📋 Identifier: \(firstHost.identifier ?? "nil")")
        }
        
        // Fetch detailed health info and properties for each host
        for index in hosts.indices {
            if let identifier = hosts[index].identifier {
                print("🔍 Processing host: \(hosts[index].name) with ID: \(identifier)")
                // Fetch health score
                do {
                    let healthScore = try await fetchHealthScore(for: identifier)
                    hosts[index].healthScore = healthScore
                    if let score = healthScore {
                        print("🟢 Health score for \(hosts[index].name): \(score)")
                    }
                } catch {
                    print("⚠️ Could not fetch health score for \(hosts[index].name): \(error)")
                    hosts[index].healthScore = nil
                }
                
                // Fetch properties
                do {
                    let properties = try await fetchProperties(for: identifier)
                    hosts[index].properties = properties
                    print("🟢 Properties fetched for \(hosts[index].name)")
                } catch {
                    print("⚠️ Could not fetch properties for \(hosts[index].name): \(error)")
                    hosts[index].properties = nil
                }
            } else {
                print("⚠️ Host \(hosts[index].name) has no identifier/resource ID")
            }
        }
        
        return hosts.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    /// Fetch health score for a specific resource using the resource details endpoint
    /// This uses the endpoint: /suite-api/api/resources/{id}?_no_links=true
    /// which returns resourceHealthValue directly in the response
    func fetchHealthScore(for resourceID: String) async throws -> Double? {
        let token = try await acquireToken()
        
        print("🟢 Fetching health for resource: \(resourceID)")
        
        // Use the endpoint you found: /suite-api/api/resources/{id}?_no_links=true
        let resourceURL = baseURL
            .appendingPathComponent("suite-api/api/resources/\(resourceID)")
            .appending(queryItems: [URLQueryItem(name: "_no_links", value: "true")])
        
        var request = URLRequest(url: resourceURL)
        request.httpMethod = "GET"
        request.setValue("vRealizeOpsToken \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("⚠️ Health fetch failed (\(http.statusCode)): \(body)")
            return nil
        }
        
        // Debug: Print response to see structure
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🟢 Resource detail response (first 1000 chars):\n\(String(jsonString.prefix(1000)))")
        }
        
        // Parse the response
        let resourceDetail = try JSONDecoder().decode(OperationsResourceDetail.self, from: data)
        
        // Return the health value
        if let healthValue = resourceDetail.resourceHealthValue {
            print("🟢 Found resourceHealthValue: \(healthValue)")
            return healthValue
        } else if let healthStr = resourceDetail.resourceHealth {
            print("🟢 Found resourceHealth string: \(healthStr)")
            // Try to parse as double if it's a string
            if let healthDouble = Double(healthStr) {
                return healthDouble
            }
        }
        
        print("⚠️ No health value found in response")
        return nil
    }
    
    /// Fetch properties for a specific resource
    /// Uses the endpoint: /suite-api/api/resources/{id}/properties?_no_links=true
    func fetchProperties(for resourceID: String) async throws -> HostProperties {
        let token = try await acquireToken()
        
        print("🟢 Fetching properties for resource: \(resourceID)")
        
        // Build the properties URL
        let propertiesURL = baseURL
            .appendingPathComponent("suite-api/api/resources/\(resourceID)/properties")
            .appending(queryItems: [URLQueryItem(name: "_no_links", value: "true")])
        
        var request = URLRequest(url: propertiesURL)
        request.httpMethod = "GET"
        request.setValue("vRealizeOpsToken \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("⚠️ Properties fetch failed (\(http.statusCode)): \(body)")
            throw NSError(
                domain: "OperationsClient",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Properties fetch failed"]
            )
        }
        
        // Parse the response
        let propertiesResponse = try JSONDecoder().decode(OperationsPropertiesResponse.self, from: data)
        
        // Extract relevant properties
        var hostProperties = HostProperties()
        
        guard let properties = propertiesResponse.property else {
            return hostProperties
        }
        
        for prop in properties {
            switch prop.name {
            case "summary|version":
                hostProperties.version = prop.value
            case "sys|build":
                hostProperties.build = prop.value
            case "cpu|cpuModel":
                hostProperties.cpuModel = prop.value
            case "hardware|cpuInfo|numCpuCores":
                hostProperties.cpuCores = Int(Double(prop.value) ?? 0)
            case "hardware|memorySize":
                // Convert bytes to GB
                if let bytes = Double(prop.value) {
                    let gb = bytes / 1_073_741_824 // 1024^3
                    hostProperties.memorySize = String(format: "%.0f GB", gb)
                }
            case "net|mgmt_address":
                hostProperties.managementIP = prop.value
            case "summary|parentCluster":
                hostProperties.parentCluster = prop.value
            case "summary|parentDatacenter":
                hostProperties.parentDatacenter = prop.value
            case "runtime|connectionState":
                hostProperties.connectionState = prop.value
            case "runtime|powerState":
                hostProperties.powerState = prop.value
            case "hardware|vendor":
                hostProperties.vendor = prop.value
            case "hardware|vendorModel":
                hostProperties.model = prop.value
            case "hardware|biosVersion":
                hostProperties.biosVersion = prop.value
            case "runtime|maintenanceState":
                hostProperties.maintenanceState = prop.value
            case "config|hyperThread|active":
                hostProperties.hyperThreadActive = prop.value.lowercased() == "true"
            default:
                break
            }
        }
        
        return hostProperties
    }
    
    /// Fetch statistics for a specific resource
    /// Uses the endpoint: /suite-api/api/resources/{id}/stats/latest
    func fetchStats(for resourceID: String) async throws -> HostStats {
        let token = try await acquireToken()
        
        print("🟢 Fetching stats for resource: \(resourceID)")
        
        // Stats we want to fetch
        let statKeys = [
            // CPU stats
            "cpu|usage_average",
            "cpu|totalCapacity_average",
            "cpu|usagemhz_average",
            "hardware|cpuInfo|num_CpuCores",
            "cpu|vcpus_allocated_on_all_powered_on_vms",
            "summary|number_running_vms",
            // Memory stats
            "mem|usage_average",
            "mem|totalCapacity_average",
            "mem|consumed_average",
            "mem|active_average",
            "mem|granted_average",
            "mem|memory_allocated_on_all_powered_on_vms"
        ]
        
        // Build query items for each stat
        var queryItems: [URLQueryItem] = []
        for key in statKeys {
            queryItems.append(URLQueryItem(name: "statKey", value: key))
        }
        
        // Build the stats URL
        let statsURL = baseURL
            .appendingPathComponent("suite-api/api/resources/\(resourceID)/stats/latest")
            .appending(queryItems: queryItems)
        
        print("📊 Stats URL: \(statsURL.absoluteString)")
        
        var request = URLRequest(url: statsURL)
        request.httpMethod = "GET"
        request.setValue("vRealizeOpsToken \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("⚠️ Stats fetch failed (\(http.statusCode)): \(body)")
            throw NSError(
                domain: "OperationsClient",
                code: http.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Stats fetch failed"]
            )
        }
        
        // Debug: Print raw response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📊 Raw stats response (first 1000 chars):")
            print(String(jsonString.prefix(1000)))
        }
        
        // Parse the response
        let statsResponse = try JSONDecoder().decode(OperationsStatsResponse.self, from: data)
        
        print("📊 Stats response received, resource values count: \(statsResponse.values?.count ?? 0)")
        
        // Convert to HostStats
        var hostStats = HostStats()
        
        guard let resourceValues = statsResponse.values, let firstResource = resourceValues.first else {
            print("⚠️ No resource values in stats response")
            return hostStats
        }
        
        guard let statList = firstResource.statList, let stats = statList.stat else {
            print("⚠️ No stat list in response")
            return hostStats
        }
        
        print("📊 Processing \(stats.count) stat values...")
        
        for statValue in stats {
            guard let key = statValue.statKey?.key else {
                print("⚠️ Stat value has no key")
                continue
            }
            
            guard let data = statValue.data else {
                print("⚠️ Stat \(key) has no data array")
                continue
            }
            
            guard let firstDataPoint = data.first else {
                print("⚠️ Stat \(key) has empty data array")
                continue
            }
            
            guard let value = firstDataPoint else {
                print("⚠️ Stat \(key) has nil data point")
                continue
            }
            
            print("📊 Found stat: \(key) = \(value)")
            
            switch key {
            // CPU stats
            case "cpu|usage_average":
                hostStats.cpuUsagePercent = value
                print("   → Set cpuUsagePercent = \(value)")
            case "cpu|totalCapacity_average":
                hostStats.cpuTotalCapacityMHz = value
                print("   → Set cpuTotalCapacityMHz = \(value)")
            case "cpu|usagemhz_average":
                hostStats.cpuUsageMHz = value
                print("   → Set cpuUsageMHz = \(value)")
            case "hardware|cpuInfo|num_CpuCores":
                hostStats.cpuCores = Int(value)
                print("   → Set cpuCores = \(Int(value))")
            case "cpu|vcpus_allocated_on_all_powered_on_vms":
                hostStats.cpuVCPUsAllocated = Int(value)
                print("   → Set cpuVCPUsAllocated = \(Int(value))")
            case "summary|number_running_vms":
                hostStats.runningVMs = Int(value)
                print("   → Set runningVMs = \(Int(value))")
            // Memory stats (convert from KB to GB)
            case "mem|usage_average":
                hostStats.memUsagePercent = value
                print("   → Set memUsagePercent = \(value)")
            case "mem|totalCapacity_average":
                hostStats.memTotalCapacityGB = value / 1_048_576 // KB to GB
                print("   → Set memTotalCapacityGB = \(value / 1_048_576) GB")
            case "mem|consumed_average":
                hostStats.memConsumedGB = value / 1_048_576
                print("   → Set memConsumedGB = \(value / 1_048_576) GB")
            case "mem|active_average":
                hostStats.memActiveGB = value / 1_048_576
                print("   → Set memActiveGB = \(value / 1_048_576) GB")
            case "mem|granted_average":
                hostStats.memGrantedGB = value / 1_048_576
                print("   → Set memGrantedGB = \(value / 1_048_576) GB")
            case "mem|memory_allocated_on_all_powered_on_vms":
                hostStats.memAllocatedToVMsGB = value / 1_048_576
                print("   → Set memAllocatedToVMsGB = \(value / 1_048_576) GB")
            default:
                print("   → Unrecognized stat key: \(key)")
                break
            }
        }
        
        print("✅ Successfully parsed stats for \(resourceID)")
        print("   CPU: usage=\(hostStats.cpuUsagePercent?.description ?? "nil"), cores=\(hostStats.cpuCores?.description ?? "nil")")
        print("   Memory: usage=\(hostStats.memUsagePercent?.description ?? "nil"), total=\(hostStats.memTotalCapacityGB?.description ?? "nil") GB")
        
        return hostStats
    }
}
// MARK: - Stats Response Models

struct OperationsStatsResponse: Codable {
    let values: [ResourceStats]?
    
    struct ResourceStats: Codable {
        let resourceId: String?
        let statList: StatList?
        
        enum CodingKeys: String, CodingKey {
            case resourceId
            case statList = "stat-list"
        }
    }
    
    struct StatList: Codable {
        let stat: [StatValue]?
    }
}

struct StatValue: Codable {
    let statKey: StatKeyInfo?
    let data: [Double?]?
    let timestamps: [Int64]?
    
    struct StatKeyInfo: Codable {
        let key: String?
    }
    
    // Add debug description
    var debugDescription: String {
        return "StatValue(statKey=\(statKey?.key ?? "nil"), dataCount=\(data?.count ?? 0))"
    }
}

