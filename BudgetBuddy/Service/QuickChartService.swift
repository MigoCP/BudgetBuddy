//
//  QuickChartService.swift
//  BudgetBuddy
//
//  Created by user268910 on 4/13/25.
//

import Foundation
import SwiftUI

class QuickChartService {
    static func generateChartURL(from config: [String: Any]) -> URL? {
        guard let data = try? JSONSerialization.data(withJSONObject: config, options: []),
              let jsonString = String(data: data, encoding: .utf8) else { return nil }

        let encodedConfig = jsonString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://quickchart.io/chart?c=\(encodedConfig)"
        return URL(string: urlString)
    }
}
