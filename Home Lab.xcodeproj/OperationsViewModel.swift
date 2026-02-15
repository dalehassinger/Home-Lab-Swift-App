//
//  OperationsViewModel.swift
//  Home Lab
//
//  Created by Assistant on 2/15/26.
//

import Foundation
import Observation

@Observable
final class OperationsViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }
    
    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case failed(String)
    }
    
    var hostState: State = .idle
    var connectionState: ConnectionState = .disconnected
    var hosts: [OperationsHost] = [] {
        didSet {
            print("📝 operationsViewModel.hosts was SET to \(hosts.count) items")
            if let first = hosts.first {
                print("📝 First Host: name=\(first.name), healthScore=\(first.healthScore ?? -1)")
            }
        }
    }
    
    let client: OperationsClient
    
    init(serverURL: URL, username: String, password: String) {
        self.client = OperationsClient(baseURL: serverURL, username: username, password: password)
    }
    
    @MainActor
    func loadHosts() async {
        hostState = .loading
        print("🟢 Loading Operations Hosts...")
        
        // Update connection state
        if connectionState == .disconnected {
            connectionState = .connecting
        }
        
        do {
            let list = try await client.fetchESXiHosts()
            hosts = list
            print("🟢 Loaded \(hosts.count) Operations Hosts into operationsViewModel.hosts")
            if let first = hosts.first {
                print("🟢 First Host: \(first.name) (Health: \(first.healthScore ?? -1))")
            }
            hostState = .loaded
            connectionState = .connected
        } catch {
            print("🔴 Error loading Operations Hosts: \(error)")
            hostState = .error(error.localizedDescription)
            connectionState = .failed(error.localizedDescription)
        }
    }
}
