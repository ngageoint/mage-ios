//
//  ObservationLocationSummary.swift
//  MAGE
//
//  Created by Dan Barela on 7/17/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI

struct ObservationLocationSummary: View {
    @State private var uiImage: UIImage? = nil
    
    var timestamp: Date?
    var user: String?
    var primaryFieldText: String?
    var secondaryFieldText: String?
    var iconPath: String?
    var error: Bool = false
    var syncing: Bool = false
    
    // we do not want the date to word break so we replace all spaces with a non word breaking spaces
    var timeText: String {
        if let itemDate: NSDate = timestamp as NSDate? {
            return itemDate.formattedDisplay().uppercased().replacingOccurrences(of: " ", with: "\u{00a0}") ;
        }
        return ""
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if error == true {
                ImageTriangle(
                    uiImage: UIImage(
                        systemName: "exclamationmark",
                        withConfiguration:
                            UIImage.SymbolConfiguration(weight:.semibold)
                        )?
                        .withRenderingMode(.alwaysTemplate)
                        .withTintColor(.white),
                    color: .errorColor
                )
            }
            
            if syncing == true {
                ImageTriangle(
                    uiImage: UIImage(
                        systemName: "arrow.triangle.2.circlepath",
                        withConfiguration:
                            UIImage.SymbolConfiguration(weight:.semibold)
                    )?
                        .withRenderingMode(.alwaysTemplate)
                        .withTintColor(.white),
                    color: .secondaryColor
                )
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(user?.uppercased() ?? "") \u{2022} \(timeText)")
                        .overlineText()
                    if let primaryFieldText = primaryFieldText, !primaryFieldText.isEmpty {
                        Text(primaryFieldText)
                            .primaryText()
                    }
                    if let secondaryFieldText = secondaryFieldText, !secondaryFieldText.isEmpty {
                        Text(secondaryFieldText)
                            .secondaryText()
                    }
                    Spacer()
                }
                Spacer()
                Group {
                    if let image = uiImage {
                        Image(uiImage: image)
                            .resizable()
                            .frame(maxWidth: 48, maxHeight: 48)
                    } else {
                        // Placeholder while loading
                        Image(systemName: "photo")
                            .resizable()
                            .frame(maxWidth: 48, maxHeight: 48)
                    }
                }
                .task(id: iconPath) { // Runs when iconPath changes
                    await loadImage()
                }
            }
        }
    }

    @MainActor
    private func loadImage() async {
        guard let path = iconPath else { return }
        let image = await ObservationImageRepositoryImpl.shared.imageAtPath(imagePath: path)
        uiImage = image
    }
}
