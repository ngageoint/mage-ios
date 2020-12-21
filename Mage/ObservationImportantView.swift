//
//  ObservationImportantView.swift
//  MAGE
//
//  Created by Daniel Barela on 12/16/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout

class ObservationImportantView: UIView {
    var observation: Observation?;
    
    private lazy var flaggedByLabel: UILabel = {
        let containerScheme = globalContainerScheme();
        let label = UILabel(forAutoLayout: ());
        label.textColor = containerScheme.colorScheme.onSecondaryColor.withAlphaComponent(0.6);
        label.font = containerScheme.typographyScheme.overline;
        return label;
    }()
    
    private lazy var reasonLabel: UILabel = {
        let containerScheme = globalContainerScheme();
        let label = UILabel(forAutoLayout: ());
        label.textColor = containerScheme.colorScheme.onSecondaryColor.withAlphaComponent(0.87);
        label.font = containerScheme.typographyScheme.body2;
        return label;
    }()
    
    private lazy var flagImage: UIImageView = {
        let flag = UIImage(named: "flag");
        let flagView = UIImageView(image: flag);
        flagView.tintColor = globalContainerScheme().colorScheme.onSecondaryColor;
        return flagView;
    }()
    
    override func themeDidChange(_ theme: MageTheme) {
        self.backgroundColor = globalContainerScheme().colorScheme.secondaryColor;
    }
    
    public convenience init(observation: Observation, cornerRadius: CGFloat) {
        self.init(frame: CGRect.zero);
        layer.cornerRadius = cornerRadius;
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner];
        self.observation = observation;
        self.configureForAutoLayout();
        layoutView();
        populate(observation: observation);
        
        registerForThemeChanges();
    }
    
    func layoutView() {
        self.addSubview(flagImage);
        self.addSubview(flaggedByLabel);
        self.addSubview(reasonLabel);
        flagImage.autoPinEdge(toSuperviewEdge: .left, withInset: 16);
        flagImage.autoSetDimensions(to: CGSize(width: 32, height: 32));
        flagImage.autoAlignAxis(toSuperviewAxis: .horizontal);
        flaggedByLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 56, bottom: 0, right: 8), excludingEdge: .bottom);
        reasonLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 56, bottom: 8, right: 8), excludingEdge: .top);
        reasonLabel.autoPinEdge(.top, to: .bottom, of: flaggedByLabel, withOffset: 8);
    }
    
    public func populate(observation: Observation) {
        let important: ObservationImportant? = observation.observationImportant;
        if let userId = important?.userId {
            let user = User.mr_findFirst(byAttribute: "remoteId", withValue: userId);
            flaggedByLabel.text = "Flagged By \(user?.name ?? "")".uppercased()
        }
        if let reason = important?.reason {
            reasonLabel.text = reason;
        }
        
    }
}
