import Foundation
import ServerDTO
import Persistence
import CoreData

public extension Form {
    convenience init(formDTO: EventFormDTO, eventId: EventID, index: Int, writeContext: NSManagedObjectContext) {
        let formId = formDTO.id
        self.init(context: writeContext)
        let formJsonEntity = FormJson(context: writeContext)
        formJsonEntity.json = formDTO.dictionary?.compactMapValues { $0 }
        formJsonEntity.formId = formId.rawValue
        self.json = formJsonEntity
        self.eventId = eventId.rawValue
        self.archived = formDTO.archived ?? false
        self.formId = formId.rawValue
        self.order = NSNumber(value: index)
        
        if let formFields = formDTO.fields {
            if let primaryMapFieldName = formDTO.primaryField {
                self.primaryMapField = formFields.first { field in
                    if let fieldName = field.name {
                        return fieldName == primaryMapFieldName
                    }
                    return false
                }?.dictionary?.compactMapValues { $0 }
            }
            if let secondaryMapFieldName = formDTO.variantField {
                self.secondaryMapField = formFields.first { field in
                    if let fieldName = field.name {
                        return fieldName == secondaryMapFieldName
                    }
                    return false
                }?.dictionary?.compactMapValues { $0 }
            }
            if let primaryFeedFieldName = formDTO.primaryFeedField {
                self.primaryFeedField = formFields.first { field in
                    if let fieldName = field.name {
                        return fieldName == primaryFeedFieldName
                    }
                    return false
                }?.dictionary?.compactMapValues { $0 }
            }
            if let secondaryFeedFieldName = formDTO.secondaryFeedField {
                self.secondaryFeedField = formFields.first { field in
                    if let fieldName = field.name {
                        return fieldName == secondaryFeedFieldName
                    }
                    return false
                }?.dictionary?.compactMapValues { $0 }
            }
        }
    }
    
    static func getFieldByNameFromJSONFields(dto: [FormFieldModel], name: String) -> FormFieldModel? {
        dto.first(where: { $0.name == name })
    }
}
