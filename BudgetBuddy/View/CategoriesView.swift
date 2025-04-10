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
                        db.collection("categories").document(categoryToDelete.id.uuidString).delete { error in
                            if let error = error {
                                print("Error deleting category: \(error.localizedDescription)")
                            } else {
                                allCategories.removeAll { $0.id == categoryToDelete.id }
                                print("Category successfully deleted")
                            }
                        }
                        self.requestedCategory = nil
                    }
                } label: {
                    Text("Delete")
                }
                Button(role: .cancel) { requestedCategory = nil } label: {
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
                                let category = Category(categoryName: categoryName)
                                saveCategoryToFirestore(category)
                                allCategories.append(category)
                                allCategories.sort { $0.transactions.count > $1.transactions.count}
                                categoryName = ""
                                addCategory = false
                            }
                            .disabled(categoryName.isEmpty)
                        }
                    }
                }
                .presentationDetents([.height(180)])
                .presentationCornerRadius(20)
                .interactiveDismissDisabled()
            }
            .onAppear {
                fetchCategories()
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

            // Fetch expenses
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
                        let categoryId = data["categoryId"] as? String
                    else { return nil }
                    
                    let category = fetchedCategories.first { $0.id.uuidString == categoryId }
                    
                    return Expense(
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
                    if let category = expense.category,
                       let index = fetchedCategories.firstIndex(where: { $0.id == category.id }) {
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

