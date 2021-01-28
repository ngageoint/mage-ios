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
    
    private lazy var stackView: PassThroughStackView = {
        let stackView = PassThroughStackView(forAutoLayout: ());
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.distribution = .fill
        stackView.directionalLayoutMargins = .zero;
        stackView.isLayoutMarginsRelativeArrangement = true;
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        stackView.clipsToBounds = true;
        return stackView;
    }()
    
    private lazy var importantView: ObservationImportantView = {
        let importantView = ObservationImportantView(observation: self.observation, cornerRadius: self.card.cornerRadius);
        return importantView;
    }()
    
    private lazy var observationSummaryView: ObservationSummaryView = {
        let summary = ObservationSummaryView();
        summary.isUserInteractionEnabled = false;
        return summary;
    }()
    
    private lazy var observationActionsView: ObservationListActionsView = {
        let actions = ObservationListActionsView(observation: self.observation, observationActionsDelegate: nil, scheme: nil);
        return actions;
    }();
    
    private lazy var attachmentSlideshow: AttachmentSlideShow = {
        let actions = AttachmentSlideShow();
        actions.isUserInteractionEnabled = true;
        return actions;
    }();
    
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
        importantView.applyTheme(withScheme: scheme);
        observationSummaryView.applyTheme(withScheme: scheme);
        observationActionsView.applyTheme(withScheme: scheme);
        attachmentSlideshow.applyTheme(withScheme: scheme);
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
        self.actionsDelegate = actionsDelegate;
        if (observation.isImportant()) {
            importantView.populate(observation: observation);
            importantView.isHidden = false;
        } else {
            importantView.isHidden = true;
        }
        observationSummaryView.populate(observation: observation);
        observationActionsView.populate(observation: observation, delegate: actionsDelegate);
        if (observation.attachments != nil && (observation.attachments?.count ?? 0) > 0){
            attachmentSlideshow.populate(observation: observation, attachmentSelectionDelegate: attachmentSelectionDelegate);
            attachmentSlideshow.isHidden = false;
        } else {
            attachmentSlideshow.isHidden = true;
        }
        if let safeScheme = scheme {
            applyTheme(withScheme: safeScheme);
        }
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            card.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8));
            stackView.autoPinEdgesToSuperviewEdges();
            didSetUpConstraints = true;
        }
        super.updateConstraints();
    }
    
    func construct() {
        if (!constructed) {
            self.contentView.addSubview(card);
            self.stackView.addArrangedSubview(importantView);
            self.stackView.addArrangedSubview(observationSummaryView);
            self.stackView.addArrangedSubview(attachmentSlideshow);
            self.stackView.addArrangedSubview(observationActionsView);
            self.card.addSubview(stackView);
            setNeedsUpdateConstraints();
            constructed = true;
        }
    }
    
}
