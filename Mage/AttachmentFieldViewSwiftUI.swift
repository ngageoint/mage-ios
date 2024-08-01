//
//  AttachmentFieldViewSwiftUI.swift
//  MAGE
//
//  Created by Dan Barela on 7/31/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI

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
    
    var body: some View {
        Text("attachment count \(viewModel.attachments?.count ?? -1)")
    }
}
