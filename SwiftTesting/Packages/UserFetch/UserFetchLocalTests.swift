// 
//     
//  UserFetchLocalTests.swift
//  MAGE
//
// 


import Testing
import CoreData
import Persistence
import FetchOperation
import ServerDTO
import User
@testable import UserFetch
@testable import MAGE
import Pipeline

extension CoreDataTests {
    final class UserFetchLocalTests {
        
        let persistence: PersistenceProtocol
        let context: NSManagedObjectContext
        let local: UserFetchLocalImpl
        
        init() {
            persistence = PersistenceContext.current!.persistence
            context = persistence.writeContext
            local = UserFetchLocalImpl(persistence: persistence)
        }
        
        // MARK: - createUserFromDTO
        
        @Test
        func createUser_returnsNil_whenIDIsMissing() throws {
            let dto = UserDTO(
                id: nil,
                username: "user",
                displayName: "User"
            )
            
            let user = try UserImporterImpl().importUser(
                dto,
                context: context
            )
            
            #expect(user == nil)
        }
        
        @Test
        func createUser_createsNewUser() throws {
            let dto = UserDTO(
                id: "123",
                username: "dbarela",
                email: "test@test.com",
                displayName: "Daniel"
            )
            
            let user = try #require(
                try UserImporterImpl().importUser(dto, context: context)
            )
            
            #expect(user.remoteId == "123")
            #expect(user.username == "dbarela")
            #expect(user.email == "test@test.com")
            #expect(user.name == "Daniel")
        }
        
        @Test
        func createUser_updatesExistingUser() throws {
            let existing = User(context: context)
            existing.remoteId = "123"
            existing.username = "old"
            
            try context.obtainPermanentIDs(for: [existing])
            
            let dto = UserDTO(
                id: "123",
                username: "new"
            )
            
            let returned = try #require(
                try UserImporterImpl().importUser(dto, context: context)
            )
            
