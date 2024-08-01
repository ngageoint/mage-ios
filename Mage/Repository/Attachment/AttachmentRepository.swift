//
//  AttachmentRepository.swift
//  MAGE
//
//  Created by Dan Barela on 7/31/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

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
}
