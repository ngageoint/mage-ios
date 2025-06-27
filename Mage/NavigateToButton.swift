//
//  NavigateToButton.swift
//  MAGE
//
//  Created by Dan Barela on 7/19/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct NavigateToButton: View {
    var navigateToAction: CoordinateActions

    var body: some View {
        Button {
            navigateToAction()
        } label: {
            Label {
                Text("")
            } icon: {
                Image(uiImage: UIImage(systemName: "arrow.triangle.turn.up.right.diamond", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))!.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate))
            }
            
        }
    }
}
