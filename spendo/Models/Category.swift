//
//  Category.swift
//  Spendo
//

import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String
    var iconName: String
    var type: TransactionType
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        type: TransactionType
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.type = type
        self.createdAt = Date()
    }
}
