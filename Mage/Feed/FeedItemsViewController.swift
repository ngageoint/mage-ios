//
//  FeedItemsView.swift
//  MAGE
//
//  Created by Daniel Barela on 6/11/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Kingfisher
import UIKit

protocol FeedItemSelectionDelegate {
    func feedItemSelected(_ feedItem: FeedItem)
}

@objc class FeedItemsViewController : UITableViewController {
    
    var scheme: AppContainerScheming?;
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<FeedItem>? = {
        let fetchRequest: NSFetchRequest<FeedItem> = FeedItem.fetchRequest();
        fetchRequest.predicate = NSPredicate(format: "feed = %@", self.feed);
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "temporalSortValue", ascending: false), NSSortDescriptor(key: "remoteId", ascending: true)]
        
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard let context = context else { return nil }
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    private lazy var emptyView : EmptyState = {
        let view = EmptyState(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: self.tableView.bounds.size.height))
        view.configure(image: UIImage(systemName: "dot.radiowaves.up.forward"), title: "No Feed Items", description: "No feed items have been returned for this feed.", scheme: scheme)
        
        return view
    }()
    let cellReuseIdentifier = "feed_item";
    let feed: Feed
    var dataSource: UITableViewDiffableDataSource<Int, NSManagedObjectID>?
    var selectionDelegate: FeedItemSelectionDelegate?
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(feed:Feed, selectionDelegate: FeedItemSelectionDelegate? = nil, scheme: AppContainerScheming?) {
        self.feed = feed
        self.scheme = scheme;
        self.selectionDelegate = selectionDelegate;
        super.init(style: .grouped)
    }
    
    @objc public func applyTheme(withContainerScheme containerScheme: AppContainerScheming?) {
        guard let containerScheme = containerScheme else {
            return
        }
        self.scheme = containerScheme;
        self.tableView.separatorStyle = .none;
        self.view.backgroundColor = containerScheme.colorScheme.backgroundColor;
        self.tableView.backgroundColor = containerScheme.colorScheme.backgroundColor;
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = feed.title;
        tableView.rowHeight = UITableView.automaticDimension
        self.dataSource = UITableViewDiffableDataSource<Int, NSManagedObjectID>(
            tableView: tableView,
            cellProvider: { (tableView, indexPath, feedItemId) in
                guard let feedItem = try? self.fetchedResultsController?.managedObjectContext.existingObject(with: feedItemId) as? FeedItem else {
                    MageLogger.misc.debug("feed item \(feedItemId) not found in managed object context")
                    return nil
                }
                let feedCell = tableView.dequeueReusableCell(withIdentifier: self.cellReuseIdentifier, for: indexPath) as! FeedItemTableViewCell
                feedCell.configure(feedItem: feedItem, actionsDelegate: self, scheme: self.scheme);
                return feedCell
            }
        )
        tableView.delegate = self
        tableView.register(FeedItemTableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        if (self.feed.itemTemporalProperty == nil) {
            tableView.estimatedRowHeight = 72
        } else {
            tableView.estimatedRowHeight = 88
        }
        var emptySnapshot = NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>()
        emptySnapshot.appendSections([ 0 ])
        emptySnapshot.appendItems([])
        dataSource?.apply(emptySnapshot)
        do {
            try self.fetchedResultsController?.performFetch()
        } catch {
            let fetchError = error as NSError
            MageLogger.misc.error("Unable to perform fetch request")
            MageLogger.misc.error("\(fetchError), \(fetchError.localizedDescription)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        applyTheme(withContainerScheme: scheme);
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rowCount = dataSource?.snapshot().numberOfItems ?? 0
        if rowCount == 0 {
            tableView.backgroundView = emptyView
        } else {
            tableView.backgroundView = nil
        }
        return rowCount
    }
    
    override func numberOfSections(in: UITableView) -> Int {
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView();
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let feedItem = fetchedResultsController?.object(at: indexPath) {
            if (selectionDelegate != nil) {
                self.selectionDelegate?.feedItemSelected(feedItem);
            } else {
                let feedItemViewController: FeedItemViewController = FeedItemViewController(feedItem: feedItem, scheme: self.scheme);
                self.navigationController?.pushViewController(feedItemViewController, animated: true);
            }
        }
    }
}

extension FeedItemsViewController : NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<any NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        guard let dataSource = tableView?.dataSource as? UITableViewDiffableDataSource<Int, NSManagedObjectID> else {
            assertionFailure("The data source has not implemented snapshot support while it should")
            return
        }
        var snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
        let currentSnapshot = dataSource.snapshot() as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>

        let reloadIdentifiers: [NSManagedObjectID] = snapshot.itemIdentifiers.compactMap { itemIdentifier in
            guard let currentIndex = currentSnapshot.indexOfItem(itemIdentifier), let index = snapshot.indexOfItem(itemIdentifier), index == currentIndex else {
                return nil
            }
            guard let existingObject = try? controller.managedObjectContext.existingObject(with: itemIdentifier), existingObject.isUpdated else { return nil }
            return itemIdentifier
        }
        snapshot.reloadItems(reloadIdentifiers)

        let shouldAnimate = tableView?.numberOfSections != 0
        dataSource.apply(snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>, animatingDifferences: shouldAnimate)
    }
}

extension FeedItemsViewController: FeedItemActionsDelegate {
    func viewFeedItem(feedItem: FeedItem) {
        if (selectionDelegate != nil) {
            self.selectionDelegate?.feedItemSelected(feedItem);
        } else {
            let feedItemViewController: FeedItemViewController = FeedItemViewController(feedItem: feedItem, scheme: self.scheme);
            self.navigationController?.pushViewController(feedItemViewController, animated: true);
        }
    }
    
    func getDirectionsToFeedItem(_ feedItem: FeedItem, sourceView: UIView? = nil) {
        var extraActions: [UIAlertAction] = [];
        extraActions.append(UIAlertAction(title:"Bearing", style: .default, handler: { (action) in

            var image = UIImage.init(named: "observations")?.withRenderingMode(.alwaysTemplate).colorized(color: NamedColorTheme().colorScheme.primaryColor);
            if let url: URL = feedItem.iconURL {
                let size = 24;

                let processor = DownsamplingImageProcessor(size: CGSize(width: size, height: size))
                KingfisherManager.shared.retrieveImage(with: url, options: [
                    .requestModifier(ImageCacheProvider.shared.accessTokenModifier),
                    .processor(processor),
                    .scaleFactor(UIScreen.main.scale),
                    .transition(.fade(1)),
                    .cacheOriginalImage
                ]) { result in
                    switch result {
                    case .success(let value):
                        image = value.image.aspectResize(to: CGSize(width: size, height: size));
                    case .failure(_):
                        image = UIImage.init(named: "observations")?.withRenderingMode(.alwaysTemplate).colorized(color: NamedColorTheme().colorScheme.primaryColor);
                    }
                }
            }
            
            NotificationCenter.default.post(name: .StartStraightLineNavigation, object:StraightLineNavigationNotification(image: image, coordinate: feedItem.coordinate))
        }));
        ObservationActionHandler.getDirections(latitude: feedItem.coordinate.latitude, longitude: feedItem.coordinate.longitude, title: feedItem.title ?? "Feed item", viewController: self, extraActions: extraActions, sourceView: sourceView);
    }
    
    func copyLocation(_ location: String) {
        UIPasteboard.general.string = location;
        // TODO: BRENT - MaterialComponents, MDC
        MDCSnackbarManager.default.show(MDCSnackbarMessage(text: "Location \(location) copied to clipboard"))
    }
}
