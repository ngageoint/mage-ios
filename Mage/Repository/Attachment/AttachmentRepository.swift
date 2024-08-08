//
//  AttachmentRepository.swift
//  MAGE
//
//  Created by Dan Barela on 7/31/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

private struct AttachmentRepositoryProviderKey: InjectionKey {
    static var currentValue: AttachmentRepository = AttachmentRepository()
}

extension InjectedValues {
    var attachmentRepository: AttachmentRepository {
        get { Self[AttachmentRepositoryProviderKey.self] }
        set { Self[AttachmentRepositoryProviderKey.self] = newValue }
    }
}

class AttachmentRepository: ObservableObject {
    @Injected(\.attachmentLocalDataSource)
    var localDataSource: AttachmentLocalDataSource
    
    func getAttachments(observationUri: URL?, observationFormId: String?, fieldName: String?) async -> [AttachmentModel]? {
        await localDataSource.getAttachments(
            observationUri: observationUri,
            observationFormId: observationFormId,
            fieldName: fieldName
        )
    }
    
    func observeAttachments(observationUri: URL?, observationFormId: String?, fieldName: String?) -> AnyPublisher<CollectionDifference<AttachmentModel>, Never>? {
        localDataSource.observeAttachments(observationUri: observationUri, observationFormId: observationFormId, fieldName: fieldName)
    }
    
    func getAttachment(attachmentUri: URL?) async -> AttachmentModel? {
        await localDataSource.getAttachment(attachmentUri: attachmentUri)
    }
    
    func saveLocalPath(attachmentUri: URL?, localPath: String) {
        localDataSource.saveLocalPath(attachmentUri: attachmentUri, localPath: localPath)
    }
    
    func markForDeletion(attachmentUri: URL?) {
        localDataSource.markForDeletion(attachmentUri: attachmentUri)
    }
    
    func undelete(attachmentUri: URL?) {
        localDataSource.undelete(attachmentUri: attachmentUri)
    }
}
