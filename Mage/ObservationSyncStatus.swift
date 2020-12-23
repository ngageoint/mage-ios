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
    
    private var observation: Observation?;
    private var manualSync: Bool = false;
    private var syncStatusView: MDCBannerView?;

    public convenience init(observation: Observation?) {
        self.init(frame: .zero);
        configureForAutoLayout();
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
    
    func setupSyncStatusView() {
        if (syncStatusView != nil) {
            syncStatusView?.removeFromSuperview();
        }
        
        // if this is not the current users observation, don't show anything
        if (observation?.userId != UserDefaults.standard.currentUserId){
            self.isHidden = true;
            return;
        }
        
        self.isHidden = false;
        
        // if the observation has an error
        if (observation?.hasValidationError() ?? false) {
            let syncStatusView = MDCBannerView(forAutoLayout: ());
            syncStatusView.bannerViewLayoutStyle = .singleRow;
            syncStatusView.applyTheme(withScheme: globalContainerScheme());
            syncStatusView.textView.text = "Error Pushing Changes\n\(observation?.errorMessage() ?? "")";
            syncStatusView.textView.textColor = globalErrorContainerScheme().colorScheme.primaryColor;
            syncStatusView.imageView.image = UIImage(named: "error_outline");
            syncStatusView.imageView.tintColor = globalErrorContainerScheme().colorScheme.primaryColor;
            syncStatusView.imageView.isHidden = false;
            syncStatusView.trailingButton.isHidden = true;
            syncStatusView.leadingButton.isHidden = true;
            
            addSubview(syncStatusView);
            syncStatusView.autoPinEdgesToSuperviewEdges();
            return;
        }
        
        // if the observation is not dirty and has no error, show the push date
        if (!(observation?.isDirty() ?? false) && observation?.error == nil) {
            let syncStatusView = MDCBannerView(forAutoLayout: ());
            syncStatusView.bannerViewLayoutStyle = .singleRow;
            syncStatusView.applyTheme(withScheme: globalContainerScheme());
            if let pushedDate: NSDate = observation?.lastModified as NSDate? {
                syncStatusView.textView.text = "Pushed on \(pushedDate.formattedDisplay() ?? "")";
            }
            syncStatusView.textView.textColor = MDCPalette.green.accent700;
            syncStatusView.imageView.image = UIImage(named: "done");
            syncStatusView.imageView.tintColor = MDCPalette.green.accent700;
            syncStatusView.imageView.isHidden = false;
            syncStatusView.trailingButton.isHidden = true;
            syncStatusView.leadingButton.isHidden = true;
            
            addSubview(syncStatusView);
            syncStatusView.autoPinEdgesToSuperviewEdges();
            return;
        }
        
        // if the user has attempted to manually sync
        if (manualSync) {
            let syncStatusView = MDCBannerView(forAutoLayout: ());
            syncStatusView.bannerViewLayoutStyle = .singleRow;
            syncStatusView.applyTheme(withScheme: globalContainerScheme());
            // if the observation is dirty and needs synced
            syncStatusView.textView.text = "Force Pushing Changes...";
            syncStatusView.textView.textColor = UIColor.label.withAlphaComponent(0.6);
            syncStatusView.imageView.image = UIImage(named: "cached");
            syncStatusView.imageView.tintColor = UIColor.label.withAlphaComponent(0.6);
            syncStatusView.imageView.isHidden = false;
            syncStatusView.trailingButton.isHidden = true;
            syncStatusView.leadingButton.isHidden = true;
            
            addSubview(syncStatusView);
            syncStatusView.autoPinEdgesToSuperviewEdges();
            return;
        }
        
        // if the observation is dirty and needs synced
        let syncStatusView = MDCBannerView(forAutoLayout: ());
        syncStatusView.bannerViewLayoutStyle = .singleRow;
        syncStatusView.applyTheme(withScheme: globalContainerScheme());
        syncStatusView.textView.text = "Changes Queued";
        syncStatusView.textView.textColor = globalContainerScheme().colorScheme.secondaryColor;
        syncStatusView.imageView.image = UIImage(named: "cached");
        syncStatusView.imageView.tintColor = globalContainerScheme().colorScheme.secondaryColor;
        syncStatusView.imageView.isHidden = false;
        syncStatusView.leadingButton.setTitle("Sync Now", for: .normal);
        syncStatusView.leadingButton.accessibilityLabel = "Sync Now";
        syncStatusView.leadingButton.addTarget(self, action: #selector(self.syncObservation), for: .touchUpInside)
        syncStatusView.trailingButton.isHidden = true;
        addSubview(syncStatusView);
        syncStatusView.autoPinEdgesToSuperviewEdges();
    }
    
}
