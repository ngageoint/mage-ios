//
//  FeatureBottomSheetView.swift
//  MAGE
//
//  Created by Daniel Barela on 7/13/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class FeatureBottomSheetView: BottomSheetView {
    
    private var didSetUpConstraints = false;
    private var actionsDelegate: FeatureActionsDelegate?;
    private var featureItem: FeatureItem = FeatureItem();
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
    
    @objc public lazy var textView: UITextView = {
        let textView = UITextView();
        textView.isScrollEnabled = false;
        textView.dataDetectorTypes = .all;
        textView.isEditable = false;
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8);
        textView.backgroundColor = .clear
        return textView;
    }()
    
    lazy var descriptionHeader: CardHeader = {
        return CardHeader(headerText: "DESCRIPTION")
    }()
    
    lazy var spacer: UIView = {
        let spacer = UIView()
        spacer.autoSetDimension(.height, toSize: 8)
        return spacer
    }()
    
    private lazy var featureTitleView: UILabel = {
        let view = UILabel.newAutoLayout();
        if let featureTitle = featureItem.featureTitle {
            view.text = featureTitle;
            view.isHidden = false;
        } else {
            view.isHidden = true;
        }
        return view;
    }()
    
    private lazy var summaryView: FeatureSummaryView = {
        let view = FeatureSummaryView()
        return view;
    }()
    
    private lazy var featureActionsView: FeatureActionsView = {
        let view = FeatureActionsView(featureItem: featureItem, featureActionsDelegate: actionsDelegate, scheme: scheme);
        return view;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }

    init(featureItem: FeatureItem, actionsDelegate: FeatureActionsDelegate? = nil, scheme: MDCContainerScheming?) {
        super.init(frame: CGRect.zero);
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.actionsDelegate = actionsDelegate;
        self.scheme = scheme;
        self.featureItem = featureItem;
        createView();
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming? = nil) {
        guard let scheme = scheme else {
            return;
        }
        self.backgroundColor = scheme.colorScheme.surfaceColor;
        textView.textColor = scheme.colorScheme.onSurfaceColor;
        textView.font = scheme.typographyScheme.body1;
        spacer.backgroundColor = scheme.colorScheme.backgroundColor
        descriptionHeader.applyTheme(withScheme: scheme)
        summaryView.applyTheme(withScheme: scheme);
        self.scheme = scheme;
    }
    
    func createView() {
        stackView.addArrangedSubview(summaryView);
        stackView.addArrangedSubview(featureActionsView);
        stackView.addArrangedSubview(spacer)
        stackView.addArrangedSubview(descriptionHeader)
        stackView.addArrangedSubview(textView);
        self.addSubview(stackView);
        
        if let scheme = scheme {
            applyTheme(withScheme: scheme);
        }
        
        if featureItem.featureDetail != nil {
            textView.attributedText = getAttributedMessage();
        } else {
            spacer.isHidden = true
            descriptionHeader.isHidden = true
        }
        summaryView.populate(item: featureItem);
        
        self.setNeedsUpdateConstraints();
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            stackView.autoPinEdgesToSuperviewEdges();
            didSetUpConstraints = true;
        }
        
        super.updateConstraints();
    }
    
    func getAttributedMessage() -> NSAttributedString {
        return featureItem.featureDetail?.htmlAttributedString(font: self.scheme?.typographyScheme.body1, color: self.scheme?.colorScheme.onSurfaceColor) ?? NSAttributedString(string: "")
    }
    
    override func refresh() {
        textView.attributedText = getAttributedMessage();
    }
}
