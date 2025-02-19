//
//  Expense.swift
//  BudgetBuddy
//
//  Created by Alena Belova  on 2025-02-19.
//

import Foundation
import SwiftUI
import SwiftData

struct Expense: Identifiable, Codable {
    var id: String = UUID().uuidString // Unique Firestore ID
    var title: String
    var subTitle: String
    var amount: Double
    var date: Date
    var category: String // Store category as a string for Firestore compatibility

    // Convert Date to Timestamp for Firestore
    var timestamp: TimeInterval {
        return date.timeIntervalSince1970
    }

    // Convert to dictionary for Firestore
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "subTitle": subTitle,
            "amount": amount,
            "date": timestamp,
            "category": category
        ]
    }
}
