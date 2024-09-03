//
//  UserCoreDataDataSourceTests.swift
//  MAGETests
//
//  Created by Dan Barela on 8/25/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import Combine
import Nimble
import Kingfisher

@testable import MAGE

final class UserCoreDataDataSourceTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable> = Set()
    var coreDataStack: TestCoreDataStack?
    var context: NSManagedObjectContext?
    var roleLocalDataSource: RoleStaticLocalDataSource!

    override func setUp() {
        coreDataStack = TestCoreDataStack()
        context = coreDataStack!.persistentContainer.newBackgroundContext()
        InjectedValues[\.nsManagedObjectContext] = context
        roleLocalDataSource = RoleStaticLocalDataSource()
        InjectedValues[\.roleLocalDataSource] = roleLocalDataSource
    }
    
    override func tearDown() {
        cancellables.removeAll()
        InjectedValues[\.nsManagedObjectContext] = nil
        coreDataStack!.reset()
    }

    func testGetCurrentUser() async {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        
        UserDefaults.standard.currentUserId = "user1"
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = true
        }
        
        let localDataSource = UserCoreDataDataSource()
        let currentUser = localDataSource.getCurrentUser()
        XCTAssertNotNil(currentUser)
        XCTAssertEqual(currentUser?.remoteId, "user1")
        XCTAssertEqual(currentUser?.name, "Fred")
        
        let userUri = currentUser?.userId
        XCTAssertNotNil(userUri)
        
        let user = await localDataSource.getUser(userUri: userUri)
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.remoteId, "user1")
        XCTAssertEqual(user?.name, "Fred")
    }
    
    func testGetUserByRemoteId() {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        
        UserDefaults.standard.currentUserId = "user1"
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user2"
            user.currentUser = true
        }
        
        let localDataSource = UserCoreDataDataSource()
        let user = localDataSource.getUser(remoteId: "user2")
        
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.remoteId, "user2")
        XCTAssertEqual(user?.name, "Fred")
    }
    
    func testObserveUser() {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        
        UserDefaults.standard.currentUserId = "user1"
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            try? context.obtainPermanentIDs(for: [user])
            try? context.save()
        }
        
        var first = false
        var second = false
              
        let localDataSource = UserCoreDataDataSource()
        let user = localDataSource.getUser(remoteId: "user1")
        
        localDataSource.observeUser(userUri: user?.userId)?
            .sink(receiveValue: { model in
                if model.name == "Fred" {
                    first = true
                }
                if model.name == "Bob" {
                    second = true
                }
            })
            .store(in: &cancellables)
        
        expect(first).toEventually(beTrue())
        
        context.performAndWait {
            let user = context.fetchFirst(User.self, key: "remoteId", value: "user1")
            user?.name = "Bob"
            try? context.save()
        }
        
        expect(second).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5))
    }

    func testCanUserUpdateImportantEventPermissions() async {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        
        UserDefaults.standard.currentUserId = "user1"
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            try? context.obtainPermanentIDs(for: [user])
            try? context.save()
        }
        
        let localDataSource = UserCoreDataDataSource()
        let user = localDataSource.getUser(remoteId: "user1")
        
        let acl = [
            "user1": [
                PermissionsKey.permissions.key: [PermissionsKey.update.key]
            ]
        ]
        let eventModel = EventModel(remoteId: 1, acl: acl)
        let canUpdate = await localDataSource.canUserUpdateImportant(event: eventModel, userUri: user!.userId!)
        XCTAssertTrue(canUpdate)
    }
    
    func testCanUserUpdateImportantUpdateEvent() async {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        
        UserDefaults.standard.currentUserId = "user1"
        context.performAndWait {
            let role = Role(context: context)
            role.remoteId = "role1"
            role.permissions = [
                 "UPDATE_EVENT"
               ]
            
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.role = role
            
            try? context.obtainPermanentIDs(for: [role, user])
            try? context.save()
        }
        
        let localDataSource = UserCoreDataDataSource()
        let user = localDataSource.getUser(remoteId: "user1")
        
        let acl: [String: Any] = [:]
        let eventModel = EventModel(remoteId: 1, acl: acl)
        let canUpdate = await localDataSource.canUserUpdateImportant(event: eventModel, userUri: user!.userId!)
        XCTAssertTrue(canUpdate)
    }
    
    func testCanUserUpdateImportantNoEventPermissions() async {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        
        UserDefaults.standard.currentUserId = "user1"
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            try? context.obtainPermanentIDs(for: [user])
            try? context.save()
        }
        
        let localDataSource = UserCoreDataDataSource()
        let user = localDataSource.getUser(remoteId: "user1")
        
        let acl = [
            "user1": [
                PermissionsKey.permissions.key: []
            ]
        ]
        let eventModel = EventModel(remoteId: 1, acl: acl)
        let canUpdate = await localDataSource.canUserUpdateImportant(event: eventModel, userUri: user!.userId!)
        XCTAssertFalse(canUpdate)
    }
    
    func testCanUserUpdateImportantUpdateEventNoPermissions() async {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        
        UserDefaults.standard.currentUserId = "user1"
        context.performAndWait {
            let role = Role(context: context)
            role.remoteId = "role1"
            role.permissions = []
            
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.role = role
            
            try? context.obtainPermanentIDs(for: [role, user])
            try? context.save()
        }
        
        let localDataSource = UserCoreDataDataSource()
        let user = localDataSource.getUser(remoteId: "user1")
        
        let acl: [String: Any] = [:]
        let eventModel = EventModel(remoteId: 1, acl: acl)
        let canUpdate = await localDataSource.canUserUpdateImportant(event: eventModel, userUri: user!.userId!)
        XCTAssertFalse(canUpdate)
    }
    
    func testUsersPublisher() {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        
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
        let localDataSource = UserCoreDataDataSource()

        context.performAndWait {
            let user = User(context: context)
            user.name = "first"
            user.remoteId = "1"
            
            try? context.obtainPermanentIDs(for: [user])
            try? context.save()
        }

        Publishers.PublishAndRepeat(
            onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)
        ) { [trigger, localDataSource] in
            localDataSource.users(
                paginatedBy: trigger.signal(activatedBy: TriggerId.loadMore)
            )
            .scan([]) { $0 + $1 }
            .map {
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
        context.performAndWait {
            let user = User(context: context)
            user.name = "second"
            user.remoteId = "2"
            
            try? context.obtainPermanentIDs(for: [user])
            try? context.save()
        }
        
        // kick the publisher
        trigger.activate(for: TriggerId.reload)
        expect(state.rows.count).toEventually(equal(2))
    }
    
    func testUsersPublisherLodMore() {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        
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
        let localDataSource = UserCoreDataDataSource()
        localDataSource.fetchLimit = 1
        
        context.performAndWait {
            let user = User(context: context)
            user.name = "first"
            user.remoteId = "1"
            
            try? context.obtainPermanentIDs(for: [user])
            try? context.save()
        }

        Publishers.PublishAndRepeat(
            onOutputFrom: trigger.signal(activatedBy: TriggerId.reload)
        ) { [trigger, localDataSource] in
            localDataSource.users(
                paginatedBy: trigger.signal(activatedBy: TriggerId.loadMore)
            )
            .scan([]) { $0 + $1 }
            .map {
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
        context.performAndWait {
            let user = User(context: context)
            user.name = "second"
            user.remoteId = "2"
            
            try? context.obtainPermanentIDs(for: [user])
            try? context.save()
        }
        
        // kick the publisher
        trigger.activate(for: TriggerId.loadMore)
        expect(state.rows.count).toEventually(equal(2))
    }
    
    func testAvatarChosen() async {
        let userModel = UserModel(
            userId: URL(string: "magetest://user/1"),
            remoteId: "1",
            name: "first"
        )
        
        let localDataSource = UserCoreDataDataSource()
        let documentsDirectories: [String] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let userAvatarPath = "\(documentsDirectories[0])/userAvatars/1"
        if FileManager.default.fileExists(atPath: userAvatarPath) {
            try? FileManager.default.removeItem(atPath: userAvatarPath)
        }
        
        XCTAssertFalse(FileManager.default.fileExists(atPath: userAvatarPath))

        localDataSource.avatarChosen(user: userModel, imageData: UIImage(systemName: "face.smiling")!.jpegData(compressionQuality: 1.0)!)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: userAvatarPath))
        
        // cleanup
        try? FileManager.default.removeItem(atPath: userAvatarPath)
    }
    
    func testHandleAvatarResponse() async {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        
        UserDefaults.standard.currentUserId = "user1"
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            
            try? context.obtainPermanentIDs(for: [user])
            try? context.save()
        }
        
        let image = UIImage(systemName: "face.smiling")!
        
        let localDataSource = UserCoreDataDataSource()
        let user = localDataSource.getUser(remoteId: "user1")
        
        let cached = await localDataSource.handleAvatarResponse(
            response: [
                "lastUpdated": "2024-01-01T12:00:00.000Z",
                "name": "Fred",
                "id": "user1",
                "avatarUrl": "https://example.com/avatar"
            ],
            user: user!,
            imageData: image.jpegData(compressionQuality: 1.0)!,
            image: image
        )
        
        XCTAssertTrue(cached)
        
        let user2 = await localDataSource.getUser(userUri: user?.userId)
        let avatarUrl = user2?.avatarUrl

        XCTAssertNotNil(avatarUrl)
        
        XCTAssertTrue(KingfisherManager.shared.cache.isCached(forKey: avatarUrl!))
        
        // cleanup
        KingfisherManager.shared.cache.removeImage(forKey: avatarUrl!)
    }
    
    func testHandleUserResponseUpdate() async {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        
        let localDataSource = UserCoreDataDataSource()
        guard let userJson = TestHelpers.loadJsonFile("myself") else {
            XCTFail()
            return
        }
        
        context.performAndWait {
            let user = User(context: context)
            user.username = "Fred"
            user.name = "Fred"
            user.remoteId = "userabc"
            
            try? context.obtainPermanentIDs(for: [user])
            try? context.save()
        }
        
        let firstFoundUser = localDataSource.getUser(remoteId: "userabc")
        XCTAssertNotNil(firstFoundUser)
        XCTAssertEqual(firstFoundUser?.username, "Fred")
        
        let user = await localDataSource.handleUserResponse(response: userJson)
        
        XCTAssertNotNil(user)
        XCTAssertNotNil(roleLocalDataSource.addUserToRoleRoleJson)
        XCTAssertNotNil(roleLocalDataSource.addUserToRoleUser)
        
        let foundUser = localDataSource.getUser(remoteId: "userabc")
        XCTAssertNotNil(foundUser)
        XCTAssertEqual(foundUser?.username, "userabc")
    }
    
    func testHandleUserResponseInsert() async {
        let localDataSource = UserCoreDataDataSource()
        guard let userJson = TestHelpers.loadJsonFile("myself") else {
            XCTFail()
            return
        }
        
        let user = await localDataSource.handleUserResponse(response: userJson)
        
        XCTAssertNotNil(user)
        XCTAssertNotNil(roleLocalDataSource.addUserToRoleRoleJson)
        XCTAssertNotNil(roleLocalDataSource.addUserToRoleUser)
        
        let foundUser = localDataSource.getUser(remoteId: "userabc")
        XCTAssertNotNil(foundUser)
        XCTAssertEqual(foundUser?.username, "userabc")
    }

}
