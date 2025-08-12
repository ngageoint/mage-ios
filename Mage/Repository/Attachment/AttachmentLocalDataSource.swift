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
    func observeAttachments(observationUri: URL?, observationFormId: String?, fieldName: String?) -> AnyPublisher<CollectionDifference<AttachmentModel>, Never>
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
    
    func observeAttachments(observationUri: URL?, observationFormId: String?, fieldName: String?) -> AnyPublisher<CollectionDifference<AttachmentModel>, Never> {
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard
            let context = context,
            let observationUri = observationUri,
            let observationFormId = observationFormId,
            let fieldName = fieldName,
            let objectId = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: observationUri)
        else {
            return Empty<CollectionDifference<AttachmentModel>, Never>(completeImmediately: true).eraseToAnyPublisher()
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
    
    // Normalize to Documents-relative & use AttachmentPath for healing/existence
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
            
            // 1) Resolve the actual file URL (handles /Documents from other installs, directory prefixes, etc.)
            let resolvedURL: URL? = {
                // If caller already passed a valid file path, prefer it.
                if FileManager.default.fileExists(atPath: localPath) {
                    return URL(fileURLWithPath: localPath)
                }
                // Otherwise try to heal it using the stored name as a hint.
                return AttachmentPath.localURL(fromStored: localPath, fileName: attachment.name)
            }()
            
            guard let fileURL = resolvedURL, FileManager.default.fileExists(atPath: fileURL.path) else {
                MageLogger.db.error("BBB: saveLocalPath: file not found (input: \(localPath)); name=\(attachment.name ?? "nil")")
                return
            }
            
            // 2) ALWAYS store Documents-relative for stability across reinstalls/containers.
            let relative = AttachmentPath.stripToDocumentsRelative(fileURL.path)
            
            // 3) Save.
            attachment.localPath = relative // <— normalized
            attachment.lastModified = Date() // or Date.now if your min iOS supports it
            MageLogger.db.debug("BBB: saveLocalPath stored relative path '\(relative)' for \(attachment.objectID)")
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
