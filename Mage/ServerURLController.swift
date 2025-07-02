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
    var scheme: AppContainerScheming?
    var error: String?
    var additionalErrorInfo: Dictionary<String, Any>?
    
    lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(forAutoLayout: ())
        progressView.isHidden = true
        return progressView
    }()
    
    private lazy var serverURL: ThemedTextField = {
        let serverURL = ThemedTextField(frame: CGRect(x: 0, y: 0, width: 200, height: 100));
        serverURL.autocapitalizationType = .none;
        serverURL.accessibilityLabel = "MAGE Server URL";
        serverURL.text = "MAGE Server URL"
        serverURL.placeholder = "MAGE Server URL"
        
        let worldImage = UIImageView(image: UIImage(systemName: "globe.americas.fill")?.aspectResize(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate))
        serverURL.leftView = worldImage
        serverURL.leftViewMode = .always
        serverURL.autocorrectionType = .no
        serverURL.autocapitalizationType = .none
        serverURL.keyboardType = .URL
        serverURL.delegate = self
        serverURL.sizeToFit();
        return serverURL;
    }()
    
    lazy var setServerUrlTitle: UILabel = {
        let setServerUrlTitle = UILabel(forAutoLayout: ())
        setServerUrlTitle.textAlignment = .center
        setServerUrlTitle.backgroundColor = .clear
        setServerUrlTitle.text = "Set MAGE Server URL"
        return setServerUrlTitle
    }()
    
    lazy var wandMageContainer: UIView = {
        let container = UIView(forAutoLayout: ())
        container.backgroundColor = .clear
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
    
    private lazy var cancelButton: UIButton = {
        let cancelButton = UIButton(forAutoLayout: ());
        cancelButton.accessibilityLabel = "Cancel";
        cancelButton.setTitle("Cancel", for: .normal);
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside);
        cancelButton.clipsToBounds = true;
        return cancelButton;
    }()
    private lazy var okButton: UIButton = {
        let okButton = UIButton(forAutoLayout: ());
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
        errorStatus.backgroundColor = .clear
        errorStatus.isHidden = true
        return errorStatus
    }()
    
    lazy var errorInfoLink: UILabel = {
        let errorInfoLink = UILabel(forAutoLayout: ())
        errorInfoLink.textAlignment = .center
        errorInfoLink.backgroundColor = .clear
        errorInfoLink.text = "more info"
        errorInfoLink.isHidden = true
        errorInfoLink.isUserInteractionEnabled = true
        errorInfoLink.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(errorInfoLinkTapped)))
        return errorInfoLink
    }()
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil)
    }
    
    @objc convenience public init(delegate: ServerURLDelegate, error: String? = nil, scheme: AppContainerScheming?) {
        self.init(frame: CGRect.zero)
        self.scheme = scheme
        self.delegate = delegate
        self.error = error
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }

    @objc public func applyTheme(withContainerScheme containerScheme: AppContainerScheming?) {
        guard let scheme = containerScheme else {
            return
        }
        self.scheme = scheme
        self.view.backgroundColor = scheme.colorScheme.backgroundColor
        self.setServerUrlTitle.textColor = scheme.colorScheme.primaryColorVariant
        self.setServerUrlTitle.font = scheme.typographyScheme.headline6Font
        self.wandLabel.textColor = scheme.colorScheme.primaryColorVariant
        self.mageLabel.textColor = scheme.colorScheme.primaryColorVariant
        errorStatus.textColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.6)
        
        okButton.applyPrimaryTheme(withScheme: scheme)
        cancelButton.applyPrimaryTheme(withScheme: scheme)
        serverURL.applyPrimaryThemeWithScheme(scheme)
        serverURL.leftView?.tintColor = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.6)
        errorImage.tintColor = scheme.colorScheme.errorColor
        errorInfoLink.textColor = scheme.colorScheme.primaryColorVariant
        errorInfoLink.font = UIFont.systemFont(ofSize: 12)
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
        view.addSubview(errorInfoLink)
        
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
            serverURL.applyPrimaryThemeWithScheme(scheme)
        }
        
        if let url = url {
            serverURL.text = url.absoluteString
        } else {
            cancelButton.isEnabled = false
            cancelButton.isHidden = true
        }
    }
    
    @objc public func showError(error: String, userInfo:Dictionary<String, Any>? = nil) {
        errorStatus.isHidden = false
        errorInfoLink.isHidden = false
        errorImage.isHidden = false
        progressView.isHidden = true
        errorStatus.text = "This URL does not appear to be a MAGE server."
        additionalErrorInfo = userInfo
        
        if let scheme = scheme {
            serverURL.applyErrorThemeWithScheme(scheme)
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
            errorImage.autoPinEdge(.top, to: .bottom, of: buttonStack, withOffset: 21)
            errorImage.autoPinEdge(toSuperviewMargin: .left, withInset: 16)

            errorStatus.autoPinEdge(toSuperviewMargin: .right, withInset: 16)
            errorStatus.autoPinEdge(.left, to: .right, of: errorImage, withOffset: 8)
            errorStatus.autoPinEdge(.top, to: .bottom, of: buttonStack, withOffset: 16)
            errorStatus.autoSetDimension(.height, toSize: 32)
            
            errorInfoLink.autoPinEdge(toSuperviewMargin: .left, withInset: 16)
            errorInfoLink.autoPinEdge(toSuperviewMargin: .right, withInset: 16)
            errorInfoLink.autoPinEdge(.top, to: .bottom, of: errorStatus, withOffset: 12)
            errorInfoLink.autoSetDimension(.height, toSize: 16)

            didSetupConstraints = true;
        }
        
        super.updateViewConstraints();
    }
    
    @objc func okTapped() {
        
        guard let urlString = serverURL.text else {
            showError(error: "Invalid URL")
            return
        }
        
        guard var urlComponents = URLComponents(string: urlString) else {
            showError(error: "Invalid URL")
            return
        }
           
        // Handle cases without path or scheme, e.g. "magedev.geointnext.com"
        if urlComponents.path != "" && urlComponents.host == nil {
            urlComponents.host = urlComponents.path
            urlComponents.path = ""
        }
        
        // Remove trailing "/" in the path if they entered one by accident
        if urlComponents.path == "/" {
            urlComponents.path = ""
        }
        
        // Supply a default HTTPS scheme if none is specified
        if urlComponents.scheme == nil {
            urlComponents.scheme = "https"
        }
        
        if let url = urlComponents.url {
        
            errorStatus.isHidden = true
            errorInfoLink.isHidden = true
            errorImage.isHidden = true
            progressView.isHidden = false
            delegate?.setServerURL(url: url)
            
            if let scheme = scheme {
                serverURL.applyPrimaryThemeWithScheme(scheme)
            }
        } else {
            showError(error: "Invalid URL")
        }
        
    }
    
    @objc func cancelTapped() {
        delegate?.cancelSetServerURL()
    }
    
    @objc func errorInfoLinkTapped() {
        
        var errorTitle = "Error"
        var errorMessage = "Failed to connect to server."
        
        if let additionalErrorInfo = additionalErrorInfo {
            if let statusCode = additionalErrorInfo["statusCode"] as? Int {
                errorTitle = String(statusCode)
            }
            if let desc = additionalErrorInfo["NSLocalizedDescription"] as? String {
                errorMessage = desc
            }
        }
        let alert = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }

}

extension ServerURLController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        okTapped()
        return true
    }
}
