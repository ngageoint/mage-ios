//
//  ObservationHeaderView.swift
//  MAGE
//
//  Created by Daniel Barela on 12/16/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import PureLayout
import Kingfisher
import MaterialComponents.MaterialTypographyScheme
import MaterialComponents.MaterialCards
import SwiftUI
import MaterialViews

struct ObservationHeaderViewSwiftUI: View {
    @ObservedObject
    var viewModel: ObservationViewViewModel
    
    var showFavorites: (_ favoritesModel: ObservationFavoritesModel?) -> Void
    var moreActions: () -> Void
    
    var body: some View {
        VStack {
            ObservationSyncStatusSwiftUI(
                hasError: viewModel.observationModel?.error,
                isDirty: viewModel.observationModel?.isDirty,
                errorMessage: viewModel.observationModel?.errorMessage,
                pushedDate: viewModel.observationModel?.lastModified,
                syncNow: ObservationActions.syncNow(observationUri: viewModel.observationModel?.observationId)
            )
            .frame(maxWidth: .infinity)
            .background(Color.surfaceColor)
            .card()
            
            VStack {
                if let important = viewModel.observationImportantModel {
                    ObservationImportantViewSwiftUI(important: important)
                }
                ObservationLocationSummary(
                    timestamp: viewModel.observationModel?.timestamp,
                    user: viewModel.user?.name,
                    primaryFieldText: viewModel.primaryFieldText,
                    secondaryFieldText: viewModel.secondaryFieldText,
                    iconPath: nil, 
                    error: viewModel.observationModel?.error ?? false,
                    syncing: viewModel.observationModel?.syncing ?? false
                )
                if let observationId = viewModel.observationModel?.observationId {
                    ObservationMapItemView(observationUri: observationId)
                }
                Divider()
                if viewModel.settingImportant {
                    VStack {
                        TextField("Important Description", text: $viewModel.importantDescription, axis: .vertical)
                            .lineLimit(2...4)
                            .textFieldStyle(.roundedBorder)
                        HStack {
                            Spacer()
                            
                            Button {
                                viewModel.cancelAction()
                            } label: {
                                Label {
                                    Text(viewModel.cancelButtonText)
                                } icon: {
                                    
                                }
                            }
                            .buttonStyle(MaterialButtonStyle(type: .text))
                            
                            Button {
                                viewModel.makeImportant()
                            } label: {
                                Label {
                                    Text("Flag As Important")
                                } icon: {
                                    
                                }
                            }
                            .buttonStyle(MaterialButtonStyle(type: .contained))
                        }
                    }.padding()
                }
                ObservationViewActionBar(
                    isImportant: viewModel.isImportant,
                    importantAction: {
                        viewModel.settingImportant = !viewModel.settingImportant
                    },
                    favoriteCount: viewModel.favoriteCount,
                    currentUserFavorite: viewModel.currentUserFavorite,
                    favoriteAction:
                        ObservationActions.favorite(
                            observationUri: viewModel.observationModel?.observationId,
                            userRemoteId: viewModel.currentUser?.remoteId
                        ),
                    showFavoritesAction: {
                        showFavorites(viewModel.observationFavoritesModel)
                    },
                    navigateToAction:
                        CoordinateActions.navigateTo(
                            coordinate: viewModel.observationModel?.coordinate,
                            itemKey: viewModel.observationModel?.observationId?.absoluteString,
                            dataSource: DataSources.observation
                        ),
                    moreActions: {
                        moreActions()
                    }
                )
            }
            .frame(maxWidth: .infinity)
            .background(Color.surfaceColor)
            .card()
        }
    }
}

class ObservationHeaderView : MDCCard {
    @Injected(\.observationMapItemRepository)
    var observationMapItemRepository: ObservationMapItemRepository
    
    var didSetupConstraints = false;
    weak var observation: Observation?;
    weak var observationActionsDelegate: ObservationActionsDelegate?;
    var scheme: MDCContainerScheming?;
    
    private lazy var stack: UIStackView = {
        let stack = UIStackView(forAutoLayout: ());
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0
        stack.distribution = .fill
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        stack.isLayoutMarginsRelativeArrangement = true;
        stack.translatesAutoresizingMaskIntoConstraints = false;
        stack.addArrangedSubview(importantView);
        stack.addArrangedSubview(observationSummaryView);
        if let mapItemView = mapItemView {
            stack.addArrangedSubview(mapItemView.view)
        }
        stack.addArrangedSubview(divider);
        stack.addArrangedSubview(observationActionsView);
        return stack;
    }()
    
    private lazy var observationSummaryView: ObservationSummaryView = {
        let summary = ObservationSummaryView(imageOverride: nil, hideImage: true);
        return summary;
    }()
    
    private lazy var divider: UIView = {
        let divider = UIView(forAutoLayout: ());
        divider.autoSetDimension(.height, toSize: 1);
        return divider;
    }()
    
    lazy var locationField: [String: Any] = {
        let locationField: [String: Any] =
            [
             FieldKey.name.key: "geometry",
             FieldKey.type.key: "geometry"
            ];
        return locationField;
    }()

    private var mapItemView: SwiftUIViewController?

    private lazy var geometryView: GeometryView = {
        let geometryView = GeometryView(field: locationField, editMode: false, delegate: nil, observation: self.observation, mapEventDelegate: nil, observationActionsDelegate: observationActionsDelegate);
        
        return geometryView;
    }()
    
    private lazy var observationActionsView: ObservationActionsView = {
        let observationActionsView = ObservationActionsView(observation: self.observation!, observationActionsDelegate: observationActionsDelegate, scheme: self.scheme);
        return observationActionsView;
    }()
    
    private lazy var importantView: ObservationImportantView = {
        let importantView = ObservationImportantView(observation: self.observation, cornerRadius: self.cornerRadius, scheme: self.scheme);
        return importantView;
    }()
    
    public convenience init(observation: Observation, observationActionsDelegate: ObservationActionsDelegate?) {
        self.init(frame: CGRect.zero);
        self.observation = observation;
        self.observationActionsDelegate = observationActionsDelegate;
        let view = ObservationMapItemView(observationUri: observation.objectID.uriRepresentation())
        mapItemView = SwiftUIViewController(swiftUIView: view)

        self.configureForAutoLayout();
        layoutView();
        populate(observation: observation, animate: false);
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            stack.autoPinEdgesToSuperviewEdges();
            didSetupConstraints = true;
        }
        super.updateConstraints();
    }
    
    override func applyTheme(withScheme scheme: MDCContainerScheming?) {
        guard let scheme = scheme else {
            return
        }

        super.applyTheme(withScheme: scheme);
        self.geometryView.applyTheme(withScheme: scheme);
        self.importantView.applyTheme(withScheme: scheme);
        self.observationActionsView.applyTheme(withScheme: scheme);
        self.observationSummaryView.applyTheme(withScheme: scheme);
        divider.backgroundColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.12);
    }
    
    @objc public func populate(observation: Observation, animate: Bool = true, ignoreGeometry: Bool = false) {
        observationSummaryView.populate(observation: observation);
        if (animate) {
            UIView.animate(withDuration: 0.2) {
                self.importantView.isHidden = !observation.isImportant
            }
        } else {
            self.importantView.isHidden = !observation.isImportant
        }
        if (!ignoreGeometry) {
            geometryView.setObservation(observation: observation);
        }
        importantView.populate(observation: observation);
        observationActionsView.populate(observation: observation);
    }
    
    func layoutView() {
        self.addSubview(stack);
    }
}
