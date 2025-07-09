//
//  IDPLoginViewSwiftUI.swift
//  MAGE
//
//  Created by Brent Michalski on 7/9/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct IDPLoginViewSwiftUI: View {
    let strategy: LoginStrategy
    weak var delegate: LoginDelegate?
    var scheme: AppContainerScheming

    var body: some View {
        Button("Sign in with IDPLoginViewSwiftUI") {
//            delegate?.idpLoginTapped(strategy)
        }
        .buttonStyle(.bordered)
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.secondarySystemBackground)))
    }
}
 
