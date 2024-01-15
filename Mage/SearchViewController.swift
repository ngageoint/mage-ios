//
//  SearchViewController.swift
//  MAGE
//
//  Created by William Newman on 12/5/23.
//  Copyright © 2023 National Geospatial Intelligence Agency. All rights reserved.
//

import UIKit
import MapKit

protocol SearchControllerDelegate {
    func onSearchResultSelected(type: SearchResponseType, result: GeocoderResult);
}

class SearchSheetController: UIViewController {
    var scheme: MDCContainerScheming?
    let cellReuseIdentifier = "seachCell"
    let geocoder = Geocoder()
    var searchType: SearchResponseType?
    var searchResults: [GeocoderResult] = []
    var delegate: SearchControllerDelegate?
    var mapView: MKMapView?
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    init(mapView: MKMapView?, scheme: MDCContainerScheming?) {
        super.init(nibName: nil, bundle: nil);
        self.mapView = mapView
        self.scheme = scheme
    }

    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search"
        searchBar.delegate = self
        searchBar.searchTextField.delegate = self
        searchBar.searchBarStyle = .minimal
        return searchBar
    }()
    
    lazy var progressView: UIActivityIndicatorView = {
        let progressView = UIActivityIndicatorView.newAutoLayout()
        progressView.startAnimating()
        return progressView
    }()
    
    private lazy var refreshingView: UIView = {
        let refreshingView = UIView.newAutoLayout()
        refreshingView.addSubview(progressView)
        refreshingView.addSubview(refreshingStatus)
        refreshingView.alpha = 0.0
        return refreshingView
    }()
    
    private lazy var refreshingStatus: UILabel = {
        let refreshingStatus = UILabel.newAutoLayout()
        refreshingStatus.text = "Searching..."
        refreshingStatus.textAlignment = .center
        return refreshingStatus
    }()
    
    
    private lazy var tableView : UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: .plain);
        tableView.allowsSelection = false;
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = true;
        tableView.register(FeedItemPropertyCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        return tableView;
    }()
    
    private lazy var dragIcon: UIView = {
        let dragIcon = UIView(forAutoLayout: ());
        dragIcon.autoSetDimensions(to: CGSize(width: 50, height: 7));
        dragIcon.clipsToBounds = true;
        dragIcon.layer.cornerRadius = 3.5;
        return dragIcon;
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(dragIcon)
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(refreshingView)
        
        applyTheme(withScheme: scheme);
        
        dragIcon.autoAlignAxis(toSuperviewAxis: .vertical);
    
        dragIcon.autoPinEdge(.top, to: .top, of: view, withOffset: 8)
        
        searchBar.autoPinEdge(.top, to: .bottom, of: dragIcon, withOffset: 0)
        searchBar.autoPinEdge(.right, to: .right, of: view, withOffset: -8)
        searchBar.autoPinEdge(.left, to: .left, of: view, withOffset: 8)
        searchBar.becomeFirstResponder()
        
        tableView.autoPinEdge(.top, to: .bottom, of: searchBar, withOffset: 16)
        tableView.autoPinEdge(.right, to: .right, of: view)
        tableView.autoPinEdge(.left, to: .left, of: view)
        tableView.autoPinEdge(.bottom, to: .bottom, of: view)
        tableView.allowsSelection = true
        tableView.layoutMargins = UIEdgeInsets.zero;

        refreshingView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 16, left: 0, bottom: 0, right: 0))
        
        refreshingStatus.autoCenterInSuperview()
        
        progressView.autoPinEdge(.bottom, to: .top, of: refreshingStatus, withOffset: -8)
        progressView.autoAlignAxis(toSuperviewAxis: .vertical)
    }
    
    func applyTheme(withScheme containerScheme: MDCContainerScheming?) {
        guard let containerScheme = containerScheme else {
            return
        }

        scheme = containerScheme;
        
        view.backgroundColor = UIColor.white
        
        dragIcon.backgroundColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.6)
        
        refreshingView.backgroundColor = scheme?.colorScheme.surfaceColor
        
        refreshingStatus.font = scheme?.typographyScheme.headline6
        refreshingStatus.textColor = scheme?.colorScheme.onBackgroundColor.withAlphaComponent(0.6)

        progressView.tintColor = scheme?.colorScheme.onBackgroundColor
    }
}

