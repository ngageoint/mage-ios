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
    var scheme: AppContainerScheming?
    var colorPreference: String? {
        didSet {
            if let color = UserDefaults.standard.color(forKey: colorPreference!) {
                textField.text = color.hex()
                textFieldPreviewTile.backgroundColor = color
            } else {
                textField.text = nil
                textFieldPreviewTile.backgroundColor = .clear
            }
        }
    }
    var tempColor: UIColor?
    
    var preferenceTitle: String? {
        didSet {
            titleLabel.text = preferenceTitle
        }
    }
    
    lazy var textFieldPreviewTile: UIView = {
        let textFieldPreviewTile = UIView(forAutoLayout: ())
        textFieldPreviewTile.autoSetDimensions(to: CGSize(width: 24, height: 24))
        textFieldPreviewTile.backgroundColor = UIColor(red: 0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        textFieldPreviewTile.layer.cornerRadius = 2
        return textFieldPreviewTile
    }()
        
    lazy var textField: UITextField = {
        let textField = UITextField(forAutoLayout: ())
        textField.delegate = self
        textField.autocapitalizationType = .none
        textField.accessibilityLabel = "hex color"
        textField.placeholder = "Hex Color"
        textField.returnKeyType = .done
        textField.addTarget(self, action: #selector(textFieldDidEndEditing(_:)), for: .editingChanged)

        // Optional: Apply theming if available
        textField.applyPrimaryTheme(withScheme: scheme)

        return textField
    }()
    
    private lazy var actionButtonView: UIView = {
        let actionButtonView = UIView.newAutoLayout()
        actionButtonView.addSubview(cancelButton)
        actionButtonView.addSubview(doneButton)
        
        doneButton.autoPinEdge(toSuperviewEdge: .right, withInset: 32)
        doneButton.autoPinEdge(.left, to: .right, of: cancelButton, withOffset: 16)
        cancelButton.autoAlignAxis(.horizontal, toSameAxisOf: doneButton)
        return actionButtonView
    }()
    
    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = "done"
        button.setTitle("Done", for: .normal)
        button.addTarget(self, action: #selector(colorSet), for: .touchUpInside)
        button.applyPrimaryTheme(withScheme: scheme)
        return button
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = "cancel"
        button.setTitle("Cancel", for: .normal)
        button.addTarget(self, action: #selector(cancelButtonPressed), for: .touchUpInside)
        button.applyPrimaryTheme(withScheme: scheme)
        return button
    }()
    
    func createTapGestureRecognizer() -> UITapGestureRecognizer {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector (self.colorPicked (_:)))
        
        return tapGesture
    }
    
    let titleLabel = UILabel(forAutoLayout: ())
    
    func applyTheme(withContainerScheme containerScheme: AppContainerScheming?) {
        guard let containerScheme = containerScheme else { return }

        self.scheme = containerScheme

        // View background
        view.backgroundColor = containerScheme.colorScheme.surfaceColor

        // Apply button theming (assuming you have these extensions in UIButton+Theming)
        doneButton.applyPrimaryTheme(withScheme: containerScheme)
        cancelButton.applyPrimaryTheme(withScheme: containerScheme)

        // Apply text field theming (assuming UITextField+Theming.swift exists)
        textField.applyPrimaryTheme(withScheme: containerScheme)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.accessibilityIdentifier = "ColorPicker"
        view.accessibilityLabel = "ColorPicker"
        
        view.addSubview(titleLabel)
        titleLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        titleLabel.autoPinEdge(toSuperviewEdge: .top, withInset: 16)
        
        view.addSubview(textFieldPreviewTile)
        textFieldPreviewTile.autoPinEdge(toSuperviewEdge: .left, withInset: 32)
        view.addSubview(textField)
        textField.autoPinEdge(.left, to: .right, of: textFieldPreviewTile, withOffset: 16)
        textField.autoPinEdge(toSuperviewEdge: .right, withInset: 32)
        textField.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: 32)
        textFieldPreviewTile.autoAlignAxis(.horizontal, toSameAxisOf: textField)
        
        let colorsView = UIView(forAutoLayout: ())
        view.addSubview(colorsView)
        colorsView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 32, bottom: 32, right: 32), excludingEdge: .top)
        colorsView.autoPinEdge(.top, to: .bottom, of: textField, withOffset: 32)
        
        let colorRow1 = UIView(forAutoLayout: ())
        colorsView.addSubview(colorRow1)
        colorRow1.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .bottom)
        
        let blueView = UIView(forAutoLayout: ())
        blueView.autoSetDimensions(to: CGSize(width: 75, height: 75))
        blueView.backgroundColor = UIColor(red: 0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        blueView.layer.cornerRadius = 10
        blueView.addGestureRecognizer(createTapGestureRecognizer())
        
        let greenView = UIView(forAutoLayout: ())
        greenView.autoSetDimensions(to: CGSize(width: 75, height: 75))
        greenView.backgroundColor = UIColor(red: 52.0/255.0, green: 199.0/255.0, blue: 89.0/255.0, alpha: 1.0)
        greenView.layer.cornerRadius = 10
        greenView.addGestureRecognizer(createTapGestureRecognizer())
        
        let indigoView = UIView(forAutoLayout: ())
        indigoView.autoSetDimensions(to: CGSize(width: 75, height: 75))
        indigoView.backgroundColor = UIColor(red: 88.0/255.0, green: 86.0/255.0, blue: 214.0/255.0, alpha: 1.0)
        indigoView.layer.cornerRadius = 10
        indigoView.addGestureRecognizer(createTapGestureRecognizer())
        
        colorRow1.addSubview(blueView)
        colorRow1.addSubview(greenView)
        colorRow1.addSubview(indigoView)
        
        blueView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .right)
        greenView.autoPinEdge(toSuperviewEdge: .top)
        greenView.autoAlignAxis(toSuperviewAxis: .vertical)
        indigoView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .left)
        
        let colorRow2 = UIView(forAutoLayout: ())
        colorsView.addSubview(colorRow2)
        colorRow2.autoPinEdge(toSuperviewEdge: .left)
        colorRow2.autoPinEdge(toSuperviewEdge: .right)
        colorRow2.autoPinEdge(.top, to: .bottom, of: colorRow1, withOffset: 32)
        
        let orangeView = UIView(forAutoLayout: ())
        orangeView.autoSetDimensions(to: CGSize(width: 75, height: 75))
        orangeView.backgroundColor = UIColor(red: 255.0/255.0, green: 149.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        orangeView.layer.cornerRadius = 10
        orangeView.addGestureRecognizer(createTapGestureRecognizer())
        
        let pinkView = UIView(forAutoLayout: ())
        pinkView.autoSetDimensions(to: CGSize(width: 75, height: 75))
        pinkView.backgroundColor = UIColor(red: 255.0/255.0, green: 45.0/255.0, blue: 95.0/255.0, alpha: 1.0)
        pinkView.layer.cornerRadius = 10
        pinkView.addGestureRecognizer(createTapGestureRecognizer())
        
        let purpleView = UIView(forAutoLayout: ())
        purpleView.autoSetDimensions(to: CGSize(width: 75, height: 75))
        purpleView.backgroundColor = UIColor(red: 175.0/255.0, green: 82.0/255.0, blue: 222.0/255.0, alpha: 1.0)
        purpleView.layer.cornerRadius = 10
        purpleView.addGestureRecognizer(createTapGestureRecognizer())
        
        colorRow2.addSubview(orangeView)
        colorRow2.addSubview(pinkView)
        colorRow2.addSubview(purpleView)
        
        orangeView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .right)
        pinkView.autoPinEdge(toSuperviewEdge: .top)
        pinkView.autoAlignAxis(toSuperviewAxis: .vertical)
        purpleView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .left)
        
        let colorRow3 = UIView(forAutoLayout: ())
        colorsView.addSubview(colorRow3)
        colorRow3.autoPinEdge(toSuperviewEdge: .left)
        colorRow3.autoPinEdge(toSuperviewEdge: .right)
        colorRow3.autoPinEdge(.top, to: .bottom, of: colorRow2, withOffset: 32)
        
        let redView = UIView(forAutoLayout: ())
        redView.autoSetDimensions(to: CGSize(width: 75, height: 75))
        redView.backgroundColor = UIColor(red: 255.0/255.0, green: 59.0/255.0, blue: 48.0/255.0, alpha: 1.0)
        redView.layer.cornerRadius = 10
        redView.addGestureRecognizer(createTapGestureRecognizer())
        
        let tealView = UIView(forAutoLayout: ())
        tealView.autoSetDimensions(to: CGSize(width: 75, height: 75))
        tealView.backgroundColor = UIColor(red: 90.0/255.0, green: 200.0/255.0, blue: 250.0/255.0, alpha: 1.0)
        tealView.layer.cornerRadius = 10
        tealView.addGestureRecognizer(createTapGestureRecognizer())
        
        let yellowView = UIView(forAutoLayout: ())
        yellowView.autoSetDimensions(to: CGSize(width: 75, height: 75))
        yellowView.backgroundColor = UIColor(red: 255.0/255.0, green: 204.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        yellowView.layer.cornerRadius = 10
        yellowView.addGestureRecognizer(createTapGestureRecognizer())
        
        colorRow3.addSubview(redView)
        colorRow3.addSubview(tealView)
        colorRow3.addSubview(yellowView)
        
        redView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .right)
        tealView.autoPinEdge(toSuperviewEdge: .top)
        tealView.autoAlignAxis(toSuperviewAxis: .vertical)
        yellowView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .left)
        
        let colorRow4 = UIView(forAutoLayout: ())
        colorsView.addSubview(colorRow4)
        colorRow4.autoPinEdge(toSuperviewEdge: .left)
        colorRow4.autoPinEdge(toSuperviewEdge: .right)
        colorRow4.autoPinEdge(.top, to: .bottom, of: colorRow3, withOffset: 32)
        
        let lightGrayView = UIView(forAutoLayout: ())
        lightGrayView.autoSetDimensions(to: CGSize(width: 75, height: 75))
        lightGrayView.backgroundColor = UIColor(red: 224.0/255.0, green: 224.0/255.0, blue: 224.0/255.0, alpha: 1.0)
        lightGrayView.layer.cornerRadius = 10
        lightGrayView.addGestureRecognizer(createTapGestureRecognizer())
        
        let darkGrayView = UIView(forAutoLayout: ())
        darkGrayView.autoSetDimensions(to: CGSize(width: 75, height: 75))
        darkGrayView.backgroundColor = UIColor(red: 97.0/255.0, green: 97.0/255.0, blue: 97.0/255.0, alpha: 1.0)
        darkGrayView.layer.cornerRadius = 10
        darkGrayView.addGestureRecognizer(createTapGestureRecognizer())
        
        let blackView = UIView(forAutoLayout: ())
        blackView.autoSetDimensions(to: CGSize(width: 75, height: 75))
        blackView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        blackView.layer.cornerRadius = 10
        blackView.addGestureRecognizer(createTapGestureRecognizer())
        
        colorRow4.addSubview(lightGrayView)
        colorRow4.addSubview(darkGrayView)
        colorRow4.addSubview(blackView)
        
        lightGrayView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .right)
        darkGrayView.autoPinEdge(toSuperviewEdge: .top)
        darkGrayView.autoAlignAxis(toSuperviewAxis: .vertical)
        blackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .left)
        
        view.addSubview(actionButtonView)
        actionButtonView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .top)
        actionButtonView.autoPinEdge(.top, to: .bottom, of: blackView, withOffset: 32)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme(withContainerScheme: scheme)
    }
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil)
    }
    
    @objc convenience public init(containerScheme: AppContainerScheming?) {
        self.init(frame: CGRect.zero)
        self.scheme = containerScheme
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    @objc func cancelButtonPressed() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func colorSet() {
        if let colorPreference = colorPreference {
            UserDefaults.standard.set(tempColor, forKey: colorPreference)
        }
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func colorPicked(_ sender:UITapGestureRecognizer) {
        tempColor = sender.view?.backgroundColor
        textFieldPreviewTile.backgroundColor = tempColor
        textField.text = tempColor?.hex()
    }
}

extension ColorPickerViewController: UITextFieldDelegate {

    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let color: UIColor = UIColor(hex: textField.text ?? "") {
            textFieldPreviewTile.backgroundColor = color
            tempColor = color
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
