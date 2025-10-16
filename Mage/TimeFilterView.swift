//
//  TimeFilterView.swift
//  MAGE
//
//  Created by James McDougall on 10/14/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

enum TimeFilterEnum: String, CaseIterable, Identifiable {
    case all, today, last24Hours, lastWeek, lastMonth, custom
    var id: Self { self }
    
    var title: String {
        switch self {
        case .all: return "All"
        case .today: return "Today"
        case .last24Hours: return "24 Hours"
        case .lastWeek: return "Last Week"
        case .lastMonth: return "Last Month"
        case .custom: return "Custom"
        }
    }
    
    var subtitle: String {
        switch self {
        case .all: return "Do not filter observations by time"
        case .today: return "Show today's observations"
        case .last24Hours: return "Show observations for the last 24 hours"
        case .lastWeek: return "Show observations for last week"
        case .lastMonth: return "Show observations for the last month"
        case .custom: return "Define a custom rolling window"
        }
    }
}

extension TimeFilterEnum {
    init(objc: TimeFilterType) {
        switch objc {
        case .all:        self = .all
        case .today:      self = .today
        case .last24Hours:self = .last24Hours
        case .lastWeek:   self = .lastWeek
        case .lastMonth:  self = .lastMonth
        case .custom:     self = .custom
        @unknown default: self = .all
        }
    }

    var objc: TimeFilterType {
        switch self {
        case .all:         return .all
        case .today:       return .today
        case .last24Hours: return .last24Hours
        case .lastWeek:    return .lastWeek
        case .lastMonth:   return .lastMonth
        case .custom:      return .custom
        }
    }
}


struct TimeFilterView: View {
    let title: String
    let subTitle: String
    @Binding var isSelected: Bool
    
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                    Text(subTitle)
                        .font(.body2)
                        .foregroundStyle(.gray)
                }
                Spacer()
                if isSelected { Image(systemName: "checkmark") }
            }
            .contentShape(Rectangle())
            .onTapGesture { isSelected = true }
            
            
        }
    }
}

#Preview {
    TimeFilterView(title: "All", subTitle: "Do not filter based on time", isSelected: .constant(false))
}
