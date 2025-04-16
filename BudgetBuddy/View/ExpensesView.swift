//
//  ExpensesView.swift
//  BudgetBuddy
//
//  Created by english on 2025-03-5.
//

import SwiftUI
import FirebaseFirestore

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
                        Label("No transactions", systemImage: "tray.fill")
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
        .onAppear {
            if allExpenses.isEmpty {
                fetchExpenses()
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
                allExpenses.append(newExpense)
                fetchExpenses()
            }
            .interactiveDismissDisabled()
        }
    }

    func fetchExpenses() {
        let db = Firestore.firestore()
        db.collection("expenses").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching expenses: \(error)")
                return
            }

            guard let documents = snapshot?.documents else { return }

            let fetchedExpenses: [Expense] = documents.compactMap { doc in
                let data = doc.data()
                guard
                    let title = data["title"] as? String,
                    let amount = data["amount"] as? Double,
                    let categoryId = data["categoryId"] as? String
                else { return nil }

                let id = UUID(uuidString: data["id"] as? String ?? "") ?? UUID()

                let category = Category(
                    id: UUID(uuidString: categoryId) ?? UUID(),
                    categoryName: data["categoryName"] as? String ?? "Unknown"
                )

                return Expense(
                    id: id,
                    title: title,
                    subTitle: data["subTitle"] as? String ?? "",
                    amount: amount,
                    date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                    category: category,
                    paymentMethod: data["paymentMethod"] as? String ?? "",
                    isRecurring: data["isRecurring"] as? Bool ?? false,
                    transactionType: data["transactionType"] as? String ?? "expense"
                )
            }


            self.allExpenses = fetchedExpenses
            createGroupedExpenses(from: fetchedExpenses)
        }
    }

    func deleteExpense(_ expense: Expense, from group: GroupedTransaction) {
        let db = Firestore.firestore()

        db.collection("expenses").document(expense.id.uuidString).delete { error in
            if let error = error {
                print("Error deleting expense from Firestore: \(error.localizedDescription)")
                return
            }

            if let index = groupedExpenses.firstIndex(where: { $0.date == group.date }) {
                groupedExpenses[index].transactions.removeAll { $0.id == expense.id }
                if groupedExpenses[index].transactions.isEmpty {
                    groupedExpenses.remove(at: index)
                }
            }

            allExpenses.removeAll { $0.id == expense.id }

            // ✅ Notify Category View
            NotificationCenter.default.post(name: Notification.Name("ExpenseDataChanged"), object: nil)
        }
    }



    func refreshCategoriesAfterDeletion() {
        let db = Firestore.firestore()

        db.collection("categories").getDocuments { snapshot, error in
            if let error = error {
                print("Error refreshing categories: \(error)")
                return
            }

            guard let categoryDocs = snapshot?.documents else { return }

            var refreshedCategories: [Category] = categoryDocs.map { doc in
                let data = doc.data()
                return Category(
                    id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
                    categoryName: data["categoryName"] as? String ?? "Unknown"
                )
            }

            db.collection("expenses").getDocuments { snapshot, error in
                if let error = error {
                    print("Error refreshing expenses for categories: \(error)")
                    return
                }

                guard let expenseDocs = snapshot?.documents else { return }

                let refreshedExpenses: [Expense] = expenseDocs.compactMap { doc in
                    let data = doc.data()
                    guard
                        let idStr = data["id"] as? String,
                        let title = data["title"] as? String,
                        let amount = data["amount"] as? Double,
                        let categoryId = data["categoryId"] as? String
                    else { return nil }

                    guard let category = refreshedCategories.first(where: { $0.id.uuidString == categoryId }) else {
                        return nil
                    }

                    return Expense(
                        id: UUID(uuidString: idStr) ?? UUID(),
                        title: title,
                        subTitle: data["subTitle"] as? String ?? "",
                        amount: amount,
                        date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                        category: category,
                        paymentMethod: data["paymentMethod"] as? String ?? "",
                        isRecurring: data["isRecurring"] as? Bool ?? false,
                        transactionType: data["transactionType"] as? String ?? "expense"
                    )
                }

                for expense in refreshedExpenses {
                    if let cat = expense.category,
                       let index = refreshedCategories.firstIndex(where: { $0.id == cat.id }) {
                        refreshedCategories[index].transactions.append(expense)
                    }
                }

                // 👇 Push to CategoriesView using NotificationCenter (temp solution)
                NotificationCenter.default.post(name: NSNotification.Name("RefreshCategoriesView"), object: refreshedCategories)
            }
        }
    }

    
    func filterExpenses(_ text: String) {
        let query = text.lowercased()
        groupedExpenses = originalGroupedExpenses.compactMap { group in
            let filteredExpenses = group.transactions.filter { $0.title.lowercased().contains(query) }
            return filteredExpenses.isEmpty ? nil : GroupedTransaction(date: group.date, transactions: filteredExpenses)
        }
    }

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
                NavigationLink(destination: TransactionDetailView(expense: expense)) {
                    TransactionCardView(expense: expense)
                }
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
