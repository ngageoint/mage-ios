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
        
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard let context = context else { return nil }
        
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
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard let context = context else { return nil }
        
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
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard let context = context else { return nil }
        
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
        guard let attachmentUri else { return }
        
        MagicalRecord.save({ localContext in
            guard let psc = localContext.persistentStoreCoordinator else {
                MageLogger.db.error("BBB: PSC is nil in saveLocalPath")
                return
            }
            
            guard let objectID = psc.managedObjectID(forURIRepresentation: attachmentUri) else {
                MageLogger.db.error("BBB: Could not resolve objectID for URI: \(attachmentUri)")
                return
            }
            
            guard let attachment = try? localContext.existingObject(with: objectID) as? Attachment else {
                MageLogger.db.error("BBB: No Attachment for objectID: \(objectID)")
                return
            }
            
//            attachment.localPath = localPath
//            attachment.lastModified = Date()
//            MageLogger.db.debug("BBB: Saved localPath for attachment \(objectID): \(localPath)")
            
            var finalPath = localPath

            // 🔧 If someone passed a directory/prefix, try to fix it by appending name
            if !FileManager.default.fileExists(atPath: finalPath),
               let name = attachment.name {
                // If localPath looks like a directory/prefix, append the file name
                let candidate = URL(fileURLWithPath: finalPath).appendingPathComponent(name).path
                if FileManager.default.fileExists(atPath: candidate) {
                    finalPath = candidate
                }
            }

            // Last sanity: only store if the file actually exists
            if FileManager.default.fileExists(atPath: finalPath) {
                attachment.localPath = finalPath
                attachment.lastModified = Date()
                MageLogger.db.debug("BBB: saveLocalPath: set \(finalPath) for \(attachment.objectID)")
            } else {
                MageLogger.db.error("BBB: saveLocalPath: file not found at \(finalPath); name=\(attachment.name ?? "nil"); original=\(localPath)")
            }
            
        })
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
