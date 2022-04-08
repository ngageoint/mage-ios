//
//  FormPickerViewController.m
//  MAGE
//
//  Created by Dan Barela on 8/10/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//
import Foundation
import MaterialComponents.MDCButton;

@objc protocol FormPickedDelegate {
    @objc func formPicked (form: Form);
    @objc func cancelSelection();
}

@objc class FormPickerViewController: UIViewController {

    weak var delegate: FormPickedDelegate?;
    var forms: [Form]?;
    var scheme: MDCContainerScheming?;
    weak var observation: Observation?;
    var formIdCount: [Int : Int] = [ : ];
    
    private lazy var divider: UIView = {
        let divider = UIView(forAutoLayout: ());
        divider.autoSetDimension(.height, toSize: 1);
        return divider;
    }()
    
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel(forAutoLayout: ());
        titleLabel.text = "Add A Form To Your Observation";
        return titleLabel;
    }()
    
    private lazy var tableSectionHeaderView: UIView = {
        let headerView = UIView(forAutoLayout: ());
        headerView.addSubview(titleLabel)
        headerView.addSubview(divider)
        titleLabel.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        divider.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .top)
        headerView.autoSetDimension(.height, toSize: 50)
        headerView.autoSetDimension(.width, toSize: max(UIScreen.main.bounds.height, UIScreen.main.bounds.width))
        return headerView;
    }()
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(forAutoLayout: ());
        tableView.accessibilityLabel = "Add A Form Table";
        tableView.estimatedRowHeight = 100;
        tableView.rowHeight = UITableView.automaticDimension;
        tableView.insetsContentViewsToSafeArea = false;
        return tableView;
    }()
    
    private lazy var cancelButton: MDCButton = {
        let cancelButton = MDCButton(forAutoLayout: ());
        cancelButton.accessibilityLabel = "Cancel";
        cancelButton.setTitle("Cancel", for: .normal);
        cancelButton.clipsToBounds = true;
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped(_:)), for: .touchUpInside);
        return cancelButton;
    }()
    
    @objc func cancelButtonTapped(_ sender: UIButton) {
        delegate?.cancelSelection();
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming? = nil) {
        guard let scheme = scheme else {
            return
        }

        self.scheme = scheme;
        self.view.backgroundColor = scheme.colorScheme.backgroundColor
        self.tableView.backgroundColor = scheme.colorScheme.backgroundColor;
        cancelButton.applyTextTheme(withScheme: scheme);
        cancelButton.setTitleColor(scheme.colorScheme.primaryColorVariant, for: .normal)
        titleLabel.font = scheme.typographyScheme.body1
        titleLabel.backgroundColor = scheme.colorScheme.surfaceColor
        tableSectionHeaderView.backgroundColor = scheme.colorScheme.surfaceColor
        divider.backgroundColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.12);
    }
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil);
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    @objc public convenience init(delegate: FormPickedDelegate? = nil, forms: [Form]? = nil, observation: Observation? = nil, scheme: MDCContainerScheming?) {
        self.init(frame: CGRect.zero);
        self.delegate = delegate;
        self.forms = forms;
        self.observation = observation;
        self.scheme = scheme;
        applyTheme(withScheme: scheme);
        if let observation = self.observation, let properties = observation.properties {
            if (properties.keys.contains(ObservationKey.forms.key)) {
                let observationForms: [[String: Any]] = properties[ObservationKey.forms.key] as! [[String: Any]];
                let formsToBeDeleted = observation.formsToBeDeleted;
                for (index, form) in observationForms.enumerated() {
                    if (!formsToBeDeleted.contains(index)) {
                        let formId = form[EventKey.formId.key] as! Int;
                        formIdCount[formId] = (formIdCount[formId] ?? 0) + 1;
                    }
                }
            }
        }
    }
    
    override func loadView() {
        super.loadView();
        view.addSubview(tableView);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        tableView.autoPinEdgesToSuperviewEdges();
        tableView.contentInsetAdjustmentBehavior = .never;
    }
}

extension FormPickerViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.forms?.count ?? 0;
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "formCell") else {
                // Never fails:
                return UITableViewCell(style: .subtitle, reuseIdentifier: "formCell")
            }
            return cell
        }()
        cell.backgroundColor = scheme?.colorScheme.surfaceColor;

        if let form = self.forms?[indexPath.row] {
            cell.accessibilityLabel = form.name;
            cell.textLabel?.text = form.name
            cell.detailTextLabel?.text = form.formDescription;
            cell.imageView?.image = UIImage(systemName: "doc.text.fill")?.aspectResize(to: CGSize(width: 40, height: 40)).withRenderingMode(.alwaysTemplate);
            
            
            let formCount = formIdCount[form.formId?.intValue ?? Int.min] ?? 0;
            let formMin: Int = form.min ?? 0;
            let formMax: Int = form.max ?? Int.max;
            
            if (formCount < formMin) {
                cell.textLabel?.text = "\(cell.textLabel?.text ?? "")*";
            }
            
            if (formCount >= formMax) {
                cell.imageView?.tintColor = globalDisabledScheme().colorScheme.onSurfaceColor
                cell.textLabel?.textColor = globalDisabledScheme().colorScheme.onSurfaceColor
                cell.detailTextLabel?.textColor = globalDisabledScheme().colorScheme.onSurfaceColor;
                cell.backgroundColor = globalDisabledScheme().colorScheme.surfaceColor;
            } else {
                if let color = form.color {
                    cell.imageView?.tintColor = UIColor(hex: color);
                } else {
                    cell.imageView?.tintColor = scheme?.colorScheme.primaryColor
                }
                cell.textLabel?.textColor = scheme?.colorScheme.onSurfaceColor;
                cell.detailTextLabel?.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
                cell.backgroundColor = scheme?.colorScheme.surfaceColor;
                cell.textLabel?.font = scheme?.typographyScheme.subtitle1;
            }
        }

        return cell;
    }
}

extension FormPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let form = self.forms?[indexPath.row] {
            if (form.formDescription != nil) {
                return 72.0
            } else {
                return 56.0
            }
        }
        return UITableView.automaticDimension;
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let form = self.forms?[indexPath.row] {
            
            let formCount = formIdCount[form.formId?.intValue ?? Int.min] ?? 0;
            let formMax: Int = form.max ?? Int.max;
            
            if (formCount >= formMax) {
                // max amount of this form have already been added
                let message: MDCSnackbarMessage = MDCSnackbarMessage(text: "\(form.name ?? "") form cannot be included in an observation more than \(formMax) time\(formMax == 1 ? "" : "s")");
                let messageAction = MDCSnackbarMessageAction();
                messageAction.title = "OK";
                message.action = messageAction;
                MDCSnackbarManager.default.show(message);
            } else {
                delegate?.formPicked(form: form);
            }
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: .zero);
        footerView.addSubview(cancelButton);
        cancelButton.autoAlignAxis(toSuperviewAxis: .vertical);
        cancelButton.autoPinEdge(toSuperviewEdge: .top, withInset: 12);
        cancelButton.autoPinEdge(toSuperviewEdge: .bottom, withInset: 20);
        footerView.backgroundColor = scheme?.colorScheme.backgroundColor
        return footerView;
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableSectionHeaderView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
}
