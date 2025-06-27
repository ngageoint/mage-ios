//
//  EmailButton.swift
//  MAGE
//
//  Created by Dan Barela on 7/23/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct EmailButton: View {
    var emailAction: UserActions

    var body: some View {
        Button {
            emailAction()
        } label: {
            Label {
                Text("")
            } icon: {
                Image(uiImage: UIImage(systemName: "envelope")!.aspectResize(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate))
            }
        }
    }
}
