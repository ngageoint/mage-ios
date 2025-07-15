//
//  ThemedTextFieldView.swift
//  MAGE
//
//  Created by Brent Michalski on 7/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct ThemedTextFieldView: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let iconSystemName: String
    let scheme: AppContainerScheming?
    
    var body: some View {
        HStack {
            Image(systemName: iconSystemName)
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary, lineWidth: 1)
        )
    }
}

//#Preview {
//    ThemedTextFieldView()
//}
