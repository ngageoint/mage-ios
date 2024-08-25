//
//  UserRepositoryTests.swift
//  MAGETests
//
//  Created by Dan Barela on 8/23/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import Combine
import Nimble

@testable import MAGE

final class UserRepositoryTests: XCTestCase {
    
    var eventRepository = EventRepositoryMock()
    var userLocalDataSource = UserStaticLocalDataSource()
    var userRemoteDataSource = UserRemoteDataSourceMock()
    
    var cancellables: Set<AnyCancellable> = Set()
    
    override func setUp() {
        InjectedValues[\.eventRepository] = eventRepository
        InjectedValues[\.userLocalDataSource] = userLocalDataSource
        InjectedValues[\.userRemoteDataSource] = userRemoteDataSource
        InjectedValues[\.geoPackageRepository] = GeoPackageRepositoryMock()
    }
    
    override func tearDown() {
        cancellables.removeAll()
    }

    func testGetCurrentUser() {
        userLocalDataSource.users = [
            UserModel(
                userId: URL(string: "magetest://user/1")
            )
        ]
        
        userLocalDataSource.currentUserUri = URL(string: "magetest://user/1")
        
        let userRepostory = UserRepository()
        
        let currentUser = userRepostory.getCurrentUser()
        XCTAssertNotNil(currentUser)
        XCTAssertEqual(currentUser?.userId, URL(string: "magetest://user/1"))
    }
    
