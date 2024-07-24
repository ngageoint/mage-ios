//
//  FeedItemBottomSheetView.swift
//  MAGE
//
//  Created by Daniel Barela on 7/14/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import MaterialViews

class FeedItemBottomSheeViewModel: ObservableObject {
    @Injected(\.feedItemRepository)
    var repository: FeedItemRepository
    
    var disposables = Set<AnyCancellable>()
    
    @Published
    var feedItem: FeedItemModel?
    
    var feedItemUri: URL?
    
    init(feedItemUri: URL?) {
        self.feedItemUri = feedItemUri
        repository.observeFeedItem(feedItemUri: feedItemUri)?
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] updatedObject in
                self?.feedItem = updatedObject
            })
            .store(in: &disposables)
    }
}

struct FeedItemBottomSheet: View {
    @ObservedObject
    var viewModel: FeedItemBottomSheeViewModel
    
    var body: some View {
        Group {
            if let feedItem = viewModel.feedItem {
                VStack(spacing: 0) {
                    FeedItemSummaryView(
                        timestamp: feedItem.timestamp,
                        primaryValue: feedItem.primaryValue,
                        secondaryValue: feedItem.secondaryValue,
                        iconUrl: feedItem.iconUrl
                    )
                    
                    StaticLayerFeatureBottomSheetActionBar(
                        coordinate: feedItem.coordinate,
                        navigateToAction: CoordinateActions.navigateTo(
                            coordinate: feedItem.coordinate,
                            itemKey: feedItem.feedItemId.absoluteString,
                            dataSource: DataSources.featureItem
                        )
                    )
                    
                    Button {
                        // let the ripple dissolve before transitioning otherwise it looks weird
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NotificationCenter.default.post(name: .ViewFeedItem, object: feedItem.feedItemId)
                        }
                    } label: {
                        Text("More Details")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(MaterialButtonStyle(type: .contained))
                    .padding(8)
                }
                .id("\(viewModel.feedItemUri?.absoluteString ?? "")")
                .ignoresSafeArea()
            }
        }
        .animation(.default, value: self.viewModel.feedItem != nil)
    }
}

class FeedItemBottomSheetView: UIView, BottomSheetView {
    
    private var didSetUpConstraints = false;
    private var feedItem: FeedItem?;
    private var actionsDelegate: FeedItemActionsDelegate?;
    var scheme: MDCContainerScheming?;
    
    private lazy var stackView: PassThroughStackView = {
        let stackView = PassThroughStackView(forAutoLayout: ());
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 0
        stackView.distribution = .fill;
        stackView.directionalLayoutMargins = .zero;
        stackView.isLayoutMarginsRelativeArrangement = false;
        stackView.translatesAutoresizingMaskIntoConstraints = false;
        stackView.clipsToBounds = true;
        return stackView;
    }()
    
    private lazy var summaryView: FeedItemSummary = {
        let view = FeedItemSummary();
        return view;
    }()
    
    private lazy var actionsView: FeedItemActionsView? = {
        guard let feedItem = self.feedItem else {
            return nil;
        }
        let view = FeedItemActionsView(feedItem: feedItem, actionsDelegate: actionsDelegate, scheme: scheme);
        return view;
    }()
    
    private lazy var detailsButton: MDCButton = {
        let detailsButton = MDCButton(forAutoLayout: ());
        detailsButton.accessibilityLabel = "More Details";
        detailsButton.setTitle("More Details", for: .normal);
        detailsButton.clipsToBounds = true;
        detailsButton.addTarget(self, action: #selector(detailsButtonTapped), for: .touchUpInside);
        return detailsButton;
    }()
    
    private lazy var detailsButtonView: UIView = {
        let view = UIView();
        view.addSubview(detailsButton);
        detailsButton.autoAlignAxis(toSuperviewAxis: .vertical);
        detailsButton.autoMatch(.width, to: .width, of: view, withMultiplier: 0.9);
        detailsButton.autoPinEdge(.top, to: .top, of: view);
        detailsButton.autoPinEdge(.bottom, to: .bottom, of: view);
        return view;
    }()
    
    private lazy var expandView: UIView = {
        let view = UIView(forAutoLayout: ());
        view.setContentHuggingPriority(.defaultLow, for: .vertical);
        return view;
    }();
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    init(feedItem: FeedItem, actionsDelegate: FeedItemActionsDelegate? = nil, scheme: MDCContainerScheming?) {
        super.init(frame: CGRect.zero);
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.actionsDelegate = actionsDelegate;
        self.feedItem = feedItem;
        self.scheme = scheme;
        
        stackView.addArrangedSubview(summaryView);
        if (actionsView != nil) {
            stackView.addArrangedSubview(actionsView!);
        }
        stackView.addArrangedSubview(detailsButtonView);
        self.addSubview(stackView);
        stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0));
        
        populateView();
        if let scheme = scheme {
            applyTheme(withScheme: scheme);
        }
    }
    
    func applyTheme(withScheme scheme: MDCContainerScheming? = nil) {
        guard let scheme = scheme else {
            return;
        }
        self.backgroundColor = scheme.colorScheme.surfaceColor;
        summaryView.applyTheme(withScheme: scheme);
        actionsView?.applyTheme(withScheme: scheme);
        detailsButton.applyContainedTheme(withScheme: scheme);
    }
    
    func populateView() {
        guard let feedItem = self.feedItem else {
            return
        }
        summaryView.populate(item: feedItem, actionsDelegate: actionsDelegate);
        actionsView?.populate(feedItem: feedItem, delegate: actionsDelegate)
    }
    
    override func updateConstraints() {
        if (!didSetUpConstraints) {
            stackView.autoPinEdgesToSuperviewEdges(with: .zero);
            didSetUpConstraints = true;
        }
        
        super.updateConstraints();
    }
    
    func refresh() {
        guard let feedItem = self.feedItem else {
            return
        }
        summaryView.populate(item: feedItem, actionsDelegate: actionsDelegate);
    }
    
    @objc func detailsButtonTapped() {
        if let feedItem = feedItem {
            // let the ripple dissolve before transitioning otherwise it looks weird
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .ViewFeedItem, object: feedItem)
                self.actionsDelegate?.viewFeedItem?(feedItem: feedItem)
            }
        }
    }
}
