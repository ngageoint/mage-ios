//
//  UserObservationFilterViewModel.swift
//  MAGE
//
//  Created by James McDougall on 10/7/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import CoreData

class UserObservationFilterViewModel: ObservableObject {
    
    @Injected(\.nsManagedObjectContext)
    var context: NSManagedObjectContext?
    
    @Published var users: [UserModel]
    @Published var selectedUsers: Set<String>
    @Published var searchText: String
    
    var filteredUsers: [UserModel] {
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
    
    init(users: [UserModel] = []) {
        self.users = users
        self.selectedUsers = []
        self.searchText = ""
        setupUsers()
        setupSelectedUsers()
    }
    
    func setupUsers() {
        guard let context = context,
              let event = Event.getCurrentEvent(context: context)
        else { return }
        
        var tempUsers: Set<UserModel> = []
        if let teams = event.teams {
            for team in teams {
                if let users = team.users {
                    let userModels: [UserModel] = users.map { UserModel(user: $0) }
                    tempUsers.formUnion(userModels)
                }
            }
        }
        self.users = Array(tempUsers).sorted { ($0.username ?? "") < ($1.username ?? "") }
    }
    
    func setupSelectedUsers() {
        let saved = UserDefaults.standard.userFilterRemoteIds ?? []
        selectedUsers = Set(saved)
    }
    
    @MainActor
    func clearSelectedUsers() async {
        selectedUsers.removeAll()
        UserDefaults.standard.userFilterRemoteIds = []
        NotificationCenter.default.post(name: .ObservationFiltersChanged, object: nil)
    }
    
    @MainActor
    func updateSelectedUsers(remoteId: String) {
        if selectedUsers.contains(remoteId) {
            selectedUsers.remove(remoteId)
        } else {
            selectedUsers.insert(remoteId)
        }
        UserDefaults.standard.userFilterRemoteIds = Array(selectedUsers)
        NotificationCenter.default.post(name: .ObservationFiltersChanged, object: nil)
    }
}
