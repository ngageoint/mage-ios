//
//  AttachmentFieldViewSwiftUI.swift
//  MAGE
//
//  Created by Dan Barela on 7/31/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import Kingfisher

class AttachmentFieldViewModel: ObservableObject {
    @Injected(\.attachmentRepository)
    var repository: AttachmentRepository
    
    @Published
    var attachments: [AttachmentModel]?
    
    init(observationUri: URL?, observationFormId: String, fieldName: String) {
        Task {
            let attachments = await repository.getAttachments(observationUri: observationUri, observationFormId: observationFormId, fieldName: fieldName)
            await MainActor.run {
                self.attachments = attachments
            }
        }
    }
}

struct AttachmentFieldViewSwiftUI: View {
    @StateObject var viewModel: AttachmentFieldViewModel
    
    let layout = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns:layout) {
            ForEach(viewModel.attachments ?? []) { attachment in
                VStack{
                    if let url = URL(string: attachment.url ?? "") {
                        KFImage(url)
                            .requestModifier(ImageCacheProvider.shared.accessTokenModifier)
                            .forceRefresh()
                            .cacheOriginalImage()
                            .onlyFromCache(DataConnectionUtilities.shouldFetchAttachments())
                            .placeholder {
                                Image("observations")
                                    .symbolRenderingMode(.monochrome)
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
                            }
                        
                            .fade(duration: 0.3)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: 150)
                            .clipShape(RoundedRectangle(cornerSize: CGSizeMake(5, 5)))
                    }
                }
            }
        }
    }
}
