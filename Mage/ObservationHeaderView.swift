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
    var observation: Observation!;
    var observationActionsDelegate: ObservationActionsDelegate?;
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
    
    private lazy var observationSummaryView: UIView = {
        let summary = UIView(forAutoLayout: ());
        let stack = UIStackView(forAutoLayout: ());
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0;
        stack.distribution = .fill
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 8)
        stack.isLayoutMarginsRelativeArrangement = true;
        stack.translatesAutoresizingMaskIntoConstraints = false;
        
        stack.addArrangedSubview(timestamp);
        stack.setCustomSpacing(16, after: timestamp);
        stack.addArrangedSubview(primaryField);
        stack.addArrangedSubview(secondaryField);
        
        summary.addSubview(stack);
        summary.addSubview(itemImage);
        stack.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .right);
        stack.autoPinEdge(.right, to: .left, of: itemImage, withOffset: 16);
        itemImage.autoSetDimensions(to: CGSize(width: 48, height: 48));
        itemImage.autoPinEdge(toSuperviewEdge: .right, withInset: 16);
        itemImage.autoPinEdge(toSuperviewEdge: .top, withInset: 16);
        
        summary.autoSetDimension(.height, toSize: 80, relation: .greaterThanOrEqual)
        return summary;
    }()
    
    private lazy var divider: UIView = {
        let divider = UIView(forAutoLayout: ());
        divider.backgroundColor = UIColor.black.withAlphaComponent(0.12);
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
        let geometryView = GeometryView(field: locationField, editMode: false, delegate: nil, observation: self.observation, eventForms: nil, mapEventDelegate: nil);
        
        return geometryView;
    }()
    
    private lazy var observationActionsView: ObservationActionsView = {
        let observationActionsView = ObservationActionsView(observation: self.observation!, observationActionsDelegate: observationActionsDelegate, scheme: self.scheme);
        return observationActionsView;
    }()
    
    private lazy var timestamp: UILabel = {
        let timestamp = UILabel(forAutoLayout: ());
        timestamp.numberOfLines = 0;
        return timestamp;
    }()
    
    private lazy var itemImage: UIImageView = {
        let itemImage = UIImageView(forAutoLayout: ());
        itemImage.image = ObservationImage.image(for: self.observation!);
        itemImage.contentMode = .scaleAspectFit;
        return itemImage;
    }()
    
    private lazy var primaryField: UILabel = {
        let primaryField = UILabel(forAutoLayout: ());
        return primaryField;
    }()
    
    private lazy var secondaryField: UILabel = {
        let secondaryField = UILabel(forAutoLayout: ());
        return secondaryField;
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
    
    override func applyTheme(withScheme scheme: MDCContainerScheming) {
        super .applyTheme(withScheme: scheme);
        self.timestamp.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        self.timestamp.font = scheme.typographyScheme.overline;
        self.primaryField.textColor = scheme.colorScheme.primaryColor;
        self.primaryField.font = scheme.typographyScheme.headline6;
        self.secondaryField.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        self.secondaryField.font = scheme.typographyScheme.subtitle2;
        self.geometryView.applyTheme(withScheme: scheme);
        self.importantView.applyTheme(withScheme: scheme);
        self.observationActionsView.applyTheme(withScheme: scheme);
    }
    
    @objc public func populate(observation: Observation, animate: Bool = true) {
        primaryField.text = observation.primaryFeedFieldText();
        secondaryField.text = observation.secondaryFeedFieldText();
        
        if (animate) {
            UIView.animate(withDuration: 0.2) {
                self.importantView.isHidden = !observation.isImportant()
            }
        } else {
            self.importantView.isHidden = !observation.isImportant()
        }
        
        importantView.populate(observation: observation);
        
        // we do not want the date to word break so we replace all spaces with a non word breaking spaces
        var timeText = "";
        if let itemDate: NSDate = observation.timestamp as NSDate? {
            timeText = itemDate.formattedDisplayDate(withDateStyle: .medium, andTime: .short)?.uppercased().replacingOccurrences(of: " ", with: "\u{00a0}") ?? "";
        }
        timestamp.text = "\(observation.user?.name?.uppercased() ?? "") \u{2022} \(timeText)";
        
        observationActionsView.populate(observation: observation);
    }
    
    func layoutView() {
        self.addSubview(stack);
    }
}
