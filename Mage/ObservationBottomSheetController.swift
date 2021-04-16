//
//  ObservationMapBottomSheet.swift
//  MAGE
//
//  Created by Daniel Barela on 4/6/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc class ObservationBottomSheetController: UIViewController {
    
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
    
    private lazy var dragHandleView: UIView = {
        let drag = UIView(forAutoLayout: ());
        drag.autoSetDimensions(to: CGSize(width: 50, height: 7));
        drag.clipsToBounds = true;
        drag.backgroundColor = .lightGray;
        drag.layer.cornerRadius = 3.5;
        
        let view = UIView(forAutoLayout: ());
        view.addSubview(drag);
        drag.autoAlignAxis(toSuperviewAxis: .vertical);
        drag.autoPinEdge(toSuperviewEdge: .bottom);
        drag.autoPinEdge(toSuperviewEdge: .top, withInset: 7);
        return view;
    }()
    
    private lazy var importantView: ObservationImportantView = {
        let importantView = ObservationImportantView(observation: self.observation, cornerRadius: 0);
        return importantView;
    }()
    
    private lazy var observationSummaryView: ObservationSummaryView = {
        let summary = ObservationSummaryView();//imageOverride: UIImage(named: "navigate_next_large"));
        summary.isUserInteractionEnabled = false;
        return summary;
    }()
    
    private lazy var observationActionsView: ObservationListActionsView = {
        let actions = ObservationListActionsView(observation: self.observation, observationActionsDelegate: self.actionsDelegate, scheme: self.scheme);
        return actions;
    }();
    
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
        return view;
    }()
    
    private lazy var expandView: UIView = {
        let view = UIView(forAutoLayout: ());
        view.setContentHuggingPriority(.defaultLow, for: .vertical);
        return view;
    }();
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil);
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    @objc public convenience init(observation: Observation, actionsDelegate: ObservationActionsDelegate? = nil, scheme: MDCContainerScheming?) {
        self.init(frame: CGRect.zero);
        self.actionsDelegate = actionsDelegate;
        self.observation = observation;
        self.scheme = scheme;
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming? = nil) {
        guard let safeScheme = scheme else {
            return;
        }
        self.view.backgroundColor = safeScheme.colorScheme.surfaceColor;
        importantView.applyTheme(withScheme: safeScheme);
        observationSummaryView.applyTheme(withScheme: safeScheme);
        observationActionsView.applyTheme(withScheme: safeScheme);
        detailsButton.applyContainedTheme(withScheme: safeScheme);
    }
    
    override func viewDidLoad() {
        stackView.addArrangedSubview(dragHandleView);
        stackView.addArrangedSubview(observationSummaryView);
        stackView.addArrangedSubview(observationActionsView);
        stackView.addArrangedSubview(viewObservationButtonView);
        let container = UIView(forAutoLayout: ());
        container.addSubview(stackView);
        container.addSubview(expandView);
        self.view.addSubview(container);
        container.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0));
        guard let safeObservation = self.observation else {
            return
        }

        if (safeObservation.isImportant()) {
            importantView.populate(observation: safeObservation);
            importantView.isHidden = false;
        } else {
            importantView.isHidden = true;
        }
        observationSummaryView.populate(observation: safeObservation);
        observationActionsView.populate(observation: safeObservation, delegate: actionsDelegate);
        if let safeScheme = scheme {
            applyTheme(withScheme: safeScheme);
        }
        
        self.view.setNeedsUpdateConstraints();
    }
    
    override func updateViewConstraints() {
        if (!didSetUpConstraints) {
            stackView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
            expandView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top);
            expandView.autoPinEdge(.top, to: .bottom, of: stackView);
            didSetUpConstraints = true;
        }
        
        super.updateViewConstraints();
    }
    
    func refresh() {
        guard let safeObservation = self.observation else {
            return
        }
        observationSummaryView.populate(observation: safeObservation);
        observationActionsView.populate(observation: safeObservation, delegate: actionsDelegate);
    }
    
    @objc func tap(_ card: MDCCard) {
        if let safeObservation = observation {
            // let the ripple dissolve before transitioning otherwise it looks weird
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.actionsDelegate?.viewObservation?(safeObservation);
            }
        }
    }
    
    @objc func detailsButtonTapped() {
        if let safeObservation = observation {
            // let the ripple dissolve before transitioning otherwise it looks weird
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.actionsDelegate?.viewObservation?(safeObservation);
            }
        }
    }
}