extension SearchSheetController : UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.searchTextField.text else {
            return
        }
        
        UIView.animate(withDuration: 0.3) {
            self.refreshingView.alpha = 1.0
        }
                
        geocoder.search(text: text, region: mapView?.region) { searchResponse in
            switch searchResponse {
                case let .success(type, results):
                    self.searchType = type
                    self.searchResults = results
                case let .error(message):
                    print("search error \(message)")
            }
            
            self.tableView.reloadData()
            UIView.animate(withDuration: 0.3) {
                self.refreshingView.alpha = 0.0
            }
        }
    }
}

extension SearchSheetController : UITextFieldDelegate {
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.searchType = nil
        self.searchResults = []
        self.tableView.reloadData()
        
        return true
    }
}

extension SearchSheetController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView();
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = searchResults[indexPath.row]
        self.delegate?.onSearchResultSelected(type: self.searchType ?? SearchResponseType.geocoder, result: result)
    }
}

extension SearchSheetController : UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count;
    }

    func numberOfSections(in: UITableView) -> Int {
        return 1;
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = searchResults[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) else {
            return UITableViewCell(style: .default, reuseIdentifier: cellReuseIdentifier)
        }
                    
        let configuration = SearchResultConfiguration(name: result.name, address: result.address, location: result.location, scheme: self.scheme)
        cell.contentConfiguration = configuration
        return cell
    }
}

struct SearchResultConfiguration : UIContentConfiguration {
    let name: String
    let address: String?
    let location: CLLocationCoordinate2D?
    let scheme: MDCContainerScheming?
    
    func makeContentView() -> UIView & UIContentView {
        let view = SearchResultContentView(configuration: self, scheme: scheme)
        return view
    }
    
    func updated(for state: UIConfigurationState) -> SearchResultConfiguration {
        return self
    }
}

class SearchResultContentView: UIView, UIContentView {
    
    var configuration: UIContentConfiguration {
        didSet {
            self.configure()
        }
    }
    
    private let stackView = UIStackView(forAutoLayout: ())
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()
    
    lazy var locationButton: LatitudeLongitudeButton = LatitudeLongitudeButton()
    
    init(configuration: UIContentConfiguration, scheme: MDCContainerScheming?) {
        self.configuration = configuration
        
        super.init(frame: .zero)
        addSubview(stackView)
        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(addressLabel)
        stackView.addArrangedSubview(locationButton)

        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 0
        stackView.distribution = .fill;
        stackView.isLayoutMarginsRelativeArrangement = false;
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        stackView.clipsToBounds = true;
        stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0))
        
        stackView.setCustomSpacing(4, after: nameLabel)
        nameLabel.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.87);
        nameLabel.autoPinEdge(.left, to: .left, of: stackView, withOffset: 16)
        nameLabel.autoPinEdge(.right, to: .right, of: stackView, withOffset: 16)

        stackView.setCustomSpacing(0, after: addressLabel)
        addressLabel.autoPinEdge(.top, to: .bottom, of: nameLabel, withOffset: 16)
        addressLabel.autoPinEdge(.left, to: .left, of: stackView, withOffset: 16)
        addressLabel.autoPinEdge(.right, to: .right, of: stackView, withOffset: 16)
        addressLabel.textColor = scheme?.colorScheme.onSurfaceColor.withAlphaComponent(0.60);
        addressLabel.numberOfLines = 0;
        addressLabel.lineBreakMode = .byWordWrapping;
        
        locationButton.applyTheme(withScheme: scheme);
        locationButton.autoPinEdge(toSuperviewEdge: .left, withInset: 0);
        
        self.configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        guard let configuration = self.configuration as? SearchResultConfiguration else { return }
        
        nameLabel.text = configuration.name
        addressLabel.text = configuration.address
        locationButton.coordinate = configuration.location
    }
}
