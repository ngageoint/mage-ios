//
//  EventChooserController.m
//  MAGE
//
//

import UIKit
import CoreData

@objc protocol EventSelectionDelegate {

func didSelectEvent(event: Event)
func actionButtonTapped()

}

@objc class EventChooserController: UIViewController {
    var scheme: MDCContainerScheming?
    var didSetupConstraints = false
    var delegate: EventSelectionDelegate?
    var eventDataSource: EventTableDataSource?
    var checkForms = false
    var eventsFetched = false
    var eventsInitialized = false
    var eventsChanged = false
    var registeredForSearchFrameUpdates = false
    var searchBar: UISearchBar?
    var searchContainerHeightConstraint: NSLayoutConstraint?
    var emptyState: EmptyState?

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(forAutoLayout: ());
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 0
        stackView.distribution = .fill
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = .clear
        return stackView
    }()
    
    private lazy var searchContainer: UIView = {
        let searchContainer = UIView.newAutoLayout()
        searchContainer.clipsToBounds = true
        return searchContainer
    }()
        
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.autocapitalizationType = .none
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.isTranslucent = true
        return searchController
    }()
    
    private lazy var eventInstructions: UILabel = {
        let eventInstructions = UILabel.newAutoLayout()
        eventInstructions.numberOfLines = 0
        eventInstructions.text = "Please choose an event.  The observations you create and your reported location will be part of the selected event."
        eventInstructions.lineBreakMode = .byWordWrapping
        eventInstructions.textAlignment = .center
        eventInstructions.isHidden = true
        return eventInstructions
    }()
    
    private lazy var refreshingButton: MDCFloatingButton = {
        let refreshingButton = MDCFloatingButton(shape: .default)
        refreshingButton.mode = MDCFloatingButtonMode.expanded
        refreshingButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        refreshingButton.addTarget(self, action: #selector(refreshingButtonTapped), for: .touchUpInside)
        refreshingButton.accessibilityLabel = "Refresh Events"
        refreshingButton.setTitle("Refresh Events", for: .normal)
        refreshingButton.isHidden = true
        return refreshingButton
    }()
    
    lazy var progressView: MDCProgressView = {
        let progressView = MDCProgressView(forAutoLayout: ())
        progressView.mode = MDCProgressViewMode.indeterminate
        progressView.isHidden = false
        progressView.startAnimating()
        return progressView
    }()
    
    private lazy var refreshingView: UIView = {
        let refreshingView = UIView.newAutoLayout()
        refreshingView.addSubview(progressView)
        refreshingView.addSubview(refreshingStatus)
        return refreshingView
    }()
    
    private lazy var refreshingStatus: UILabel = {
        let refreshingStatus = UILabel.newAutoLayout()
        refreshingStatus.text = "Refreshing Events"
        refreshingStatus.textAlignment = .center
        return refreshingStatus
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.estimatedRowHeight = 52
        tableView.rowHeight = UITableView.automaticDimension
        return tableView
    }()
    
    let allEventsController = Event.caseInsensitiveSortFetchAll(sortTerm: "name", ascending: true, predicate: NSPredicate(format: "TRUEPREDICATE"), groupBy: nil, context: NSManagedObjectContext.mr_default())

    
    init(frame: CGRect) {
        super.init(nibName: nil, bundle: nil);
    }
    
    @objc convenience public init(delegate: EventSelectionDelegate, scheme: MDCContainerScheming? = nil) {
        self.init(frame: CGRect.zero);
        self.modalPresentationStyle = .fullScreen
        self.scheme = scheme
        self.delegate = delegate
        self.eventDataSource = EventTableDataSource(scheme: scheme)
        self.eventDataSource?.tableView = self.tableView
        self.eventDataSource?.eventSelectionDelegate = self
        self.allEventsController?.delegate = self
        
        do {
            try self.allEventsController?.performFetch()
        } catch {
            NSLog("Error fetching events \(error) \(error.localizedDescription)")
        }
        
        eventDataSource?.startFetchController()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        title = "Welcome To MAGE"
        navigationItem.hidesBackButton = true
        
        tableView.dataSource = eventDataSource
        tableView.delegate = eventDataSource
        tableView.register(UINib(nibName: "EventCell", bundle: nil), forCellReuseIdentifier: "eventCell")
        tableView.isAccessibilityElement = true
        tableView.accessibilityLabel = "Event Table"
        tableView.accessibilityIdentifier = "Event Table"
        
        searchController.searchResultsUpdater = self
        applyTheme(withContainerScheme: scheme)
        
        emptyState = EmptyState(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: self.tableView.bounds.size.height))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !eventsFetched && !eventsInitialized && eventDataSource?.otherFetchedResultsController?.fetchedObjects?.count == 0 && eventDataSource?.recentFetchedResultsController?.fetchedObjects?.count == 0 {
            emptyState?.configure(image: UIImage(systemName: "calendar"), title: "Loading Events", showActivityIndicator: true, scheme: self.scheme)
            emptyState?.toggleVisible(true)
            tableView.backgroundView = emptyState
        }
    }
    
    func applyTheme(withContainerScheme containerScheme: MDCContainerScheming?) {
        guard let containerScheme = containerScheme else {
            return
        }
        
        self.scheme = containerScheme
        view.backgroundColor = scheme?.colorScheme.primaryColor
        eventInstructions.textColor = scheme?.colorScheme.onPrimaryColor
        eventInstructions.font = scheme?.typographyScheme.caption
        // actionbutton
        tableView.backgroundColor = scheme?.colorScheme.surfaceColor
        refreshingButton.applySecondaryTheme(withScheme: containerScheme)
        searchController.searchBar.barTintColor = scheme?.colorScheme.onPrimaryColor;
        searchController.searchBar.tintColor = scheme?.colorScheme.onPrimaryColor;
        searchController.searchBar.backgroundColor = scheme?.colorScheme.primaryColor;
        searchContainer.backgroundColor = scheme?.colorScheme.primaryColor
        searchController.searchBar.searchTextField.backgroundColor = scheme?.colorScheme.surfaceColor;
        refreshingView.backgroundColor = scheme?.colorScheme.primaryColor
        refreshingStatus.textColor = scheme?.colorScheme.onPrimaryColor
        refreshingStatus.font = scheme?.typographyScheme.caption
        progressView.progressTintColor = scheme?.colorScheme.primaryColor
        var red: CGFloat = 1.0
        var blue: CGFloat = 1.0
        var green: CGFloat = 1.0
        var alpha: CGFloat = 1.0
        scheme?.colorScheme.primaryColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        progressView.trackTintColor = UIColor(red: CGFloat.minimum(red + 0.2, 1.0), green: CGFloat.minimum(green + 0.2, 1.0), blue: CGFloat.minimum(blue + 0.2, 1.0), alpha: 1.0)
    }
    
    override func loadView() {
        super.loadView()
        
        stackView.addArrangedSubview(eventInstructions)
        
        view.addSubview(stackView)
        searchBar = searchController.searchBar
        if let searchBar = searchBar {
            searchContainer.addSubview(searchBar)
        }
        view.addSubview(searchContainer)
        view.addSubview(tableView)
        view.addSubview(refreshingButton)
        view.addSubview(refreshingView)
        searchContainerHeightConstraint = searchContainer.autoSetDimension(.height, toSize: 56)
        initializeView()
    }
    
    override func updateViewConstraints() {
        if (!didSetupConstraints) {
            stackView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
            searchContainer.autoPinEdge(toSuperviewEdge: .left)
            searchContainer.autoPinEdge(toSuperviewEdge: .right)
            searchContainer.autoPinEdge(.top, to: .bottom, of: stackView)

            NSLayoutConstraint.autoSetPriority(.defaultHigh) {
                tableView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
                tableView.autoPinEdge(.top, to: .bottom, of: searchContainer)
            }

            NSLayoutConstraint.autoSetPriority(.defaultLow) {
                tableView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
                tableView.autoPinEdge(.top, to: .bottom, of: stackView)
            }

            eventInstructions.autoSetDimension(.height, toSize: 32)

            refreshingButton.autoAlignAxis(toSuperviewAxis: .vertical)
            refreshingButton.autoPinEdge(.top, to: .top, of: tableView, withOffset: 8)
            
            refreshingStatus.autoPinEdgesToSuperviewSafeArea(with: UIEdgeInsets(top: 16, left: 8, bottom: 0, right: 8))
            refreshingView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
            
            progressView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
            progressView.autoSetDimension(.height, toSize: 5)
            
            didSetupConstraints = true;
        }
        
        super.updateViewConstraints();
    }
    
    private func initializeView() {
        if eventDataSource?.otherFetchedResultsController?.fetchedObjects?.count == 0 && eventDataSource?.recentFetchedResultsController?.fetchedObjects?.count == 0 {
            //no events have been fetched at this point
            refreshingView.isHidden = true
            eventInstructions.isHidden = true
            searchContainerHeightConstraint?.constant = 0.0
        } else {
            eventsInitialized = true
            if eventDataSource?.otherFetchedResultsController?.fetchedObjects?.count == 1 && eventDataSource?.recentFetchedResultsController?.fetchedObjects?.count == 0 {
                if let e = eventDataSource?.otherFetchedResultsController.fetchedObjects?[0] as? Event, let remoteId = e.remoteId {
                    Server.setCurrentEventId(remoteId)
                }
            }
            eventInstructions.isHidden = false
            searchContainerHeightConstraint?.constant = 56.0
        }
        
        if eventDataSource?.otherFetchedResultsController?.fetchedObjects?.count ?? 0 > 1 {
            eventInstructions.text = "Please choose an event.  The observations you create and your reported location will be part of the selected event."
        } else if (eventDataSource?.otherFetchedResultsController?.fetchedObjects?.count == 1 && eventDataSource?.recentFetchedResultsController?.fetchedObjects?.count == 0) || (eventDataSource?.otherFetchedResultsController?.fetchedObjects?.count == 0 && eventDataSource?.recentFetchedResultsController?.fetchedObjects?.count == 1) {
            eventInstructions.text = "You are a part of one event.  The observations you create and your reported location will be part of this event."
            if !UserDefaults.standard.showEventChooserOnce {
                if eventDataSource?.recentFetchedResultsController?.fetchedObjects?.count == 1 {
                    if let e = eventDataSource?.recentFetchedResultsController?.fetchedObjects?[0] as? Event {
                        didSelectEvent(event: e)
                    }
                } else if eventDataSource?.otherFetchedResultsController?.fetchedObjects?.count == 1 {
                    if let e = eventDataSource?.otherFetchedResultsController?.fetchedObjects?[0] as? Event {
                        didSelectEvent(event: e)
                    }
                }
            } else {
                UserDefaults.standard.showEventChooserOnce = false
            }
            tableView.reloadData()
        }
        
        let timer = Timer(timeInterval: 10, repeats: true) { [weak self] timer in
            if let eventsFetched = self?.eventsFetched, eventsFetched {
                timer.invalidate()
            } else {
                self?.refreshingStatus.text = "Refreshing events seems to be taking a while..."
            }
        }
        
        RunLoop.main.add(timer, forMode: .common)
    }
    
    @objc public func eventsFetchedFromServer() {
        eventsFetched = true
        refreshingView.isHidden = true
        emptyState?.toggleVisible(false)

        if !eventsInitialized {
            eventsInitialized = true
            refreshingButtonTapped()
        } else if eventsChanged {
            self.refreshingButton.isHidden = false
            UIView.animate(withDuration: 0.45, delay: 0, options: [], animations: { [weak self] in
                self?.refreshingButton.alpha = 1
            }, completion: nil)
        }
        
        progressView.stopAnimating()
    }
    
    @objc func refreshingButtonTapped() {
        eventDataSource?.refreshEventData()
        tableView.reloadData()
        refreshingButton.isHidden = true
        
        if eventDataSource?.otherFetchedResultsController?.fetchedObjects?.count == 0 && eventDataSource?.recentFetchedResultsController?.fetchedObjects?.count == 0 {
            let error = "You must be a member of at least one event to use MAGE.  Ask your administrator to add you to an event."
            let info = ContactInfo(title: nil, andMessage: error)
            if let currentUser = User.fetchCurrentUser(context: NSManagedObjectContext.mr_default()), let username = currentUser.username {
                info.username = username
            }
            
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            let attributedString = NSMutableAttributedString(attributedString: info.messageWithContactInfo())
            attributedString.addAttribute(.paragraphStyle, value: paragraph, range: NSRange(location: 0, length: attributedString.length))
            
            emptyState?.configure(image: UIImage(systemName: "calendar"), title: "No Events", attributedDescription: attributedString, buttonText: "Return to Login", tapHandler: self, selector: #selector(actionButtonTapped), scheme: scheme)
            self.tableView.backgroundView = emptyState
            emptyState?.toggleVisible(true)
            eventInstructions.isHidden = true
            searchContainerHeightConstraint?.constant = 0.0
        } else if eventDataSource?.otherFetchedResultsController?.fetchedObjects?.count == 1 && eventDataSource?.recentFetchedResultsController?.fetchedObjects?.count == 0 {
            if let e = eventDataSource?.otherFetchedResultsController.fetchedObjects?[0] as? Event {
                didSelectEvent(event: e)
            }
        } else if eventDataSource?.otherFetchedResultsController?.fetchedObjects?.count == 0 && eventDataSource?.recentFetchedResultsController?.fetchedObjects?.count == 1 {
            if let e = eventDataSource?.recentFetchedResultsController.fetchedObjects?[0] as? Event {
                didSelectEvent(event: e)
            }
        } else {
            searchContainerHeightConstraint?.constant = 56.0
            eventInstructions.isHidden = false
        }
    }
}

