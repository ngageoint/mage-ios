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
    
    func applyTheme(withScheme scheme: MDCContainerScheming) {
        self.scheme = scheme;
        self.backgroundColor = scheme.colorScheme.surfaceColor;
        syncStatusView.applyTheme(withScheme: scheme);
        if (observation?.hasValidationError() ?? false) {
            syncStatusView.textView.textColor = scheme.colorScheme.errorColor;
            syncStatusView.imageView.tintColor = scheme.colorScheme.errorColor;
        } else if (!(observation?.isDirty() ?? false) && observation?.error == nil) {
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
        self.observation = observation;
    }
    
    @objc func syncObservation() {
        manualSync = true;
        ObservationPushService.singleton()?.pushObservations([observation!]);
        setupSyncStatusView();
    }
    
    func updateObservationStatus() {
        setupSyncStatusView();
    }
    
    override func updateConstraints() {
        if (!didSetupConstraints) {
            syncStatusView.autoPinEdgesToSuperviewEdges();
            didSetupConstraints = true;
        }
        super.updateConstraints();
    }
    
    func setupSyncStatusView() {
        self.isHidden = false;
        // if the observation has an error
        if (observation?.hasValidationError() ?? false) {
            syncStatusView.textView.text = "Error Pushing Changes\n\(observation?.errorMessage() ?? "")";
            syncStatusView.accessibilityLabel = "Error Pushing Changes\n\(observation?.errorMessage() ?? "")";
            syncStatusView.imageView.image = UIImage(named: "error_outline");
            syncStatusView.leadingButton.isHidden = true;
            if let safeScheme = scheme {
                applyTheme(withScheme: safeScheme);
            }
            return;
        }
        
        // if the observation is not dirty and has no error, show the push date
        if (!(observation?.isDirty() ?? false) && observation?.error == nil) {
            if let pushedDate: NSDate = observation?.lastModified as NSDate? {
                syncStatusView.textView.text = "Pushed on \(pushedDate.formattedDisplay() ?? "")";
                syncStatusView.accessibilityLabel = "Pushed on \(pushedDate.formattedDisplay() ?? "")";
            }
            syncStatusView.textView.textColor = MDCPalette.green.accent700;
            syncStatusView.imageView.image = UIImage(named: "done");
            syncStatusView.imageView.tintColor = MDCPalette.green.accent700;
            syncStatusView.leadingButton.isHidden = true;
            if let safeScheme = scheme {
                applyTheme(withScheme: safeScheme);
            }
            return;
        }
        
        // if the user has attempted to manually sync
        if (manualSync) {
            syncStatusView.textView.text = "Force Pushing Changes...";
            syncStatusView.accessibilityLabel = "Force Pushing Changes..."
            syncStatusView.imageView.image = UIImage(named: "cached");
            syncStatusView.leadingButton.isHidden = true;
            if let safeScheme = scheme {
                applyTheme(withScheme: safeScheme);
            }
            return;
        }
        
        // if the observation is dirty and needs synced
        syncStatusView.textView.text = "Changes Queued";
        syncStatusView.accessibilityLabel = "Changes Queued";
        syncStatusView.imageView.image = UIImage(named: "cached");
        syncStatusView.leadingButton.setTitle("Sync Now", for: .normal);
        syncStatusView.leadingButton.accessibilityLabel = "Sync Now";
        syncStatusView.leadingButton.addTarget(self, action: #selector(self.syncObservation), for: .touchUpInside)
        if let safeScheme = scheme {
            applyTheme(withScheme: safeScheme);
        }
    }
    
}
