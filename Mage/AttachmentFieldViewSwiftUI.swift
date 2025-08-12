//
//  AttachmentFieldViewSwiftUI.swift
//  MAGE
//
//  Created by Dan Barela on 7/31/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
//import Kingfisher
import Combine

class AttachmentFieldViewModel: ObservableObject {
    @Injected(\.attachmentRepository) var repository: AttachmentRepository
    
    @Published var attachments: [AttachmentModel] = []
    @Published var fieldTitle: String
    
    var cancellable = Set<AnyCancellable>()
    
    init(observationUri: URL?, observationFormId: String, fieldName: String, fieldTitle: String) {
        self.fieldTitle = fieldTitle
        
        repository.observeAttachments(
            observationUri: observationUri,
            observationFormId: observationFormId,
            fieldName: fieldName
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] changes in
            guard let self else { return }
            
            for change in changes {
                switch change {
                case .insert(_, let element, _):
                    if !self.attachments.contains(where: { $0.attachmentUri == element.attachmentUri }) {
                        self.attachments.append(element)
                    } else {
                        // Refresh existing element if fields like lastModified changed
                        if let idx = self.attachments.firstIndex(where: { $0.attachmentUri == element.attachmentUri }) {
                            self.attachments[idx] = element
                        }
                    }
                case .remove(_, element: let element, _):
                    self.attachments.removeAll { $0.attachmentUri == element.attachmentUri }
                }
            }
        }
        .store(in: &cancellable)
    }
    
    func appendAttachmentViewRoute(router: MageRouter, attachment: AttachmentModel) {
        repository.appendAttachmentViewRoute(router: router, attachment: attachment)
    }
    
    var orderedAttachments: [AttachmentModel] {
        attachments.sorted { first, second in
            let firstOrder = first.order.intValue
            let secondOrder = second.order.intValue
            if firstOrder != secondOrder { return firstOrder < secondOrder }
            return (first.lastModified ?? Date()) < (second.lastModified ?? Date())
        }
    }
}

struct AttachmentFieldViewSwiftUI: View {
    @StateObject var viewModel: AttachmentFieldViewModel
    @EnvironmentObject var router: MageRouter
    
    var selectedUnsentAttachment: (_ localPath: String, _ contentType: String) -> Void
    
    let layout = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        if !viewModel.attachments.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.fieldTitle)
                    .secondaryText()
                LazyVGrid(columns:layout) {
                    ForEach(viewModel.orderedAttachments) { attachment in
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
