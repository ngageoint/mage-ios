//
//  FormDefaultsViewController.swift
//  MAGE
//
//  Created by Daniel Barela on 2/8/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

class FormDefaultsViewController: UIViewController {
    
    var didSetupConstraints = false;
    var formDefaultsCoordinator: FormDefaultsCoordinator?;
    var observationFormView: ObservationFormView?;
    var navController: UINavigationController!;
    var event: Event!;
    var eventForm: Form!;
    var scheme: AppContainerScheming?;
    let card = UIView(forAutoLayout: ())
    let formNameLabel = UILabel.newAutoLayout();
    let formDescriptionLabel = UILabel.newAutoLayout();
    let defaultsLabel = UILabel.newAutoLayout();
    let defaultDescriptionLabel = UILabel.newAutoLayout();
    let image = UIImageView(image: UIImage(systemName: "doc.text.fill"));
    
    private lazy var managedObjectContext: NSManagedObjectContext = {
        var managedObjectContext: NSManagedObjectContext = .mr_newMainQueue();
        managedObjectContext.parent = .mr_rootSaving();
        managedObjectContext.stalenessInterval = 0.0;
        managedObjectContext.mr_setWorkingName("Form Default Temporary Context");
        return managedObjectContext;
    } ()
    
    private lazy var divider: UIView = {
        let divider = UIView(forAutoLayout: ());
        divider.autoSetDimension(.height, toSize: 1);
        return divider;
    }()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView.newAutoLayout();
        return scrollView;
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView.newAutoLayout();
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 8
        stackView.distribution = .fill
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8)
        stackView.isLayoutMarginsRelativeArrangement = true;
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        return stackView;
    }()
    
    private lazy var resetButton: UIButton = {
        let button = UIButton(forAutoLayout: ());
        button.accessibilityLabel = "reset defaults";
        button.setTitle("Reset To Server Defaults", for: .normal);
        button.addTarget(self, action: #selector(resetDefaults), for: .touchUpInside);
        return button;
    }()
    
    private lazy var header: UIView = {
        let stack = UIStackView.newAutoLayout();
        stack.alignment = .fill;
        stack.distribution = .fill;
        stack.axis = .vertical;
        stack.spacing = 4;
        formNameLabel.text = eventForm.name;
        formDescriptionLabel.text = eventForm.formDescription
        formDescriptionLabel.numberOfLines = 0;
        formDescriptionLabel.lineBreakMode = .byWordWrapping;
        stack.addArrangedSubview(formNameLabel);
        stack.addArrangedSubview(formDescriptionLabel);
        
        let header = UIView.newAutoLayout();
        header.addSubview(image);
        header.addSubview(stack);
        image.autoPinEdge(toSuperviewEdge: .left);
        image.autoSetDimensions(to: CGSize(width: 36, height: 36));
        stack.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .left);
        stack.autoPinEdge(.left, to: .right, of: image, withOffset: 16);
        image.autoAlignAxis(.horizontal, toSameAxisOf: stack);
        return header;
    }()
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil);
    }
    
    @objc convenience public init(event: Event, eventForm: Form, navigationController: UINavigationController, scheme: AppContainerScheming, formDefaultsCoordinator: FormDefaultsCoordinator?) {
        self.init(frame: CGRect.zero);
        self.event = event;
        self.eventForm = eventForm;
        self.scheme = scheme;
        self.navController = navigationController;
        self.formDefaultsCoordinator = formDefaultsCoordinator;
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    @objc public func applyTheme(withContainerScheme containerScheme: AppContainerScheming?) {
        guard let containerScheme = containerScheme else {
            return
        }

        self.scheme = containerScheme;
        self.view.backgroundColor = containerScheme.colorScheme.backgroundColor;
        formNameLabel.textColor = containerScheme.colorScheme.onBackgroundColor?.withAlphaComponent(0.87);
        formNameLabel.font = containerScheme.typographyScheme.headline6Font;
        formDescriptionLabel.textColor = containerScheme.colorScheme.onBackgroundColor?.withAlphaComponent(0.6);
        formDescriptionLabel.font = containerScheme.typographyScheme.subtitle2Font;
        defaultsLabel.textColor = containerScheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.87);
        defaultsLabel.font = containerScheme.typographyScheme.subtitle1Font;
        defaultDescriptionLabel.textColor = containerScheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.6);
        defaultDescriptionLabel.font = containerScheme.typographyScheme.captionFont;
        observationFormView?.applyTheme(withScheme: containerScheme);
        
//        card.applyTheme(withScheme: containerScheme);
        
        if let color = eventForm.color {
            image.tintColor = UIColor(hex: color);
        } else {
            image.tintColor = containerScheme.colorScheme.primaryColor
        }
