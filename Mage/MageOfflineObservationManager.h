//
//  MageOfflineObservationController.h
//  MAGE
//
//  Created by William Newman on 5/22/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OfflineObservationDelegate <NSObject>

@required
-(void) offlineObservationsDidChangeCount:(NSInteger) count;

@end

@interface MageOfflineObservationManager : NSObject

@property (weak, nonatomic) id<OfflineObservationDelegate> delegate;

- (instancetype) initWithDelegate:(id<OfflineObservationDelegate>) delegate context: (NSManagedObjectContext *) context;
- (void) start;
- (void) stop;

+ (NSUInteger) offlineObservationCount;

@end
