//
//  DownloadingFileView.swift
//  MAGE
//
//  Created by Dan Barela on 8/19/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI

struct DownloadingFileView: View {
    @ObservedObject
    var viewModel: DownloadingFileViewModel
    
    var bcf: ByteCountFormatter {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useAll]
        bcf.countStyle = .file
        return bcf
    }
    
    var body: some View {
        VStack {
            Spacer()
            if let error = viewModel.error {
                Text("Error Downloading: \(error)")
                    .foregroundColor(Color.errorColor)
                    .primaryText()
            } else {
                Text("Downloading")
                    .primaryText()
            }
            ProgressView(value: (Float(viewModel.receivedSize) / Float(viewModel.totalSize)))
                .tint(Color.primaryColor)
            Text("Downloaded \(bcf.string(fromByteCount: viewModel.receivedSize)) of \(bcf.string(fromByteCount: viewModel.totalSize))")
                .secondaryText()
            Spacer()
        }
        .padding()
        .background(Color.backgroundColor)
    }
}
