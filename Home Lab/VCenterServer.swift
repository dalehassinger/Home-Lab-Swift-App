//
//  VCenterServer.swift
//  Home Lab
//
//  Created by Dale Hassinger on 2/6/26.
//

import Foundation
import SwiftData

@Model
final class VCenterServer {
    var id: UUID
    var name: String
    var url: String
    var username: String
    var password: String
    var isDefault: Bool
    var createdAt: Date
    
    init(name: String, url: String, username: String, password: String, isDefault: Bool = false) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.username = username
        self.password = password
        self.isDefault = isDefault
        self.createdAt = Date()
    }
}
