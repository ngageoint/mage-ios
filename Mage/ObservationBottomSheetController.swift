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
        drag.backgroundColor = .black.withAlphaComponent(0.37);
        drag.layer.cornerRadius = 3.5;
        
        let view = UIView(forAutoLayout: ());
        view.addSubview(drag);
        drag.autoAlignAxis(toSuperviewAxis: .vertical);
        drag.autoPinEdge(toSuperviewEdge: .bottom);
        drag.autoPinEdge(toSuperviewEdge: .top, withInset: 7);
        return view;
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
        compactView.applyTheme(withScheme: safeScheme);
        detailsButton.applyContainedTheme(withScheme: safeScheme);
    }
    
    override func viewDidLoad() {
        stackView.addArrangedSubview(dragHandleView);
        stackView.addArrangedSubview(compactView);
        stackView.addArrangedSubview(viewObservationButtonView);
        self.view.addSubview(stackView);
        stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0));
        guard let safeObservation = self.observation else {
            return
        }
        
        compactView.configure(observation: safeObservation, scheme: scheme, actionsDelegate: actionsDelegate, attachmentSelectionDelegate: attachmentSelectionDelegate);

        if (safeObservation.isImportant()) {
            dragHandleView.backgroundColor = compactView.importantView.backgroundColor;
        } else {
            dragHandleView.backgroundColor = .clear;
        }
        if let safeScheme = scheme {
            applyTheme(withScheme: safeScheme);
        }
        
        self.view.setNeedsUpdateConstraints();
    }
    
    override func updateViewConstraints() {
        if (!didSetUpConstraints) {
            stackView.autoPinEdgesToSuperviewEdges(with: .zero);
            didSetUpConstraints = true;
        }
        
        super.updateViewConstraints();
    }
    
    func refresh() {
        guard let safeObservation = self.observation else {
            return
        }
        compactView.configure(observation: safeObservation, scheme: scheme, actionsDelegate: actionsDelegate, attachmentSelectionDelegate: attachmentSelectionDelegate);
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
