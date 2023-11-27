//
//  AudioRecorderViewController.h
//  MAGE
//
//  Created by Dan Barela on 8/14/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Recording.h"

@protocol AudioRecordingDelegate;

@class AudioRecorderViewController;

@interface AudioRecorderViewController :UIViewController

@property(nonatomic, strong) Recording *recording;
@property(nonatomic, strong) id<AudioRecordingDelegate> audioRecordingDelegate;

- (instancetype) initWithDelegate: (id<AudioRecordingDelegate>) audioRecordingDelegate;

@end
