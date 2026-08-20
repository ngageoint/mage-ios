//
//  UserSummaryView.swift
//  MAGE
//
//  Created by Daniel Barela on 7/5/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import CoreImage
import Kingfisher
import Persistence

class UserSummaryView: CommonSummaryView<User, UserActionsDelegate> {
    
    private weak var user: User?;
    private var userActionsDelegate: UserActionsDelegate?;
    private var didSetUpConstraints = false;
    private var fetchedResultsController: NSFetchedResultsController<User>?
    
    lazy var avatarImage: UIImageView = {
        let avatarImage = UserAvatarUIImageView(image: nil);
        avatarImage.configureForAutoLayout();
        avatarImage.autoSetDimensions(to: CGSize(width: 48, height: 48));
        return avatarImage;
    }()
    
    override var itemImage: UIImageView {
        get { return avatarImage }
        set { avatarImage = newValue }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override init(imageOverride: UIImage? = nil, hideImage: Bool = false) {
        super.init(imageOverride: imageOverride, hideImage: hideImage);
        isUserInteractionEnabled = false;
    }
    
    override func applyTheme(withScheme scheme: MDCContainerScheming?) {
        super.applyTheme(withScheme: scheme);

        guard let scheme = scheme else {
            return
        }
        
        avatarImage.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
    }
    
    override func populate(item: User, actionsDelegate: UserActionsDelegate? = nil) {
        self.user = item;
        self.userActionsDelegate = actionsDelegate;
        
        if (self.imageOverride != nil) {
            avatarImage.image = self.imageOverride;
        } else {
            self.avatarImage.kf.indicatorType = .activity;
            (avatarImage as! UserAvatarUIImageView).setUser(user: item);
            let cacheOnly = DataConnectionUtilities.shouldFetchAvatars();
            (avatarImage as! UserAvatarUIImageView).showImage(cacheOnly: cacheOnly);
        }
        if let name = item.name {
            primaryField.text = name;
            fetchedResultsController?.delegate = nil
            fetchedResultsController = nil
        } else if let remoteId = item.remoteId, fetchedResultsController == nil {
            primaryField.text = "unknown";
            let request = User.fetchRequest()
            request.predicate = NSPredicate(
                format: "remoteId == %@",
                remoteId
            )
            request.sortDescriptors = [NSSortDescriptor(key: "remoteId", ascending: true)]
            fetchedResultsController = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: PersistenceContainer.shared
                    .get().viewContext,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            fetchedResultsController?.delegate = self
            try? fetchedResultsController?.performFetch()
            if let user = fetchedResultsController?.fetchedObjects?.first {
                populate(item: user, actionsDelegate: self.userActionsDelegate)
            }
        }
        
        // we do not want the date to word break so we replace all spaces with a non word breaking spaces
        var timeText = "";
        if let itemDate: NSDate = item.location?.timestamp as NSDate? {
            timeText = itemDate.formattedDisplay().uppercased().replacingOccurrences(of: " ", with: "\u{00a0}") ;
        }
        timestamp.text = timeText;
    }
}

extension UserSummaryView: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if let user = anObject as? User {
            populate(item: user, actionsDelegate: self.userActionsDelegate)
        }
    }
}