            #expect(returned.remoteId == existing.remoteId)
            #expect(existing.username == "new")
        }
        
        @Test
        func createUser_setsPhoneFromFirstPhone() throws {
            let dto = UserDTO(
                id: "123",
                phones: [
                    UserPhoneDTO(number: "111"),
                    UserPhoneDTO(number: "222")
                ]
            )
            
            let user = try #require(
                try UserImporterImpl().importUser(dto, context: context)
            )
            
            #expect(user.phone == "111")
        }
        
        @Test
        func createUser_setsIconFields() throws {
            let dto = UserDTO(
                id: "123",
                icon: UserIconDTO(
                    text: "DB",
                    color: "#ff0000",
                    contentType: nil,
                    size: nil,
                    type: nil
                )
            )
            
            let user = try #require(
                try UserImporterImpl().importUser(dto, context: context)
            )
            
            #expect(user.iconText == "DB")
            #expect(user.iconColor == "#ff0000")
        }
        
        @Test
        func createUser_convertsRecentEventIds() throws {
            let dto = UserDTO(
                id: "123",
                recentEventIds: [1, 2, 3]
            )
            
            let user = try #require(
                try UserImporterImpl().importUser(dto, context: context)
            )
            
            #expect(user.recentEventIds == [
                NSNumber(value: 1),
                NSNumber(value: 2),
                NSNumber(value: 3)
            ])
        }
        
        @Test
        func createUser_createsRoleWhenMissing() throws {
            let dto = UserDTO(
                id: "123",
                role: RoleDTO(
                    id: "admin",
                    permissions: ["READ", "WRITE"]
                )
            )
            
            let user = try #require(
                try UserImporterImpl().importUser(dto, context: context)
            )
            
            let role = try #require(user.role)
            
            #expect(role.remoteId == "admin")
            #expect(role.permissions == ["READ", "WRITE"])
        }
        
        @Test
        func createUser_reusesExistingRole() throws {
            let role = Role(context: context)
            role.remoteId = "admin"
            
            try context.obtainPermanentIDs(for: [role])
            
            let dto = UserDTO(
                id: "123",
                roleId: "admin"
            )
            
            let user = try #require(
                try UserImporterImpl().importUser(dto, context: context)
            )
            
            #expect(user.role?.remoteId == role.remoteId)
        }
        
        // MARK: - save
        
        @Test
        func save_returnsSavedCount() async throws {
            let users = [
                UserDTO(id: "1"),
                UserDTO(id: "2"),
                UserDTO(id: "3")
            ]
            
            var progress: [OperationProgress] = []
            
            let result = try await local.save(users) {
                progress.append($0)
            }
            
            #expect(result.saveCount == 3)
            #expect(progress.count == 1)
            
            let last = try #require(progress.last)
            #expect(last.completed == 3)
            #expect(last.total == 3)
        }
        
        @Test
        func save_reportsProgressEvery50Records() async throws {
            
            let users = (0..<120).map {
                UserDTO(id: "\($0)")
            }
            
            var updates: [OperationProgress] = []
            
            let result = try await local.save(users) {
                updates.append($0)
            }
            
            #expect(result.saveCount == 120)
            
            #expect(updates.map(\.completed) == [
                50,
                100,
                120
            ])
        }
        
        @Test
        func createUser_emptyPhones_doesNotSetPhone() throws {
            let dto = UserDTO(
                id: "123",
                phones: []
            )
            
            let user = try #require(
                try UserImporterImpl().importUser(dto, context: context)
            )
            
            #expect(user.phone == nil)
        }
        
        @Test
        func createUser_nilRoleAndRoleId_leavesRoleNil() throws {
            let dto = UserDTO(
                id: "123"
            )
            
            let user = try #require(
                try UserImporterImpl().importUser(dto, context: context)
            )
            
            #expect(user.role == nil)
        }
        
        @Test
        func createUser_reusesExistingRoleFromRoleDTO() throws {
            let role = Role(context: context)
            role.remoteId = "admin"
            role.permissions = ["OLD"]
            
            try context.obtainPermanentIDs(for: [role])
            
            let dto = UserDTO(
                id: "123",
                role: RoleDTO(
                    id: "admin",
                    permissions: ["READ", "WRITE"]
                )
            )
            
            let user = try #require(
                try UserImporterImpl().importUser(dto, context: context)
            )
            
            #expect(user.role?.remoteId == role.remoteId)
            
            // Existing role should not be overwritten.
            #expect(role.permissions == ["OLD"])
        }
        
        @Test
        func createUser_changesUserToDifferentExistingRole() throws {
            let oldRole = Role(context: context)
            oldRole.remoteId = "old"
            
            let newRole = Role(context: context)
            newRole.remoteId = "new"
            
            try context.obtainPermanentIDs(for: [oldRole, newRole])
            
            let user = User(context: context)
            user.remoteId = "123"
            user.role = oldRole
            
            try context.obtainPermanentIDs(for: [user])
            
            let dto = UserDTO(
                id: "123",
                roleId: "new"
            )
            
            let updated = try #require(
                try UserImporterImpl().importUser(dto, context: context)
            )
            
            #expect(updated.role?.remoteId == newRole.remoteId)
        }
        
        @Test
        func createUser_setsDates() throws {
            let created = Date(timeIntervalSince1970: 1000)
            let updated = Date(timeIntervalSince1970: 2000)
            
            let dto = UserDTO(
                id: "123",
                createdAt: created,
                lastUpdated: updated
            )
            
            let user = try #require(
                try UserImporterImpl().importUser(dto, context: context)
            )
            
            #expect(user.createdAt == created)
            #expect(user.lastUpdated == updated)
        }
        
        @Test
        func createUser_setsAvatarAndIconURLs() throws {
            let dto = UserDTO(
                id: "123",
                iconUrl: "icon",
                avatarUrl: "avatar",
            )
            
            let user = try #require(
                try UserImporterImpl().importUser(dto, context: context)
            )
            
            #expect(user.avatarUrl == "avatar?_lastUpdated=0")
            #expect(user.iconUrl == "icon")
        }
    }
}
