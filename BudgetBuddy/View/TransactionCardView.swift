//
//  ExpenseCardView.swift
//  BudgetBuddy
//
//  Created by english on 2025-03-5.
//

import SwiftUI

struct TransactionCardView: View {
    let expense: Expense
    var displayTag: Bool = true

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(expense.title)
                Text(expense.subTitle)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if let categoryName = expense.category?.categoryName, displayTag {
                    Text(categoryName)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.red.gradient, in: .capsule)
                }
            }
            .lineLimit(1)
            
            Spacer(minLength: 5)
            
            Text(expense.currencyString)
                .font(.title3.bold())
                .foregroundColor(expense.transactionType == "Income" ? .green : .red)
        }
    }
}


