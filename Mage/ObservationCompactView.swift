//
//  ObservationCompactView.swift
//  MAGE
//
//  Created by Daniel Barela on 5/28/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class ObservationCompactView: UIView {
    private var constructed = false;
    private var didSetUpConstraints = false;
    private var observation: Observation?;
    private weak var actionsDelegate: ObservationActionsDelegate?;
    private var scheme: MDCContainerScheming?;
    private var cornerRadius:CGFloat = 0.0;
    private var includeAttachments: Bool = false;
    
    private lazy var stackView: PassThroughStackView = {
        let stackView = PassThroughStackView(forAutoLayout: ());
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.distribution = .fill
        stackView.directionalLayoutMargins = .zero;
        stackView.isLayoutMarginsRelativeArrangement = false;
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        stackView.clipsToBounds = true;
        return stackView;
    }()
    
    public lazy var importantView: ObservationImportantView = {
        let importantView = ObservationImportantView(observation: self.observation, cornerRadius: self.cornerRadius);
        return importantView;
    }()
    
    private lazy var observationSummaryView: ObservationSummaryView = {
        let summary = ObservationSummaryView();
        summary.isUserInteractionEnabled = false;
        return summary;
    }()
    
    private lazy var observationActionsView: ObservationListActionsView = {
        let actions = ObservationListActionsView(observation: self.observation, observationActionsDelegate: actionsDelegate, scheme: nil);
        return actions;
    }();
    
    private lazy var attachmentSlideshow: AttachmentSlideShow = {
        let actions = AttachmentSlideShow();
        actions.isUserInteractionEnabled = true;
        return actions;
    }();
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        if result == self { return nil }
        return result
    }
    
    init(cornerRadius: CGFloat, includeAttachments: Bool = false, actionsDelegate: ObservationActionsDelegate? = nil, scheme: MDCContainerScheming? = nil) {
        super.init(frame: CGRect.zero);
        translatesAutoresizingMaskIntoConstraints = false;
        self.cornerRadius = cornerRadius;
        self.actionsDelegate = actionsDelegate;
        self.scheme = scheme;
        self.includeAttachments = includeAttachments;
        construct()
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming?) {
        self.scheme = scheme;
        importantView.applyTheme(withScheme: scheme);
        observationSummaryView.applyTheme(withScheme: scheme);
        observationActionsView.applyTheme(withScheme: scheme);
        attachmentSlideshow.applyTheme(withScheme: scheme);
    }
    
    @objc public func configure(observation: Observation, scheme: MDCContainerScheming?, actionsDelegate: ObservationActionsDelegate?, attachmentSelectionDelegate: AttachmentSelectionDelegate?) {
        self.observation = observation;
        self.actionsDelegate = actionsDelegate;
        if (observation.isImportant) {
            importantView.populate(observation: observation);
            importantView.isHidden = false;
        } else {
            importantView.isHidden = true;
        }
        observationSummaryView.populate(observation: observation);
        observationActionsView.populate(observation: observation, delegate: actionsDelegate);
        if includeAttachments, let attachments = observation.attachments, attachments.filter({ attachment in
            attachment.url != nil
        }).count > 0 {
            attachmentSlideshow.populate(observation: observation, attachmentSelectionDelegate: attachmentSelectionDelegate);
            attachmentSlideshow.isHidden = false;
        } else {
            attachmentSlideshow.isHidden = true;
        }
        applyTheme(withScheme: scheme);
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            stackView.autoPinEdgesToSuperviewEdges();
            didSetUpConstraints = true;
        }
        super.updateConstraints();
    }
    
    func construct() {
        if (!constructed) {
            self.addSubview(stackView)
            self.stackView.addArrangedSubview(importantView);
            self.stackView.addArrangedSubview(observationSummaryView);
            self.stackView.addArrangedSubview(attachmentSlideshow);
            self.stackView.addArrangedSubview(observationActionsView);
            setNeedsUpdateConstraints();
            constructed = true;
        }
    }
}
