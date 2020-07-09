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

class FeedItemTableViewCell : UITableViewCell {
    
    private lazy var feedItemView: FeedItemSummaryView = {
        let view = FeedItemSummaryView();
        return view;
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(feedItemView);
        feedItemView.autoPinEdgesToSuperviewEdges();
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func populate(feedItem: FeedItem) {
        feedItemView.populate(feedItem: feedItem);
    }
}