//
//  AttachmentLocalDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 7/31/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct AttachmentLocalDataSourceProviderKey: InjectionKey {
    static var currentValue: AttachmentLocalDataSource = AttachmentCoreDataDataSource()
}

extension InjectedValues {
    var attachmentLocalDataSource: AttachmentLocalDataSource {
        get { Self[AttachmentLocalDataSourceProviderKey.self] }
        set { Self[AttachmentLocalDataSourceProviderKey.self] = newValue }
    }
}

protocol AttachmentLocalDataSource {
    func getAttachments(observationUri: URL?, observationFormId: String?, fieldName: String?) async -> [AttachmentModel]?
    
}

class AttachmentCoreDataDataSource: CoreDataDataSource, AttachmentLocalDataSource, ObservableObject {
    
    func getAttachments(observationUri: URL?, observationFormId: String?, fieldName: String?) async -> [AttachmentModel]? {
        
        let context = NSManagedObjectContext.mr_default()
        
        guard let observationUri = observationUri,
              let objectId = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationUri),
              let observationFormId = observationFormId,
              let fieldName = fieldName
        else {
            return nil
        }
        return await context.perform {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "observation == %@", objectId),
                NSPredicate(format: "observationFormId == %@", observationFormId),
                NSPredicate(format: "fieldName == %@", fieldName)
            ])
            
            let fetchRequest = Attachment.fetchRequest()
            fetchRequest.predicate = predicate
            let results = context.fetch(request: fetchRequest)
            return results?.compactMap({ attachment in
                AttachmentModel(attachment: attachment)
            })
        }
    }
}
