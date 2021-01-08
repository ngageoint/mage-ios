//
//  ObservationActionsSheetController.swift
//  MAGE
//
//  Created by Daniel Barela on 1/5/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCAppBar;

class ObservationActionsSheetController: UITableViewController {
    var observation: Observation!;
    var delegate: ObservationActionsDelegate!;
    var scheme: MDCContainerScheming = globalContainerScheme();
    
    @objc func cancelButtonTapped(_ sender: UIButton) {
        delegate?.cancelAction?();
    }
    
    private lazy var cancelButton: MDCButton = {
        let cancelButton = MDCButton(forAutoLayout: ());
        cancelButton.accessibilityLabel = "Cancel";
        cancelButton.setTitle("Cancel", for: .normal);
        cancelButton.clipsToBounds = true;
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped(_:)), for: .touchUpInside);
        return cancelButton;
    }()
    
    init(frame: CGRect) {
        super.init(style: .plain);
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    @objc public convenience init(observation: Observation, delegate: ObservationActionsDelegate) {
        self.init(frame: CGRect.zero);
        self.observation = observation;
        self.delegate = delegate;
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming? = nil) {
        if (scheme != nil) {
            self.scheme = scheme!;
        }
        self.tableView.backgroundColor = self.scheme.colorScheme.backgroundColor;
        cancelButton.applyTextTheme(withScheme: self.scheme);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        self.navigationItem.largeTitleDisplayMode = .never;
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = UIView(frame: .zero);
        footerView.addSubview(cancelButton);
        cancelButton.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 12, left: 32, bottom: -8, right: 32));
        return footerView;
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell") else {
                // Never fails:
                return UITableViewCell(style: .default, reuseIdentifier: "ActionCell")
            }
            return cell
        }()
        
        cell.imageView?.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        cell.textLabel?.textColor = scheme.colorScheme.onSurfaceColor;
        cell.backgroundColor = scheme.colorScheme.surfaceColor;
        cell.textLabel?.font = scheme.typographyScheme.subtitle1;
        cell.accessoryType = .none;
        
        if (indexPath.row == 0) {
            cell.textLabel?.text = "Delete Observation";
            cell.accessibilityLabel = "Delete Observation";
            cell.imageView?.image = UIImage(named: "trash")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate);
            cell.textLabel?.textColor = scheme.colorScheme.errorColor;
            cell.imageView?.tintColor = scheme.colorScheme.errorColor;
        }
        
        if (indexPath.row == 1) {
            cell.textLabel?.text = "Edit Observation";
            cell.accessibilityLabel = "Edit Observation";
            cell.imageView?.image = UIImage(named: "edit")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate);
        }
        
        if (indexPath.row == 2) {
            cell.textLabel?.text = "View \(observation.user?.name ?? "")'s Observations";
            cell.accessibilityLabel = "Edit Observation";
            cell.imageView?.image = UIImage(named: "observations")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate);
            cell.accessoryType = .disclosureIndicator;
        }
        
        return cell;
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("row selected \(indexPath)")
        tableView.deselectRow(at: indexPath, animated: true);
        if (indexPath.row == 0) {
            delegate.deleteObservation?(observation);
        }
        if (indexPath.row == 1) {
            delegate.editObservation?(observation);
        }
    }
    
}
