//
//  AskToDownloadFileView.swift
//  MAGE
//
//  Created by Dan Barela on 8/19/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI

struct AskToDownloadFileView: View {
    
    @EnvironmentObject
    var router: MageRouter
    
    var url: URL
    
    var body: some View {
        VStack {
            Spacer()
            Text("Your attachment fetch settings do not allow auto downloading.  Would you like to download and view the file?")
                .font(.body1)
                .foregroundStyle(Color.onSurfaceColor)
            Button {
                router.appendRoute(FileRoute.downloadFile(url: url))
            } label: {
                Text("View")
            }
            Spacer()
        }
        .padding()
        .background(Color.backgroundColor)
    }
}
