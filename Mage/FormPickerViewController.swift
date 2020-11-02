//
//  FormPickerViewController.m
//  MAGE
//
//  Created by Dan Barela on 8/10/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//
import Foundation
import UIKit

@objc protocol FormPickedDelegate {
    @objc func formPicked (form: [String: Any]);
    @objc func cancelSelection();
}

@objc class FormPickerViewController: UIViewController {
    
    var delegate: FormPickedDelegate?;
    var forms: [[String: Any]]?;
    
    var tableView: UITableView = {
        let tableView = UITableView(forAutoLayout: ());
        tableView.accessibilityLabel = "Add A Form Table";
        tableView.estimatedRowHeight = 100;
        tableView.rowHeight = UITableView.automaticDimension;
        return tableView;
    }()
    
    var navBar: UINavigationBar = {
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: #selector(closeButtonTapped(_:)))
        cancelItem.accessibilityLabel = "Cancel"
        
        let navItem = UINavigationItem(title: "Add A Form")
        
        navItem.rightBarButtonItem = cancelItem;
        
        let navBar = UINavigationBar(forAutoLayout: ());
        navBar.titleTextAttributes = [.foregroundColor: globalContainerScheme().colorScheme.onPrimaryColor];
        navBar.isTranslucent = false;
        navBar.barTintColor = globalContainerScheme().colorScheme.primaryColor;
        navBar.tintColor = globalContainerScheme().colorScheme.onPrimaryColor;
        navBar.setItems([navItem], animated: false);
        
        return navBar;
    }()
    
    override func themeDidChange(_ theme: MageTheme) {
        self.tableView.backgroundColor = .tableBackground();
        self.tableView.reloadData();
    }
    
    @objc func closeButtonTapped(_ sender: UIButton) {
        delegate?.cancelSelection();
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        self.registerForThemeChanges();
    }
    
    override func loadView() {
        super.loadView();
        view.addSubview(tableView);
        tableView.autoPinEdgesToSuperviewEdges();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        
        self.title = "Add A Form";
        self.navigationItem.largeTitleDisplayMode = .never;
        self.view.addSubview(navBar);
        navBar.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets.zero, excludingEdge: .bottom);
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
        
        if let safeForm = self.forms?[indexPath.row] {
            cell.accessibilityLabel = safeForm["name"] as? String;
            cell.textLabel?.text = safeForm["name"] as? String;
            cell.detailTextLabel?.text = safeForm["description"] as? String;
            cell.imageView?.image = UIImage(named: "form");
            if let safeColor = safeForm["color"] as? String {
                cell.imageView?.tintColor = UIColor(hex: safeColor);
            } else {
                cell.imageView?.tintColor = globalContainerScheme().colorScheme.primaryColor
            }
            cell.textLabel?.textColor = .label;
            cell.detailTextLabel?.textColor = .secondaryLabel;
            cell.backgroundColor = .systemBackground;
        }
        
        return cell;
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView();
    }
}

extension FormPickerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let safeForm = self.forms?[indexPath.row] {
            delegate?.formPicked(form: safeForm);
        }
    }
}
