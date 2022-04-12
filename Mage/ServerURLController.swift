//
//  ServerURLController.m
//  MAGE
//
//  Created by William Newman on 11/16/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

import CoreGraphics
import UIKit

@objc public protocol ServerURLDelegate {
    @objc func setServerURL(url: URL)
    @objc func cancelSetServerURL()
}

class ServerURLController: UIViewController {
    var didSetupConstraints = false
    @objc public var delegate: ServerURLDelegate?
    var scheme: MDCContainerScheming?
    var error: String?
    
    lazy var progressView: MDCProgressView = {
        let progressView = MDCProgressView(forAutoLayout: ())
        progressView.mode = MDCProgressViewMode.indeterminate
        progressView.isHidden = true
        return progressView
    }()
    
    private lazy var serverURL: MDCFilledTextField = {
        let serverURL = MDCFilledTextField(frame: CGRect(x: 0, y: 0, width: 200, height: 100));
        serverURL.autocapitalizationType = .none;
        serverURL.accessibilityLabel = "Server URL";
        serverURL.label.text = "Server URL"
        serverURL.placeholder = "Server URL"
        let worldImage = UIImageView(image: UIImage(systemName: "globe.americas.fill")?.aspectResize(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate))
        serverURL.leadingView = worldImage
        serverURL.leadingViewMode = .always
        serverURL.autocorrectionType = .no
        serverURL.autocapitalizationType = .none
        serverURL.keyboardType = .URL
        serverURL.delegate = self
        serverURL.sizeToFit();
        return serverURL;
    }()
    
