//
//  UserViewSwiftUI.swift
//  MAGE
//
//  Created by Dan Barela on 8/9/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import SwiftUI
import Kingfisher
import MAGEStyle
import MapFramework

struct UserViewSwiftUI: View {
    @StateObject
    var viewModel: UserViewViewModel
    
    @EnvironmentObject
    var router: MageRouter
    
    @StateObject var mixins: MapMixins = MapMixins()
    @StateObject var mapState: MapState = MapState()
    
    var viewImage: (_ imageUrl: URL) -> Void
    
    var map: some View {
        MapRepresentable(name: "MAGE Map", mixins: mixins, mapState: mapState)
            .ignoresSafeArea()
    }
    
    var body: some View {
        List {
            Group {
                VStack(alignment: .leading) {
                    map.frame(maxWidth: .infinity, minHeight: 150, maxHeight: 150)
                    Group {
                        if let url = URL(string: viewModel.user?.avatarUrl ?? "") {
                            KFImage(url)
                                .requestModifier(ImageCacheProvider.shared.accessTokenModifier)
                                .forceRefresh()
                                .cacheOriginalImage()
                                .onlyFromCache(DataConnectionUtilities.shouldFetchAttachments())
                                .placeholder {
                                    Image(systemName: "person.crop.square")
                                        .symbolRenderingMode(.monochrome)
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundStyle(Color.onSurfaceColor.opacity(0.45))
                                        .background(Color.backgroundColor)
                                }
                                .roundCorner(radius: Radius.point(5))
                                .fade(duration: 0.3)
                                .resizable()
                                .scaledToFill()
                                .frame(idealWidth: 80, maxWidth: 80, idealHeight: 80, maxHeight: 80)
                                .clipShape(RoundedRectangle(cornerSize: CGSizeMake(5, 5)))
                                .overlay( /// apply a rounded border
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.backgroundColor, lineWidth: 3)
                                )
                                .padding(.top, -35)
                                .onTapGesture {
                                    viewImage(url)
                                }
                        }
                        
                        if let userName = viewModel.user?.name {
                            Text(userName)
                                .font(.headline6)
                                .foregroundStyle(Color.onSurfaceColor.opacity(0.87))
                        }
                        if let coordinate = viewModel.user?.coordinate {
                            HStack {
                                Image(systemName: "globe.americas.fill")
                                    .foregroundStyle(Color.onSurfaceColor.opacity(0.87))
                                    .frame(width: 18, height: 18)
                                Text(coordinate.toDisplay())
                                    .font(.subtitle2)
                                    .foregroundStyle(Color.onSurfaceColor.opacity(0.87))
                                if let horizontalAccuracy = viewModel.user?.cllocation?.horizontalAccuracy {
                                    Text("GPS +/- \(horizontalAccuracy, specifier: "%.2f")")
                                        .font(.caption)
                                        .foregroundStyle(Color.onSurfaceColor.opacity(0.6))
                                }
                            }
                            .onTapGesture {
                                CoordinateActions.navigateTo(
                                    coordinate: coordinate,
                                    itemKey: viewModel.uri.absoluteString,
                                    dataSource: DataSources.user,
                                    includeCopy: true
                                )()
                            }
                        }
                        if let phone = viewModel.user?.phone {
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundStyle(Color.onSurfaceColor.opacity(0.87))
                                    .frame(width: 18, height: 18)
                                Text(phone)
                                    .font(.subtitle2)
                                    .foregroundStyle(Color.onSurfaceColor.opacity(0.87))
                            }
                            .onTapGesture {
                                UserActions.phone(phone: phone)()
                            }
                        }
                        if let email = viewModel.user?.email {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(Color.onSurfaceColor.opacity(0.87))
                                    .frame(width: 18, height: 18)
                                Text(email)
                                    .font(.subtitle2)
                                    .foregroundStyle(Color.onSurfaceColor.opacity(0.87))
                            }
                            .onTapGesture {
                                UserActions.email(email: email)()
                            }
                        }
                    }
                    .padding([.trailing, .leading], 8)
                }
            }
            .padding(.bottom, 16)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.backgroundColor)
            
            UserObservationList(
                viewModel: viewModel
            )
            .listRowBackground(Color.backgroundColor)
        }
        .listStyle(.plain)
        .listSectionSeparator(.hidden)
        .background(Color.backgroundColor)
        .onAppear {
            viewModel.fetchObservations()
            mixins.addMixin(OnlineLayerMapMixin())
            mixins.addMixin(ObservationMap(mapFeatureRepository: ObservationMapFeatureRepository(userUri: viewModel.uri)))
        }
    }
}
