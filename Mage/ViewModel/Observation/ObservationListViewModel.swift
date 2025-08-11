//
//  ObservationListViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData
import Combine

class ObservationListViewModel: ObservationViewViewModel, NSFetchedResultsControllerDelegate {
    @Published var attachments: [AttachmentModel] = []
    
    private var fetchedResultsController: NSFetchedResultsController<Attachment>?
    private var context: NSManagedObjectContext?
    private var observableObjectID: NSManagedObjectID
    
    // Computed property for ordered attachments
    var orderedAttachments: [AttachmentModel]? {
        var observationForms: [[String: Any]] = []
        if let properties = observationModel?.properties as? [String: Any] {
            if (properties.keys.contains("forms")) {
                observationForms = properties["forms"] as! [[String: Any]];
            }
        }
        
        return attachments.sorted(by: { first, second in
            // return true if first comes before second, false otherwise
            
            if first.formId == second.formId {
                // if they are in the same form, sort on field
                if first.fieldName == second.fieldName {
                    // if they are the same field return the order comparison unless they are both zero, then return the lat modified comparison
                    let firstOrder = first.order.intValue
                    let secondOrder = second.order.intValue
                    return (firstOrder != secondOrder) ? (firstOrder < secondOrder) : (first.lastModified ?? Date()) < (second.lastModified ?? Date())
                } else {
                    // return the first field
                    let form = observationForms.first { form in
                        return form[FormKey.id.key] as? String == first.formId
                    }
                    
                    let firstFieldIndex = (form?[FormKey.fields.key] as? [[String: Any]])?.firstIndex { form in
                        return form[FieldKey.name.key] as? String == first.fieldName
                    } ?? 0
                    let secondFieldIndex = (form?[FormKey.fields.key] as? [[String: Any]])?.firstIndex { form in
                        return form[FieldKey.name.key] as? String == second.fieldName
                    } ?? 0
                    return firstFieldIndex < secondFieldIndex
                }
            } else {
                // different forms, sort on form order
                let firstFormIndex = observationForms.firstIndex { form in
                    return form[FormKey.id.key] as? String == first.formId
                } ?? 0
                let secondFormIndex = observationForms.firstIndex { form in
                    return form[FormKey.id.key] as? String == second.formId
                } ?? 0
                return firstFormIndex < secondFormIndex
            }
        })
    }
    
    // Pass in observation's objectID so we can safely fetch (never switches)
    init(observationObjectID: NSManagedObjectID, context: NSManagedObjectContext? = nil) {
        self.observableObjectID = observationObjectID
        super.init(uri: observationObjectID.uriRepresentation())
        
        // Use injected context if not provided
        if let context {
            self.context = context
        } else {
            @Injected(\.nsManagedObjectContext) var injectedContext: NSManagedObjectContext?
            self.context = injectedContext
        }
        
        setupFetchedResultsController()
    }
    
    private func setupFetchedResultsController() {
        guard let context = context, let observation = context.object(with: observableObjectID) as? Observation else { return }
        
        let fetchRequest: NSFetchRequest<Attachment> = Attachment.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "observation == %@", observation)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "lastModified", ascending: true)
        ]
        
        let frc = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        frc.delegate = self
        self.fetchedResultsController = frc
        
        do {
            try frc.performFetch()
            self.updateAttachments()
        } catch {
            print("Error fetching attachments \(error.localizedDescription)")
        }
    }
    
    // Called whenever the underlying attachments change in Core Data
    @objc func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateAttachments()
    }
    
    private func updateAttachments() {
        let fetched = fetchedResultsController?.fetchedObjects ?? []
        self.attachments = fetched.map { AttachmentModel(attachment: $0) }
    }
    
    func appendAttachmentViewRoute(router: MageRouter, attachment: AttachmentModel) {
        attachmentRepository.appendAttachmentViewRoute(router: router, attachment: attachment)
    }
}