    lazy var setServerUrlTitle: UITextView = {
        let setServerUrlTitle = UITextView(forAutoLayout: ())
        setServerUrlTitle.textAlignment = .center
        setServerUrlTitle.isSelectable = false
        setServerUrlTitle.backgroundColor = .clear
        setServerUrlTitle.text = "Set MAGE Server URL"
        return setServerUrlTitle
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
    
    lazy var errorImage: UIImageView = {
        let errorImage = UIImageView(image: UIImage(systemName: "exclamationmark.circle.fill"))
        errorImage.isHidden = true
        return errorImage
    }()
    
    private lazy var buttonStack: UIStackView = {
        let buttonStack = UIStackView(forAutoLayout: ())
        buttonStack.axis = .horizontal
        buttonStack.alignment = .fill
        buttonStack.spacing = 16
        buttonStack.distribution = .fillEqually
        buttonStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        buttonStack.isLayoutMarginsRelativeArrangement = false;
        buttonStack.addArrangedSubview(cancelButton)
        buttonStack.addArrangedSubview(okButton)
        return buttonStack;
    }()
    
    private lazy var cancelButton: MDCButton = {
        let cancelButton = MDCButton(forAutoLayout: ());
        cancelButton.accessibilityLabel = "Cancel";
        cancelButton.setTitle("Cancel", for: .normal);
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside);
        cancelButton.clipsToBounds = true;
        return cancelButton;
    }()
    private lazy var okButton: MDCButton = {
        let okButton = MDCButton(forAutoLayout: ());
        okButton.accessibilityLabel = "OK";
        okButton.setTitle("OK", for: .normal);
        okButton.addTarget(self, action: #selector(okTapped), for: .touchUpInside);
        okButton.clipsToBounds = true;
        return okButton;
    }()
    
    lazy var errorStatus: UITextView = {
        let errorStatus = UITextView(forAutoLayout: ())
        errorStatus.accessibilityLabel = "Server URL Error"
        errorStatus.textAlignment = .left
        errorStatus.isSelectable = true
        errorStatus.backgroundColor = .clear
        errorStatus.isHidden = true
        return errorStatus
    }()
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil)
    }
    
    @objc convenience public init(delegate: ServerURLDelegate, error: String? = nil, scheme: MDCContainerScheming?) {
        self.init(frame: CGRect.zero)
        self.scheme = scheme
        self.delegate = delegate
        self.error = error
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }

    @objc public func applyTheme(withContainerScheme containerScheme: MDCContainerScheming?) {
        guard let scheme = containerScheme else {
            return
        }
        self.scheme = scheme
        self.view.backgroundColor = scheme.colorScheme.backgroundColor
        self.setServerUrlTitle.textColor = scheme.colorScheme.primaryColorVariant
        self.setServerUrlTitle.font = scheme.typographyScheme.headline6
        self.wandLabel.textColor = scheme.colorScheme.primaryColorVariant
        self.mageLabel.textColor = scheme.colorScheme.primaryColorVariant
        errorStatus.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
        okButton.applyContainedTheme(withScheme: scheme)
        cancelButton.applyContainedTheme(withScheme: scheme)
        serverURL.applyTheme(withScheme: scheme)
        serverURL.leadingView?.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
        errorImage.tintColor = scheme.colorScheme.errorColor
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad();
        view.addSubview(wandMageContainer)
        view.addSubview(setServerUrlTitle)
        view.addSubview(serverURL)
        view.addSubview(buttonStack)
        view.addSubview(progressView)
        view.addSubview(errorImage)
        view.addSubview(errorStatus)
        
        applyTheme(withContainerScheme: scheme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let url = MageServer.baseURL()
        
        if let error = error {
            showError(error: error)
            cancelButton.isEnabled = false
            cancelButton.isHidden = true
            serverURL.text = url?.absoluteString
        } else if let scheme = scheme {
            serverURL.applyTheme(withScheme: scheme)
        }
        
        if let url = url {
            serverURL.text = url.absoluteString
        } else {
            cancelButton.isEnabled = false
            cancelButton.isHidden = true
        }
    }
    
    @objc public func showError(error: String) {
        errorStatus.isHidden = false
        errorImage.isHidden = false
        progressView.isHidden = true
        progressView.stopAnimating()
        errorStatus.text = error
        serverURL.leadingAssistiveLabel.text = error
        if let scheme = scheme {
            serverURL.applyErrorTheme(withScheme: scheme)
        }
    }

    public override func updateViewConstraints() {
        if (!didSetupConstraints) {
            wandLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .right)
            mageLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: -45, right: 0), excludingEdge: .left)
            mageLabel.autoPinEdge(.left, to: .right, of: wandLabel, withOffset: 8)
            wandLabel.autoAlignAxis(.horizontal, toSameAxisOf: mageLabel)
            wandMageContainer.autoPinEdge(toSuperviewSafeArea: .top, withInset: 40)
            wandMageContainer.autoAlignAxis(toSuperviewAxis: .vertical)
            setServerUrlTitle.autoPinEdge(.top, to: .bottom, of: wandMageContainer, withOffset: 16)
            setServerUrlTitle.autoPinEdge(toSuperviewEdge: .left, withInset: 16)
            setServerUrlTitle.autoPinEdge(toSuperviewEdge: .right, withInset: 16)
            setServerUrlTitle.autoSetDimension(.height, toSize: 32)
            serverURL.autoPinEdge(.top, to: .bottom, of: setServerUrlTitle, withOffset: 16)
            serverURL.autoPinEdge(toSuperviewEdge: .left, withInset: 16)
            serverURL.autoPinEdge(toSuperviewEdge: .right, withInset: 16)
            buttonStack.autoPinEdge(.top, to: .bottom, of: serverURL, withOffset: 8)
            buttonStack.autoPinEdge(toSuperviewEdge: .left, withInset: 16)
            buttonStack.autoPinEdge(toSuperviewEdge: .right, withInset: 16)
            progressView.autoPinEdge(toSuperviewEdge: .left, withInset: 16)
            progressView.autoPinEdge(toSuperviewEdge: .right, withInset: 16)
            progressView.autoSetDimension(.height, toSize: 5)
            progressView.autoPinEdge(.top, to: .bottom, of: serverURL)
            errorImage.autoPinEdge(.top, to: .bottom, of: buttonStack, withOffset: 16)
            errorImage.autoPinEdge(toSuperviewMargin: .left, withInset: 16)
            errorStatus.autoPinEdge(toSuperviewMargin: .bottom)
            errorStatus.autoPinEdge(toSuperviewMargin: .right, withInset: 16)
            errorStatus.autoPinEdge(.left, to: .right, of: errorImage, withOffset: 8)
            errorStatus.autoPinEdge(.top, to: .bottom, of: buttonStack, withOffset: 16)
            didSetupConstraints = true;
        }
        
        super.updateViewConstraints();
    }
    
    @objc func okTapped() {
        if let urlString = serverURL.text, let url = URL(string: urlString), url.scheme != nil, url.host != nil {
            errorStatus.isHidden = true
            errorImage.isHidden = true
            progressView.isHidden = false
            progressView.startAnimating()
            delegate?.setServerURL(url: url)
            if let scheme = scheme {
                serverURL.applyTheme(withScheme: scheme)
            }
        } else {
            showError(error: "Invalid URL")
        }
    }
    
    @objc func cancelTapped() {
        delegate?.cancelSetServerURL()
    }

}

extension ServerURLController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        okTapped()
        return true
    }
}
