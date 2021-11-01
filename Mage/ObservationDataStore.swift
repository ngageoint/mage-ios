//
//  ObservationDataStore.swift
//  MAGE
//
//  Created by Daniel Barela on 1/27/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class ObservationDataStore: NSObject {
    
    var tableView: UITableView;
    var scheme: MDCContainerScheming?;
    var observations: Observations?;
    weak var observationActionsDelegate: ObservationActionsDelegate?;
    weak var attachmentSelectionDelegate: AttachmentSelectionDelegate?;
    
    public init(tableView: UITableView, observationActionsDelegate: ObservationActionsDelegate?, attachmentSelectionDelegate: AttachmentSelectionDelegate?, scheme: MDCContainerScheming?) {
        self.scheme = scheme;
        self.tableView = tableView;
        self.observationActionsDelegate = observationActionsDelegate;
        self.attachmentSelectionDelegate = attachmentSelectionDelegate;
        super.init();
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
    }
    
    func applyTheme(withContainerScheme containerScheme: MDCContainerScheming?) {
        self.scheme = containerScheme;
    }
    
    func startFetchController(observations: Observations? = nil) {
        if (observations == nil) {
            self.observations = Observations.list();
        } else {
            self.observations = observations;
        }
        self.observations?.delegate = self;
        do {
            try self.observations?.fetchedResultsController.performFetch()
        } catch {
            print("Error fetching observations \(error) \(error.localizedDescription)")
        }
        self.tableView.reloadData();
    }
    
    func updatePredicates() {
        self.observations?.fetchedResultsController.fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: Observations.getPredicatesForObservations() as! [NSPredicate]);
        do {
            try self.observations?.fetchedResultsController.performFetch()
        } catch {
            print("Error fetching observations \(error) \(error.localizedDescription)")
        }
        self.tableView.reloadData();
    }
}

extension ObservationDataStore: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo: NSFetchedResultsSectionInfo? = self.observations?.fetchedResultsController.sections?[section];
        return sectionInfo?.numberOfObjects ?? 0;
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.observations?.fetchedResultsController.sections?.count ?? 0;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cellClass: ObservationListCardCell.self, forIndexPath: indexPath);
        configure(cell: cell, at: indexPath);
        return cell;
    }
    
    func configure(cell: ObservationListCardCell, at indexPath: IndexPath) {
        let observation: Observation = self.observations?.fetchedResultsController.object(at: indexPath) as! Observation;
        cell.configure(observation: observation, scheme: scheme, actionsDelegate: observationActionsDelegate, attachmentSelectionDelegate: attachmentSelectionDelegate)
    }
}

extension ObservationDataStore: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude;
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48.0;
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView();
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sectionInfo: NSFetchedResultsSectionInfo = self.observations?.fetchedResultsController.sections?[section] else {
            return nil;
        }
        
        return ObservationTableHeaderView(name: sectionInfo.name, andScheme: self.scheme);
    }
}

extension ObservationDataStore: NSFetchedResultsControllerDelegate {
    
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
