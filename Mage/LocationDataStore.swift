//
//  LocationDataStore.swift
//  MAGE
//
//  Created by Daniel Barela on 7/14/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class LocationDataStore: NSObject {
    
    var tableView: UITableView;
    var scheme: MDCContainerScheming?;
    var locations: Locations?;
    var actionsDelegate: UserActionsDelegate?;
    
    public init(tableView: UITableView, actionsDelegate: UserActionsDelegate?, scheme: MDCContainerScheming?) {
        self.scheme = scheme;
        self.tableView = tableView;
        self.actionsDelegate = actionsDelegate;
        super.init();
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
    }
    
    func applyTheme(withContainerScheme containerScheme: MDCContainerScheming!) {
        self.scheme = containerScheme;
    }
    
    func startFetchController(locations: Locations? = nil) {
        if (locations == nil) {
            self.locations = Locations.forAllUsers();
        } else {
            self.locations = locations;
        }
        self.locations?.delegate = self;
        do {
            try self.locations?.fetchedResultsController.performFetch()
        } catch {
            print("Error fetching locations \(error) \(error.localizedDescription)")
        }
        self.tableView.reloadData();
    }
    
    func updatePredicates() {
        self.locations?.fetchedResultsController.fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: Locations.getPredicatesForLocations() as! [NSPredicate]);
        do {
            try self.locations?.fetchedResultsController.performFetch()
        } catch {
            print("Error fetching users \(error) \(error.localizedDescription)")
        }
        self.tableView.reloadData();
    }
}

extension LocationDataStore: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo: NSFetchedResultsSectionInfo? = self.locations?.fetchedResultsController.sections?[section];
        return sectionInfo?.numberOfObjects ?? 0;
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.locations?.fetchedResultsController.sections?.count ?? 0;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: PersonTableViewCell.self, forIndexPath: indexPath);
        configure(cell: cell, at: indexPath);
        return cell;
    }
    
    func configure(cell: PersonTableViewCell, at indexPath: IndexPath) {
        if let location: Location = self.locations?.fetchedResultsController.object(at: indexPath) {
            cell.configure(location: location, actionsDelegate: actionsDelegate, scheme: scheme);
        }
    }
}

extension LocationDataStore: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude;
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude;
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView();
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView();
    }
}

extension LocationDataStore: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let insertIndexPath = newIndexPath {
                self.tableView.insertRows(at: [insertIndexPath], with: .fade);
            }
            break;
        case .delete:
            if let deleteIndexPath = indexPath {
                self.tableView.deleteRows(at: [deleteIndexPath], with: .fade);
            }
            break;
        case .update:
            if let updateIndexPath = indexPath {
                self.tableView.reloadRows(at: [updateIndexPath], with: .none);
            }
            break;
        case .move:
            if let deleteIndexPath = indexPath {
                self.tableView.deleteRows(at: [deleteIndexPath], with: .fade);
            }
            if let insertIndexPath = newIndexPath {
                self.tableView.insertRows(at: [insertIndexPath], with: .fade);
            }
            break;
        default:
            break;
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade);
            break;
        case .delete:
            self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade);
            break;
        default:
            break;
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates();
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates();
    }
}
