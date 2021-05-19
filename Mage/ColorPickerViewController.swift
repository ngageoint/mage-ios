//
//  ColorPickerViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 5/18/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

// delete this class once ios13 support is dropped
import Foundation

@objc class ColorPickerViewController: UIViewController {
    var scheme: MDCContainerScheming?;
    var colorPreference: String?;
    
    var preferenceTitle: String? {
        didSet {
            titleLabel.text = preferenceTitle;
        }
    }
    
    private lazy var cancelButton: UIButton = {
        let cancelButton = UIButton(type: .custom);
        cancelButton.accessibilityLabel = "cancel";
        cancelButton.setImage(UIImage(named: "cancel" )?.withRenderingMode(.alwaysTemplate), for: .normal);
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        return cancelButton;
    }();
    
    func createTapGestureRecognizer() -> UITapGestureRecognizer {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector (self.colorPicked (_:)))
        
        return tapGesture;
    }
    
    let titleLabel = UILabel(forAutoLayout: ());
    
    func applyTheme(withContainerScheme containerScheme: MDCContainerScheming!) {
        self.scheme = containerScheme;
        view.backgroundColor = self.scheme?.colorScheme.surfaceColor;
        cancelButton.tintColor = self.scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.accessibilityIdentifier = "ColorPicker"
        view.accessibilityLabel = "ColorPicker"
        
        view.addSubview(titleLabel);
        titleLabel.autoAlignAxis(toSuperviewAxis: .vertical);
        titleLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 16);
        
        view.addSubview(cancelButton);
        cancelButton.autoPinEdge(toSuperviewEdge: .right, withInset: 16);
        cancelButton.autoPinEdge(toSuperviewEdge: .top, withInset: 16);
        
        let colorsView = UIView(forAutoLayout: ());
        view.addSubview(colorsView);
        colorsView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 32, bottom: 32, right: 32), excludingEdge: .top);
        colorsView.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: 16);
        
        let colorRow1 = UIView(forAutoLayout: ());
        colorsView.addSubview(colorRow1);
        colorRow1.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .bottom);
        
        let blueView = UIView(forAutoLayout: ());
        blueView.autoSetDimensions(to: CGSize(width: 75, height: 75));
        blueView.backgroundColor = UIColor(red: 0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        blueView.layer.cornerRadius = 10;
        blueView.addGestureRecognizer(createTapGestureRecognizer());
        
        let greenView = UIView(forAutoLayout: ());
        greenView.autoSetDimensions(to: CGSize(width: 75, height: 75));
        greenView.backgroundColor = UIColor(red: 52.0/255.0, green: 199.0/255.0, blue: 89.0/255.0, alpha: 1.0)
        greenView.layer.cornerRadius = 10;
        greenView.addGestureRecognizer(createTapGestureRecognizer());
        
        let indigoView = UIView(forAutoLayout: ());
        indigoView.autoSetDimensions(to: CGSize(width: 75, height: 75));
        indigoView.backgroundColor = UIColor(red: 88.0/255.0, green: 86.0/255.0, blue: 214.0/255.0, alpha: 1.0)
        indigoView.layer.cornerRadius = 10;
        indigoView.addGestureRecognizer(createTapGestureRecognizer());
        
        colorRow1.addSubview(blueView);
        colorRow1.addSubview(greenView);
        colorRow1.addSubview(indigoView);
        
        blueView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .right)
        greenView.autoPinEdge(toSuperviewEdge: .top);
        greenView.autoAlignAxis(toSuperviewAxis: .vertical);
        indigoView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .left);
        
        let colorRow2 = UIView(forAutoLayout: ());
        colorsView.addSubview(colorRow2);
        colorRow2.autoPinEdge(toSuperviewEdge: .left);
        colorRow2.autoPinEdge(toSuperviewEdge: .right);
        colorRow2.autoPinEdge(.top, to: .bottom, of: colorRow1, withOffset: 32);
        
        let orangeView = UIView(forAutoLayout: ());
        orangeView.autoSetDimensions(to: CGSize(width: 75, height: 75));
        orangeView.backgroundColor = UIColor(red: 255.0/255.0, green: 149.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        orangeView.layer.cornerRadius = 10;
        orangeView.addGestureRecognizer(createTapGestureRecognizer());
        
        let pinkView = UIView(forAutoLayout: ());
        pinkView.autoSetDimensions(to: CGSize(width: 75, height: 75));
        pinkView.backgroundColor = UIColor(red: 255.0/255.0, green: 45.0/255.0, blue: 95.0/255.0, alpha: 1.0)
        pinkView.layer.cornerRadius = 10;
        pinkView.addGestureRecognizer(createTapGestureRecognizer());
        
        let purpleView = UIView(forAutoLayout: ());
        purpleView.autoSetDimensions(to: CGSize(width: 75, height: 75));
        purpleView.backgroundColor = UIColor(red: 175.0/255.0, green: 82.0/255.0, blue: 222.0/255.0, alpha: 1.0)
        purpleView.layer.cornerRadius = 10;
        purpleView.addGestureRecognizer(createTapGestureRecognizer());
        
        colorRow2.addSubview(orangeView);
        colorRow2.addSubview(pinkView);
        colorRow2.addSubview(purpleView);
        
        orangeView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .right)
        pinkView.autoPinEdge(toSuperviewEdge: .top);
        pinkView.autoAlignAxis(toSuperviewAxis: .vertical);
        purpleView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .left);
        
        let colorRow3 = UIView(forAutoLayout: ());
        colorsView.addSubview(colorRow3);
        colorRow3.autoPinEdge(toSuperviewEdge: .left);
        colorRow3.autoPinEdge(toSuperviewEdge: .right);
        colorRow3.autoPinEdge(.top, to: .bottom, of: colorRow2, withOffset: 32);
        
        let redView = UIView(forAutoLayout: ());
        redView.autoSetDimensions(to: CGSize(width: 75, height: 75));
        redView.backgroundColor = UIColor(red: 255.0/255.0, green: 59.0/255.0, blue: 48.0/255.0, alpha: 1.0)
        redView.layer.cornerRadius = 10;
        redView.addGestureRecognizer(createTapGestureRecognizer());
        
        let tealView = UIView(forAutoLayout: ());
        tealView.autoSetDimensions(to: CGSize(width: 75, height: 75));
        tealView.backgroundColor = UIColor(red: 90.0/255.0, green: 200.0/255.0, blue: 250.0/255.0, alpha: 1.0)
        tealView.layer.cornerRadius = 10;
        tealView.addGestureRecognizer(createTapGestureRecognizer());
        
        let yellowView = UIView(forAutoLayout: ());
        yellowView.autoSetDimensions(to: CGSize(width: 75, height: 75));
        yellowView.backgroundColor = UIColor(red: 255.0/255.0, green: 204.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        yellowView.layer.cornerRadius = 10;
        yellowView.addGestureRecognizer(createTapGestureRecognizer());
        
        colorRow3.addSubview(redView);
        colorRow3.addSubview(tealView);
        colorRow3.addSubview(yellowView);
        
        redView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .right)
        tealView.autoPinEdge(toSuperviewEdge: .top);
        tealView.autoAlignAxis(toSuperviewAxis: .vertical);
        yellowView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .left);
        
        let colorRow4 = UIView(forAutoLayout: ());
        colorsView.addSubview(colorRow4);
        colorRow4.autoPinEdge(toSuperviewEdge: .left);
        colorRow4.autoPinEdge(toSuperviewEdge: .right);
        colorRow4.autoPinEdge(.top, to: .bottom, of: colorRow3, withOffset: 32);
        
        let lightGrayView = UIView(forAutoLayout: ());
        lightGrayView.autoSetDimensions(to: CGSize(width: 75, height: 75));
        lightGrayView.backgroundColor = .lightGray
        lightGrayView.layer.cornerRadius = 10;
        lightGrayView.addGestureRecognizer(createTapGestureRecognizer());
        
        let darkGrayView = UIView(forAutoLayout: ());
        darkGrayView.autoSetDimensions(to: CGSize(width: 75, height: 75));
        darkGrayView.backgroundColor = .darkGray
        darkGrayView.layer.cornerRadius = 10;
        darkGrayView.addGestureRecognizer(createTapGestureRecognizer());
        
        let blackView = UIView(forAutoLayout: ());
        blackView.autoSetDimensions(to: CGSize(width: 75, height: 75));
        blackView.backgroundColor = .black
        blackView.layer.cornerRadius = 10;
        blackView.addGestureRecognizer(createTapGestureRecognizer());
        
        colorRow4.addSubview(lightGrayView);
        colorRow4.addSubview(darkGrayView);
        colorRow4.addSubview(blackView);
        
        lightGrayView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .right)
        darkGrayView.autoPinEdge(toSuperviewEdge: .top);
        darkGrayView.autoAlignAxis(toSuperviewAxis: .vertical);
        blackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .left);
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        if let safeScheme = self.scheme {
            applyTheme(withContainerScheme: safeScheme);
        }
    }
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil);
    }
    
    @objc convenience public init(containerScheme: MDCContainerScheming?) {
        self.init(frame: CGRect.zero);
        self.scheme = containerScheme;
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    @objc func cancelButtonPressed() {
        self.presentingViewController?.dismiss(animated: true, completion: nil);
    }
    
    @objc func colorPicked(_ sender:UITapGestureRecognizer) {
        if let safeColorPreference = colorPreference {
            UserDefaults.standard.set(sender.view?.backgroundColor, forKey: safeColorPreference)
        }
        self.presentingViewController?.dismiss(animated: true, completion: nil);
    }
}
