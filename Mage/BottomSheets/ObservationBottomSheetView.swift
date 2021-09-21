//
//  ObservationMapBottomSheet.swift
//  MAGE
//
//  Created by Daniel Barela on 4/6/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class ObservationBottomSheetView: BottomSheetView {
    
    private var didSetUpConstraints = false;
    private var observation: Observation?;
    private var actionsDelegate: ObservationActionsDelegate?;
    private var attachmentSelectionDelegate: AttachmentSelectionDelegate?;
    var scheme: MDCContainerScheming?;
    
    private lazy var stackView: PassThroughStackView = {
        let stackView = PassThroughStackView(forAutoLayout: ());
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.distribution = .fill;
        stackView.directionalLayoutMargins = .zero;
        stackView.isLayoutMarginsRelativeArrangement = false;
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        stackView.clipsToBounds = true;
        return stackView;
    }()
    
    private lazy var compactView: ObservationCompactView = {
        let view = ObservationCompactView(cornerRadius: 0.0, includeAttachments: false);
        return view;
    }()
    
    private lazy var detailsButton: MDCButton = {
        let detailsButton = MDCButton(forAutoLayout: ());
        detailsButton.accessibilityLabel = "More Details";
        detailsButton.setTitle("More Details", for: .normal);
        detailsButton.clipsToBounds = true;
        detailsButton.addTarget(self, action: #selector(detailsButtonTapped), for: .touchUpInside);
        return detailsButton;
    }()
    
    private lazy var viewObservationButtonView: UIView = {
        let view = UIView();
        view.addSubview(detailsButton);
        detailsButton.autoAlignAxis(toSuperviewAxis: .vertical);
        detailsButton.autoMatch(.width, to: .width, of: view, withMultiplier: 0.9);
        detailsButton.autoPinEdge(.top, to: .top, of: view);
        detailsButton.autoPinEdge(.bottom, to: .bottom, of: view);
        return view;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    init(observation: Observation, actionsDelegate: ObservationActionsDelegate? = nil, scheme: MDCContainerScheming?) {
        self.actionsDelegate = actionsDelegate;
        self.observation = observation;
        self.scheme = scheme;
        super.init(frame: CGRect.zero);
        
        stackView.addArrangedSubview(compactView);
        stackView.addArrangedSubview(viewObservationButtonView);
        self.addSubview(stackView);
        populateView();
        applyTheme(withScheme: self.scheme);
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming? = nil) {
        guard let scheme = scheme else {
            return;
        }
        self.backgroundColor = scheme.colorScheme.surfaceColor;
        compactView.applyTheme(withScheme: scheme);
        detailsButton.applyContainedTheme(withScheme: scheme);
    }
    
    func populateView() {
        guard let observation = self.observation else {
            return
        }
        
        compactView.configure(observation: observation, scheme: scheme, actionsDelegate: actionsDelegate, attachmentSelectionDelegate: attachmentSelectionDelegate);


        if let safeScheme = scheme {
            applyTheme(withScheme: safeScheme);
        }
        
        self.setNeedsUpdateConstraints();
    }
    
    override func getHeaderColor() -> UIColor? {
        guard let observation = self.observation else {
            return .clear
        }
        if (observation.isImportant()) {
            return compactView.importantView.backgroundColor;
        } else {
            return .clear;
        }
    }
    
    override func refresh() {
        guard let observation = self.observation else {
            return
        }
        compactView.configure(observation: observation, scheme: scheme, actionsDelegate: actionsDelegate, attachmentSelectionDelegate: attachmentSelectionDelegate);
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            stackView.autoPinEdgesToSuperviewEdges();
            didSetUpConstraints = true;
        }
        
        super.updateConstraints();
    }
    
    @objc func tap(_ card: MDCCard) {
        if let observation = observation {
            // let the ripple dissolve before transitioning otherwise it looks weird
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.actionsDelegate?.viewObservation?(observation);
            }
        }
    }
    
    @objc func detailsButtonTapped() {
        if let observation = observation {
            // let the ripple dissolve before transitioning otherwise it looks weird
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.actionsDelegate?.viewObservation?(observation);
            }
        }
    }
}
