//
//  ObservationListCard.swift
//  MAGE
//
//  Created by Daniel Barela on 1/21/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCCard;

@objc class ObservationListCardCell: UITableViewCell {
    
    private var constructed = false;
    private var didSetUpConstraints = false;
    private var observation: Observation?;
    private var actionsDelegate: ObservationActionsDelegate?;
    
    private lazy var card: MDCCard = {
        let card = MDCCard(forAutoLayout: ());
        card.enableRippleBehavior = true
        card.addTarget(self, action: #selector(tap(_:)), for: .touchUpInside)
        return card;
    }()
    
    private lazy var compactView: ObservationCompactView = {
        let view = ObservationCompactView(cornerRadius: self.card.cornerRadius, includeAttachments: true);
        view.isUserInteractionEnabled = false;
        return view;
    }()
    
    @objc public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        construct()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming) {
        self.backgroundColor = scheme.colorScheme.backgroundColor;
        card.applyTheme(withScheme: scheme);
        compactView.applyTheme(withScheme: scheme);
    }
    
    @objc func tap(_ card: MDCCard) {
        if let safeObservation = observation {
            // let the ripple dissolve before transitioning otherwise it looks weird
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.actionsDelegate?.viewObservation?(safeObservation);
            }
        }
    }
    
    @objc public func configure(observation: Observation, scheme: MDCContainerScheming?, actionsDelegate: ObservationActionsDelegate?, attachmentSelectionDelegate: AttachmentSelectionDelegate?) {
        self.observation = observation;
        card.accessibilityLabel = "observation card \(observation.objectID.uriRepresentation().absoluteString)"
        self.actionsDelegate = actionsDelegate;
        
        compactView.configure(observation: observation, scheme: scheme, actionsDelegate: actionsDelegate, attachmentSelectionDelegate: attachmentSelectionDelegate);
        
        if let safeScheme = scheme {
            applyTheme(withScheme: safeScheme);
        }
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            card.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8));
            compactView.autoPinEdgesToSuperviewEdges();
            didSetUpConstraints = true;
        }
        super.updateConstraints();
    }
    
    func construct() {
        if (!constructed) {
            self.contentView.addSubview(card);
            card.addSubview(compactView);
            setNeedsUpdateConstraints();
            constructed = true;
        }
    }
    
}
