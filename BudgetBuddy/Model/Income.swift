//
//  Income.swift
//  BudgetBuddy
//
//  Created by english on 2025-03-12.
//

import SwiftUI

struct Income: Identifiable, Transaction {
    let id = UUID()
    var title: String
    var subTitle: String
    var amount: Double
    var date: Date
    var category: Category?
    var type: TransactionType = .income
    var source: String
    var isPassive: Bool

    func calculateTaxes() -> [Double] {
        return []
    }
}

