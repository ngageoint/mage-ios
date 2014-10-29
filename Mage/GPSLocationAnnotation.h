//
//  GPSLocationAnnotation.h
//  MAGE
//
//  Created by Dan Barela on 10/28/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <GPSLocation.h>
#import <User.h>

@interface GPSLocationAnnotation : NSObject <MKAnnotation>

@property (weak, nonatomic) GPSLocation *gpsLocation;
@property (weak, nonatomic) User *user;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic) NSDate *timestamp;

@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;

@property (nonatomic) NSString *username;
@property (nonatomic) NSString *name;

- (id)initWithGPSLocation:(GPSLocation *) location andUser: (User *) user;

@end
