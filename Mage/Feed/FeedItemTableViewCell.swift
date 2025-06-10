//
//  FeedItemTableViewCell.swift
//  MAGE
//
//  Created by Daniel Barela on 6/12/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout
import Kingfisher
//import MaterialComponents.MDCCard;

class FeedItemTableViewCell : UITableViewCell {
    private var constructed = false;
    private var feedItem: FeedItem?;
    private var didSetUpConstraints = false;
    private var actionsDelegate: FeedItemActionsDelegate?;
    private var scheme: AppContainerScheming?;

    // TODO: BRENT - get rid of MDCCard
    private lazy var card: UIView = {
        let card = UIView(forAutoLayout: ());
//        card.enableRippleBehavior = true
//        card.addTarget(self, action: #selector(tap(_:)), for: .touchUpInside)
        return card;
    }()
    
    @objc func tap(_ card: UIView) {
        if let feedItem = self.feedItem {
            // let the ripple dissolve before transitioning otherwise it looks weird
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.actionsDelegate?.viewFeedItem?(feedItem: feedItem);
            }
        }
    }
    
    private lazy var actionsView: FeedItemActionsView = {
        let view = FeedItemActionsView(feedItem: feedItem, actionsDelegate: actionsDelegate, scheme: scheme)
        return view;
    }()
    
    private lazy var feedItemView: FeedItemSummary = {
        let view = FeedItemSummary();
        return view;
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        construct();
    }
    
    func construct() {
        if (!constructed) {
            self.contentView.addSubview(card);
            card.addSubview(feedItemView);
            card.addSubview(actionsView);
            setNeedsUpdateConstraints();
            constructed = true;
        }
    }
    
    func applyTheme(withScheme scheme: AppContainerScheming?) {
        guard let scheme = scheme else {
            return
        }

        self.scheme = scheme;
        self.backgroundColor = scheme.colorScheme.backgroundColor;
//        card.applyTheme(withScheme: scheme);
        feedItemView.applyTheme(withScheme: scheme);
        actionsView.applyTheme(withScheme: scheme);
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(feedItem: FeedItem, actionsDelegate: FeedItemActionsDelegate?, scheme: AppContainerScheming?) {
        self.feedItem = feedItem;
        self.actionsDelegate = actionsDelegate;
        card.accessibilityLabel = "feed item card \(feedItem.title ?? "")"
        feedItemView.populate(item: feedItem, actionsDelegate: actionsDelegate);
        actionsView.populate(feedItem: feedItem, delegate: actionsDelegate);
        applyTheme(withScheme: scheme);
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            card.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8));
            feedItemView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
            actionsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top);
            feedItemView.autoPinEdge(.bottom, to: .top, of: actionsView, withOffset: 8);
            didSetUpConstraints = true;
        }
        super.updateConstraints();
    }
}
