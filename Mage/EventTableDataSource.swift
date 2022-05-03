//
//  EventTableDataSource.m
//  MAGE
//
//

import CoreData
import UIKit

class EventTableDataSource: NSObject {
    var tableView: UITableView
    var scheme: MDCContainerScheming?
    var eventSelectionDelegate: EventSelectionDelegate?
    var otherFetchedResultsController: NSFetchedResultsController<Event>?
    var recentFetchedResultsController:NSFetchedResultsController<Event>?
    var filteredFetchedResultsController:NSFetchedResultsController<Event>?
    var eventIdToOfflineObservationCount: [NSNumber : NSNumber] = [:]
    
    public init(tableView: UITableView, eventSelectionDelegate: EventSelectionDelegate? = nil, scheme: MDCContainerScheming? = nil) {
        self.scheme = scheme
        self.tableView = tableView
        self.eventSelectionDelegate = eventSelectionDelegate
        super.init()
    }
    
    func startFetchController() {
        refreshEventData()
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Observation")
        
        let eventExpression = NSExpression(forKeyPath: "eventId")
        let countExpression = NSExpressionDescription()
        countExpression.name = "count"
        countExpression.expression = NSExpression(forFunction: "count:", arguments: [eventExpression])
        countExpression.expressionResultType = .integer64AttributeType
        
        request.resultType = .dictionaryResultType
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        request.propertiesToGroupBy = ["eventId"]
        request.propertiesToFetch = ["eventId", countExpression]
        request.predicate = NSPredicate(format: "error != nil")
        
        do {
            let groups = try NSManagedObjectContext.mr_default().fetch(request)
            var offlineCount: [NSNumber:NSNumber] = [:]
            for group in groups {
                if let dictionary = group as? [String : NSNumber], let eventId = dictionary["eventId"], let count = dictionary["count"] {
                    offlineCount[eventId] = count
                }
            }
            eventIdToOfflineObservationCount = offlineCount
        } catch {
            NSLog("Error fetching offline observation counts \(error)")
        }
    }
    
    func refreshEventData() {
        guard let current = User.fetchCurrentUser(context: NSManagedObjectContext.mr_default()), let recentEventIds = current.recentEventIds else {
            return
        }
        updateOtherFetchedResultsController(recentEventIds: recentEventIds)
        updateRecentFetchedResultsController(recentEventIds: recentEventIds)
    }
    
    func updateOtherFetchedResultsController(recentEventIds: [NSNumber]) {
        otherFetchedResultsController = otherFetchedResultsController ?? {
            let frc = Event.caseInsensitiveSortFetchAll(sortTerm: "name", ascending: true, predicate: NSPredicate(format: "NOT (remoteId IN %@)", recentEventIds), groupBy: nil, context: NSManagedObjectContext.mr_default())
            frc?.accessibilityLabel = "Other Events"
            return frc
        }()
        do {
            try otherFetchedResultsController?.performFetch()
        } catch {
            NSLog("Error fetching other events \(error)")
        }
    }
    
    func updateRecentFetchedResultsController(recentEventIds: [NSNumber]) {
        guard let recentRequest: NSFetchRequest<Event> = Event.mr_requestAll(in: NSManagedObjectContext.mr_default()) as? NSFetchRequest<Event> else {
            return
        }
        recentRequest.predicate = NSPredicate(format: "(remoteId IN %@)", recentEventIds)
        recentRequest.includesSubentities = false
        let sortBy = NSSortDescriptor(key: "recentSortOrder", ascending: true)
        recentRequest.sortDescriptors = [sortBy]
        recentFetchedResultsController = recentFetchedResultsController ?? {
            let frc = NSFetchedResultsController(fetchRequest: recentRequest, managedObjectContext: NSManagedObjectContext.mr_default(), sectionNameKeyPath: nil, cacheName: nil)
            frc.accessibilityLabel = "My Recent Events"
            return frc
        }()
        do {
            try recentFetchedResultsController?.performFetch()
        } catch {
            NSLog("Error fetching recent events \(error)")
        }
    }
    
