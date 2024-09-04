//
//  TeamLocalDataSource.swift
//  MAGE
//
//  Created by Dan Barela on 8/30/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

private struct TeamLocalDataSourceProviderKey: InjectionKey {
    static var currentValue: TeamLocalDataSource = TeamCoreDataDataSource()
}

extension InjectedValues {
    var teamLocalDataSource: TeamLocalDataSource {
        get { Self[TeamLocalDataSourceProviderKey.self] }
        set { Self[TeamLocalDataSourceProviderKey.self] = newValue }
    }
}


protocol TeamLocalDataSource {
    func updateOrInsert(json: [AnyHashable: Any]) -> Team?
}

class TeamCoreDataDataSource: CoreDataDataSource<Team>, TeamLocalDataSource {
    func updateOrInsert(json: [AnyHashable : Any]) -> Team? {
        guard let remoteId = json[TeamKey.id.key] as? String,
              let context = context
        else {
            return nil
        }
        context.performAndWait {
            let team = context.fetchFirst(Team.self, key: TeamKey.remoteId.key, value: remoteId) ?? Team(context: context)
            team.name = json[TeamKey.name.key] as? String
            team.teamDescription = json[TeamKey.description.key] as? String
            var teamUsers: Set<User> = Set<User>()
            
            if let userIds = json[TeamKey.userIds.key] as? [String] {
                for userId in userIds {
                    if let user = context.fetchFirst(User.self, key: UserKey.remoteId.key, value: userId) {
                        teamUsers.insert(user)
                    } else {
                        let user = User(context: context)
                        user.remoteId = userId;
                        teamUsers.insert(user)
                    }
                }
            }
            
            team.users = teamUsers
            
            try? context.save()
        }
        return nil
    }
}
