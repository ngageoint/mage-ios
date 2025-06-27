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
    @objc func formPicked (form: Form);
    @objc func cancelSelection();
}

class ButtonFooterView: UICollectionReusableView {
    var buttonDidTappedCallback: (() -> Void)?
    var title: String? {
        get {
            return button.title(for: .normal)
        }
        set {
            button.setTitle(newValue, for: .normal)
            button.accessibilityLabel = newValue
        }
    }
    
    var _scheme: AppContainerScheming?
    var scheme: AppContainerScheming? {
        get {
            return _scheme
        }
        set {
            _scheme = newValue
            if let scheme = newValue {
                button.setTitleColor(scheme.colorScheme.primaryColorVariant, for: .normal)
            }
        }
    }
    
    lazy var button: UIButton = {
        let button = UIButton(forAutoLayout: ());
        button.clipsToBounds = true;
        button.addAction(UIAction(handler: { [unowned self] _ in
            self.buttonDidTappedCallback?()
        }), for: .touchUpInside)
        return button;
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
    
    func configure() {
        addSubview(button);
        button.autoAlignAxis(toSuperviewAxis: .vertical);
        button.autoPinEdge(toSuperviewEdge: .top, withInset: 12);
        button.autoPinEdge(toSuperviewEdge: .bottom, withInset: 40);
    }
}

@objc class FormPickerViewController: UIViewController {
    
    enum Section {
        case main
    }

    weak var delegate: FormPickedDelegate?;
    var forms: [Form] = []
    var scheme: AppContainerScheming?;
    weak var observation: Observation?;
    var formIdCount: [Int : Int] = [ : ];
    var didSetupConstraints = false
    
    var dataSource: UICollectionViewDiffableDataSource<Section, Form>?
    var snapshot: NSDiffableDataSourceSnapshot<Section, Form>!
    var cellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, Form>?
    var footerRegistration: UICollectionView.SupplementaryRegistration<ButtonFooterView>?
    var headerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewListCell>?
    
    lazy var collectionView: UICollectionView = {
        var configuration = UICollectionLayoutListConfiguration(appearance: .grouped)
        configuration.headerMode = .supplementary
        configuration.footerMode = .supplementary
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout:  UICollectionViewCompositionalLayout.list(using: configuration))
        collectionView.isAccessibilityElement = true
        collectionView.accessibilityIdentifier = "Add A Form Table"
        collectionView.accessibilityLabel = "Add A Form Table"
        return collectionView
    }()
    
    @objc func cancelButtonTapped(_ sender: UIButton) {
        delegate?.cancelSelection()
    }
    
    func applyTheme(withScheme scheme: AppContainerScheming? = nil) {
        guard let scheme = scheme else {
            return
        }

        self.scheme = scheme
        self.view.backgroundColor = scheme.colorScheme.backgroundColor
        self.collectionView.backgroundColor = scheme.colorScheme.backgroundColor
    }
    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    @objc public convenience init(delegate: FormPickedDelegate? = nil, forms: [Form]? = nil, observation: Observation? = nil, scheme: AppContainerScheming?) {
        self.init(frame: CGRect.zero)
        self.delegate = delegate
        if let forms = forms {
            self.forms = forms
        }
        self.observation = observation
        self.scheme = scheme
        applyTheme(withScheme: scheme)
        if let observation = self.observation, let properties = observation.properties {
            if (properties.keys.contains(ObservationKey.forms.key)) {
                let observationForms: [[String: Any]] = properties[ObservationKey.forms.key] as! [[String: Any]]
                let formsToBeDeleted = observation.formsToBeDeleted
                for (index, form) in observationForms.enumerated() {
                    if (!formsToBeDeleted.contains(index)) {
                        let formId = form[EventKey.formId.key] as! Int
                        formIdCount[formId] = (formIdCount[formId] ?? 0) + 1
                    }
                }
            }
        }
    }
    
    func footerRegistrationHandler(footerView: ButtonFooterView, elementKind: String, indexPath: IndexPath) {
        footerView.title = "Cancel"
        footerView.buttonDidTappedCallback = { [weak self] in
            self?.delegate?.cancelSelection()
        }
        if let scheme = self.scheme {
            footerView.scheme = scheme
        }
    }
    
    func headerRegistrationHandler(headerView: UICollectionViewListCell, elementKind: String, indexPath: IndexPath) {
        var configuration = headerView.defaultContentConfiguration()
        var backgroundConfiguration = UIBackgroundConfiguration.listGroupedHeaderFooter()
        
        configuration.text = "Add A Form To Your Observation"
        
        if let scheme = self.scheme {
            configuration.textProperties.font = scheme.typographyScheme.bodyFont
            backgroundConfiguration.backgroundColor = scheme.colorScheme.surfaceColor
        }
        
        headerView.contentConfiguration = configuration
        headerView.backgroundConfiguration = backgroundConfiguration
    }
    
