//
//  Item.swift
//  Home Lab
//
//  Created by Dale Hassinger on 2/6/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
