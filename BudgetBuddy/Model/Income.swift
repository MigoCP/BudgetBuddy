//
//  Income.swift
//  BudgetBuddy
//
//  Created by english on 2025-03-12.
//

import SwiftUI

struct Income: Identifiable, Transaction {
    let id: UUID
    var title: String
    var subTitle: String
    var amount: Double
    var date: Date
    var category: Category?
    var type: TransactionType = .income
    var source: String
    var isPassive: Bool

    init(
        id: UUID = UUID(),
        title: String,
        subTitle: String,
        amount: Double,
        date: Date,
        category: Category?,
        source: String,
        isPassive: Bool
    ) {
        self.id = id
        self.title = title
        self.subTitle = subTitle
        self.amount = amount
        self.date = date
        self.category = category
        self.source = source
        self.isPassive = isPassive
        self.type = .income
    }
}


