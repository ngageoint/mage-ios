//
//  EventTableDataSource.m
//  MAGE
//
//

import CoreData
import UIKit

class EventTableDataSource: NSObject {
    var scheme: MDCContainerScheming?
    var eventSelectionDelegate: EventSelectionDelegate?
    var otherFetchedResultsController: NSFetchedResultsController<Event>?
    var recentFetchedResultsController:NSFetchedResultsController<Event>?
    var filteredFetchedResultsController:NSFetchedResultsController<Event>?
    
    var disclosureIndicator: UICellAccessory?
    var cellRegistration: UICollectionView.CellRegistration<EventCell, EventScheme>?
    var headerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewListCell>?
    var footerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewListCell>?

    public init(eventSelectionDelegate: EventSelectionDelegate? = nil, scheme: MDCContainerScheming? = nil) {
        self.scheme = scheme
        self.eventSelectionDelegate = eventSelectionDelegate
        super.init()
    }
    
    func startFetchController() {

        self.disclosureIndicator = self.disclosureIndicator ?? UICellAccessory.disclosureIndicator(options: .init(tintColor: scheme?.colorScheme.primaryColorVariant))
        cellRegistration = cellRegistration ?? UICollectionView.CellRegistration<EventCell, EventScheme> { (cell, indexPath, item) in
            cell.event = item.event
            cell.scheme = item.scheme
            if let disclosureIndicator = self.disclosureIndicator {
                cell.accessories = [disclosureIndicator]//, customAccessory]
            }
        }
        
        headerRegistration = UICollectionView.SupplementaryRegistration
        <UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader) {
            [unowned self] (headerView, elementKind, indexPath) in
            
            var headerText = ""
            if let filteredFetchedResultsController = filteredFetchedResultsController {
                headerText = "\(filteredFetchedResultsController.accessibilityLabel ?? "Filtered Events") (\(filteredFetchedResultsController.fetchedObjects?.count ?? 0))"
            }
            if indexPath.section == 1 {
                headerText = "\(recentFetchedResultsController?.accessibilityLabel ?? "My Recent Events") (\(recentFetchedResultsController?.fetchedObjects?.count ?? 0))"
            }
            if indexPath.section == 2 {
                headerText = "\(otherFetchedResultsController?.accessibilityLabel ?? "Other Events") (\(otherFetchedResultsController?.fetchedObjects?.count ?? 0))"
            }
            var configuration = headerView.defaultContentConfiguration()
            configuration.text = headerText
            
            headerView.contentConfiguration = configuration
        }
        
        footerRegistration = UICollectionView.SupplementaryRegistration
        <UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionFooter) {
            [unowned self] (headerView, elementKind, indexPath) in
            
            var headerText = ""
            if filteredFetchedResultsController != nil {
                headerText = "End of Results"
            }
            if indexPath.section == 1 {
                headerText = ""
            }
            if indexPath.section == 2 {
                headerText = ""
            }
            var configuration = headerView.defaultContentConfiguration()
            configuration.text = headerText
            
            headerView.contentConfiguration = configuration
        }
        
        refreshEventData()
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
        
        var predicate: NSPredicate? = nil
        if filter == "" {
            predicate = NSPredicate(format: "TRUEPREDICATE")
        } else {
            predicate = NSPredicate(format: "name contains[cd] %@", filter)
        }
                
        if let filteredFetchedResultsController = filteredFetchedResultsController {
            filteredFetchedResultsController.fetchRequest.predicate = predicate
        } else {
            filteredFetchedResultsController = Event.caseInsensitiveSortFetchAll(sortTerm: "name", ascending: true, predicate: predicate, groupBy: nil, context: NSManagedObjectContext.mr_default())
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

extension EventTableDataSource : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var event: Event? = nil
        if let filteredFetchedResultsController = filteredFetchedResultsController {
            event = filteredFetchedResultsController.fetchedObjects?[indexPath.row]
        } else if indexPath.section == 1 {
            event = recentFetchedResultsController?.fetchedObjects?[indexPath.row]
        } else if indexPath.section == 2 {
            event = otherFetchedResultsController?.fetchedObjects?[indexPath.row]
        }
        
        let cell = collectionView.dequeueConfiguredReusableCell(
            using: cellRegistration!, for: indexPath, item: EventScheme(event: event, scheme: scheme))
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if filteredFetchedResultsController != nil {
            return 1
        }
        if otherFetchedResultsController?.fetchedObjects?.count == 0 && recentFetchedResultsController?.fetchedObjects?.count == 0 {
            return 0
        }
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration!, for: indexPath)
        }
        return collectionView.dequeueConfiguredReusableSupplementary(using: footerRegistration!, for: indexPath)
    }
}

extension EventTableDataSource : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
