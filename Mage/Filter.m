//
//  Filter.m
//  MAGE
//
//  Created by William Newman on 1/13/17.
//

#import "Filter.h"
#import "TimeFilter.h"
#import "Observations.h"

@implementation Filter

+ (NSString *) getFilterString {
    NSMutableArray *filters = [[NSMutableArray alloc] init];
    NSString *timeFilterString = [TimeFilter getTimeFilterString];
    if ([timeFilterString length] && ![timeFilterString isEqualToString:@"All"]) {
        [filters addObject:timeFilterString];
    }
    
    NSMutableArray *observationFilters = [[NSMutableArray alloc] init];
    if([Observations getFavoritesFilter]) {
        [observationFilters addObject:@"Favorites"];
    }
    
    if ([Observations getImportantFilter]) {
        [observationFilters addObject:@"Important"];
    }
    
    NSString *observationFilterString = [observationFilters componentsJoinedByString:@" & "];
    if ([observationFilterString length]) {
        [filters addObject:observationFilterString];
    }

    return [filters componentsJoinedByString:@", "];
}


@end
