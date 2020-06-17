//
//  FeedItemPropertyCell.swift
//  MAGE
//
//  Created by Daniel Barela on 6/15/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout

class FeedItemPropertyCell : UITableViewCell {

    public lazy var keyField: UILabel = {
        let primaryField = UILabel(forAutoLayout: ());
        primaryField.font = UIFont.systemFont(ofSize: 16.0, weight: .regular);
        primaryField.textColor = UIColor.black.withAlphaComponent(0.87);
        return primaryField;
    }()
    
    public lazy var valueField: UILabel = {
        let secondaryField = UILabel(forAutoLayout: ());
        secondaryField.font = UIFont.systemFont(ofSize: 14.0, weight: .regular);
        secondaryField.textColor = UIColor.black.withAlphaComponent(0.60);
        return secondaryField;
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(keyField);
        self.contentView.addSubview(valueField);
        
        keyField.autoPinEdge(.bottom, to: .top, of: contentView, withOffset: 32);
        keyField.autoPinEdge(toSuperviewEdge: .leading, withInset: 16);
        keyField.autoPinEdge(toSuperviewEdge: .trailing, withInset: 16);
        valueField.autoPinEdge(.bottom, to: .bottom, of: keyField, withOffset: 20);
        valueField.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16), excludingEdge: .top);
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
