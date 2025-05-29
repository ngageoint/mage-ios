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
    
    func appendAttachmentViewRoute(router: MageRouter, attachment: AttachmentModel) {
        repository.appendAttachmentViewRoute(router: router, attachment: attachment)
    }
    
    var orderedAttachments: [AttachmentModel]? {
        return attachments?.sorted(by: { first, second in
            let firstOrder = first.order.intValue
            let secondOrder = second.order.intValue
            return (firstOrder != secondOrder) ? (firstOrder < secondOrder) : (first.lastModified ?? Date()) < (second.lastModified ?? Date())
        })
    }
}

struct AttachmentFieldViewSwiftUI: View {
    @StateObject var viewModel: AttachmentFieldViewModel
    
    @EnvironmentObject
    var router: MageRouter
    
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
                    ForEach(viewModel.orderedAttachments ?? []) { attachment in
                        AttachmentPreviewView(attachment: attachment) {
                            viewModel.appendAttachmentViewRoute(router: router, attachment: attachment)
                        }
                        .clipShape(RoundedRectangle(cornerSize: CGSizeMake(5, 5)))
                    }
                }
            }
        }
    }
}
