//
//  AnnotationDragCallback.h
//  MAGE
//
//  Created by Brian Osborn on 5/25/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#ifndef AnnotationDragCallback_h
#define AnnotationDragCallback_h

/**
 *  Annotation Drag Callback protocol for receiving callbacks when an annotation is dragged
 */
@protocol AnnotationDragCallback <NSObject>

/**
 *  Annotation view is being dragged at current coordinate location
 *
 *  @param annotationView annotation view
 *  @param coordinate coordinate
 */
- (void)draggingAnnotationView:(MKAnnotationView *) annotationView atCoordinate: (CLLocationCoordinate2D) coordinate;

@end

#endif /* AnnotationDragCallback_h */
