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
    @objc func formPicked (form: [String: Any]);
    @objc func cancelSelection();
}

@objc class FormPickerViewController: UIViewController {

    var delegate: FormPickedDelegate?;
    var forms: [[String: Any]]?;
    var scheme: MDCContainerScheming = globalContainerScheme();
    
    var tableView: UITableView = {
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
        if let safeScheme = scheme {
            self.scheme = safeScheme;
        }
        self.tableView.backgroundColor = self.scheme.colorScheme.backgroundColor;
        cancelButton.applyTextTheme(withScheme: self.scheme);
    }
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil);
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    @objc public convenience init(delegate: FormPickedDelegate? = nil, forms: [[String: Any]]? = nil) {
        self.init(frame: CGRect.zero);
        self.delegate = delegate;
        self.forms = forms;
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
        cell.backgroundColor = scheme.colorScheme.surfaceColor;

        if let safeForm = self.forms?[indexPath.row] {
            cell.accessibilityLabel = safeForm["name"] as? String;
            cell.textLabel?.text = safeForm["name"] as? String;
            cell.detailTextLabel?.text = safeForm["description"] as? String;
            cell.imageView?.image = UIImage(named: "form");
            if let safeColor = safeForm["color"] as? String {
                cell.imageView?.tintColor = UIColor(hex: safeColor);
            } else {
                cell.imageView?.tintColor = scheme.colorScheme.primaryColor
            }
            cell.textLabel?.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
            cell.detailTextLabel?.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
            cell.backgroundColor = scheme.colorScheme.surfaceColor;
        }

        return cell;
    }
}

extension FormPickerViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let safeForm = self.forms?[indexPath.row] {
            delegate?.formPicked(form: safeForm);
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: .zero);
        footerView.addSubview(cancelButton);
        cancelButton.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 12, left: 32, bottom: 20, right: 32));
        return footerView;
    }
}
