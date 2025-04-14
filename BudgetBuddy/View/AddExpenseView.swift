//
//  AddExpenseView.swift
//  BudgetBuddy
//
//  Created by english on 2025-03-5.
//

import SwiftUI
import FirebaseFirestore

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var transactionType: String? = "Expense"
    let transactionTypes = ["Expense", "Income"]
    @State private var title: String = ""
    @State private var subTitle: String = ""
    @State private var date: Date = .init()
    @State private var amount: Double = 0
    @State private var category: Category?
    @State private var allCategories: [Category] = []

    let db = Firestore.firestore()

    var onAddExpense: (Expense) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Title") {
                    TextField("Magic Keyboard", text: $title)
                }

                Section("Description") {
                    TextField("Bought a keyboard at the Apple Store", text: $subTitle)
                }

                Section("Amount") {
                    TextField("0.0", value: $amount, formatter: formatter)
                        .keyboardType(.decimalPad)
                }

                Section("Date") {
                    DatePicker("", selection: $date, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                }

                if !allCategories.isEmpty {
                    Picker("Category", selection: $category) {
                        Text("None").tag(nil as Category?)
                        ForEach(allCategories) { category in
                            Text(category.categoryName).tag(category as Category?)
                        }
                    }
                }
                Section("Transaction Type") {
                    Picker("Type", selection: $transactionType) {
                        ForEach(transactionTypes, id: \.self) { type in
                            Text(type).tag(type as String?)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .onAppear {
                fetchCategories()
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .tint(.red)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", action: addExpense)
                        .disabled(isAddButtonDisabled)
                }
            }
        }
    }

    func fetchCategories() {
        db.collection("categories").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching categories: \(error)")
                return
            }
            if let documents = snapshot?.documents {
                self.allCategories = documents.map { doc in
                    let data = doc.data()
                    return Category(
                        id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
                        categoryName: data["categoryName"] as? String ?? "Unknown"
                    )
                }
            }
        }
    }

    func addExpense() {
        let newExpense = Expense(
            title: title,
            subTitle: subTitle,
            amount: amount,
            date: date,
            category: category,
            paymentMethod: "Cash",
            isRecurring: false,
            transactionType: transactionType ?? "Expense"
        )

        let expenseData: [String: Any] = [
            "id": newExpense.id.uuidString,
            "title": newExpense.title,
            "subTitle": newExpense.subTitle,
            "amount": newExpense.amount,
            "date": Timestamp(date: newExpense.date),
            "paymentMethod": newExpense.paymentMethod,
            "isRecurring": newExpense.isRecurring,
            "type": newExpense.type.rawValue,
            "transactionType": newExpense.transactionType,
            "categoryName": newExpense.category?.categoryName ?? "Uncategorized",
            "categoryId": newExpense.category?.id.uuidString ?? ""
        ]

        db.collection("expenses").document(newExpense.id.uuidString).setData(expenseData) { error in
            if let error = error {
                print("Error saving expense: \(error)")
                return
            }

            onAddExpense(newExpense)
            NotificationCenter.default.post(name: Notification.Name("ExpenseDataChanged"), object: nil)
            dismiss()

        }
    }


    var isAddButtonDisabled: Bool {
        title.isEmpty || subTitle.isEmpty || amount == .zero
    }

    var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }
}
