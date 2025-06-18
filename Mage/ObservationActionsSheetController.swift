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
    static let DELETE_CELL_TAG: Int = 1
    static let EDIT_CELL_TAG: Int = 2
    static let REORDER_CELL_TAG: Int = 3
    static let USER_CELL_TAG: Int = 4
    
    var observation: Observation!;
    weak var delegate: ObservationActionsDelegate?;
    var scheme: AppContainerScheming?;
    var userHasEditPermissions: Bool = false;
    var router: MageRouter
    
    @objc func cancelButtonTapped(_ sender: UIButton) {
        router.bottomSheetRoute = nil
    }
    
    private lazy var cancelButton: MDCButton = {
        let cancelButton = MDCButton(forAutoLayout: ());
        cancelButton.accessibilityLabel = "Cancel";
        cancelButton.setTitle("Cancel", for: .normal);
        cancelButton.clipsToBounds = true;
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped(_:)), for: .touchUpInside);
        return cancelButton;
    }()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    public init(observation: Observation, delegate: ObservationActionsDelegate, router: MageRouter) {
        self.router = router
        super.init(style: .plain);
        self.observation = observation;
        self.delegate = delegate;
        self.router = router
        @Injected(\.nsManagedObjectContext)
        var context: NSManagedObjectContext?
        
        guard let context = context else { return }
        let user = User.fetchCurrentUser(context: context);
        self.userHasEditPermissions = user?.hasEditPermission ?? false;
    }
    
    func applyTheme(withContainerScheme containerScheme: AppContainerScheming?) {
        guard let containerScheme = containerScheme else {
            return
        }

        self.scheme = containerScheme;
        self.tableView.backgroundColor = containerScheme.colorScheme.backgroundColor;
        
        // TODO: BRENT - MDC
//        cancelButton.applyTextTheme(withScheme: containerScheme);
        cancelButton.setTitleColor(containerScheme.colorScheme.primaryColorVariant, for: .normal)
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
        if (userHasEditPermissions) {
            // not enough forms to reorder
            if((((observation.properties?["forms"] as? [[AnyHashable : Any]])?.count ?? 0) <= 1)) {
                return 3;
            } else {
                return 4;
            }
        }
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "ActionCell") else {
                // Never fails:
                return UITableViewCell(style: .default, reuseIdentifier: "ActionCell")
            }
            return cell
        }()
        cell.imageView?.tintColor = scheme?.colorScheme.onSurfaceColor?.withAlphaComponent(0.87);
        cell.textLabel?.textColor = scheme?.colorScheme.onSurfaceColor;
        cell.backgroundColor = scheme?.colorScheme.surfaceColor;
        cell.accessoryType = .none;
        
        var correctedRow = indexPath.row + (userHasEditPermissions ? 0 : 3);
        if (correctedRow == 0) {
            cell.textLabel?.text = "Delete Observation";
            cell.accessibilityLabel = "Delete Observation";
            cell.imageView?.image = UIImage(systemName: "trash.fill")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate);
            cell.tag = ObservationActionsSheetController.DELETE_CELL_TAG
            cell.textLabel?.textColor = scheme?.colorScheme.errorColor;
            cell.imageView?.tintColor = scheme?.colorScheme.errorColor;
            return cell;
        }
        
        if (correctedRow == 1) {
            cell.textLabel?.text = "Edit Observation";
            cell.accessibilityLabel = "Edit Observation";
            cell.tag = ObservationActionsSheetController.EDIT_CELL_TAG
            cell.imageView?.image = UIImage(systemName: "pencil", withConfiguration: UIImage.SymbolConfiguration(weight: .black))?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate);
            return cell;
        }
        
        if (userHasEditPermissions && ((observation.properties?["forms"] as? [[AnyHashable : Any]])?.count ?? 0) <= 1) {
            // if there is 1 form or less, don't show reorder
            correctedRow = correctedRow + 1;
        }
        
        if (correctedRow == 2) {
            cell.textLabel?.text = "Reorder Forms";
            cell.accessibilityLabel = "Reorder Forms";
            cell.tag = ObservationActionsSheetController.REORDER_CELL_TAG
            cell.imageView?.image = UIImage(systemName: "arrow.up.arrow.down")?.aspectResize(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate);
            cell.accessoryType = .disclosureIndicator;
            return cell;
        }
        
        if (correctedRow == 3) {
            cell.textLabel?.text = "View \(observation.user?.name ?? "")'s Observations";
            cell.accessibilityLabel = "View Other Observations";
            cell.tag = ObservationActionsSheetController.USER_CELL_TAG
            cell.imageView?.image = UIImage(named: "observations")?.resized(to: CGSize(width: 24, height: 24)).withRenderingMode(.alwaysTemplate);
            cell.accessoryType = .disclosureIndicator;
            return cell;
        }
        
        return cell;
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true);
        let tag = tableView.cellForRow(at: indexPath)?.tag
        
        if (tag == ObservationActionsSheetController.DELETE_CELL_TAG) {
            delegate?.deleteObservation?(observation);
        }
        if (tag == ObservationActionsSheetController.EDIT_CELL_TAG) {
            router.appendRoute(ObservationRoute.edit(uri: observation.objectID.uriRepresentation()))
        }
        
        if (tag == ObservationActionsSheetController.REORDER_CELL_TAG) {
            delegate?.reorderForms?(observation);
        }
        
        if (tag == ObservationActionsSheetController.USER_CELL_TAG) {
            // show the user page
            if let user = observation.user {
                router.appendRoute(UserRoute.detail(uri: user.objectID.uriRepresentation()))
            }
        }
        
    }
    
}
