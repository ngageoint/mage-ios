//
//  ObservationHeaderView.swift
//  MAGE
//
//  Created by Daniel Barela on 12/16/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout
import Kingfisher
import MaterialComponents.MaterialTypographyScheme
import MaterialComponents.MaterialCards

class ObservationHeaderView : MDCCard {
    var didSetupConstraints = false;
    weak var observation: Observation?;
    weak var observationActionsDelegate: ObservationActionsDelegate?;
    var scheme: MDCContainerScheming?;
    
    private lazy var stack: UIStackView = {
        let stack = UIStackView(forAutoLayout: ());
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0
        stack.distribution = .fill
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        stack.isLayoutMarginsRelativeArrangement = true;
        stack.translatesAutoresizingMaskIntoConstraints = false;
        stack.addArrangedSubview(importantView);
        stack.addArrangedSubview(observationSummaryView);
        stack.addArrangedSubview(geometryView);
        stack.addArrangedSubview(divider);
        stack.addArrangedSubview(observationActionsView);
        return stack;
    }()
    
    private lazy var observationSummaryView: ObservationSummaryView = {
        let summary = ObservationSummaryView(imageOverride: nil, hideImage: true);
        return summary;
    }()
    
    private lazy var divider: UIView = {
        let divider = UIView(forAutoLayout: ());
        divider.autoSetDimension(.height, toSize: 1);
        return divider;
    }()
    
    lazy var locationField: [String: Any] = {
        let locationField: [String: Any] =
            [
             FieldKey.name.key: "geometry",
             FieldKey.type.key: "geometry"
            ];
        return locationField;
    }()
    
    private lazy var geometryView: GeometryView = {
        let geometryView = GeometryView(field: locationField, editMode: false, delegate: nil, observation: self.observation, eventForms: nil, mapEventDelegate: nil, observationActionsDelegate: observationActionsDelegate);
        
        return geometryView;
    }()
    
    private lazy var observationActionsView: ObservationActionsView = {
        let observationActionsView = ObservationActionsView(observation: self.observation!, observationActionsDelegate: observationActionsDelegate, scheme: self.scheme);
        return observationActionsView;
    }()
    
    private lazy var importantView: ObservationImportantView = {
        let importantView = ObservationImportantView(observation: self.observation, cornerRadius: self.cornerRadius, scheme: self.scheme);
        return importantView;
    }()
    
    public convenience init(observation: Observation, observationActionsDelegate: ObservationActionsDelegate?) {
        self.init(frame: CGRect.zero);
        self.observation = observation;
        self.observationActionsDelegate = observationActionsDelegate;
        self.configureForAutoLayout();
        layoutView();
        populate(observation: observation, animate: false);
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            stack.autoPinEdgesToSuperviewEdges();
            didSetupConstraints = true;
        }
        super.updateConstraints();
    }
    
    override func applyTheme(withScheme scheme: MDCContainerScheming?) {
        guard let scheme = scheme else {
            return
        }

        super.applyTheme(withScheme: scheme);
        self.geometryView.applyTheme(withScheme: scheme);
        self.importantView.applyTheme(withScheme: scheme);
        self.observationActionsView.applyTheme(withScheme: scheme);
        self.observationSummaryView.applyTheme(withScheme: scheme);
        divider.backgroundColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.12);
    }
    
    @objc public func populate(observation: Observation, animate: Bool = true, ignoreGeometry: Bool = false) {
        observationSummaryView.populate(observation: observation);
        
        if (animate) {
            UIView.animate(withDuration: 0.2) {
                self.importantView.isHidden = !observation.isImportant()
            }
        } else {
            self.importantView.isHidden = !observation.isImportant()
        }
        if (!ignoreGeometry) {
            geometryView.setObservation(observation: observation);
        }
        importantView.populate(observation: observation);
        observationActionsView.populate(observation: observation);
    }
    
    func layoutView() {
        self.addSubview(stack);
    }
}
