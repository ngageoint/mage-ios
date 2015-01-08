//
//  AudioRecordingDelegate.h
//  MAGE
//
//  Created by Dan Barela on 1/8/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Recording.h"

@protocol AudioRecordingDelegate <NSObject>

@required

- (void) recordingAvailable: (Recording *) recording;

@end
