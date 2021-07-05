//
//  FeatureDetailCoordinator.h
//  MAGE
//
//  Created by William Newman on 1/17/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MaterialComponents;
NS_ASSUME_NONNULL_BEGIN

@protocol FeatureDetailDelegate
- (void) featureDetailComplete: (NSObject *) coordinator;
@end

@interface FeatureDetailCoordinator : NSObject
- (instancetype) initWithViewController: (UIViewController *) viewController detail:(NSAttributedString *) detail  containerScheme:(id<MDCContainerScheming>)containerScheme;

@property (weak, nonatomic) id<FeatureDetailDelegate> delegate;

- (void) start;

@end

NS_ASSUME_NONNULL_END
