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
    
    @Published
    var fieldTitle: String
    
    var cancellable = Set<AnyCancellable>()
    
    init(observationUri: URL?, observationFormId: String, fieldName: String, fieldTitle: String) {
        self.fieldTitle = fieldTitle
        self.repository.observeAttachments(
            observationUri: observationUri,
            observationFormId: observationFormId,
            fieldName: fieldName
        )?
        .receive(on: DispatchQueue.main)
        .sink { changes in
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
        }
        .store(in: &cancellable)
    }
}

struct AttachmentFieldViewSwiftUI: View {
    @StateObject var viewModel: AttachmentFieldViewModel
    
    var selectedAttachment: (_ attachmentUri: URL) -> Void
    var selectedUnsentAttachment: (_ localPath: String, _ contentType: String) -> Void
    
    let layout = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        if !(viewModel.attachments ?? []).isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.fieldTitle)
                    .secondaryText()
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
                                    .onTapGesture {
                                        selectedAttachment(attachment.attachmentUri)
                                    }
                            }
                        }
                    }
                }
            }
        }
    }
}
