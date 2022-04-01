//
//  ConsentViewController.m
//  MAGE
//
//

import UIKit

@objc public protocol DisclaimerDelegate {
    @objc func disclaimerAgree()
    @objc func disclaimerDisagree()
}

@objc public class DisclaimerViewController: UIViewController {
    var didSetupConstraints = false;
    @objc public var delegate: DisclaimerDelegate?
    var scheme: MDCContainerScheming?;
    
    lazy var consentText: UITextView = {
        let consentText = UITextView(forAutoLayout: ())
        consentText.isScrollEnabled = true
        consentText.isSelectable = false
        return consentText
    }()
    
    lazy var consentTitle: UITextView = {
        let consentTitle = UITextView(forAutoLayout: ())
        consentTitle.textAlignment = .center
        consentTitle.isSelectable = false
        return consentTitle
    }()
    
    lazy var wandMageContainer: UIView = {
        let container = UIView(forAutoLayout: ())
        container.clipsToBounds = false
        container.addSubview(wandLabel)
        container.addSubview(mageLabel)
        return container
    }()

    lazy var wandLabel: UILabel = {
        let wandLabel = UILabel(forAutoLayout: ());
        wandLabel.numberOfLines = 0;
        wandLabel.font = UIFont(name: "FontAwesome", size: 50)
        wandLabel.text = "\u{0000f0d0}"
        wandLabel.baselineAdjustment = .alignBaselines
        return wandLabel;
    }()
    lazy var mageLabel: UILabel = {
        let mageLabel = UILabel(forAutoLayout: ());
        mageLabel.numberOfLines = 0;
        mageLabel.font = UIFont(name: "GondolaMageRegular", size: 52)
        mageLabel.text = "MAGE"
        mageLabel.baselineAdjustment = .alignBaselines
        return mageLabel;
    }()
    private lazy var disagreeButton: MDCButton = {
        let disagreeButton = MDCButton(forAutoLayout: ());
        disagreeButton.accessibilityLabel = "Disagree";
        disagreeButton.setTitle("Disagree", for: .normal);
        disagreeButton.addTarget(self, action: #selector(disagreeTapped), for: .touchUpInside);
        disagreeButton.clipsToBounds = true;
        return disagreeButton;
    }()
    private lazy var agreeButton: MDCButton = {
        let agreeButton = MDCButton(forAutoLayout: ());
        agreeButton.accessibilityLabel = "Agree";
        agreeButton.setTitle("Agree", for: .normal);
        agreeButton.addTarget(self, action: #selector(agreeTapped), for: .touchUpInside);
        agreeButton.clipsToBounds = true;
        return agreeButton;
    }()
    
    @objc public func applyTheme(withContainerScheme containerScheme: MDCContainerScheming?) {
        guard let scheme = containerScheme else {
            return
        }
        self.scheme = scheme
        self.view.backgroundColor = scheme.colorScheme.surfaceColor
        self.consentText.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
        self.consentText.font = scheme.typographyScheme.body2
        self.consentTitle.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87)
        self.consentTitle.font = scheme.typographyScheme.headline6
        self.wandLabel.textColor = scheme.colorScheme.primaryColorVariant
        self.mageLabel.textColor = scheme.colorScheme.primaryColorVariant
        agreeButton.applyContainedTheme(withScheme: scheme)
        disagreeButton.applyContainedTheme(withScheme: scheme)
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.title = "Disclaimer"
        consentTitle.text = UserDefaults.standard.disclaimerTitle
        consentText.text = UserDefaults.standard.disclaimerText
        
        if let navigationController = navigationController, !navigationController.isNavigationBarHidden {
            agreeButton.isHidden = true
            disagreeButton.isHidden = true
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad();
        view.addSubview(wandMageContainer)
        view.addSubview(consentTitle)
        view.addSubview(consentText)
        view.addSubview(disagreeButton)
        view.addSubview(agreeButton)
    }
    
    public override func updateViewConstraints() {
        if (!didSetupConstraints) {
            wandLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .right)
            mageLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: -45, right: 0), excludingEdge: .left)
            mageLabel.autoPinEdge(.left, to: .right, of: wandLabel, withOffset: 8)
            wandLabel.autoAlignAxis(.horizontal, toSameAxisOf: mageLabel)
            wandMageContainer.autoPinEdge(toSuperviewSafeArea: .top, withInset: 40)
            wandMageContainer.autoAlignAxis(toSuperviewAxis: .vertical)
            consentTitle.autoPinEdge(.top, to: .bottom, of: wandMageContainer, withOffset: 16)
            consentTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 16)
            consentTitle.autoPinEdge(toSuperviewEdge: .right, withInset: 16)
            consentTitle.autoSetDimension(.height, toSize: 32)
            consentText.autoPinEdge(.top, to: .bottom, of: consentTitle, withOffset: 16)
            consentText.autoPinEdge(toSuperviewEdge: .left, withInset: 16)
            consentText.autoPinEdge(toSuperviewEdge: .right, withInset: 16)
            consentText.autoPinEdge(.bottom, to: .top, of: disagreeButton, withOffset: 8)
            disagreeButton.autoPinEdge(toSuperviewEdge: .left, withInset: 16)
            disagreeButton.autoPinEdge(toSuperviewEdge: .bottom, withInset: 20)
            agreeButton.autoPinEdge(.left, to: .right, of: disagreeButton, withOffset: 16)
            agreeButton.autoPinEdge(toSuperviewEdge: .right, withInset: 16)
            agreeButton.autoPinEdge(toSuperviewEdge: .bottom, withInset: 20)
            agreeButton.autoMatch(.width, to: .width, of: disagreeButton)
            didSetupConstraints = true;
        }
        
        super.updateViewConstraints();
    }
    
    @objc func agreeTapped() {
        delegate?.disclaimerAgree()
    }
    
    @objc func disagreeTapped() {
        delegate?.disclaimerDisagree()
    }
}
