//
//  InsightsView.swift
//  BudgetBuddy
//
//  Created by user268910 on 4/13/25.
//

import SwiftUI
import FirebaseFirestore

struct InsightsView: View {
    @State private var chartURLs: [URL?] = []
    @State private var allExpenses: [Expense] = []
    @State private var allIncomes: [Income] = []

    let db = Firestore.firestore()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    ForEach(chartURLs.indices, id: \.self) { index in
                        if let url = chartURLs[index] {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .cornerRadius(12)
                                        .padding()
                                case .failure:
                                    Text("Failed to load chart.")
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Insights")
            .onAppear {
                fetchData()
            }
        }
    }

    func fetchData() {
        // Fetch EXPENSES
        db.collection("expenses").getDocuments { snapshot, error in
            guard let docs = snapshot?.documents else { return }

            let expenses: [Expense] = docs.compactMap { doc in
                let data = doc.data()

                guard
                    (data["transactionType"] as? String)?.lowercased() != "income",
                    let title = data["title"] as? String,
                    let amount = data["amount"] as? Double,
                    let categoryName = data["categoryName"] as? String,
                    let idStr = data["id"] as? String
                else { return nil }

                let category = Category(categoryName: categoryName)
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


            self.allExpenses = expenses
            fetchIncomes() // Next: incomes
        }
    }

    func fetchIncomes() {
        db.collection("incomes").getDocuments { snapshot, error in
            guard let docs = snapshot?.documents else {
                // even if no incomes, still proceed
                generateChartURLs()
                return
            }

            let incomes: [Income] = docs.compactMap { doc in
                let data = doc.data()
                guard
                    let title = data["title"] as? String,
                    let amount = data["amount"] as? Double,
                    let idStr = data["id"] as? String
                else { return nil }

                let category = Category(categoryName: data["categoryName"] as? String ?? "")
                return Income(
                    id: UUID(uuidString: idStr) ?? UUID(),
                    title: title,
                    subTitle: data["subTitle"] as? String ?? "",
                    amount: amount,
                    date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                    category: category,
                    source: data["source"] as? String ?? "",
                    isPassive: data["isPassive"] as? Bool ?? false
                )
            }

            self.allIncomes = incomes
            generateChartURLs()
        }
    }

    func generateChartURLs() {
        chartURLs = [
            QuickChartService.generateChartURL(from: generatePieChartData()),
            QuickChartService.generateChartURL(from: generateLineChartData()),
            QuickChartService.generateChartURL(from: generateBarChartData())
        ]
    }

    // ✅ PIE: Expense by Category
    func generatePieChartData() -> [String: Any] {
        let grouped = Dictionary(grouping: allExpenses) { $0.category?.categoryName ?? "Uncategorized" }
        let labels = Array(grouped.keys)
        let data = labels.map { label in
            grouped[label]?.reduce(0.0, { $0 + $1.amount }) ?? 0.0
        }

        return [
            "type": "pie",
            "data": [
                "labels": labels,
                "datasets": [[
                    "data": data
                ]]
            ],
            "options": [
                "plugins": [
                    "title": ["display": true, "text": "Expenses by Category"]
                ]
            ]
        ]
    }

    // ✅ LINE: Income vs Expense by Month
    func generateLineChartData() -> [String: Any] {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        let incomeData = months.map { month in
            allIncomes.filter { formatter.string(from: $0.date) == month }
                .reduce(0.0, { $0 + $1.amount })
        }

        let expenseData = months.map { month in
            allExpenses.filter { formatter.string(from: $0.date) == month }
                .reduce(0.0, { $0 + $1.amount })
        }

        return [
            "type": "line",
            "data": [
                "labels": months,
                "datasets": [
                    [
                        "label": "Income",
                        "data": incomeData,
                        "borderColor": "green",
                        "fill": false
                    ],
                    [
                        "label": "Expenses",
                        "data": expenseData,
                        "borderColor": "red",
                        "fill": false
                    ]
                ]
            ],
            "options": [
                "plugins": [
                    "title": ["display": true, "text": "Income vs Expenses"]
                ]
            ]
        ]
    }

    // ✅ BAR: Monthly Expenses
    func generateBarChartData() -> [String: Any] {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        let data = months.map { month in
            allExpenses.filter { formatter.string(from: $0.date) == month }
                .reduce(0.0, { $0 + $1.amount })
        }

        return [
            "type": "bar",
            "data": [
                "labels": months,
                "datasets": [[
                    "label": "Monthly Expenses",
                    "data": data,
                    "backgroundColor": "rgba(255,99,132,0.8)"
                ]]
            ],
            "options": [
                "plugins": [
                    "title": ["display": true, "text": "Monthly Expenses"]
                ]
            ]
        ]
    }
}



#Preview {
    InsightsView()
}
