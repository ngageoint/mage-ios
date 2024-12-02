//
//  AttachmentViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/19/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class AttachmentViewModel: ObservableObject {
    @Injected(\.attachmentRepository)
    var repository: AttachmentRepository
    
    @Published
    var attachment: AttachmentModel?
    
    @Published
    var date = Date()
    
    @Published
    var attachmentServerUrl: URL?
    
    var attachmentUri: URL?
    
    init(attachmentUri: URL?) {
        self.attachmentUri = attachmentUri
        Task { [weak self] in
            let attachment = await self?.repository.getAttachment(attachmentUri: attachmentUri)
            await MainActor.run { [weak self] in
                self?.attachment = attachment
                if let urlString = attachment?.url {
                    self?.attachmentServerUrl = URL(string: "\(urlString)")
                    self?.date = Date()
                }
            }
        }
    }
}
