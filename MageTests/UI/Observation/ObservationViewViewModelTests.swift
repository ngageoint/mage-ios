//
//  ObservationViewViewModelTests.swift
//  MAGETests
//
//  Created by Dan Barela on 8/28/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import Combine
import Nimble

@testable import MAGE

final class ObservationViewViewModelTests: MageInjectionTestCase {
        
    var observationRepository: ObservationRepositoryMock!
    var importantRepository: ObservationImportantRepositoryMock!
    var eventRepository: EventRepositoryMock!
    var userRepository: UserRepositoryMock!
    var formRepository: FormRepositoryMock!
    var attachmentRepository: AttachmentRepositoryMock!
    var roleRepository: RoleRepositoryMock!
    var observationImageRepository: ObservationImageRepositoryMock!

    override func setUp() {
        observationRepository = ObservationRepositoryMock()
        InjectedValues[\.observationRepository] = observationRepository
        importantRepository = ObservationImportantRepositoryMock()
        InjectedValues[\.observationImportantRepository] = importantRepository
        eventRepository = EventRepositoryMock()
        InjectedValues[\.eventRepository] = eventRepository
        userRepository = UserRepositoryMock()
        InjectedValues[\.userRepository] = userRepository
        formRepository = FormRepositoryMock()
        InjectedValues[\.formRepository] = formRepository
        attachmentRepository = AttachmentRepositoryMock()
        InjectedValues[\.attachmentRepository] = attachmentRepository
        roleRepository = RoleRepositoryMock()
        InjectedValues[\.roleRepository] = roleRepository
        observationImageRepository = ObservationImageRepositoryMock()
    }

    func testInit() {
        UserDefaults.standard.currentEventId = 1
        UserDefaults.standard.currentUserId = "user1"
        
        eventRepository.events = [
            EventModel(
                remoteId: 1,
                acl: [
                    "user1": [
                        PermissionsKey.permissions.key: [PermissionsKey.update.key]
                    ]
                ]
            )
        ]
        
        var primaryField = [
            "name": "field0",
            "required": false,
            "type": "dropdown",
            "title": "Incident Type",
            "id": 0,
            "choices": [
              [
                "id": 0,
                "value": 0,
                "title": "At Venue"
              ],
              [
                "id": 1,
                "value": 1,
                "title": "Protest"
              ]
            ]
        ] as [String : Any]
        
        var variantField = [
            "name": "field1",
            "id": 1,
            "required": true,
            "value": "None",
            "type": "dropdown",
            "title": "Level",
            "choices": [
              [
                "id": 0,
                "value": 0,
                "title": "None"
              ],
              [
                "id": 1,
                "value": 1,
                "title": "Low"
              ],
              [
                "id": 2,
                "value": 2,
                "title": "Medium"
              ],
              [
                "id": 3,
                "value": 3,
                "title": "High"
              ]
            ]
        ] as [String : Any]
        
        formRepository.forms = [
            FormModel(
                archived: false,
                eventId: 1,
                formId: 1,
                order: 0,
                primaryFeedField: primaryField, 
                secondaryFeedField: variantField,
                primaryMapField: primaryField,
                secondaryMapField: variantField,
                formJson: [
                  "variantField": "field1",
                  "name": "Test",
                  "color": "#355332",
                  "primaryField": "field0",
                  "primaryFeedField": "field0",
                  "secondaryFeedField": "field1",
                  "fields": [
                    primaryField,
                    variantField,
                    [
                      "name": "field2",
                      "id": 2,
                      "required": false,
                      "value": "",
                      "type": "textarea",
                      "title": "Description",
                      "choices": []
                    ]
                  ],
                  "userFields": [],
                  "archived": false,
                  "id": 1
                ]
            )
        ]
        
        let user = UserModel(
            userId: URL(string: "magetest://user/1"),
            remoteId: "user1",
            hasEditPermissions: true
        )
        
        roleRepository.roles = [
            RoleModel(
                permissions: [PermissionsKey.UPDATE_OBSERVATION_ALL.key],
                users: [user]
            )
        ]
        
        userRepository.users = [user]
        userRepository.canUpdateImportantReturnValue = true
        
        let properties: [AnyHashable: Any] = [
            ObservationKey.accuracy.key: 2.0,
            ObservationKey.provider.key: "gps",
            ObservationKey.forms.key: [
                [
                    FormKey.formId.key: 1,
                    FormKey.id.key: "form1",
                    "field0": "Protest",
                    "field1": "Low"
                ]
            ]
        ]
        
        observationRepository.list = [
            ObservationModel(
                observationId: URL(string: "magetest://observation/1"),
                remoteId: "1",
                eventId: 1,
                userId: URL(string:"magetest://user/1"),
                properties: properties as [AnyHashable: AnyObject]
            )
        ]
        
        observationRepository.addFavoriteToObservation(observationUri: URL(string: "magetest://observation/1")!, userRemoteId: "user1")
        
        importantRepository.updateObservationImportant(
            observationUri: URL(string: "magetest://observation/1")!,
            model: ObservationImportantModel(
                important: true,
                userId: "user1",
                reason: "important",
                timestamp: Date(timeIntervalSince1970: 10000),
                observationRemoteId: "1",
                importantUri: URL(string: "magetest://observationImportant/1")!,
                eventId: 1
            )
        )
        
        let viewModel = ObservationViewViewModel(uri: URL(string: "magetest://observation/1")!)
        
        expect(viewModel.user).toEventuallyNot(beNil())
        expect(viewModel.event).toEventuallyNot(beNil())
        expect(viewModel.observationModel).toEventuallyNot(beNil())
        expect(viewModel.observationForms).toEventuallyNot(beNil())
        expect(viewModel.observationFavoritesModel).toEventuallyNot(beNil())
        expect(viewModel.observationImportantModel).toEventuallyNot(beNil())
        expect(viewModel.iconPath).toEventuallyNot(beNil())
        expect(viewModel.isImportant).toEventually(beTrue())
        expect(viewModel.currentUser).toEventuallyNot(beNil())
        expect(viewModel.favoriteCount).toEventuallyNot(beNil())
        expect(viewModel.currentUserFavorite).toEventually(beTrue())
        expect(viewModel.currentUserCanUpdateImportant).toEventually(beTrue())
        expect(viewModel.currentUserCanEdit).toEventually(beTrue())
        expect(viewModel.currentUserCanUpdateImportant).toEventually(beTrue())
        expect(viewModel.observationForms).toEventuallyNot(beNil())
        expect(viewModel.primaryEventForm).toEventuallyNot(beNil())
        
        expect(viewModel.primaryFieldText).toEventually(equal("Protest"))
        expect(viewModel.secondaryFieldText).toEventually(equal("Low"))
        
        expect(viewModel.primaryFeedFieldText).toEventually(equal("Protest"))
        expect(viewModel.secondaryFeedFieldText).toEventually(equal("Low"))
        
        expect(viewModel.cancelButtonText).toEventually(equal("Remove Important"))
        viewModel.importantDescription = "new important"
        viewModel.makeImportant()
        expect(viewModel.observationImportantModel?.reason).toEventually(equal("new important"))
        
        // this will remove the important since it exists
        viewModel.cancelAction()
        expect(viewModel.isImportant).toEventually(beFalse())
        expect(viewModel.cancelButtonText).toEventually(equal("Cancel"))
    }

}
