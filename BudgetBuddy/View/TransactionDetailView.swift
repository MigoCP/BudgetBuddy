//
//  TransactionDetailView.swift
//  BudgetBuddy
//
//  Created by Alena Belova  on 2025-04-16.
//

import SwiftUI

struct TransactionDetailView: View {
    let expense: Expense

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(expense.title)
                    .font(.largeTitle)
                    .bold()

                Text(expense.subTitle)
                    .font(.title3)
                    .foregroundColor(.gray)

                if let categoryName = expense.category?.categoryName {
                    Text("Category: \(categoryName)")
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }

                Text("Payment Method: \(expense.paymentMethod)")
                Text("Amount: \(expense.currencyString)")
                    .foregroundColor(expense.transactionType == "Income" ? .green : .red)
                    .font(.title2.bold())
            }
            .padding()
        }
        .navigationTitle("Transaction Details")
    }
}


