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

class ObservationViewViewModel: NSObject, ObservableObject {
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
    
    @Injected(\.attachmentRepository)
    var attachmentRepository: AttachmentRepository
    
    var imageRepository: ObservationImageRepository
    
    @Published
    var event: EventModel?
    
    @Published
    var observationModel: ObservationModel?
    
    @Published
    var user: UserModel?
    
    var primaryObservationForm: [AnyHashable : Any]?
    var primaryEventForm: FormModel?
    
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
            return imageRepository.imageName(eventId: Int64(truncating: eventRemoteId), formId: formid, primaryFieldText: primaryFieldText, secondaryFieldText: secondaryFieldText)
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
    
    init(uri: URL, imageRepository: ObservationImageRepository = ObservationImageRepositoryImpl.shared) {
        self.imageRepository = imageRepository
        super.init()
        
        $observationModel.sink { [weak self] observationModel in
            Task { [weak self] in
                await self?.setupModels()
            }
        }.store(in: &cancellables)
        
        repository.observeObservation(observationUri: uri)?
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .assign(to: &$observationModel)
    }
    
    @MainActor
    func setupModels() async {
        guard let observationModel = observationModel else {
            return
        }
        
        if let eventId = observationModel.eventId {
            self.event = self.eventRepository.getEvent(eventId: eventId as NSNumber)
        }
        if let userId = observationModel.userId {
            self.user = await self.userRepository.getUser(userUri: userId)
        }
        self.currentUserCanEdit = self.currentUser?.hasEditPermissions ?? false
        if let eventId = observationModel.eventId,
           let currentUserUri = self.currentUser?.userId
        {
            self.currentUserCanUpdateImportant = await self.userRepository.canUserUpdateImportant(
                eventId: eventId as NSNumber,
                userUri: currentUserUri
            )
        }
        
        self.setupFavorites(observationModel: observationModel)
        self.setupImportant(observationModel: observationModel)
        self.setupForms(observationModel: observationModel)
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
