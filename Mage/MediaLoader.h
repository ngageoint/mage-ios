//
//  MediaLoader.h
//  MAGE
//
//  Created by Daniel Barela on 4/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVFoundation/AVFoundation.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MediaLoaderDelegate <NSObject>

- (void) mediaLoadComplete: (NSString *) filePath withNewFile: (BOOL) newFile;

@optional
- (void) mediaLoadProgress: (float) progress;

@end

@interface MediaLoader : NSObject <AVAssetResourceLoaderDelegate>

- (instancetype) initWithUrlToLoad: (NSURL *) urlToLoad andTempFile: (NSString *) tempFile andDelegate: (id<MediaLoaderDelegate>) delegate;
- (instancetype) initWithDelegate: (id<MediaLoaderDelegate>) delegate;
- (void) downloadAudioToFile: (NSString *) file fromURL: (NSURL *) url;
- (AVPlayerItem *) createPlayerItemFromURL: (NSURL *) url toFile: (nullable NSString *) file;

@end

NS_ASSUME_NONNULL_END
