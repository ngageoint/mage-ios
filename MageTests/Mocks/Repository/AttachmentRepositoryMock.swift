//
//  AttachmentRepositoryMock.swift
//  MAGETests
//
//  Created by Dan Barela on 8/28/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

@testable import MAGE

class AttachmentRepositoryMock: AttachmentRepository {
    var list: [AttachmentModel] = []
    
    func getAttachments(observationUri: URL?, observationFormId: String?, fieldName: String?) async -> [MAGE.AttachmentModel]? {
        nil
    }
    
    func observeAttachments(observationUri: URL?, observationFormId: String?, fieldName: String?) -> AnyPublisher<CollectionDifference<MAGE.AttachmentModel>, Never>? {
        AnyPublisher(Just(list.difference(from: [])).setFailureType(to: Never.self))
    }
    
    func getAttachment(attachmentUri: URL?) async -> MAGE.AttachmentModel? {
        list.first { model in
            model.attachmentUri == attachmentUri
        }
    }
    
    var saveLocalPathAttachmentUri: URL?
    var saveLocalPathLocalPath: String?
    func saveLocalPath(attachmentUri: URL?, localPath: String) {
        saveLocalPathLocalPath = localPath
        saveLocalPathAttachmentUri = attachmentUri
    }
    
    var markForDeletionAttachmentUri: URL?
    func markForDeletion(attachmentUri: URL?) {
        self.markForDeletionAttachmentUri = attachmentUri
    }
    
    var undeleteAttachmentUri: URL?
    func undelete(attachmentUri: URL?) {
        undeleteAttachmentUri = attachmentUri
    }
    
    var appendAttachmentVieRouteAttachment: AttachmentModel?
    func appendAttachmentViewRoute(router: MAGE.MageRouter, attachment: MAGE.AttachmentModel) {
        appendAttachmentVieRouteAttachment = attachment
    }
}
