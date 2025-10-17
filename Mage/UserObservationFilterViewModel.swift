//
//  UserObservationFilterViewModel.swift
//  MAGE
//
//  Created by James McDougall on 10/7/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Combine
import SwiftUI
import CoreData

class UserObservationFilterViewModel: ObservableObject {
    
    @Injected(\.nsManagedObjectContext)
    var context: NSManagedObjectContext?
    
    @Published var users: [User] = []
    @Published var selectedUsers: Set<String> = []
    @Published var searchText: String = ""
    
    @Published private(set) var filteredUsers: [User] = []
    
    private var bag = Set<AnyCancellable>()
    
    init() {
        bindFiltering()
        setupUsers()
        setupSelectedUsers()
    }
    
    private func bindFiltering() {
        $searchText
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .combineLatest($users)
            .map { query, users in
                let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return users }
                
                let needle = trimmed.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                
                return users.filter { user in
                    let username = (user.username ?? "").folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                    let name     = (user.name ?? "").folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                    let rid      = (user.remoteId ?? "").folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
                    
                    return username.contains(needle) || name.contains(needle) || rid.contains(needle)
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$filteredUsers)
    }
    
    // Get Event -> Teams -> Users (unique), sorted by username
    func setupUsers() {
        guard let context = context,
              let event = Event.getCurrentEvent(context: context)
        else { return }
        
        var tempUsers: Set<User> = []
        if let teams = event.teams {
            for team in teams {
                if let users = team.users {
                    tempUsers.formUnion(users)
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
