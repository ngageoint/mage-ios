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

enum TimeUnitWrapper: String, CaseIterable, Identifiable {
    case hours = "Hours"
    case days = "Days"
    case months = "Months"

    var id: Self { self }

    var objcValue: TimeUnit {
        switch self {
        case .hours: return .Hours
        case .days: return .Days
        case .months: return .Months
        }
    }

    init(objcValue: TimeUnit) {
        switch objcValue {
        case .Hours: self = .hours
        case .Days: self = .days
        case .Months: self = .months
        default: self = .hours
        }
    }
}


struct TimeFilterView: View {
    let title: String
    let subTitle: String
    let timeFilter: TimeFilterEnum
    @Binding var customTimeFieldValue: Int
    @Binding var customTimePickerEnum: TimeUnitWrapper
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
            .onTapGesture {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                    isSelected = true
                }
            }
            
            if timeFilter == .custom && isSelected {
                CustomTimeView(customTimeFieldValue: $customTimeFieldValue, customTimePickerValue: $customTimePickerEnum
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: isSelected)
    }
}

struct CustomTimeView: View {
    @Binding var customTimeFieldValue: Int
    @Binding var customTimePickerValue: TimeUnitWrapper
    var body: some View {
        HStack {
            Text("Last")
            TextField("", value: $customTimeFieldValue, format: .number)
            Picker("", selection: $customTimePickerValue) {
                ForEach(TimeUnitWrapper.allCases, id: \.self) {
                    Text($0.rawValue)
                        .minimumScaleFactor(0.5)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.top, 4)
        .contentTransition(.opacity)
    }
}

#Preview {
    TimeFilterView(title: "All", subTitle: "Do not filter based on time", timeFilter: .custom, customTimeFieldValue: .constant(0), customTimePickerEnum: .constant(.days), isSelected: .constant(false))
}