//        resetButton.applyTextTheme(withScheme: globalErrorContainerScheme());
        divider.backgroundColor = containerScheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.12);
    }
    
    @objc func resetDefaults() {
        observationFormView?.removeFromSuperview();
        
        var newForm: [String: AnyHashable] = [:];
        let fields: [[String : AnyHashable]] = eventForm.fields ?? [];
        let filteredFields: [[String: AnyHashable]] = fields.filter {(($0[FieldKey.archived.key] as? Bool) == nil || ($0[FieldKey.archived.key] as? Bool) == false) }
        for (_, field) in filteredFields.enumerated() {
            // grab the server default from the form fields value property
            if let value: AnyHashable = field[FieldKey.value.key] {
                newForm[field[FieldKey.name.key] as! String] = value;
            }
        }
        
        let observation: Observation = Observation(context: managedObjectContext);
        observation.properties = [ObservationKey.forms.key: [newForm]];
        observationFormView = ObservationFormView(observation: observation, form: newForm, eventForm: eventForm, formIndex: 0, viewController: navController, delegate: formDefaultsCoordinator);
        
        stackView.insertArrangedSubview(observationFormView!, at: 2);
        observationFormView?.applyTheme(withScheme: self.scheme!);
    }
    
    func buildObservationFormView() {
        var newForm: [String: AnyHashable] = [:];
        let defaults: FormDefaults = FormDefaults(eventId: self.event.remoteId as! Int, formId: eventForm.formId?.intValue ?? -1);
        let formDefaults: [String: AnyHashable] = defaults.getDefaults() as! [String: AnyHashable];
        
        let fields: [[String : AnyHashable]] = eventForm.fields ?? [];
        let filteredFields: [[String: AnyHashable]] = fields.filter {(($0[FieldKey.archived.key] as? Bool) == nil || ($0[FieldKey.archived.key] as? Bool) == false) }
        if (formDefaults.count > 0) { // user defaults
            for (_, field) in filteredFields.enumerated() {
                var value: AnyHashable? = nil;
                if let defaultField: AnyHashable = formDefaults[field[FieldKey.name.key] as! String] {
                    value = defaultField
                }
                
                if (value != nil) {
                    newForm[field[FieldKey.name.key] as! String] = value;
                }
            }
        } else { // server defaults
            for (_, field) in filteredFields.enumerated() {
                // grab the server default from the form fields value property
                if let value: AnyHashable = field[FieldKey.value.key] {
                    newForm[field[FieldKey.name.key] as! String] = value;
                }
            }
        }
        let observation: Observation = Observation(context: managedObjectContext);
        observation.properties = [ObservationKey.forms.key: [newForm]];
        observationFormView = ObservationFormView(observation: observation, form: newForm, eventForm: eventForm, formIndex: 0, viewController: navController, delegate: formDefaultsCoordinator, includeAttachmentFields: false);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Apply", style: .done, target: self, action: #selector(self.saveDefaults));
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(self.cancel));
        
        view.addSubview(scrollView);
        scrollView.addSubview(card);
        card.addSubview(stackView);

        scrollView.addSubview(header);
        defaultsLabel.text = "Custom Form Defaults";
        defaultDescriptionLabel.text = "Personalize the default values MAGE will autofill when you add this form to an observation.";
        defaultDescriptionLabel.lineBreakMode = .byWordWrapping;
        defaultDescriptionLabel.numberOfLines = 0;
        stackView.addArrangedSubview(defaultsLabel);
        stackView.addArrangedSubview(defaultDescriptionLabel);
        stackView.setCustomSpacing(16, after: defaultDescriptionLabel);
        buildObservationFormView();
        if let formView = observationFormView {
            stackView.addArrangedSubview(formView);
        }
        
        stackView.addArrangedSubview(divider);
        
        let buttonContainer = UIView.newAutoLayout();
        buttonContainer.addSubview(resetButton);

        resetButton.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0), excludingEdge: .left);
        
        stackView.addArrangedSubview(buttonContainer);
        view.setNeedsUpdateConstraints();
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        applyTheme(withContainerScheme: scheme);
    }
    
    override func updateViewConstraints() {
        if (!didSetupConstraints) {
            scrollView.autoPinEdgesToSuperviewEdges(with: .zero);
            stackView.autoPinEdgesToSuperviewEdges();
            
            card.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8), excludingEdge: .top);
            card.autoMatch(.width, to: .width, of: view, withOffset: -16);
            
            header.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 16), excludingEdge: .bottom);
            card.autoPinEdge(.top, to: .bottom, of: header, withOffset: 16);
            
            didSetupConstraints = true;
        }
        
        super.updateViewConstraints();
    }
    
    @objc func saveDefaults() {
        let valid = observationFormView?.checkValidity(enforceRequired: false) ?? false;
        if (!valid) {
            if let fieldViews = observationFormView?.fieldViews {
                for (_, subview) in fieldViews {
                    if !subview.isValid(enforceRequired: false) {
                        var yOffset = subview.frame.origin.y
                        var superview = subview.superview
                        while (superview != nil) {
                            yOffset += superview?.frame.origin.y ?? 0.0
                            superview = superview?.superview
                        }
                        let newFrame = CGRect(x: 0, y: yOffset, width: subview.frame.size.width, height: subview.frame.size.height)
                        scrollView.scrollRectToVisible(newFrame, animated: true)
                        return
                    }
                }
            }
            return
        }
        
        let currentDefaults: [String: AnyHashable] = (observationFormView?.observation.properties!["forms"] as! [[String: AnyHashable]])[0];
        
        formDefaultsCoordinator?.save(defaults: currentDefaults);
    }
    
    @objc func cancel() {
        formDefaultsCoordinator?.cancel();
    }
}
