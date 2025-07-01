//
//  EmptyStateList.swift
//  MAGE
//
//  Created by Brent Michalski on 6/30/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

public struct EmptyStateList<Data: RandomAccessCollection, RowContent: View, Placeholder: View>: View
where Data.Element: Identifiable {
    let data: Data
    let rowContent: (Data.Element) -> RowContent
    let placeholder: () -> Placeholder

    public init(
        data: Data,
        @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.data = data
        self.rowContent = rowContent
        self.placeholder = placeholder
    }

    public var body: some View {
        if data.isEmpty {
            placeholder()
        } else {
            List {
                ForEach(data) { element in
                    rowContent(element)
                }
            }
        }
    }
}
