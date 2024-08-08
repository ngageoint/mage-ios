//
//  ObservationSyncStatus.swift
//  MAGE
//
//  Created by Daniel Barela on 12/22/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MaterialComponents.MDCBannerView
import MaterialComponents.MDCPalettes
import SwiftUI
import MAGEStyle
import MaterialViews

struct ObservationSyncStatusSwiftUI: View {
    
    var hasError: Bool?
    var isDirty: Bool?
    var errorMessage: String?
    var pushedDate: Date?
    var syncing: Bool?
    var syncNow: ObservationActions
    
    var body: some View {
        Group {
            if !(isDirty ?? false), !(hasError ?? false), let pushedDate = pushedDate {
                successfulPush(pushedDate: pushedDate)
            } else if (hasError ?? false) {
                error(errorMessage: errorMessage)
            } else if (syncing ?? false) {
                syncInProgress()
            }
        }
    }
    
    // if the observation is not dirty and has no error, show the push date
    @ViewBuilder
    func successfulPush(pushedDate: Date) -> some View {
        HStack {
            Image(systemName: "checkmark")
            Text("Pushed on \((pushedDate as NSDate).formattedDisplay())")
        }
        .font(Font.overline)
        .foregroundColor(Color.favoriteColor)
        .opacity(0.6)
        .padding([.top, .bottom], 8)
    }
    
    // if the observation has an error
    @ViewBuilder
    func error(errorMessage: String?) -> some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
            VStack {
                Text("Error Pushing Changes")
                if let errorMessage = errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                }
            }
            .font(Font.overline)
        }
        
        .foregroundColor(Color.errorColor)
        .opacity(0.6)
        .padding([.top, .bottom], 8)
    }
    
    // If the observation is syncing
    @ViewBuilder
    func syncInProgress() -> some View {
        HStack {
            Group {
                Image(systemName: "arrow.triangle.2.circlepath")
                Text("Changes Queued...")
            }
            .font(Font.overline)
            .foregroundColor(Color.onSurfaceColor)
            .opacity(0.6)
            
            Button {
                syncNow()
            } label: {
                Text("Sync Now")
            }
            .buttonStyle(MaterialButtonStyle(type: .text))
        }
    }
}

class ObservationSyncStatus: UIView {
    private var didSetupConstraints = false;
    private weak var observation: Observation?;
    private var manualSync: Bool = false;
    private var scheme: MDCContainerScheming?;
    
    private lazy var syncStatusView: MDCBannerView = {
        let syncStatusView = MDCBannerView(forAutoLayout: ());
        syncStatusView.bannerViewLayoutStyle = .singleRow;
        syncStatusView.trailingButton.isHidden = true;
        syncStatusView.imageView.isHidden = false;
        syncStatusView.imageView.contentMode = .center;
        return syncStatusView;
    }();
    
    func applyTheme(withScheme scheme: MDCContainerScheming?) {
        guard let scheme = scheme else {
            return
        }

        self.scheme = scheme;
        self.backgroundColor = scheme.colorScheme.surfaceColor;
        syncStatusView.applyTheme(withScheme: scheme);
        if (observation?.hasValidationError ?? false) {
            syncStatusView.textView.textColor = scheme.colorScheme.errorColor;
            syncStatusView.imageView.tintColor = scheme.colorScheme.errorColor;
        } else if (!(observation?.isDirty ?? false) && observation?.error == nil) {
            syncStatusView.textView.textColor = MDCPalette.green.accent700;
            syncStatusView.imageView.tintColor = MDCPalette.green.accent700;
        } else if (manualSync) {
            syncStatusView.textView.textColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
            syncStatusView.imageView.tintColor = scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6);
        } else {
            syncStatusView.textView.textColor = scheme.colorScheme.secondaryColor;
            syncStatusView.imageView.tintColor = scheme.colorScheme.secondaryColor;
        }
    }

    public convenience init(observation: Observation?) {
        self.init(frame: .zero);
        configureForAutoLayout();
        addSubview(syncStatusView);
        self.observation = observation;
        setupSyncStatusView();
    }
    
    @objc func syncObservation() {
        manualSync = true;
        ObservationPushService.singleton.pushObservations(observations: [observation!]);
        setupSyncStatusView();
    }
    
    func updateObservationStatus(observation: Observation? = nil) {
        if (observation != nil) {
            self.observation = observation;
        }
        setupSyncStatusView();
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            syncStatusView.autoSetDimension(.height, toSize: 36);
            syncStatusView.autoPinEdgesToSuperviewEdges();
            didSetupConstraints = true;
        }
        super.updateConstraints();
    }
    
    func setupSyncStatusView() {
        self.isHidden = false;
        // if the observation has an error
        if (observation?.hasValidationError ?? false) {
            syncStatusView.textView.text = "Error Pushing Changes\n\(observation?.errorMessage ?? "")";
            syncStatusView.accessibilityLabel = "Error Pushing Changes\n\(observation?.errorMessage ?? "")";
            syncStatusView.imageView.image = UIImage(systemName: "exclamationmark.circle");
            syncStatusView.leadingButton.isHidden = true;
            if let scheme = scheme {
                applyTheme(withScheme: scheme);
            }
            syncStatusView.sizeToFit();
            return;
        }
        
        // if the observation is not dirty and has no error, show the push date
        if (!(observation?.isDirty ?? false) && observation?.error == nil) {
            if let pushedDate: NSDate = observation?.lastModified as NSDate? {
                syncStatusView.textView.text = "Pushed on \(pushedDate.formattedDisplay())";
                syncStatusView.accessibilityLabel = "Pushed on \(pushedDate.formattedDisplay())";
            }
            syncStatusView.textView.textColor = MDCPalette.green.accent700;
            syncStatusView.imageView.image = UIImage(systemName: "checkmark");
            syncStatusView.imageView.tintColor = MDCPalette.green.accent700;
            syncStatusView.leadingButton.isHidden = true;
            if let scheme = scheme {
                applyTheme(withScheme: scheme);
            }
            syncStatusView.sizeToFit();
            return;
        }
        
        // if the user has attempted to manually sync
        if (manualSync) {
            syncStatusView.textView.text = "Force Pushing Changes...";
            syncStatusView.accessibilityLabel = "Force Pushing Changes..."
            syncStatusView.imageView.image = UIImage(systemName: "arrow.triangle.2.circlepath");
            syncStatusView.leadingButton.isHidden = true;
            if let scheme = scheme {
                applyTheme(withScheme: scheme);
            }
            syncStatusView.sizeToFit();
            return;
        }
        
        // if the observation is dirty and needs synced
        syncStatusView.textView.text = "Changes Queued";
        syncStatusView.accessibilityLabel = "Changes Queued";
        syncStatusView.imageView.image = UIImage(systemName: "arrow.triangle.2.circlepath");
        syncStatusView.leadingButton.setTitle("Sync Now", for: .normal);
        syncStatusView.leadingButton.accessibilityLabel = "Sync Now";
        syncStatusView.leadingButton.addTarget(self, action: #selector(self.syncObservation), for: .touchUpInside)
        if let scheme = scheme {
            applyTheme(withScheme: scheme);
        }
        syncStatusView.sizeToFit();
    }
    
}
