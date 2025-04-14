//
//  CategoriesView.swift
//  BudgetBuddy
//
//  Created by english on 2025-03-12.
//

import SwiftUI
import FirebaseFirestore

struct CategoriesView: View {
    @State private var allCategories: [Category] = []
    @State private var addCategory: Bool = false
    @State private var categoryName: String = ""
    @State private var deleteRequest: Bool = false
    @State private var requestedCategory: Category?
    @State private var showDuplicateAlert: Bool = false

    let db = Firestore.firestore()

    var sortedCategories: [Category] {
        allCategories.sorted { $0.transactions.count > $1.transactions.count }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedCategories) { category in
                    DisclosureGroup {
                        if !category.transactions.isEmpty {
                            ForEach(category.transactions.compactMap { $0 as? Expense }) { expense in
                                TransactionCardView(expense: expense, displayTag: false)
                            }
                        } else {
                            ContentUnavailableView {
                                Label("No Transactions", systemImage: "tray.fill")
                            }
                        }
                    } label: {
                        Text(category.categoryName)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            deleteRequest.toggle()
                            requestedCategory = category
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
            .navigationTitle("Categories")
            .overlay {
                if allCategories.isEmpty {
                    ContentUnavailableView {
                        Label("No Categories", systemImage: "tray.fill")
                    }
                }
            }
            .alert("If you delete a category, all associated transactions will be deleted too.", isPresented: $deleteRequest) {
                Button(role: .destructive) {
                    if let categoryToDelete = requestedCategory {
                        let categoryId = categoryToDelete.id.uuidString

                        // Step 1: Query all expenses with this category ID
                        db.collection("expenses")
                            .whereField("categoryId", isEqualTo: categoryId)
                            .getDocuments { snapshot, error in
                                if let error = error {
                                    print("Error fetching related expenses: \(error.localizedDescription)")
                                    return
                                }

                                let batch = db.batch()

                                // Step 2: Delete related expenses
                                snapshot?.documents.forEach { doc in
                                    batch.deleteDocument(doc.reference)
                                }

                                // Step 3: Delete the category
                                let categoryRef = db.collection("categories").document(categoryId)
                                batch.deleteDocument(categoryRef)

                                // Step 4: Commit the batch
                                batch.commit { error in
                                    if let error = error {
                                        print("Batch delete failed: \(error.localizedDescription)")
                                    } else {
                                        print("Category and associated expenses deleted")
                                        fetchCategories()
                                    }
                                }
                            }

                        self.requestedCategory = nil
                    }
                } label: {
                    Text("Delete")
                }

                Button(role: .cancel) {
                    requestedCategory = nil
                } label: {
                    Text("Cancel")
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addCategory.toggle()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $addCategory) {
                NavigationStack {
                    List {
                        Section("Title") {
                            TextField("General", text: $categoryName)
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { addCategory = false }
                                .tint(.red)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Add") {
                                let trimmedName = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                                if allCategories.contains(where: { $0.categoryName.lowercased() == trimmedName.lowercased() }) {
                                    showDuplicateAlert = true
                                } else {
                                    let category = Category(categoryName: trimmedName)
                                    saveCategoryToFirestore(category)
                                    fetchCategories()
                                    categoryName = ""
                                    addCategory = false
                                }
                            }
                            .disabled(categoryName.isEmpty)
                        }
                    }
                }
                .presentationDetents([.height(180)])
                .presentationCornerRadius(20)
                .interactiveDismissDisabled()
            }
            .alert("Duplicate Category", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("A category with this name already exists.")
            }
            .onAppear {
                fetchCategories()

                // 👂 Listen for expense updates
                NotificationCenter.default.addObserver(forName: Notification.Name("ExpenseDataChanged"), object: nil, queue: .main) { _ in
                    fetchCategories()
                }
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(self, name: Notification.Name("ExpenseDataChanged"), object: nil)
            }
        }
    }

    func saveCategoryToFirestore(_ category: Category) {
        let categoryData: [String: Any] = [
            "id": category.id.uuidString,
            "categoryName": category.categoryName
        ]
        db.collection("categories").document(category.id.uuidString).setData(categoryData)
    }

    func fetchCategories() {
        db.collection("categories").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching categories: \(error)")
                return
            }

            guard let documents = snapshot?.documents else { return }

            var fetchedCategories: [Category] = documents.map { doc in
                let data = doc.data()
                return Category(
                    id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
                    categoryName: data["categoryName"] as? String ?? "Unknown"
                )
            }

            db.collection("expenses").getDocuments { expenseSnapshot, error in
                if let error = error {
                    print("Error fetching expenses: \(error)")
                    return
                }

                guard let expenseDocs = expenseSnapshot?.documents else { return }

                let expenses: [Expense] = expenseDocs.compactMap { doc in
                    let data = doc.data()
                    guard
                        let title = data["title"] as? String,
                        let amount = data["amount"] as? Double,
                        let categoryId = data["categoryId"] as? String,
                        let idStr = data["id"] as? String
                    else { return nil }

                    guard let category = fetchedCategories.first(where: { $0.id.uuidString == categoryId }) else {
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

                for expense in expenses {
                    if let cat = expense.category,
                       let index = fetchedCategories.firstIndex(where: { $0.id == cat.id }) {
                        fetchedCategories[index].transactions.append(expense)
                    }
                }

                self.allCategories = fetchedCategories
            }
        }
    }
}

#Preview {
    CategoriesView()
}

