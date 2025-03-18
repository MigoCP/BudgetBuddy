//
//  AddExpenseView.swift
//  BudgetBuddy
//
//  Created by english on 2025-03-5.
//

import SwiftUI

import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var subTitle: String = ""
    @State private var date: Date = .init()
    @State private var amount: Double = 0
    @State private var category: Category?
    @State private var allCategories: [Category] = []
    
    var onAddExpense: (Expense) -> Void // Closure to handle the new expense

    var body: some View {
        NavigationStack {
            List {
                Section("Title") {
                    TextField("Magic Keyboard", text: $title)
                }
                
                Section("Description") {
                    TextField("Bought a keyboard at the Apple Store", text: $subTitle)
                }
                
                Section("Amount Spent") {
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
            }
            .navigationTitle("Add Expense")
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
    
    var isAddButtonDisabled: Bool {
        title.isEmpty || subTitle.isEmpty || amount == .zero
    }
    
    func addExpense() {
        let newExpense = Expense(
            title: title,
            subTitle: subTitle,
            amount: amount,
            date: date,
            category: category,
            paymentMethod: "Cash",
            isRecurring: false
        )
        onAddExpense(newExpense) // Pass the expense back to ExpensesView
        dismiss()
    }
    
    var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }
}
