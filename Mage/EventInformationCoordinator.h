//
//  EventInformationCoordinator.h
//  MAGE
//
//  Created by William Newman on 1/29/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EventInformationController.h"
#import <MaterialComponents/MDCContainerScheme.h>

NS_ASSUME_NONNULL_BEGIN

@protocol EventInformationDelegate
- (void) eventInformationComplete:(id) coordinator;
@end

@interface EventInformationCoordinator : NSObject<EventInformationControllerDelegate>

@property (weak, nonatomic) id<EventInformationDelegate> delegate;

- (instancetype) initWithViewController: (UINavigationController *) viewController event:(Event *) event scheme: (id<MDCContainerScheming>) containerScheme;
- (void) start;

@end

NS_ASSUME_NONNULL_END