    func cellRegistrationHandler(cell: UICollectionViewListCell, indexPath: IndexPath, item: Form) {
        var configuration = cell.defaultContentConfiguration()
        configuration.text = item.name
        configuration.secondaryText = item.formDescription
        
        configuration.image = UIImage(systemName: "doc.text.fill")?.aspectResize(to: CGSize(width: 40, height: 40)).withRenderingMode(.alwaysTemplate)
        configuration.imageProperties.maximumSize = CGSize(width: 40, height: 40)
        configuration.imageProperties.reservedLayoutSize = CGSize(width: 40, height: 40)
        
        let formCount = self.formIdCount[item.formId?.intValue ?? Int.min] ?? 0
        let formMin: Int = item.min ?? 0
        let formMax: Int = item.max ?? Int.max
        
        if (formCount < formMin) {
            configuration.text = "\(configuration.text ?? "")*"
        }
        
        var backgroundColor: UIColor = .clear
        if (formCount >= formMax) {
            configuration.imageProperties.tintColor = globalDisabledScheme().colorScheme.onSurfaceColor
            configuration.textProperties.color = globalDisabledScheme().colorScheme.onSurfaceColor ?? UIColor.magenta
            configuration.secondaryTextProperties.color = globalDisabledScheme().colorScheme.onSurfaceColor  ?? UIColor.magenta
            backgroundColor = globalDisabledScheme().colorScheme.surfaceColor  ?? UIColor.magenta
            
        } else {
            if let color = item.color {
                configuration.imageProperties.tintColor = UIColor(hex: color);
            } else {
                configuration.imageProperties.tintColor = self.scheme?.colorScheme.primaryColor
            }
            if let scheme = self.scheme {
                configuration.textProperties.color = scheme.colorScheme.onSurfaceColor ?? UIColor.magenta
                configuration.textProperties.font = scheme.typographyScheme.subtitle1Font
                configuration.secondaryTextProperties.color = scheme.colorScheme.onSurfaceColor?.withAlphaComponent(0.6) ?? UIColor.magenta
                backgroundColor = scheme.colorScheme.surfaceColor ?? UIColor.magenta
            }
        }
        
        
        // TODO: BRENT - FIX COLORS
        
        var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
        backgroundConfiguration.backgroundColor = backgroundColor
        cell.contentConfiguration = configuration
        cell.backgroundConfiguration = backgroundConfiguration
    }
    
    override func loadView() {
        super.loadView()
        view.addSubview(collectionView)
        collectionView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        collectionView.autoPinEdge(toSuperviewMargin: .top)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        footerRegistration = UICollectionView.SupplementaryRegistration
        <ButtonFooterView>(elementKind: UICollectionView.elementKindSectionFooter, handler: footerRegistrationHandler)
        
        headerRegistration = UICollectionView.SupplementaryRegistration
        <UICollectionViewListCell>(elementKind: UICollectionView.elementKindSectionHeader, handler: headerRegistrationHandler)
        
        cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Form>(handler: cellRegistrationHandler)
        
        dataSource = UICollectionViewDiffableDataSource<Section, Form>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: Form) -> UICollectionViewCell? in
            
            let cell = collectionView.dequeueConfiguredReusableCell(
                using: self.cellRegistration!, for: indexPath, item: identifier)
            
            return cell
        }
        
        dataSource?.supplementaryViewProvider = { [unowned self]
            (collectionView, elementKind, indexPath) -> UICollectionReusableView? in
            
            if elementKind == UICollectionView.elementKindSectionHeader {
                return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration!, for: indexPath)
            }
            return collectionView.dequeueConfiguredReusableSupplementary(using: footerRegistration!, for: indexPath)
        }
        
        snapshot = NSDiffableDataSourceSnapshot<Section, Form>()
        snapshot.appendSections([.main])
        snapshot.appendItems(forms, toSection: .main)
        
        dataSource?.apply(snapshot, animatingDifferences: false)
        
        self.collectionView.delegate = self
    }
}

extension FormPickerViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let form = dataSource?.itemIdentifier(for: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        
        let formCount = formIdCount[form.formId?.intValue ?? Int.min] ?? 0
        let formMax: Int = form.max ?? Int.max
        
        if (formCount >= formMax) {
            // max amount of this form have already been added
            AlertManager.shared.showAlertWithTitle(
                form.name ?? "",
                message: "Form cannot be included in an observation more than \(formMax) time\(formMax == 1 ? "" : "s")",
                okTitle: "OK"
            )
        } else {
            delegate?.formPicked(form: form)
        }
    }
}
