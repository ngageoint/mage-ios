//
//  Event.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData
import Persistence

extension Event {
    @objc public static func sendRecentEvent() {
        guard let u = User.fetchCurrentUser(context: NSManagedObjectContext.mr_default()), let baseURL = MageServer.baseURL() else {
            return;
        }
        let manager = MageSessionManager.shared();
        guard let currentEventId = Server.currentEventId(), let task: URLSessionDataTask = manager?.post_TASK("\(baseURL.absoluteURL)/api/users/\(u.remoteId ?? "")/events/\(currentEventId)/recent", parameters: nil, progress: nil, success: { task, response in
            
        }, failure: { task, error in
            print("Error posting recent event")
        }) else {
            return
        }
        manager?.addTask(task)
    }
    
    @objc public static func getCurrentEvent(context: NSManagedObjectContext) -> Event? {
        if let currentEventId = Server.currentEventId() {
            return Event.mr_findFirst(byAttribute: EventKey.remoteId.key, withValue: currentEventId, in: context);
        }
        return nil;
    }
    
    @objc public static func getEvent(eventId: NSNumber, context: NSManagedObjectContext) -> Event? {
        return Event.mr_findFirst(byAttribute: EventKey.remoteId.key, withValue: eventId, in: context);
    }
    
    @objc public static func caseInsensitiveSortFetchAll(sortTerm: String?, ascending: Bool, predicate: NSPredicate?, groupBy: String?, context: NSManagedObjectContext) -> NSFetchedResultsController<Event>? {
        guard let request = Event.mr_requestAll(in: context) as? NSFetchRequest<Event> else {
            return nil;
        }
        request.predicate = predicate;
        request.includesSubentities = false;
        
        if let sortTerm = sortTerm {
            let sortBy = NSSortDescriptor(key: sortTerm, ascending: ascending, selector: #selector(NSString.localizedCaseInsensitiveCompare));
            request.sortDescriptors = [sortBy];
        }
        return NSFetchedResultsController<Event>(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: groupBy, cacheName: nil);
    }
    
    @objc public func isUserInEvent(user: User?) -> Bool {
        guard let user = user, let teams = teams else {
            return false;
        }
        for team in teams {
            if let users = team.users {
                if users.contains(user) {
                    return true;
                }
            }
        }
        print("User \(user.name ?? "") is not in the event \(self.name ?? "")");
        return false;
    }
    
    @objc public func form(observation: Observation) -> Form? {
        return observation.primaryEventForm;
    }
    
    @objc public func form(id: NSNumber?) -> Form? {
        guard let id = id, let managedObjectContext = self.managedObjectContext, let remoteId = remoteId else {
            return nil
        }
        return Form.mr_findFirst(with: NSPredicate(format: "\(FormKey.eventId.key) == %@ AND \(FormKey.formId.key) == %@", remoteId, id), in: managedObjectContext)
    }
    
    @objc public var forms: [Form]? {
        get {
            guard let managedObjectContext = managedObjectContext, let remoteId = remoteId else {
                return nil
            }
            return Form.mr_findAllSorted(by: "order", ascending: true, with: NSPredicate(format: "eventId == %@", remoteId), in: managedObjectContext) as? [Form]
        }
    }
    
    @objc public var nonArchivedForms: [Form]? {
        get {
            guard let managedObjectContext = managedObjectContext, let remoteId = remoteId else {
                return nil
            }
            return Form.mr_findAllSorted(by: "order", ascending: true, with: NSPredicate(format: "eventId == %@ AND \(FormKey.archived.key) == false", remoteId), in: managedObjectContext) as? [Form]
        }
    }
}
