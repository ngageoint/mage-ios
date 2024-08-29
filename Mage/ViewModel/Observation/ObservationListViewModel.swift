//
//  ObservationListViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class ObservationListViewModel: ObservationViewViewModel {
    var attachments: [AttachmentModel]?
    
    var orderedAttachments: [AttachmentModel]? {
        var observationForms: [[String: Any]] = []
        if let properties = observationModel?.properties as? [String: Any] {
            if (properties.keys.contains("forms")) {
                observationForms = properties["forms"] as! [[String: Any]];
            }
        }
        
        return attachments?.sorted(by: { first, second in
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
    
    override init(uri: URL) {
        super.init(uri: uri)
        
        $observationModel.sink { [weak self] observationModel in
            guard let observationModel = observationModel else {
                return
            }
            Task { @MainActor [weak self] in
                self?.attachments = await self?.attachmentRepository.getAttachments(
                    observationUri:observationModel.observationId,
                    observationFormId: nil,
                    fieldName: nil
                )
            }
        }
        .store(in: &cancellables)
    }
    
    func appendAttachmentViewRoute(router: MageRouter, attachment: AttachmentModel) {
        attachmentRepository.appendAttachmentViewRoute(router: router, attachment: attachment)
    }
}
