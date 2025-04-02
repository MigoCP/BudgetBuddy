//
//  Expense.swift
//  BudgetBuddy
//
//  Created by english on 2025-03-2.
//

import SwiftUI

struct Expense: Identifiable, Transaction, Equatable {
    let id = UUID()
    var title: String
    var subTitle: String
    var amount: Double
    var date: Date
    var category: Category?
    var type: TransactionType = .expense
    var paymentMethod: String
    var isRecurring: Bool
    var transactionType: String

    func isEssential() -> Bool {
        return false
    }

    // Add Equatable conformance
    static func == (lhs: Expense, rhs: Expense) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.subTitle == rhs.subTitle &&
               lhs.amount == rhs.amount &&
               lhs.date == rhs.date &&
               lhs.category == rhs.category &&
               lhs.type == rhs.type &&
               lhs.paymentMethod == rhs.paymentMethod &&
               lhs.isRecurring == rhs.isRecurring
    }
}


