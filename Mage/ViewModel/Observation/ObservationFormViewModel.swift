//
//  ObservationFormViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 7/30/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI

class ObservationFormViewModel: ObservableObject {
    @Injected(\.formRepository)
    var formRepository: FormRepository
    
    @Published
    var form: ObservationFormModel
    
    @Published
    var eventForm: FormModel?
    
    init(form: ObservationFormModel) {
        self.form = form
        if let eventFormId = form.eventFormId as? NSNumber {
            eventForm = formRepository.getForm(formId: eventFormId)
        }
    }
    
    var formName: String? {
        eventForm?.name
    }
    
    var formColor: Color {
        if let color = eventForm?.color, let uiColor = UIColor(hex: color) {
            return Color(uiColor: uiColor)
        }
        return .primaryColor
    }
    
    var primaryFieldText: String? {
        return Observation.text(form: form.form, fieldDefinition: eventForm?.primaryFeedField)
    }
    
    var secondaryFieldText: String? {
        return Observation.text(form: form.form, fieldDefinition: eventForm?.secondaryFeedField)
    }
    
    lazy var formFields: [ObservationFormFieldModel] = {
        let fields: [[String: AnyHashable]] = self.eventForm?.fields ?? [];
        
        return fields.filter { (field) -> Bool in
            let archived: Bool = field[FieldKey.archived.key] as? Bool ?? false;
            let hidden : Bool = field[FieldKey.hidden.key] as? Bool ?? false;
            let type : String = field[FieldKey.type.key] as? String ?? "";
            return !archived && !hidden && type != FieldType.hidden.key;
        }.sorted { (field0, field1) -> Bool in
            return (field0[FieldKey.id.key] as? Int ?? Int.max ) < (field1[FieldKey.id.key] as? Int ?? Int.max)
        }.map { fieldDictionary in
            ObservationFormFieldModel(field: fieldDictionary)
        }
    }()
    
    func shouldDisplay(field: ObservationFormFieldModel) -> Bool {
        if field.type == FieldType.attachment.key { return true }
        guard let value = form.form[field.name] else { return false }
        
        if let value = value as? String {
            return !value.isEmpty
        }
        
        if let value = value as? [Any] {
            return !value.isEmpty
        }
        
        return true
    }
    
    func fieldStringValue(fieldName: String) -> String? {
        let field = formFields.first { fieldModel in
            fieldModel.name == fieldName
        }
        switch (field?.type) {
        case FieldType.numberfield.key:
            return (form.form[fieldName] as? NSNumber)?.stringValue
        case FieldType.multiselectdropdown.key:
            return (form.form[fieldName] as? [String])?.joined(separator: ", ")
        case FieldType.checkbox.key:
            return ((form.form[fieldName] as? Bool) ?? false) == true ? "true" : "false"
        default:
            return form.form[fieldName] as? String
        }
    }
    
}
