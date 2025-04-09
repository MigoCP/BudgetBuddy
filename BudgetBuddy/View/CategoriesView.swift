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
                                        if let requestedCategory {
                                            allCategories.removeAll { $0.id == requestedCategory.id }
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
                                allCategories.sort { $0.transactions.count > $1.transactions.count }
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
            if let documents = snapshot?.documents {
                self.allCategories = documents.map { doc in
                    let data = doc.data()
                    return Category(
                        categoryName: data["categoryName"] as? String ?? "Unknown"
                    )
                }
            }
        }
    }
}

#Preview {
    CategoriesView()
}
 
