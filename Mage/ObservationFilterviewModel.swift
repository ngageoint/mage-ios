//
//  ObservationFilterviewModel.swift
//  MAGE
//
//  Created by James McDougall on 10/2/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Combine

class ObservationFilterviewModel: ObservableObject {
    
    @Injected(\.nsManagedObjectContext)
    var context: NSManagedObjectContext?
    var users: Set<User> = []
    
    init() {
        guard let context = context else { return }
        guard let event = Event.getCurrentEvent(context: context) else {
            return
        }
        if let teams = event.teams {
            for team in teams {
                if let users = team.users {
                    self.users.formUnion(users)
                }
            }
        }
    }
}
