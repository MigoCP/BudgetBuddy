//
//  ExpenseCardView.swift
//  BudgetBuddy
//
//  Created by Alena Belova  on 2025-03-18.
//
//
//import SwiftUI
//
//struct ExpenseCardView: View {
//    @Bindable var expense: Expense
//    var displayTag: Bool = true
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading) {
//                Text(expense.title)
//                
//                Text(expense.subTitle)
//                    .font(.caption)
//                    .foregroundStyle(.gray)
//                
//                if let categoryName = expense.category?.categoryName, displayTag {
//                    Text(categoryName)
//                        .font(.caption2)
//                        .foregroundStyle(.white)
//                        .padding(.horizontal, 10)
//                        .padding(.vertical, 4)
//                        .background(.red.gradient, in: .capsule)
//                }
//            }
//            .lineLimit(1)
//            
//            Spacer(minLength: 5)
//            
//            /// Currency String
//            Text(expense.currencyString)
//                .font(.title3.bold())
//        }
//    }
//}
//
//#Preview {
//    ExpenseCardView()
//}
