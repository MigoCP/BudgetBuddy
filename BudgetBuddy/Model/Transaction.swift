//
//  Transaction.swift
//  BudgetBuddy
//
//  Created by english on 2025-03-12.
//

import SwiftUI

enum TransactionType: String, Codable {
    case expense = "EXPENSE"
    case income = "INCOME"
}

protocol Transaction: Identifiable {
    var id: UUID { get }
    var title: String { get set }
    var subTitle: String { get set }
    var amount: Double { get set }
    var date: Date { get set }
    var category: Category? { get set }
    var type: TransactionType { get set }
}

extension Transaction {
    var currencyString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    func getSummary() -> String {
        let summary: [String: Any] = [
            "title": title,
            "subTitle": subTitle,
            "amount": amount,
            "date": date,
            "category": category?.categoryName ?? "None",
            "type": type.rawValue
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: summary, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return "{}"
    }

    func isValid() -> Bool {
        return !title.isEmpty && amount > 0
    }
}

