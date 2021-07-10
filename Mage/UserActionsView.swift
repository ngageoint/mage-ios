//
//  UserActionsView.swift
//  MAGE
//
//  Created by Daniel Barela on 7/5/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout
import MaterialComponents.MDCPalettes

class UserActionsView: UIView {
    var didSetupConstraints = false;
    var user: User?;
    var userActionsDelegate: UserActionsDelegate?;
    var bottomSheet: MDCBottomSheetController?;
    internal var scheme: MDCContainerScheming?;
    
    private lazy var actionButtonView: UIStackView = {
        let stack = UIStackView.newAutoLayout()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.spacing = 24
        stack.distribution = .fill
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        stack.isLayoutMarginsRelativeArrangement = true;
        stack.translatesAutoresizingMaskIntoConstraints = false;
        stack.addArrangedSubview(emailButton);
        stack.addArrangedSubview(textButton);
        stack.addArrangedSubview(phoneButton);
        stack.addArrangedSubview(directionsButton);
        return stack;
    }()
    
    private lazy var directionsButton: MDCButton = {
        let directionsButton = MDCButton();
        directionsButton.accessibilityLabel = "directions";
        directionsButton.setImage(UIImage(named: "directions_large")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        directionsButton.addTarget(self, action: #selector(getDirectionsToUser), for: .touchUpInside);
        directionsButton.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        directionsButton.inkMaxRippleRadius = 30;
        directionsButton.inkStyle = .unbounded;
        return directionsButton;
    }()
    
    private lazy var textButton: MDCButton = {
        let textButton = MDCButton();
        textButton.accessibilityLabel = "sms";
        textButton.setImage(UIImage(named: "sms")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        textButton.addTarget(self, action: #selector(textUser), for: .touchUpInside);
        textButton.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        textButton.inkMaxRippleRadius = 30;
        textButton.inkStyle = .unbounded;
        return textButton;
    }()
    
    private lazy var phoneButton: MDCButton = {
        let phoneButton = MDCButton();
        phoneButton.accessibilityLabel = "phone";
        phoneButton.setImage(UIImage(named: "phone")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        phoneButton.addTarget(self, action: #selector(callUser), for: .touchUpInside);
        phoneButton.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        phoneButton.inkMaxRippleRadius = 30;
        phoneButton.inkStyle = .unbounded;
        return phoneButton;
    }()
    
    private lazy var emailButton: MDCButton = {
        let emailButton = MDCButton();
        emailButton.accessibilityLabel = "email";
        emailButton.setImage(UIImage(named: "email")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate), for: .normal);
        emailButton.addTarget(self, action: #selector(emailUser), for: .touchUpInside);
        emailButton.setInsets(forContentPadding: UIEdgeInsets.zero, imageTitlePadding: 0);
        emailButton.inkMaxRippleRadius = 30;
        emailButton.inkStyle = .unbounded;
        return emailButton;
    }()
    
    func applyTheme(withScheme scheme: MDCContainerScheming) {
        self.scheme = scheme;
        emailButton.applyTextTheme(withScheme: scheme);
        emailButton.setImageTintColor(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal)
        phoneButton.applyTextTheme(withScheme: scheme);
        phoneButton.setImageTintColor(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal)
        directionsButton.applyTextTheme(withScheme: scheme);
        directionsButton.setImageTintColor(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6), for: .normal)
    }
    
    public convenience init(user: User?, userActionsDelegate: UserActionsDelegate?, scheme: MDCContainerScheming?) {
        self.init(frame: CGRect.zero);
        self.scheme = scheme;
        self.user = user;
        self.userActionsDelegate = userActionsDelegate;
        self.configureForAutoLayout();
        layoutView();
        if let safeUser = user {
            populate(user: safeUser, delegate: userActionsDelegate);
        }
        if let safeScheme = self.scheme {
            applyTheme(withScheme: safeScheme);
        }
    }
    
    func layoutView() {
        self.addSubview(actionButtonView);
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            actionButtonView.autoSetDimension(.height, toSize: 56);
            actionButtonView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 16), excludingEdge: .left);

            didSetupConstraints = true;
        }
        super.updateConstraints();
    }
    
    public func populate(user: User!, delegate: UserActionsDelegate?) {
        self.user = user;
        self.userActionsDelegate = delegate;
        if (self.user?.email == nil) {
            emailButton.isHidden = true;
        }
        if (self.user?.phone == nil) {
            phoneButton.isHidden = true;
            textButton.isHidden = true;
        }

        if let safeScheme = scheme {
            applyTheme(withScheme: safeScheme);
        }
    }
    
    @objc func getDirectionsToUser() {
        userActionsDelegate?.getDirectionsToUser?(user!);
    }
    
    @objc func callUser() {
        guard let number = URL(string: "tel://\(user?.phone ?? "")") else { return }
        UIApplication.shared.open(number)
    }
    
    @objc func textUser() {
        guard let number = URL(string: "sms://\(user?.phone ?? "")") else { return }
        UIApplication.shared.open(number)
    }
    
    @objc func emailUser() {
        guard let number = URL(string: "mailto://\(user?.email ?? "")") else { return }
        UIApplication.shared.open(number)
    }
}
