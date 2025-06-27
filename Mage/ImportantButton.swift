//
//  ImportantButton.swift
//  MAGE
//
//  Created by Dan Barela on 7/30/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct ImportantButton: View {
    var importantAction: () -> Void
    var isImportant: Bool = false
    
    var body: some View {
        Button {
            importantAction()
        } label: {
            Label {
                Text("")
            } icon: {
                if isImportant {
                    Image(
                        uiImage: UIImage(
                            systemName: "flag.fill",
                            withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))!
                            .aspectResize(to: CGSize(width: 24, height: 24))
                            .withRenderingMode(.alwaysTemplate)
                    )
                } else {
                    Image(
                        uiImage: UIImage(
                            systemName: "flag",
                            withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))!
                            .aspectResize(to: CGSize(width: 24, height: 24))
                            .withRenderingMode(.alwaysTemplate)
                    )
                }
            }
            
        }
        .transformEffect(.identity)
    }
}
