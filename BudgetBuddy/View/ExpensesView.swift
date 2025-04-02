//
//  ExpensesView.swift
//  BudgetBuddy
//
//  Created by english on 2025-03-5.
//

import SwiftUI

import SwiftUI

struct ExpensesView: View {
    @Binding var currentTab: String

    @State private var allExpenses: [Expense] = []
    @State private var groupedExpenses: [GroupedTransaction] = []
    @State private var originalGroupedExpenses: [GroupedTransaction] = []
    @State private var addExpense: Bool = false
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedExpenses, id: \.date) { group in
                    ExpenseSection(group: group, deleteExpense: deleteExpense)
                }
            }
            .navigationTitle("Transactions")
            .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: Text("Search"))
            .overlay {
                if allExpenses.isEmpty || groupedExpenses.isEmpty {
                    ContentUnavailableView {
                        Label("No transactioins", systemImage: "tray.fill")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addExpense.toggle()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
        }
        .onChange(of: searchText) { newValue in
            if newValue.isEmpty {
                groupedExpenses = originalGroupedExpenses
            } else {
                filterExpenses(newValue)
            }
        }
        .onChange(of: allExpenses) { newValue in
            if newValue.count != groupedExpenses.flatMap({ $0.transactions }).count || groupedExpenses.isEmpty || currentTab == "Categories" {
                createGroupedExpenses(from: newValue)
            }
        }
        .sheet(isPresented: $addExpense) {
            AddExpenseView { newExpense in
                allExpenses.append(newExpense) // Append expense and update the UI
            }
            .interactiveDismissDisabled()
        }
    }

    /// Deletes an expense and updates the grouped list
    func deleteExpense(_ expense: Expense, from group: GroupedTransaction) {
        if let index = groupedExpenses.firstIndex(where: { $0.date == group.date }) {
            groupedExpenses[index].transactions.removeAll { $0.id == expense.id }
            groupedExpenses.removeAll { $0.transactions.isEmpty }
        }
    }

    /// Filters expenses based on search text
    func filterExpenses(_ text: String) {
        let query = text.lowercased()
        groupedExpenses = originalGroupedExpenses.compactMap { group in
            let filteredExpenses = group.transactions.filter { $0.title.lowercased().contains(query) }
            return filteredExpenses.isEmpty ? nil : GroupedTransaction(date: group.date, transactions: filteredExpenses)
        }
    }

    /// Groups expenses by date
    func createGroupedExpenses(from expenses: [Expense]) {
        let groupedDict = Dictionary(grouping: expenses) { Calendar.current.startOfDay(for: $0.date) }
        let sortedDict = groupedDict.sorted { $0.key > $1.key }
        groupedExpenses = sortedDict.map { GroupedTransaction(date: $0.key, transactions: $0.value) }
        originalGroupedExpenses = groupedExpenses
    }
}

/// Extracted section to improve SwiftUI performance
struct ExpenseSection: View {
    let group: GroupedTransaction
    let deleteExpense: (Expense, GroupedTransaction) -> Void
    
    var body: some View {
        Section(header: Text(group.getGroupTitle())) {
            ForEach(group.transactions, id: \.id) { expense in
                TransactionCardView(expense: expense)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            deleteExpense(expense, group)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(.red)
                    }
            }
        }
    }
}

#Preview {
    ExpensesView(currentTab: .constant("Transactions"))
}