    func setEventFilter(filter: String?, delegate: NSFetchedResultsControllerDelegate?) {
        guard let filter = filter else {
            filteredFetchedResultsController?.delegate = nil
            filteredFetchedResultsController = nil
            return
        }
        
        if let filteredFetchedResultsController = filteredFetchedResultsController {
            filteredFetchedResultsController.fetchRequest.predicate = NSPredicate(format: "name contains[cd] %@", filter)
        } else {
            filteredFetchedResultsController = Event.caseInsensitiveSortFetchAll(sortTerm: "name", ascending: true, predicate: NSPredicate(format:"name contains[cd] %@", filter), groupBy: nil, context: NSManagedObjectContext.mr_default())
            filteredFetchedResultsController?.delegate = delegate
            filteredFetchedResultsController?.accessibilityLabel = "Filtered"
        }
        
        do {
            try filteredFetchedResultsController?.performFetch()
        } catch {
            NSLog("Error fetching filtered events \(error)")
        }
    }
}

extension EventTableDataSource : UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var event: Event? = nil
        if let filteredFetchedResultsController = filteredFetchedResultsController {
            event = filteredFetchedResultsController.fetchedObjects?[indexPath.row]
        } else if indexPath.section == 1 {
            event = recentFetchedResultsController?.fetchedObjects?[indexPath.row]
        } else if indexPath.section == 2 {
            event = otherFetchedResultsController?.fetchedObjects?[indexPath.row]
        }
        
        if let event = event, let remoteId = event.remoteId {
            Server.setCurrentEventId(remoteId)
            eventSelectionDelegate?.didSelectEvent(event: event)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if let filteredFetchedResultsController = filteredFetchedResultsController, section == 0, filteredFetchedResultsController.fetchedObjects?.count != 0 {
            return 40.0
        }
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if filteredFetchedResultsController != nil {
            return 48.0
        }
        
        if section == 0 {
            return CGFloat.leastNormalMagnitude
        }
        
        if section == 1, let fetchedObjects = recentFetchedResultsController?.fetchedObjects?.count, fetchedObjects == 0 {
            return CGFloat.leastNormalMagnitude
        }
        
        if section == 2, let fetchedObjects = otherFetchedResultsController?.fetchedObjects?.count, fetchedObjects == 0 {
            return CGFloat.leastNormalMagnitude
        }
        
        return 48.0
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if let filteredFetchedResultsController = filteredFetchedResultsController, let fetchedObjects = filteredFetchedResultsController.fetchedObjects?.count, fetchedObjects != 0 {
            return "End of Results"
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int){
        view.tintColor = UIColor.red
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87)
        header.backgroundColor = .clear
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension EventTableDataSource : UITableViewDataSource {
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let filteredFetchedResultsController = filteredFetchedResultsController {
            return filteredFetchedResultsController.fetchedObjects?.count ?? 0
        }
        if section == 1 {
            return recentFetchedResultsController?.fetchedObjects?.count ?? 0
        }
        if section == 2 {
            return otherFetchedResultsController?.fetchedObjects?.count ?? 0
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell") as! EventTableViewCell
        cell.eventName.textColor = scheme?.colorScheme.onSurfaceColor
        cell.eventDescription.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
        
        var event: Event? = nil
        if let filteredFetchedResultsController = filteredFetchedResultsController {
            event = filteredFetchedResultsController.fetchedObjects?[indexPath.row]
        } else if indexPath.section == 1 {
            event = recentFetchedResultsController?.fetchedObjects?[indexPath.row]
        } else if indexPath.section == 2 {
            event = otherFetchedResultsController?.fetchedObjects?[indexPath.row]
        }
        
        if let event = event, let remoteId = event.remoteId {
            cell.populateCell(with: event, offlineObservationCount: UInt(truncating: eventIdToOfflineObservationCount[remoteId] ?? 0))
        }
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if filteredFetchedResultsController != nil {
            return 1
        }
        if otherFetchedResultsController?.fetchedObjects?.count == 0 && recentFetchedResultsController?.fetchedObjects?.count == 0 {
            return 0
        }
        return 3
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let filteredFetchedResultsController = filteredFetchedResultsController {
            return "\(filteredFetchedResultsController.accessibilityLabel ?? "Filtered Events") (\(filteredFetchedResultsController.fetchedObjects?.count ?? 0))"
        }
        if section == 1 {
            return "\(recentFetchedResultsController?.accessibilityLabel ?? "My Recent Events") (\(recentFetchedResultsController?.fetchedObjects?.count ?? 0))"
        }
        if section == 2 {
            return "\(otherFetchedResultsController?.accessibilityLabel ?? "Other Events") (\(otherFetchedResultsController?.fetchedObjects?.count ?? 0))"
        }
        return nil
    }
}
