//
//  ContentView.swift
//  BudgetBuddy
//
//  Created by user268910 on 1/30/25.
//

import SwiftUI

struct ContentView: View {
    @State private var currentTab: String = "Expenses"
    
    var body: some View {
        TabView(selection: $currentTab) {
            ExpensesView(currentTab: $currentTab)
                .tag("Expenses")
                .tabItem {
                    Image(systemName: "creditcard.fill")
                    Text("Transactions")
                }

            CategoriesView()
                .tag("Categories")
                .tabItem {
                    Image(systemName: "list.clipboard.fill")
                    Text("Categories")
                }

            InsightsView()
                .tag("Insights")
                .tabItem {
                    Image(systemName: "chart.pie.fill")
                    Text("Insights")
                }
        }

    }
}

#Preview {
    ContentView()
}
