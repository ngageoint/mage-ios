//
//  PersonTableViewCell.swift
//  MAGE
//
//  Created by Daniel Barela on 7/14/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout
import Kingfisher
import MaterialComponents.MDCCard;

class PersonTableViewCell : UITableViewCell {
    private var constructed = false;
    private var location: Location?;
    private var user: User?;
    private var didSetUpConstraints = false;
    private var actionsDelegate: UserActionsDelegate?;
    private var scheme: MDCContainerScheming?;
    
    private lazy var card: MDCCard = {
        let card = MDCCard(forAutoLayout: ());
        card.enableRippleBehavior = true
        card.addTarget(self, action: #selector(tap(_:)), for: .touchUpInside)
        return card;
    }()
    
    @objc func tap(_ card: MDCCard) {
        if let user = self.user {
            // let the ripple dissolve before transitioning otherwise it looks weird
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.actionsDelegate?.viewUser?(user);
            }
        }
    }
    
    private lazy var actionsView: UserActionsView = {
        let view = UserActionsView(user: self.user, userActionsDelegate: actionsDelegate, scheme: scheme);
        return view;
    }()
    
    private lazy var userSummaryView: UserSummaryView = {
        let view = UserSummaryView();
        return view;
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        construct();
    }
    
    func construct() {
        if (!constructed) {
            self.contentView.addSubview(card);
            card.addSubview(userSummaryView);
            card.addSubview(actionsView);
            setNeedsUpdateConstraints();
            constructed = true;
        }
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming?) {
        guard let scheme = scheme else {
            return
        }

        self.scheme = scheme;
        self.backgroundColor = scheme.colorScheme.backgroundColor;
        card.applyTheme(withScheme: scheme);
        userSummaryView.applyTheme(withScheme: scheme);
        actionsView.applyTheme(withScheme: scheme);
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(location: Location, actionsDelegate: UserActionsDelegate?, scheme: MDCContainerScheming?) {
        self.location = location;
        configure(user: location.user, actionsDelegate: actionsDelegate, scheme: scheme);
    }
    
    func configure(user: User?, actionsDelegate: UserActionsDelegate?, scheme: MDCContainerScheming?) {
        self.user = user;
        self.actionsDelegate = actionsDelegate;
        if let user = self.user {
            card.accessibilityLabel = "user card \(user.username ?? "")"
            userSummaryView.populate(item: user);
            actionsView.populate(user: user, delegate: actionsDelegate);
        }
        applyTheme(withScheme: scheme);
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            card.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8));
            userSummaryView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
            actionsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top);
            userSummaryView.autoPinEdge(.bottom, to: .top, of: actionsView, withOffset: 8);
            didSetUpConstraints = true;
        }
        super.updateConstraints();
    }
}
