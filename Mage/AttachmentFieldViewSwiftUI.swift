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
import Combine

class AttachmentFieldViewModel: ObservableObject {
    @Injected(\.attachmentRepository)
    var repository: AttachmentRepository
    
    @Published
    var attachments: [AttachmentModel]?
    
    var cancellable = Set<AnyCancellable>()
    
    init(observationUri: URL?, observationFormId: String, fieldName: String) {
//        Task {
//            let attachments = await repository.getAttachments(observationUri: observationUri, observationFormId: observationFormId, fieldName: fieldName)
//            await MainActor.run {
//                self.attachments = attachments
//            }
//        }
        
        self.repository.observeAttachments(
            observationUri: observationUri,
            observationFormId: observationFormId,
            fieldName: fieldName
        )?
            .receive(on: DispatchQueue.main)
//        .dropFirst()
        .sink { changes in
//            Task {
                var attachments: [AttachmentModel] = []
                for change in changes {
                    switch (change) {
                    case .insert(offset: _, element: let element, associatedWith: _):
                        attachments.append(element)
                    case .remove(offset: _, element: let element, associatedWith: _):
                        attachments.removeAll { model in
                            model.attachmentUri == element.attachmentUri
                        }
                    }
                }
                self.attachments = attachments
//            }
        }
        .store(in: &cancellable)
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
