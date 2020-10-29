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
    var showExpanded: Bool = true;
    
    convenience init(header: String? = nil, subheader: String? = nil, imageName: String? = nil, title: String? = nil, expandedView: UIView? = nil) {
        self.init(frame: CGRect.zero);
        self.configureForAutoLayout();
        self.configure(header: header, subheader: subheader, imageName: imageName, title: title, expandedView: expandedView);
    }
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ());
        stackView.alignment = .fill;
        stackView.distribution = .fill;
        stackView.axis = .vertical;
        stackView.spacing = 0;
        return stackView;
    }()
    
    private lazy var headerArea: UIView = {
        let headerArea = UIView(forAutoLayout: ());
        return headerArea;
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
        let label = UILabel(forAutoLayout: ());
        label.numberOfLines = 1
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.font = globalContainerScheme().typographyScheme.headline6
        label.textColor = globalContainerScheme().colorScheme.primaryColor
        return label
    }()

    private lazy var subhead: UILabel = {
        let label = UILabel(forAutoLayout: ());
        label.numberOfLines = 1
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.font = globalContainerScheme().typographyScheme.subtitle2
        label.textColor = .systemGray
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
        setExpanded(expanded: !self.showExpanded);
    }
    
    func configure(header: String?, subheader: String?, imageName: String?, title: String? = nil, expandedView: UIView?) {
        if let safeImageName = imageName {
            self.thumbnail.image  = UIImage(named: safeImageName)
        }
        self.headerText.text = header
        self.subhead.text = subheader;
        if let safeTitle = title {
            self.titleText.text = safeTitle.uppercased();
        }
        self.expandedView = expandedView;
        
        constructCard();
    }
    
    private func constructCard() {
        self.container?.addSubview(self);
        self.addSubview(stackView);

        stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 0, bottom: 0, right: 0))
        
        stackView.addArrangedSubview(titleArea);
        if (self.thumbnail.image != nil || self.titleText.text != nil) {
            titleArea.addSubview(thumbnail);
            thumbnail.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 16, bottom: 4, right: 0), excludingEdge: .right);
            thumbnail.autoSetDimensions(to: CGSize(width: 24, height: 24));
        }
        
        if (self.titleText.text != nil) {
            titleArea.addSubview(thumbnail);
            thumbnail.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 16, bottom: 4, right: 0), excludingEdge: .right);
            thumbnail.autoSetDimensions(to: CGSize(width: 24, height: 24));
            
            titleArea.addSubview(titleText);
            titleText.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 56, bottom: 4, right: 16));
        }
        if (headerText.text != nil || subhead.text != nil) {
            headerArea.addSubview(headerText)
            headerText.autoPinEdge(.top, to: .top, of: headerArea, withOffset: 0);
            headerText.autoPinEdge(toSuperviewEdge: .left, withInset: 16);
            headerText.autoPinEdge(toSuperviewEdge: .right, withInset: 16);
            
            if (subhead.text != nil) {
                headerArea.addSubview(subhead);
                subhead.autoPinEdge(.bottom, to: .bottom, of: headerText, withOffset: 22);
                subhead.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16), excludingEdge: .top);
            } else {
                headerText.autoPinEdge(toSuperviewEdge: .bottom, withInset: 0);
            }
            
            stackView.addArrangedSubview(headerArea);
            headerArea.autoPinEdge(toSuperviewEdge: .left);
            headerArea.autoPinEdge(toSuperviewEdge: .right);
        }
        
        let spacerView = UIView(forAutoLayout: ());
        spacerView.autoSetDimension(.height, toSize: 8);
        stackView.addArrangedSubview(spacerView);
        
        if expandedView != nil {
            self.addSubview(expandAction);
            expandAction.autoPinEdge(toSuperviewEdge: .top, withInset: 8);
            expandAction.autoPinEdge(toSuperviewEdge: .right, withInset: 16);
            expandAction.autoSetDimensions(to: CGSize(width: 24, height: 24));
            
            expandableView.addSubview(expandedView!);
            expandedView?.autoPinEdgesToSuperviewEdges();
            stackView.addArrangedSubview(expandableView);
        }
    }
    
    public func setExpanded(expanded: Bool = true) {
        self.showExpanded = expanded;
        self.expandableView.isHidden = !self.showExpanded;
        expandAction.setImage(UIImage(named: self.showExpanded ? "collapse" : "expand" ), for: .normal);
    }
    
}
