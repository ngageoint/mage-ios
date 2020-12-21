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
        
        importantView.isHidden = !observation.isImportant()
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
    
    private lazy var geometryView: EditGeometryView = {
        let geometryView = EditGeometryView(field: locationField, editMode: false, delegate: nil, observation: self.observation, eventForms: nil, mapEventDelegate: nil);
        
        return geometryView;
    }()
    
    private lazy var observationActionsView: ObservationActionsView = {
        let observationActionsView = ObservationActionsView(observation: self.observation!);
        return observationActionsView;
    }()
    
    private lazy var timestamp: UILabel = {
        let timestamp = UILabel(forAutoLayout: ());
        timestamp.font = globalContainerScheme().typographyScheme.overline;
        timestamp.textColor = UIColor.label.withAlphaComponent(0.6);
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
        primaryField.font = globalContainerScheme().typographyScheme.headline6;
        primaryField.textColor = globalContainerScheme().colorScheme.primaryColor;
        return primaryField;
    }()
    
    private lazy var secondaryField: UILabel = {
        let secondaryField = UILabel(forAutoLayout: ());
        secondaryField.font = globalContainerScheme().typographyScheme.subtitle2;
        secondaryField.textColor = UIColor.label.withAlphaComponent(0.60);
        return secondaryField;
    }()
    
    private lazy var importantView: ObservationImportantView = {
        let importantView = ObservationImportantView(observation: self.observation, cornerRadius: self.cornerRadius);
        return importantView;
    }()
    
    @objc public convenience init(observation: Observation) {
        self.init(frame: CGRect.zero);
        self.observation = observation;
        self.configureForAutoLayout();
        layoutView();
        populate(observation: observation);
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            stack.autoPinEdgesToSuperviewEdges();
            didSetupConstraints = true;
        }
        super.updateConstraints();
    }
    
    override func themeDidChange(_ theme: MageTheme) {
        self.timestamp.textColor = UIColor.label.withAlphaComponent(0.6);
        self.primaryField.textColor = globalContainerScheme().colorScheme.primaryColor;
        self.secondaryField.textColor = UIColor.label.withAlphaComponent(0.60);
        
        self.backgroundColor = UIColor.background();
    }
    
    @objc public func populate(observation: Observation) {
        primaryField.text = observation.primaryFeedFieldText();
        secondaryField.text = observation.secondaryFeedFieldText();
        
        // we do not want the date to word break so we replace all spaces with a non word breaking spaces
        var timeText = "";
        if let itemDate: NSDate = observation.timestamp as NSDate? {
            timeText = itemDate.formattedDisplayDate(withDateStyle: .medium, andTime: .short)?.uppercased().replacingOccurrences(of: " ", with: "\u{00a0}") ?? "";
        }
        timestamp.text = "\(observation.user?.name?.uppercased() ?? "") \u{2022} \(timeText)";

        self.registerForThemeChanges()
    }
    
    func layoutView() {
        self.addSubview(stack);
    }
}
