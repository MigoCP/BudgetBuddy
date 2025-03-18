//
//  Category.swift
//  BudgetBuddy
//
//  Created by english on 2025-03-2.
//


import SwiftUI

struct Category: Identifiable, Hashable {
    let id = UUID()
    var categoryName: String
    var transactions: [Expense] = [] // Use a concrete type

    static func == (lhs: Category, rhs: Category) -> Bool {
        return lhs.id == rhs.id && lhs.categoryName == rhs.categoryName
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(categoryName)
    }
}



