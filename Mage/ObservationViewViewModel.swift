//
//  ObservationViewViewModel.swift
//  MAGE
//
//  Created by Dan Barela on 7/26/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class ObservationViewViewModel: ObservableObject {
    @Injected(\.observationRepository)
    var repository: ObservationRepository
    
    @Injected(\.observationImportantRepository)
    var importantRepository: ObservationImportantRepository
    
    @Injected(\.eventRepository)
    var eventRepository: EventRepository
    
    @Injected(\.userRepository)
    var userRepository: UserRepository
    
    @Injected(\.formRepository)
    var formRepository: FormRepository
    
    @Published
    var event: Event?
    
    @Published
    var observationModel: ObservationModel?
    
    @Published
    var user: UserModel?
    
    var primaryObservationForm: [AnyHashable : Any]?
    var primaryEventForm: Form?
    
    @Published
    var observationForms: [ObservationFormModel]?
    
    @Published
    var totalFavorites: Int = 0
    
    @Published
    var observationFavoritesModel: ObservationFavoritesModel?
    
    @Published
    var observationImportantModel: ObservationImportantModel?
    
    @Published
    var settingImportant: Bool = false
    
    @Published
    var importantDescription: String = ""
    
    var iconPath: String? {
        if let eventRemoteId = event?.remoteId, let formid = primaryEventForm?.formId {
            return ObservationImage.imageName(eventId: Int64(truncating: eventRemoteId), formId: Int64(truncating: formid), primaryFieldText: primaryFieldText, secondaryFieldText: secondaryFieldText)
        }
        return nil
    }
    
    var isImportant: Bool {
        observationImportantModel?.important ?? false
    }
    
    lazy var currentUser: UserModel? = {
        userRepository.getCurrentUser()
    }()
    
    var favoriteCount: Int? {
        observationFavoritesModel?.favoriteUsers?.count
    }
    
    var currentUserFavorite: Bool {
        ((observationFavoritesModel?.favoriteUsers?.contains(where: { userId in
            userId == currentUser?.remoteId
        })) == true)
    }
    
    @Published
    var currentUserCanEdit: Bool = false
    
    @Published
    var currentUserCanUpdateImportant: Bool = false
    
    var cancelButtonText: String {
        isImportant ? "Remove Important" : "Cancel"
    }
        
    var cancellables = Set<AnyCancellable>()
    
    init(uri: URL) {
        $observationModel.sink { [weak self] observationModel in
            guard let observationModel = observationModel else {
                return
            }
            Task { @MainActor [weak self] in
                if let eventId = observationModel.eventId {
                    self?.event = self?.eventRepository.getEvent(eventId: eventId as NSNumber)
                }
                if let userId = observationModel.userId {
                    self?.user = await self?.userRepository.getUser(userUri: userId)
                }
                self?.currentUserCanEdit = self?.currentUser?.hasEditPermissions ?? false
                if let eventId = observationModel.eventId,
                   let currentUserUri = self?.currentUser?.userId
                {
                    self?.currentUserCanUpdateImportant = await self?.userRepository.canUserUpdateImportant(
                        eventId: eventId as NSNumber,
                        userUri: currentUserUri
                    ) ?? false
                }
            }
            
            self?.setupFavorites(observationModel: observationModel)
            self?.setupImportant(observationModel: observationModel)
            self?.setupForms(observationModel: observationModel)
        }.store(in: &cancellables)
        
        repository.observeObservation(observationUri: uri)?
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .assign(to: &$observationModel)
    }
    
    func makeImportant() {
        settingImportant = false
        importantRepository.flagImportant(observationUri: observationModel?.observationId, reason: importantDescription)
    }
    
    func cancelAction() {
        settingImportant = false
        if isImportant {
            importantRepository.removeImportant(observationUri: observationModel?.observationId)
        }
    }
    
    private func setupFavorites(observationModel: ObservationModel) {
        if let observationUri = observationModel.observationId {
            self.repository.observeObservationFavorites(observationUri: observationUri)?
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] updatedObject in
                    self?.observationFavoritesModel = updatedObject
                })
                .store(in: &cancellables)
        }
    }
    
    private func setupImportant(observationModel: ObservationModel) {
        if let observationUri = observationModel.observationId {
            self.importantRepository.observeObservationImportant(observationUri: observationUri)?
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] updatedObject in
                    if let important = updatedObject.first, let important = important {
                        self?.observationImportantModel = important
                        self?.importantDescription = important.reason ?? ""

                    } else {
                        self?.observationImportantModel = nil
                        self?.importantDescription = ""
                    }
                })
                .store(in: &cancellables)
        }
    }
    
    private func setupForms(observationModel: ObservationModel) {
        guard let properties = observationModel.properties else {
            return
        }
        if let forms = properties[ObservationKey.forms.key] as? [[String:AnyHashable]] {
            primaryObservationForm = forms.first
            observationForms = forms.map({ form in
                ObservationFormModel(observationId: observationModel.observationId, form: form)
            })
            //                for (index, form) in forms.enumerated() {
            //                    // here we can ignore forms which will be deleted
            //                    if !self.formsToBeDeleted.contains(index) {
            //                        return form;
            //                    }
            //                }
        }
        setPrimaryEventForm()
    }
    
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

class ObservationListViewModel: ObservationViewViewModel {
    @Injected(\.attachmentRepository)
    var attachmentRepository: AttachmentRepository
    
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
}