    func testGetUser() async {
        userLocalDataSource.users = [
            UserModel(
                userId: URL(string: "magetest://user/1")
            )
        ]
                
        let userRepostory = UserRepository()
        
        let user = await userRepostory.getUser(userUri: URL(string: "magetest://user/1"))
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.userId, URL(string: "magetest://user/1"))
    }
    
    func testGetUserByRemoteId() {
        userLocalDataSource.users = [
            UserModel(
                userId: URL(string: "magetest://user/1"),
                remoteId: "1"
            )
        ]
                
        let userRepostory = UserRepository()
        
        let user = userRepostory.getUser(remoteId: "1")
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.userId, URL(string: "magetest://user/1"))
    }
    
    func testCanUpdate() async {
        let userModel = UserModel(
            userId: URL(string: "magetest://user/1"),
            remoteId: "1"
        )
        let userModel2 = UserModel(
            userId: URL(string: "magetest://user/2"),
            remoteId: "2"
        )
        userLocalDataSource.users = [
            userModel,
            userModel2
        ]
        
        userLocalDataSource.canUpdateImportantReturnValues = [1 : [userModel]]
        
        eventRepository.events = [
            EventModel(remoteId: 1)
        ]
                
        let userRepostory = UserRepository()
        
        let canUpdate = await userRepostory.canUserUpdateImportant(eventId: 1, userUri: URL(string: "magetest://user/1")!)
        XCTAssertTrue(canUpdate)
        
        let noUpdate = await userRepostory.canUserUpdateImportant(eventId: 1, userUri: URL(string: "magetest://user/2")!)
        XCTAssertFalse(noUpdate)
        
        let unkonwnEvent = await userRepostory.canUserUpdateImportant(eventId: 2, userUri: URL(string: "magetest://user/1")!)
        XCTAssertFalse(unkonwnEvent)
    }
    
    func testObserveUser() {
        let userModel = UserModel(
            userId: URL(string: "magetest://user/1"),
            remoteId: "1",
            name: "first"
        )
        userLocalDataSource.users = [
            userModel
        ]
        
        let firstExpectation = XCTestExpectation(description: "First Model")
        let changeExpectation = XCTestExpectation(description: "change Model")
        
        eventRepository.events = [
            EventModel(remoteId: 1)
        ]
                
        let userRepostory = UserRepository()
        
        userRepostory.observeUser(userUri: URL(string: "magetest://user/1"))?
            .sink(receiveValue: { model in
                if model.name == "first" {
                    firstExpectation.fulfill()
                }
                if model.name == "second" {
                    changeExpectation.fulfill()
                }
            })
            .store(in: &cancellables)
        
        wait(for: [firstExpectation], timeout: 1)
        
        userLocalDataSource.updateUser(userUri: URL(string: "magetest://user/1")!, model: UserModel(
            userId: URL(string: "magetest://user/1"),
            remoteId: "1",
            name: "second"
        ))
        
        wait(for: [changeExpectation], timeout: 1)
    }
    
    func testUsersPublisher() {
        enum State {
            case loading
            case loaded(rows: [URIItem])
            case failure(error: Error)

            fileprivate var rows: [URIItem] {
                if case let .loaded(rows: rows) = self {
                    return rows
                } else {
                    return []
                }
            }
        }
        enum TriggerId: Hashable {
            case reload
            case loadMore
        }
        var state: State = .loading

        let trigger = Trigger()
        let userRepostory = UserRepository()
        
        let userModel = UserModel(
            userId: URL(string: "magetest://user/1"),
            remoteId: "1",
            name: "first"
        )
        userLocalDataSource.users = [userModel]

        Publishers.PublishAndRepeat(
            onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)
        ) { [trigger, userRepostory] in
            userRepostory.users(
                paginatedBy: trigger.signal(activatedBy: TriggerId.loadMore)
            )
            .scan([]) { $0 + $1 }
            .map { 
                print("XXX rows \($0)")
                return State.loaded(rows: $0)
            }
            .catch { error in
                XCTFail()
                return Just(State.failure(error: error))
            }
        }
        .receive(on: DispatchQueue.main)
        .sink { recieve in
            switch(state, recieve) {
            case (.loaded, .loaded):
                state = recieve
            default:
                state = recieve
            }
        }
        .store(in: &cancellables)

        expect(state.rows.count).toEventually(equal(1))

        // insert another item
        userLocalDataSource.users += [
            UserModel(
                userId: URL(string: "magetest://user/2"),
                remoteId: "2",
                name: "second"
            )
        ]

        // kick the publisher
        trigger.activate(for: TriggerId.reload)
        expect(state.rows.count).toEventually(equal(2))
    }
    
    func testAvatarChosen() async {
        let userModel = UserModel(
            userId: URL(string: "magetest://user/1"),
            remoteId: "1",
            name: "first"
        )
        
        var repository = UserRepository()
        
        await repository.avatarChosen(user: userModel, image: UIImage(systemName: "face.smiling")!)
        
        XCTAssertNotNil(userLocalDataSource.avatarChosenUser)
        XCTAssertNotNil(userLocalDataSource.avatarChosenImageData)
        XCTAssertEqual(userModel.userId, userLocalDataSource.avatarChosenUser?.userId)
        
        XCTAssertNotNil(userLocalDataSource.avatarResponse)
        XCTAssertEqual(userLocalDataSource.avatarResponse as? [String: String], ["userRemoteId":"1"] )
        XCTAssertNotNil(userLocalDataSource.avatarResponseUser)
        XCTAssertEqual(userModel.userId, userLocalDataSource.avatarResponseUser?.userId)
        XCTAssertNotNil(userLocalDataSource.avatarResponseImageData)
        XCTAssertNotNil(userLocalDataSource.avatarResponseImage)
        
        XCTAssertNotNil(userRemoteDataSource.uploadAvatarUser)
        XCTAssertEqual(userModel.userId, userRemoteDataSource.uploadAvatarUser?.userId)
        XCTAssertNotNil(userRemoteDataSource.uploadAvatarImageData)
        
        let imageData = userLocalDataSource.avatarChosenImageData
        XCTAssertEqual(imageData, userLocalDataSource.avatarResponseImageData)
        XCTAssertEqual(imageData, userRemoteDataSource.uploadAvatarImageData)
    }

}