extension EventChooserController : EventSelectionDelegate {
    func didSelectEvent(event: Event) {
        // verify the user is still in this event
        if let remoteId = event.remoteId, let fetchedEvent = Event.getEvent(eventId: remoteId, context: NSManagedObjectContext.mr_default()) {
            // dismiss the search view if showing
            searchController.isActive = false
            // show the loading indicator
            let gathering = EmptyState()
            gathering.configure(image: UIImage(systemName: "calendar"), title: "Gathering information for \(fetchedEvent.name ?? "the event")", showActivityIndicator: true, scheme: self.scheme)
            view.addSubview(gathering)
            gathering.autoPinEdgesToSuperviewEdges()
            gathering.toggleVisible(true, completion: { [weak self] success in
                self?.delegate?.didSelectEvent(event: event)
            })
        } else {
            let alert = UIAlertController(title: "Unauthorized", message: "You are no longer a part of the event '\(event.name ?? "")'.  Please contact an administrator if you need access.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Refresh Events", style: .default, handler: { action in
                self.refreshingButtonTapped()
            }))
            self.present(alert, animated: true)
        }
    }
    
    @objc func actionButtonTapped() {
        delegate?.actionButtonTapped()
    }
}

extension EventChooserController : NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if (type == .insert || type == .delete) {
            eventsChanged = true
        }
    }
}

extension EventChooserController : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if searchController.isActive {
            eventDataSource?.setEventFilter(searchController.searchBar.text, with: self)
        } else {
            eventDataSource?.setEventFilter(nil, with: nil)
        }
        tableView.reloadData()
    }
}
