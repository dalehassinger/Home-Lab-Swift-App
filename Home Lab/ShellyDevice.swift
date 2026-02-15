//
//  ShellyDevice.swift
//  Home Lab
//
//  Created by Dale Hassinger on 2/15/26.
//

import Foundation
import SwiftData

@Model
final class ShellyDevice {
    var id: UUID
    var name: String
    var ipAddress: String
    var isEnabled: Bool
    var createdAt: Date
    
    init(name: String, ipAddress: String, isEnabled: Bool = true) {
        self.id = UUID()
        self.name = name
        self.ipAddress = ipAddress
        self.isEnabled = isEnabled
        self.createdAt = Date()
    }
}
