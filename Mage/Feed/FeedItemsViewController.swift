//
//  FeedItemsView.swift
//  MAGE
//
//  Created by Daniel Barela on 6/11/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Kingfisher

@objc class FeedItemsViewController : UITableViewController {
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<FeedItem> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<FeedItem> = FeedItem.fetchRequest();
        fetchRequest.predicate = NSPredicate(format: "feed = %@", self.feed);
        
        // Configure Fetch Request
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "remoteId", ascending: true)]
        
        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: NSManagedObjectContext.mr_default(), sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    let cellReuseIdentifier = "cell";
    
    let feed : Feed
    var selectionDelegate: FeedItemSelectionDelegate?
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc public init(feed:Feed, selectionDelegate: FeedItemSelectionDelegate? = nil) {
        self.feed = feed
        self.selectionDelegate = selectionDelegate;
        super.init(style: .grouped)
        self.title = feed.title;
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(FeedItemTableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
    }
    
    override func themeDidChange(_ theme: MageTheme) {
        self.navigationController?.navigationBar.barTintColor = UIColor.primary();
        self.navigationController?.navigationBar.tintColor = UIColor.navBarPrimaryText();
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension

        if (self.feed.itemTemporalProperty == nil) {
            tableView.estimatedRowHeight = 72
        } else {
            tableView.estimatedRowHeight = 88
        }
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("Unable to Perform Fetch Request")
            print("\(fetchError), \(fetchError.localizedDescription)")
        }
        self.registerForThemeChanges();
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let items = fetchedResultsController.fetchedObjects else { return 0 }
        return items.count
    }
    
    override func numberOfSections(in: UITableView) -> Int {
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView();
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell;
        let feedCell: FeedItemTableViewCell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! FeedItemTableViewCell;
        
        let feedItem = fetchedResultsController.object(at: indexPath)
        feedCell.populate(feedItem: feedItem);
        cell = feedCell;
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let feedItem = fetchedResultsController.object(at: indexPath)
        if (selectionDelegate != nil) {
            self.selectionDelegate?.feedItemSelected(feedItem);
        } else {
            let feedItemViewController: FeedItemViewViewController = FeedItemViewViewController(feedItem: feedItem);
            self.navigationController?.pushViewController(feedItemViewController, animated: true);
        }
    }
}

extension FeedItemsViewController : NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        @unknown default:
            print("...")
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}
