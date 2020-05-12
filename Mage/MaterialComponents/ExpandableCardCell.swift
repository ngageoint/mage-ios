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
    
    private var container: UIView?;
    private var expandedView: UIView?;
    private var showExpanded: Bool = true;
    private var cell: ObservationFormCardCell?;
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        self.translatesAutoresizingMaskIntoConstraints = false;
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder);
        self.translatesAutoresizingMaskIntoConstraints = false;
    }
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ());
        stackView.alignment = UIStackView.Alignment.fill;
        stackView.distribution = UIStackView.Distribution.equalSpacing;
        stackView.axis = NSLayoutConstraint.Axis.vertical;
        return stackView;
    }()
    
    private lazy var headerArea: UIView = {
        let headerArea = UIView(forAutoLayout: ());
        return headerArea;
    }()
    
    private lazy var thumbnail: UIImageView = {
        let imageView = UIImageView(forAutoLayout: ());
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.tintColor = UIColor.blue;
        return imageView
    }()

    private lazy var headerText: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.numberOfLines = 1
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private lazy var subhead: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.numberOfLines = 1
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private lazy var expandAction: UIButton = {
        let expandAction = UIButton(type: .custom);
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
        self.showExpanded = !self.showExpanded;
        self.expandableView.isHidden = !self.showExpanded;
        expandAction.setImage(UIImage(named: self.showExpanded ? "collapse" : "expand" ), for: .normal);
        cell?.somethingChanged();
    }
    
    var cellWidthConstraint: NSLayoutConstraint?;
    
    func set(container: UIView) {
        self.container = container;
        self.container?.addSubview(self);
        self.autoPinEdgesToSuperviewEdges();
        cellWidthConstraint = NSLayoutConstraint(item: container, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0);
    }
    
    func configure(header: String, subheader: String, imageName: String, expandedView: UIView?, cell: ObservationFormCardCell?) {
        self.thumbnail.image  = UIImage(named: imageName)
        self.headerText.text = header
        self.subhead.text = subheader;
        self.expandedView = expandedView;
        self.cell = cell;
        
        constructCard();
        addConstraints()
    }
    
    func setWidth(width: CGFloat) {
        cellWidthConstraint?.constant = width;
        cellWidthConstraint?.isActive = true;
        NSLog("Setting constraint width to %f", width);
    }
    
    func apply(containerScheme: MDCContainerScheming, typographyScheme: MDCTypographyScheming) {
        self.applyTheme(withScheme: containerScheme)
        self.headerText.font = typographyScheme.headline6
        self.subhead.font = typographyScheme.subtitle2
    }
    
    private func constructCard() {
        self.container?.addSubview(self);
        self.addSubview(stackView);
        stackView.addArrangedSubview(headerArea);
        headerArea.addSubview(thumbnail)
        headerArea.addSubview(headerText)
        headerArea.addSubview(subhead);
        headerArea.addSubview(expandAction);
        
        if expandedView != nil {
            expandableView.addSubview(expandedView!);
            stackView.addArrangedSubview(expandableView);
        }
    }
    
    private func setStackViewConstraints() {
        stackView.autoPinEdgesToSuperviewEdges();
    }
    
    private func setHeaderAreaConstraints() {
        headerArea.autoPinEdge(toSuperviewEdge: .left);
        headerArea.autoPinEdge(toSuperviewEdge: .right);
        headerArea.autoSetDimension(.height, toSize: 56).priority = UILayoutPriority.defaultHigh;
    }
    
    private func setThumbnailConstraints() {
        thumbnail.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 0), excludingEdge: .right);
        thumbnail.autoSetDimensions(to: CGSize(width: 40, height: 40));
    }
    
    private func setHeaderTextConstraints() {
        headerText.autoPinEdge(.bottom, to: .top, of: headerArea, withOffset: 34);
        headerText.autoPinEdge(toSuperviewEdge: .left, withInset: 72);
        headerText.autoPinEdge(toSuperviewEdge: .right, withInset: 16);
    }
    
    private func setSubheadConstraints() {
        subhead.autoPinEdge(.bottom, to: .bottom, of: headerText, withOffset: 22);
        subhead.autoPinEdge(toSuperviewEdge: .left, withInset: 72);
        subhead.autoPinEdge(toSuperviewEdge: .right, withInset: 16);
    }
    
    private func setExpandActionConstraints() {
        expandAction.autoPinEdge(toSuperviewEdge: .right, withInset: 16);
        expandAction.autoAlignAxis(toSuperviewAxis: .horizontal);
        expandAction.autoSetDimensions(to: CGSize(width: 24, height: 24));
    }
    
    private func setExpandableViewConstraints() {
        if expandedView != nil {
            expandedView?.autoPinEdgesToSuperviewEdges();
        }
    }
    
    private func addConstraints() {
//        self.autoPinEdgesToSuperviewEdges();
        setStackViewConstraints();
        setHeaderAreaConstraints();
        setThumbnailConstraints();
        setHeaderTextConstraints();
        setSubheadConstraints();
        setExpandActionConstraints();
        setExpandableViewConstraints();
    }
    
}
