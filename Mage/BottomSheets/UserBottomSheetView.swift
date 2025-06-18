//
//  UserBottomSheetController.swift
//  MAGE
//
//  Created by Daniel Barela on 7/5/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class UserBottomSheetView: BottomSheetView {
    
    private var didSetUpConstraints = false;
    private var user: User?;
    private var actionsDelegate: UserActionsDelegate?;
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
    
    private lazy var summaryView: UserSummaryView = {
        let view = UserSummaryView();
        return view;
    }()
    
    private lazy var userActionsView: UserActionsView = {
        let view = UserActionsView(user: user, userActionsDelegate: actionsDelegate, scheme: scheme)
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
        detailsButton.autoPinEdge(.top, to: .top, of: view);
        detailsButton.autoPinEdge(.bottom, to: .bottom, of: view);
        return view;
    }()
    
    private lazy var expandView: UIView = {
        let view = UIView(forAutoLayout: ());
        view.setContentHuggingPriority(.defaultLow, for: .vertical);
        return view;
    }();

    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    init(user: User, actionsDelegate: UserActionsDelegate? = nil, scheme: MDCContainerScheming?) {
        super.init(frame: CGRect.zero);
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.actionsDelegate = actionsDelegate;
        self.user = user;
        self.scheme = scheme;
        stackView.addArrangedSubview(summaryView);
        stackView.addArrangedSubview(userActionsView);
        stackView.addArrangedSubview(detailsButtonView);
        self.addSubview(stackView);
        stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0));
        
        summaryView.populate(item: user, actionsDelegate: actionsDelegate);
        userActionsView.populate(user: user, delegate: actionsDelegate);
        
        if let scheme = scheme {
            applyTheme(withScheme: scheme);
        }
        
        self.setNeedsUpdateConstraints();
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming? = nil) {
        guard let scheme = scheme else {
            return;
        }
        self.scheme = scheme;
        self.backgroundColor = scheme.colorScheme.surfaceColor;
        summaryView.applyTheme(withScheme: scheme);
        userActionsView.applyTheme(withScheme: scheme);
        detailsButton.applyContainedTheme(withScheme: scheme);
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            stackView.autoPinEdgesToSuperviewEdges(with: .zero);
            didSetUpConstraints = true;
        }
        
        super.updateConstraints();
    }
    
    override func refresh() {
        guard let user = self.user else {
            return
        }
        summaryView.populate(item: user, actionsDelegate: actionsDelegate);
    }
    
    @objc func detailsButtonTapped() {
        if let user = user {
            // let the ripple dissolve before transitioning otherwise it looks weird
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .ViewUser, object: user)
                self.actionsDelegate?.viewUser?(user);
            }
        }
    }
}
