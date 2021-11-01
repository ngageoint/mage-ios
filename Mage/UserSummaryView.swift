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

class UserSummaryView: CommonSummaryView<User, UserActionsDelegate> {
    
    private weak var user: User?;
    private var userActionsDelegate: UserActionsDelegate?;
    private var didSetUpConstraints = false;
    
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
        
        avatarImage.tintColor = scheme.colorScheme.primaryColor;
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
        
        primaryField.text = item.name;
        
        // we do not want the date to word break so we replace all spaces with a non word breaking spaces
        var timeText = "";
        if let itemDate: NSDate = item.location?.timestamp as NSDate? {
            timeText = itemDate.formattedDisplay().uppercased().replacingOccurrences(of: " ", with: "\u{00a0}") ;
        }
        timestamp.text = timeText;
    }
}
