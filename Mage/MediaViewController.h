//
//  MediaViewController.h
//  UFO
//
//  Created by   on 6/2/12.
//    
//

#import <UIKit/UIKit.h>
#import "Recording.h"
#import "AudioRecordingDelegate.h"

@class MediaViewController;

@interface MediaViewController :UIViewController

@property(nonatomic, strong) Recording *recording;
@property(nonatomic, strong) id<AudioRecordingDelegate> delegate;

@end
