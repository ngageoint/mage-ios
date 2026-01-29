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
    var primaryEventForm: FormModel?
    
    private func setPrimaryEventForm() {
        if let primaryObservationForm = primaryObservationForm, let formId = primaryObservationForm[EventKey.formId.key] as? NSNumber {
            primaryEventForm = formRepository.getForm(formId: formId)
        }
    }
    
    public var primaryFieldText: String? {
        get {
            return Observation.text(
                form: primaryObservationForm,
                fieldDefinition: primaryEventForm?.primaryMapField
            )
        }
    }

    public var secondaryFieldText: String? {
        get {
            return Observation.text(
                form: primaryObservationForm,
                fieldDefinition: primaryEventForm?.secondaryMapField
            )
        }
    }

    public var primaryFeedFieldText: String? {
        get {
            return Observation.text(
                form: primaryObservationForm,
                fieldDefinition: primaryEventForm?.primaryFeedField
            )
        }
    }

    public var secondaryFeedFieldText: String? {
        get {
            return Observation.text(
                form: primaryObservationForm,
                fieldDefinition: primaryEventForm?.secondaryFeedField
            )
        }
    }
}
