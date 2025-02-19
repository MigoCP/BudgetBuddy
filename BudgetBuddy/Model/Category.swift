//
//  Category.swift
//  BudgetBuddy
//
//  Created by Alena Belova  on 2025-02-19.
//

import Foundation

import SwiftUI
import SwiftData

@Model
class Category {
    var categoryName: String
    // Category Expenses
    @Relationship(deleteRule: .cascade, inverse: \Expense.category)
    var expenses: [Expense]?
    
    init(categoryName: String) {
        self.categoryName = categoryName
    }
}
