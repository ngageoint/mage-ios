//
//  ObservationSummaryViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 8/7/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class ObservationSummaryViewModel: ObservableObject {
    @Injected(\.observationRepository)
    var repository: ObservationRepository
    
    @Injected(\.observationImportantRepository)
    var importantRepository: ObservationImportantRepository
    
    @Injected(\.userRepository)
    var userRepository: UserRepository
    
    @Injected(\.formRepository)
    var formRepository: FormRepository
    
    @Published
    var user: UserModel?
    
    @Published
    var observationImportantModel: ObservationImportantModel?
    
    @Published
    var observationModel: ObservationModel?
    
    var primaryObservationForm: [AnyHashable : Any]?
    var primaryEventForm: Form?
    
    private func setPrimaryEventForm() {
        if let primaryObservationForm = primaryObservationForm, let formId = primaryObservationForm[EventKey.formId.key] as? NSNumber {
            primaryEventForm = formRepository.getForm(formId: formId)
        }
    }
    
    public var primaryFieldText: String? {
        get {
            if let primaryField = primaryEventForm?.primaryMapField, let observationForms = self.observationModel?.properties?[ObservationKey.forms.key] as? [[AnyHashable : Any]], let primaryFieldName = primaryField[FieldKey.name.key] as? String, observationForms.count > 0 {
                let value = self.primaryObservationForm?[primaryFieldName]
                return Observation.fieldValueText(value: value, field: primaryField)
            }
            return nil;
        }
    }

    public var secondaryFieldText: String? {
        get {
            if let variantField = primaryEventForm?.secondaryMapField, let observationForms = self.observationModel?.properties?[ObservationKey.forms.key] as? [[AnyHashable : Any]], let variantFieldName = variantField[FieldKey.name.key] as? String, observationForms.count > 0 {
                let value = self.primaryObservationForm?[variantFieldName]
                return Observation.fieldValueText(value: value, field: variantField)
            }
            return nil;
        }
    }

    public var primaryFeedFieldText: String? {
        get {
            if let primaryFeedField = primaryEventForm?.primaryFeedField, let observationForms = self.observationModel?.properties?[ObservationKey.forms.key] as? [[AnyHashable : Any]], let primaryFeedFieldName = primaryFeedField[FieldKey.name.key] as? String, observationForms.count > 0 {
                let value = primaryObservationForm?[primaryFeedFieldName]
                return Observation.fieldValueText(value: value, field: primaryFeedField)
            }
            return nil;
        }
    }

    public var secondaryFeedFieldText: String? {
        get {
            if let secondaryFeedField = primaryEventForm?.secondaryFeedField, let observationForms = self.observationModel?.properties?[ObservationKey.forms.key] as? [[AnyHashable : Any]], let secondaryFeedFieldName = secondaryFeedField[FieldKey.name.key] as? String, observationForms.count > 0 {
                let value = self.primaryObservationForm?[secondaryFeedFieldName]
                return Observation.fieldValueText(value: value, field: secondaryFeedField)
            }
            return nil;
        }
    }
}
