//
//  Category.swift
//  BudgetBuddy
//
//  Created by english on 2025-03-2.
//


import SwiftUI

struct Category: Identifiable, Hashable {
    var id: UUID
    var categoryName: String
    var transactions: [Expense] = []

    init(id: UUID = UUID(), categoryName: String) {
        self.id = id
        self.categoryName = categoryName
    }

    static func == (lhs: Category, rhs: Category) -> Bool {
        return lhs.id == rhs.id && lhs.categoryName == rhs.categoryName
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(categoryName)
    }
}



