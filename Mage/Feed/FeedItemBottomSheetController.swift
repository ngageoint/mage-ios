//
//  FeedItemBottomSheetController.swift
//  MAGE
//
//  Created by Daniel Barela on 7/14/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc class FeedItemBottomSheetController: UIViewController {
    
    private var didSetUpConstraints = false;
    private var feedItem: FeedItem?;
    private var actionsDelegate: FeedItemActionsDelegate?;
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
    
    private lazy var summaryView: FeedItemSummary = {
        let view = FeedItemSummary();
        return view;
    }()
    
    private lazy var actionsView: FeedItemActionsView? = {
        guard let feedItem = self.feedItem else {
            return nil;
        }
        let view = FeedItemActionsView(feedItem: feedItem, actionsDelegate: actionsDelegate, scheme: scheme);
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
    
    private lazy var detailsButtonView: UIView = {
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
    
    @objc public convenience init(feedItem: FeedItem, actionsDelegate: FeedItemActionsDelegate? = nil, scheme: MDCContainerScheming?) {
        self.init(frame: CGRect.zero);
        self.actionsDelegate = actionsDelegate;
        self.feedItem = feedItem;
        self.scheme = scheme;
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming? = nil) {
        guard let safeScheme = scheme else {
            return;
        }
        self.view.backgroundColor = safeScheme.colorScheme.surfaceColor;
        summaryView.applyTheme(withScheme: safeScheme);
        actionsView?.applyTheme(withScheme: safeScheme);
        detailsButton.applyContainedTheme(withScheme: safeScheme);
    }
    
    override func viewDidLoad() {
        stackView.addArrangedSubview(dragHandleView);
        stackView.addArrangedSubview(summaryView);
        if (actionsView != nil) {
            stackView.addArrangedSubview(actionsView!);
        }
        stackView.addArrangedSubview(detailsButtonView);
        self.view.addSubview(stackView);
        stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0));
        
        if let safeScheme = scheme {
            applyTheme(withScheme: safeScheme);
        }
        
        self.view.setNeedsUpdateConstraints();
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let feedItem = self.feedItem else {
            return
        }
        summaryView.populate(feedItem: feedItem);
        actionsView?.populate(feedItem: feedItem, delegate: actionsDelegate)
    }
    
    override func updateViewConstraints() {
        if (!didSetUpConstraints) {
            stackView.autoPinEdgesToSuperviewEdges(with: .zero);
            didSetUpConstraints = true;
        }
        
        super.updateViewConstraints();
    }
    
    func refresh() {
        guard let feedItem = self.feedItem else {
            return
        }
        summaryView.populate(feedItem: feedItem);
    }
    
    @objc func detailsButtonTapped() {
        if let feedItem = feedItem {
            // let the ripple dissolve before transitioning otherwise it looks weird
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.actionsDelegate?.viewFeedItem?(feedItem: feedItem)
            }
        }
    }
}
