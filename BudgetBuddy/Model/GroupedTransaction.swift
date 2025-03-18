//
//  GroupedTransaction.swift
//  BudgetBuddy
//
//  Created by english on 2025-03-12.
//

import SwiftUI

struct GroupedTransaction: Identifiable {
    let id = UUID()
    var date: Date
    var transactions: [Expense] // Use a concrete type instead of `any Transaction`

    func getGroupTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}


