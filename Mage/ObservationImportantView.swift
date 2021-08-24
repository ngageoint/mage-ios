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
    weak var observation: Observation?;
    var scheme: MDCContainerScheming?;
    var reasonLabel: UILabel = UILabel(forAutoLayout: ());
    var flaggedByLabel: UILabel = UILabel(forAutoLayout: ());
    
    private lazy var flagImage: UIImageView = {
        let flag = UIImage(named: "flag");
        let flagView = UIImageView(image: flag);
        return flagView;
    }()
    
    func applyTheme(withScheme scheme: MDCContainerScheming) {
        reasonLabel.textColor = UIColor.black.withAlphaComponent(0.87);
        reasonLabel.font = scheme.typographyScheme.body2;
        flaggedByLabel.textColor = UIColor.black.withAlphaComponent(0.6);
        flaggedByLabel.font = scheme.typographyScheme.overline;
        flagImage.tintColor = UIColor.black.withAlphaComponent(0.87);
    }
    
    public convenience init(observation: Observation?, cornerRadius: CGFloat, scheme: MDCContainerScheming? = nil) {
        self.init(frame: CGRect.zero);
        layer.cornerRadius = cornerRadius;
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner];
        self.observation = observation;
        self.scheme = scheme;
        self.configureForAutoLayout();
        layoutView();
        self.backgroundColor = MDCPalette.orange.accent400;
        if let safeObservation = observation {
            populate(observation: safeObservation);
        }
        if let safeScheme = scheme {
            applyTheme(withScheme: safeScheme);
        }
    }
    
    func layoutView() {
        self.addSubview(flagImage);
        self.addSubview(flaggedByLabel);
        self.addSubview(reasonLabel);
        reasonLabel.accessibilityLabel = "important reason";
        flagImage.autoPinEdge(toSuperviewEdge: .top, withInset: 8, relation: .greaterThanOrEqual);
        flagImage.autoPinEdge(toSuperviewEdge: .bottom, withInset: 8, relation: .greaterThanOrEqual);
        flagImage.autoPinEdge(toSuperviewEdge: .left, withInset: 16);
        flagImage.autoSetDimensions(to: CGSize(width: 32, height: 32));
        flagImage.autoAlignAxis(toSuperviewAxis: .horizontal);
        flaggedByLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 56, bottom: 0, right: 8), excludingEdge: .bottom);
        reasonLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 56, bottom: 8, right: 8), excludingEdge: .top);
        reasonLabel.autoPinEdge(.top, to: .bottom, of: flaggedByLabel, withOffset: 8);
    }
    
    public func populate(observation: Observation) {
        self.observation = observation;
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
