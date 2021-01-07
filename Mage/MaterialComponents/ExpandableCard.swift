//
//  ObservationFormCardCell.swift
//  MAGE
//
//  Created by Daniel Barela on 5/1/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

import UIKit
import MaterialComponents.MaterialTypographyScheme
import MaterialComponents.MaterialCards
import PureLayout

class ExpandableCard: MDCCard {
    private var didSetUpConstraints = false;
    private var container: UIView?;
    private var expandedView: UIView?;
    var showExpanded: Bool = true;
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ());
        stackView.alignment = .fill;
        stackView.distribution = .fill;
        stackView.axis = .vertical;
        stackView.spacing = 0;
        return stackView;
    }()
    
    private lazy var titleArea: UIView = {
        let titleArea = UIView(forAutoLayout: ());
        return titleArea;
    }();
    
    private lazy var thumbnail: UIImageView = {
        let imageView = UIImageView(forAutoLayout: ());
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.tintColor = globalContainerScheme().colorScheme.primaryColor;
        return imageView
    }()
    
    private lazy var titleText: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.numberOfLines = 1
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.font = globalContainerScheme().typographyScheme.overline
        label.textColor = .systemGray;
        return label
    }()

    private lazy var headerText: UILabel = {
        let label = UILabelPadding(padding: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16));
        label.numberOfLines = 1
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.font = globalContainerScheme().typographyScheme.headline6
        label.textColor = globalContainerScheme().colorScheme.primaryColor
        return label
    }()

    private lazy var subhead: UILabel = {
        let label = UILabelPadding(padding: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16));
        label.numberOfLines = 1
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.font = globalContainerScheme().typographyScheme.subtitle2
        label.textColor = UIColor.label.withAlphaComponent(0.6);
        return label
    }()
    
    private lazy var expandAction: UIButton = {
        let expandAction = UIButton(type: .custom);
        expandAction.accessibilityLabel = "expand";
        expandAction.setImage(UIImage(named: self.showExpanded ? "collapse" : "expand" ), for: .normal);
        expandAction.addTarget(self, action: #selector(expandButtonPressed), for: .touchUpInside)
        return expandAction;
    }()
    
    private lazy var expandableView: UIView = {
        let expandableView = UIView(forAutoLayout: ());
        expandableView.isHidden = !self.showExpanded;
        return expandableView;
    }()
    
    @objc func expandButtonPressed() {
        expanded = !self.expanded;
    }
    
    var title: String? {
        get {
            return titleText.text
        }
        set(title) {
            titleText.isHidden = title == nil
            titleText.text = title?.uppercased()
        }
    }
    
    var header: String? {
        get {
            return headerText.text
        }
        set(header) {
            headerText.isHidden = header == nil
            headerText.text = header
        }
    }
    
    var subheader: String? {
        get {
            return subhead.text
        }
        set(subheader) {
            subhead.isHidden = subheader == nil
            subhead.text = subheader
        }
    }
    
    var expanded: Bool {
        get {
            return self.showExpanded
        }
        set(expanded) {
            self.showExpanded = expanded;
            self.expandableView.isHidden = !self.showExpanded;
            expandAction.setImage(UIImage(named: self.showExpanded ? "collapse" : "expand" ), for: .normal);
        }
    }
    
    convenience init(header: String? = nil, subheader: String? = nil, imageName: String? = nil, title: String? = nil, expandedView: UIView? = nil) {
        self.init(frame: .zero);
        self.configureForAutoLayout();
        self.configure(header: header, subheader: subheader, imageName: imageName, title: title, expandedView: expandedView);
    }
    
    func configure(header: String?, subheader: String?, imageName: String?, title: String? = nil, expandedView: UIView?) {
        if let safeImageName = imageName {
            self.thumbnail.image  = UIImage(named: safeImageName)
        }
        self.header = header;
        self.subheader = subheader;
        self.title = title;
        self.expandedView = expandedView;
        
        constructCard();
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0))
            if (thumbnail.superview != nil) {
                thumbnail.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 16, bottom: 4, right: 0), excludingEdge: .right);
                thumbnail.autoSetDimensions(to: CGSize(width: 24, height: 24));
            }
            titleText.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 56, bottom: 0, right: 32));
            
            if expandedView != nil {
                expandAction.autoPinEdge(toSuperviewEdge: .top, withInset: 8);
                expandAction.autoPinEdge(toSuperviewEdge: .right, withInset: 16);
                expandAction.autoSetDimensions(to: CGSize(width: 24, height: 24));
                expandedView?.autoPinEdgesToSuperviewEdges();
            }
        }
        super.updateConstraints();
    }
    
    private func constructCard() {
        self.container?.addSubview(self);
        self.addSubview(stackView);

        if (self.thumbnail.image != nil) {
            titleArea.addSubview(thumbnail);
        }
        
        titleArea.addSubview(titleText);
        
        stackView.addArrangedSubview(titleArea);
        stackView.addArrangedSubview(headerText)
        stackView.addArrangedSubview(subhead);

        let spacerView = UIView(forAutoLayout: ());
        spacerView.autoSetDimension(.height, toSize: 8);
        stackView.addArrangedSubview(spacerView);
        if expandedView != nil {
            self.addSubview(expandAction);
            
            expandableView.addSubview(expandedView!);
            stackView.addArrangedSubview(expandableView);
        }
    }
}
