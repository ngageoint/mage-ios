//
//  UserSummaryView.swift
//  MAGE
//
//  Created by Daniel Barela on 7/5/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class UserSummaryView: UIView {
    
    private weak var user: User?;
    private var userActionsDelegate: UserActionsDelegate?;
    private var imageOverride: UIImage?;
    private var didSetUpConstraints = false;
    
    private lazy var stack: UIStackView = {
        let stack = UIStackView(forAutoLayout: ());
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0;
        stack.distribution = .fillProportionally
        stack.translatesAutoresizingMaskIntoConstraints = false;
        stack.isUserInteractionEnabled = false;
        return stack;
    }()
    
    private lazy var timestamp: UILabel = {
        let timestamp = UILabel(forAutoLayout: ());
        timestamp.numberOfLines = 0;
        timestamp.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return timestamp;
    }()
    
    private lazy var avatarImage: UserAvatarUIImageView = {
        let avatarImage = UserAvatarUIImageView(image: nil);
        avatarImage.configureForAutoLayout();
//        itemImage.contentMode = .scaleAspectFit;
        return avatarImage;
    }()
    
    private lazy var primaryField: UILabel = {
        let primaryField = UILabel(forAutoLayout: ());
        primaryField.setContentHuggingPriority(.defaultLow, for: .vertical)
        primaryField.numberOfLines = 0;
        return primaryField;
    }()
    
    private lazy var secondaryField: UILabel = {
        let secondaryField = UILabel(forAutoLayout: ());
        secondaryField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        secondaryField.numberOfLines = 0;
        return secondaryField;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    init(imageOverride: UIImage? = nil, userActionsDelegate: UserActionsDelegate? = nil) {
        super.init(frame: CGRect.zero);
        self.configureForAutoLayout();
        self.imageOverride = imageOverride;
        self.userActionsDelegate = userActionsDelegate;
        stack.addArrangedSubview(timestamp);
        stack.setCustomSpacing(12, after: timestamp);
        stack.addArrangedSubview(primaryField);
        stack.setCustomSpacing(8, after: primaryField);
        stack.addArrangedSubview(secondaryField);
        
        self.addSubview(stack);
        self.addSubview(avatarImage);
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            stack.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 0), excludingEdge: .right);
            avatarImage.autoSetDimensions(to: CGSize(width: 48, height: 48));
            avatarImage.autoPinEdge(.left, to: .right, of: stack, withOffset: 8);
            avatarImage.autoPinEdge(toSuperviewEdge: .right, withInset: 16);
            avatarImage.autoPinEdge(toSuperviewEdge: .top, withInset: 24);
            avatarImage.autoPinEdge(toSuperviewEdge: .bottom, withInset: 16, relation: .greaterThanOrEqual);
            
            self.autoSetDimension(.height, toSize: 90, relation: .greaterThanOrEqual)
            didSetUpConstraints = true;
        }
        super.updateConstraints();
    }
    
    func populate(user: User, userActionsDelegate: UserActionsDelegate? = nil) {
        self.user = user;
        self.userActionsDelegate = userActionsDelegate;
        
        if (self.imageOverride != nil) {
            avatarImage.image = self.imageOverride;
        } else {
            self.avatarImage.kf.indicatorType = .activity;
            avatarImage.setUser(user: user);
            avatarImage.showImage();
        }
        
        primaryField.text = user.name;
        
        if (user.location != nil) {
            let geometry = user.location?.getGeometry();
            if let point: SFPoint = geometry?.centroid() {
                if (UserDefaults.standard.showMGRS) {
                    secondaryField.text = MGRS.mgrSfromCoordinate(CLLocationCoordinate2D.init(latitude: point.y as! CLLocationDegrees, longitude: point.x as! CLLocationDegrees))
                } else {
                    secondaryField.text = String(format: "%.5f, %.5f", point.y.doubleValue, point.x.doubleValue)
                }
            }
        }
        // we do not want the date to word break so we replace all spaces with a non word breaking spaces
        var timeText = "";
        if let itemDate: NSDate = user.location?.timestamp as NSDate? {
            timeText = itemDate.formattedDisplay().uppercased().replacingOccurrences(of: " ", with: "\u{00a0}") ;
        }
        timestamp.text = timeText;
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming) {
        timestamp.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        timestamp.font = scheme.typographyScheme.overline;
        timestamp.autoSetDimension(.height, toSize: timestamp.font.pointSize);
        primaryField.textColor = scheme.colorScheme.primaryColor;
        primaryField.font = scheme.typographyScheme.headline6;
        primaryField.autoSetDimension(.height, toSize: primaryField.font.pointSize);
        secondaryField.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        secondaryField.font = scheme.typographyScheme.subtitle2;
        secondaryField.autoSetDimension(.height, toSize: secondaryField.font.pointSize);
    }
}
