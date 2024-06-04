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
        return ObservationCompactView(cornerRadius: 0.0, includeAttachments: false);
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
        self.translatesAutoresizingMaskIntoConstraints = false;
        
        stackView.addArrangedSubview(compactView);
        stackView.addArrangedSubview(viewObservationButtonView);
        self.addSubview(stackView);
        populateView();
        applyTheme(withScheme: self.scheme);
        NotificationCenter.default.addObserver(forName: .ObservationUpdated, object: observation, queue: .main) { [weak self] notification in
            self?.refresh()
        }
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming? = nil) {
        guard let scheme = scheme else {
            return;
        }
        self.scheme = scheme;
        self.backgroundColor = scheme.colorScheme.surfaceColor;
        compactView.applyTheme(withScheme: scheme);
        detailsButton.applyContainedTheme(withScheme: scheme);
    }
    
    func populateView() {
        guard let observation = self.observation else {
            return
        }
        
        compactView.configure(observation: observation, scheme: scheme, actionsDelegate: actionsDelegate, attachmentSelectionDelegate: attachmentSelectionDelegate);

        applyTheme(withScheme: scheme);
        
        self.setNeedsUpdateConstraints();
    }
    
    override func getHeaderColor() -> UIColor? {
        guard let observation = self.observation else {
            return .clear
        }
        if (observation.isImportant) {
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
                NotificationCenter.default.post(name: .ViewObservation, object: observation)
                self.actionsDelegate?.viewObservation?(observation);
            }
        }
    }
}

class ObservationLocationBottomSheetView: BottomSheetView {
    
    private var didSetUpConstraints = false;
    private var observation: Observation?;
    private var actionsDelegate: ObservationActionsDelegate?;
    private var attachmentSelectionDelegate: AttachmentSelectionDelegate?;
    
    private var observationLocation: ObservationLocation?
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
        return ObservationCompactView(cornerRadius: 0.0, includeAttachments: false);
    }()
    private lazy var locationView: ObservationLocationCompactView = {
        return ObservationLocationCompactView(cornerRadius: 0.0, includeAttachments: false);
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
    
    init(observationLocation: ObservationLocation, actionsDelegate: ObservationActionsDelegate? = nil, scheme: MDCContainerScheming?) {
        self.observationLocation = observationLocation
        self.actionsDelegate = actionsDelegate;
        self.observation = observationLocation.observation
        self.scheme = scheme;
        super.init(frame: CGRect.zero);
        self.translatesAutoresizingMaskIntoConstraints = false;
        if observationLocation.fieldName == Observation.PRIMARY_OBSERVATION_GEOMETRY {
            stackView.addArrangedSubview(compactView);
        } else {
            stackView.addArrangedSubview(locationView)
        }
        stackView.addArrangedSubview(viewObservationButtonView);
        self.addSubview(stackView);
        populateView();
        applyTheme(withScheme: self.scheme);
        NotificationCenter.default.addObserver(forName: .ObservationUpdated, object: observation, queue: .main) { [weak self] notification in
            self?.refresh()
        }
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming? = nil) {
        guard let scheme = scheme else {
            return;
        }
        self.scheme = scheme;
        self.backgroundColor = scheme.colorScheme.surfaceColor;
        compactView.applyTheme(withScheme: scheme);
        detailsButton.applyContainedTheme(withScheme: scheme);
    }
    
    func populateView() {
        guard let observation = self.observation, let observationLocation = self.observationLocation else {
            return
        }
        locationView.configure(observationLocation: observationLocation, scheme: scheme, actionsDelegate: actionsDelegate, attachmentSelectionDelegate: attachmentSelectionDelegate);
        compactView.configure(observation: observation, scheme: scheme, actionsDelegate: actionsDelegate, attachmentSelectionDelegate: attachmentSelectionDelegate);

        applyTheme(withScheme: scheme);
        
        self.setNeedsUpdateConstraints();
    }
    
    override func getHeaderColor() -> UIColor? {
        guard let observation = self.observation else {
            return .clear
        }
        if (observation.isImportant) {
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
                NotificationCenter.default.post(name: .ViewObservation, object: observation)
                self.actionsDelegate?.viewObservation?(observation);
            }
        }
    }
}

