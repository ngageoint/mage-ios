//
//  ObservationFilterViewModel.swift
//  MAGE
//
//  Created by James McDougall on 10/7/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Combine
import SwiftUI
import CoreData

class ObservationFilterviewModel: ObservableObject {

    @Injected(\.nsManagedObjectContext)
    var context: NSManagedObjectContext?

    @Published var users: [User] = []
    @Published var selectedUsers: Set<String> = []
    @Published var searchText: String = ""

    // Output
    @Published private(set) var filteredUsers: [User] = []

    private var bag = Set<AnyCancellable>()

    init() {
        bindFiltering()
        setupUsers()
        setupSelectedUsers()
    }

    private func bindFiltering() {
        // Recompute filteredUsers whenever searchText or users changes.
        // Debounce keystrokes to avoid thrashing the UI.
        $searchText
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .combineLatest($users)
            .map { query, users in
                let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return users }

                // Case/diacritic-insensitive search on username, name, or remoteId.
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

        // Convert Set -> Array and sort by username (nil-safe)
        self.users = Array(tempUsers).sorted { ($0.username ?? "") < ($1.username ?? "") }
    }

    // Load selected ids from defaults and intersect with current users
    func setupSelectedUsers() {
        guard let ids = UserDefaults.standard.userFilterRemoteIds else {
            MageLogger.misc.debug("ObservationFilterviewModel.setupSelectedUsers: no IDs to load")
            return
        }

        self.selectedUsers = Set(
            users
                .compactMap { $0.remoteId }
                .filter { ids.contains($0) }
        )
    }

    // Toggle selection and persist
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
