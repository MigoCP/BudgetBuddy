//
//  FirestoreManager.swift
//  BudgetBuddy
//
//  Created by Alena Belova  on 2025-02-19.
//

import Foundation
import FirebaseFirestore

class FirestoreManager {
    let db = Firestore.firestore()

    // Function to add an expense to Firestore
    func addExpense(_ expense: Expense, completion: @escaping (Error?) -> Void) {
        db.collection("expenses").document(expense.id).setData(expense.toDictionary()) { error in
            completion(error)
        }
    }

    // Function to retrieve all expenses from Firestore
    func fetchExpenses(completion: @escaping ([Expense]) -> Void) {
        db.collection("expenses").order(by: "date", descending: true).addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("No documents found")
                completion([])
                return
            }

            let expenses: [Expense] = documents.compactMap { doc -> Expense? in
                let data = doc.data()
                let id = data["id"] as? String ?? UUID().uuidString
                let title = data["title"] as? String ?? ""
                let subTitle = data["subTitle"] as? String ?? ""
                let amount = data["amount"] as? Double ?? 0.0
                let timestamp = data["date"] as? TimeInterval ?? 0
                let date = Date(timeIntervalSince1970: timestamp)
                let category = data["category"] as? String ?? ""

                return Expense(id: id, title: title, subTitle: subTitle, amount: amount, date: date, category: category)
            }

            completion(expenses)
        }
    }
}
