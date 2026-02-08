//
//  OperationsViewModel.swift
//  Home Lab
//
//  Created by Assistant on 2/7/26.
//

import Foundation
import Observation

@Observable
final class OperationsViewModel {
    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case failed(String)
    }

    var connectionState: ConnectionState = .disconnected
    var hosts: [OperationsHost] = []

    let client: OperationsClient

    init(serverURL: URL, username: String, password: String) {
        self.client = OperationsClient(baseURL: serverURL, username: username, password: password)
    }

    @MainActor
    func loadHosts() async {
        connectionState = .connecting
        print("🟢 Loading Operations hosts...")
        
        do {
            let list = try await client.fetchESXiHosts()
            hosts = list
            connectionState = .connected
            print("🟢 Loaded \(hosts.count) hosts into Operations viewModel")
        } catch {
            print("🔴 Error loading Operations hosts: \(error)")
            connectionState = .failed(error.localizedDescription)
        }
    }
}
