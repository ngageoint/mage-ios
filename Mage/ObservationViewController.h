//
//  ObservationViewerViewController.h
//  Mage
//
//  Created by Dan Barela on 4/29/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Observation.h"
#import "Attachment.h"
#import "AttachmentCollectionDataStore.h"
#import "AttachmentSelectionDelegate.h"

@interface ObservationViewController : UIViewController<MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource, AttachmentSelectionDelegate>

@property (strong, nonatomic) Observation *observation;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UITableView *propertyTable;
@property (weak, nonatomic) IBOutlet UILabel *timestampLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *attachmentCollection;
@property (strong, nonatomic) IBOutlet AttachmentCollectionDataStore *attachmentCollectionDataStore;

@end
