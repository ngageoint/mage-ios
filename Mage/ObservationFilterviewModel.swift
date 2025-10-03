//
//  ObservationFilterviewModel.swift
//  MAGE
//
//  Created by James McDougall on 10/2/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Combine
import SwiftUI

class ObservationFilterviewModel: ObservableObject {
    
    @Injected(\.nsManagedObjectContext)
    var context: NSManagedObjectContext? // we only need this so we can fetch the current Event
    var users: [User] = [] // the unique [User] we get from the Event.Teams array
    @Published var selectedUsers: Set<String> = [] // [User.remoteId]
    @Published var searchText: String = "" // this is used with the .searchable()
    
    // Computed property that filters users based on searchText
    // TODO: maybe include the ability to search for characters in any order? `query.allSatisfy`
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return users
        } else {
            return users.filter {
                if let username = $0.username, let name = $0.name {
                    return username.localizedCaseInsensitiveContains(searchText) || name.localizedCaseInsensitiveContains(searchText)
                } else { return false }
            }
        }
    }
    
    init() {
        setupUsers()
        setupSelectedUsers()
    }
    
    // Get Event -> Teams -> foreach Team -> get Users
    func setupUsers() {
        guard let context = context else { return }
        guard let event = Event.getCurrentEvent(context: context) else {
            return
        }
        // remove duplicates by using a Set
        var tempUsers: Set<User> = []
        if let teams = event.teams {
            for team in teams {
                if let users = team.users {
                    tempUsers.formUnion(users)
                }
            }
        }
        // Set's are in random order, so convert to Array, then sort by User.username
        self.users = Array(tempUsers).sorted {
            ($0.username ?? "") < ($1.username ?? "")
        }
    }
    
    // we get their IDs from UserDefaults.userFilterRemoteIds, then add each ID to selectedUsers
    func setupSelectedUsers() {
        guard let IDs = UserDefaults.standard.userFilterRemoteIds else {
            MageLogger.misc.debug("ObservationFilterviewModel.setupSelectedUsers: no IDs to load")
            return
        }
        self.selectedUsers = Set(users
            .filter { user in
                if let id = user.remoteId {
                    return IDs.contains(id)
                }
                return false
            }
            .compactMap { $0.remoteId })
    }
    
    // called when a UserObservationCellView is tapped
    @MainActor
    func updateSelectedUsers(remoteId: String) {
        if selectedUsers.contains(remoteId) {
            selectedUsers.remove(remoteId)
        } else {
            selectedUsers.insert(remoteId)
        }
        UserDefaults.standard.userFilterRemoteIds = Array(selectedUsers)
    }
}
