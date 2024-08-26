//
//  AttachmentLocalDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 7/31/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine

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
    func getAttachment(attachmentUri: URL?) async -> AttachmentModel?
    func saveLocalPath(attachmentUri: URL?, localPath: String)
    func markForDeletion(attachmentUri: URL?)
    func undelete(attachmentUri: URL?)
    func observeAttachments(observationUri: URL?, observationFormId: String?, fieldName: String?) -> AnyPublisher<CollectionDifference<AttachmentModel>, Never>?
}

class AttachmentCoreDataDataSource: CoreDataDataSource<Attachment>, AttachmentLocalDataSource, ObservableObject {
    
    func getAttachments(observationUri: URL?, observationFormId: String?, fieldName: String?) async -> [AttachmentModel]? {
        
        let context = NSManagedObjectContext.mr_default()
        
        guard let observationUri = observationUri,
              let objectId = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationUri)
        else {
            return nil
        }
        return await context.perform {
            var andPredicates = [NSPredicate(format: "observation == %@", objectId)]
            if let observationFormId = observationFormId {
                andPredicates.append(NSPredicate(format: "observationFormId == %@", observationFormId))
            }
            if let fieldName = fieldName {
                andPredicates.append(NSPredicate(format: "fieldName == %@", fieldName))
            }
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: andPredicates)
            
            let fetchRequest = Attachment.fetchRequest()
            fetchRequest.predicate = predicate
            let results = context.fetch(request: fetchRequest)
            return results?.compactMap({ attachment in
                AttachmentModel(attachment: attachment)
            })
        }
    }
    
    func observeAttachments(observationUri: URL?, observationFormId: String?, fieldName: String?) -> AnyPublisher<CollectionDifference<AttachmentModel>, Never>? {
        let context = NSManagedObjectContext.mr_default()
        
        guard let observationUri = observationUri,
              let observationFormId = observationFormId,
              let fieldName = fieldName,
              let objectId = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationUri)
        else {
            return nil
        }
        var itemChanges: AnyPublisher<CollectionDifference<AttachmentModel>, Never> {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "observation == %@", objectId),
                NSPredicate(format: "observationFormId == %@", observationFormId),
                NSPredicate(format: "fieldName == %@", fieldName)
            ])
            
            let fetchRequest: NSFetchRequest<Attachment> = Attachment.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: false)]
            fetchRequest.predicate = predicate
            return context.changesPublisher(for: fetchRequest, transformer: { attachment in
                AttachmentModel(attachment: attachment)
            })
            .catch { _ in Empty() }
            .eraseToAnyPublisher()
        }

        return itemChanges
    }
    
    func getAttachment(attachmentUri: URL?) async -> AttachmentModel? {
        let context = NSManagedObjectContext.mr_default()
        
        guard let attachmentUri = attachmentUri
        else {
            return nil
        }
        
        return await context.perform {
            if let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: attachmentUri) {
                if let attachment = try? context.existingObject(with: id) as? Attachment {
                    return AttachmentModel(attachment: attachment)
                }
            }
            return nil
        }
    }
    
    func saveLocalPath(attachmentUri: URL?, localPath: String) {
        guard let attachmentUri = attachmentUri
        else {
            return
        }
        
        MagicalRecord.save({ (localContext : NSManagedObjectContext!) in
            if let id = localContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: attachmentUri) {
                if let attachment = try? localContext.existingObject(with: id) as? Attachment {
                    attachment.localPath = localPath;
                }
            }
        }) { (success, error) in
        };
    }
    
    func markForDeletion(attachmentUri: URL?) {
        guard let attachmentUri = attachmentUri
        else {
            return
        }
        
        MagicalRecord.save({ (localContext : NSManagedObjectContext!) in
            if let id = localContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: attachmentUri) {
                if let attachment = try? localContext.existingObject(with: id) as? Attachment {
                    attachment.markedForDeletion = true;
                    attachment.dirty = true;
                }
            }
        }) { (success, error) in
        };
    }
    
    func undelete(attachmentUri: URL?) {
        guard let attachmentUri = attachmentUri
        else {
            return
        }
        
        MagicalRecord.save({ (localContext : NSManagedObjectContext!) in
            if let id = localContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: attachmentUri) {
                if let attachment = try? localContext.existingObject(with: id) as? Attachment {
                    attachment.markedForDeletion = false;
                    attachment.dirty = false;
                }
            }
        }) { (success, error) in
        };
    }
}
