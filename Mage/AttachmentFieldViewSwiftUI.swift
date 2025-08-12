//
//  AttachmentFieldViewSwiftUI.swift
//  MAGE
//
//  Created by Dan Barela on 7/31/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
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
        .scan([AttachmentModel]()) { current, diff in
            Self.apply(diff: diff, to: current)
        }
        .sink { [weak self] snapshot in
            self?.attachments = snapshot
        }
        .store(in: &cancellable)
    }

    // Apply a CollectionDifference to an Array without using .applying(_:)
    private static func apply(
        diff: CollectionDifference<AttachmentModel>,
        to base: [AttachmentModel]
    ) -> [AttachmentModel] {
        var result = base

        for change in diff {
            switch change {
            case let .insert(offset, element, _):
                // If offset is within bounds, respect it; otherwise append.
                if offset <= result.count {
                    result.insert(element, at: offset)
                } else {
                    result.append(element)
                }

            case let .remove(_, element, _):
                // Prefer identity by attachmentUri; fall back to equality if needed.
                if let idx = result.firstIndex(where: { $0.attachmentUri == element.attachmentUri }) {
                    result.remove(at: idx)
                } else if let idx = result.firstIndex(of: element) { // if Equatable
                    result.remove(at: idx)
                }
            }
        }

        return result
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
