//
//  Form.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 6/27/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Form.h"
#import <AFNetworking.h>
#import "HttpManager.h"
#import "zlib.h"
#import "ZipFile.h"
#import "ZipReadStream.h"
#import "ZipException.h"
#import "FileInZipInfo.h"

static id AFJSONObjectByRemovingKeysWithNullValues(id JSONObject, NSJSONReadingOptions readingOptions) {
    if ([JSONObject isKindOfClass:[NSArray class]]) {
        NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:[(NSArray *)JSONObject count]];
        for (id value in (NSArray *)JSONObject) {
            [mutableArray addObject:AFJSONObjectByRemovingKeysWithNullValues(value, readingOptions)];
        }
        
        return (readingOptions & NSJSONReadingMutableContainers) ? mutableArray : [NSArray arrayWithArray:mutableArray];
    } else if ([JSONObject isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:JSONObject];
        for (id <NSCopying> key in [(NSDictionary *)JSONObject allKeys]) {
            id value = [(NSDictionary *)JSONObject objectForKey:key];
            if (!value || [value isEqual:[NSNull null]]) {
                [mutableDictionary removeObjectForKey:key];
            } else if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
                [mutableDictionary setObject:AFJSONObjectByRemovingKeysWithNullValues(value, readingOptions) forKey:key];
            }
        }
        
        return (readingOptions & NSJSONReadingMutableContainers) ? mutableDictionary : [NSDictionary dictionaryWithDictionary:mutableDictionary];
    }
    
    return JSONObject;
}

@implementation Form

//- (id) populateObjectFromJson: (NSDictionary *) json {
//    [self setRemoteId:[json objectForKey:@"id"]];
//    [self setUserId:[json objectForKey:@"userId"]];
//    [self setDeviceId:[json objectForKey:@"deviceId"]];
//    
//    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
//    [dateFormat setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
//    NSDate *date = [dateFormat dateFromString:[json objectForKey:@"lastModified"]];
//    [self setLastModified:date];
//    [self setUrl:[json objectForKey:@"url"]];
//    NSDictionary *jsonState = [json objectForKey: @"state"];
//    NSString *stateName = [jsonState objectForKey: @"name"];
//    State enumValue = [stateName StateEnumFromString];
//    [self setState:[NSNumber numberWithInt:(int)enumValue]];
//    
//    NSArray *coordinates = [json valueForKeyPath:@"geometry.coordinates"];
//    CLLocation *location = [[CLLocation alloc] initWithLatitude:[[coordinates objectAtIndex:1] floatValue] longitude:[[coordinates objectAtIndex:0] floatValue]];
//    
//    [self setGeometry:[[GeoPoint alloc] initWithLocation:location]];
//    
//    return self;
//}

//+ (id) observationForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
//    
//    Observation *observation = [[Observation alloc] initWithEntity:[NSEntityDescription entityForName:@"Observation" inManagedObjectContext:context] insertIntoManagedObjectContext:nil];
//    
//    [observation populateObjectFromJson:json];
//    
//    return observation;
//}

//+ (void) fetchObservationsFromServerWithManagedObjectContext: (NSManagedObjectContext *) context {
//    HttpManager *http = [HttpManager singleton];
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSURL *serverUrl = [defaults URLForKey: @"serverUrl"];
//    NSString *url = [NSString stringWithFormat:@"%@/%@", serverUrl, @"FeatureServer/3/features"];
//    [http.manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSArray *features = [responseObject objectForKey:@"features"];
//        
//        for (id feature in features) {
//            Observation *o = [Observation observationForJson:feature inManagedObjectContext:context];
//            NSDictionary *properties = [feature objectForKey: @"properties"];
//            [o setProperties:properties];
//            
//            NSSet *existingObservations = [context fetchObjectsForEntityName:@"Observation" withPredicate:@"(remoteId == %@)", o.remoteId];
//            Observation *dbObs = [existingObservations anyObject];
//            
//            //NSLog(@"there are %d observations", existingObservations.count);
//            int archive = [@"archive" IntFromStateEnum];
//            // if the Observation is archived and used to exist on this device, delete it
//            if ([o.state intValue] == archive && dbObs != nil) {
//                [context deleteObject:dbObs];
//                NSLog(@"Deleting observation with id: %@", o.remoteId);
//            }
//            // else if the observation is not archived and doesn't exist, insert it
//            else if ([o.state intValue] != archive && dbObs == nil) {
//                [context insertObject:o];
//                NSLog(@"Saving new observation with id: %@", o.remoteId);
//            }
//            // else if the observation is not archived, and not dirty and exists, update it
//            else if ([o.state intValue] != archive && [o.dirty boolValue]) {
//                [dbObs populateObjectFromJson:feature];
//                NSLog(@"Updating object with id: %@", o.remoteId);
//            }
//        }
//        
//        NSError *error = nil;
//        if (! [context save:&error]) {
//            NSLog(@"Error inserting Observation: %@", error);
//        }
//        
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        NSLog(@"Error: %@", error);
//    }];
//}
//

+ (NSOperation *) fetchFormInUseOperation {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSURL *serverUrl = [defaults URLForKey: @"serverUrl"];

    NSString* formId = [defaults objectForKey: @"formId"];
    NSString *url = [NSString stringWithFormat:@"%@/%@/%@.zip", serverUrl, @"api/forms", formId];
    
    NSString *stringPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:@"/Form.zip"];
    
    NSString *folderToUnzipTo = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat: @"/form-%@", formId]];
    
    HttpManager *http = [HttpManager singleton];
    
    NSLog(@"url is %@", url);
    
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: nil error: nil];
    AFHTTPRequestOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Form request complete");
        
        NSError *error = nil;
    
        ZipFile *unzipFile = [[ZipFile alloc] initWithFileName:stringPath mode:ZipFileModeUnzip];
        int totalNumberOfFiles = (int)[unzipFile numFilesInZip];
        [unzipFile goToFirstFileInZip];
        for (int i = 0; i < totalNumberOfFiles; i++) {
            FileInZipInfo *info = [unzipFile getCurrentFileInZipInfo];
            NSString *name = info.name;
            if (![name hasSuffix:@"/"]) {
                NSString *filePath = [folderToUnzipTo stringByAppendingPathComponent:name];
                NSString *basePath = [filePath stringByDeletingLastPathComponent];
                if (![[NSFileManager defaultManager] createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil error:&error]) {
                    [unzipFile close];
                    
                    //return NO;
                }
                
                [[NSData data] writeToFile:filePath options:0 error:nil];
                
                NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
                ZipReadStream *read = [unzipFile readCurrentFileInZip];
                NSUInteger count;
                NSMutableData *data = [NSMutableData dataWithLength:2048];
                while ((count = [read readDataWithBuffer:data])) {
                    data.length = count;
                    [handle writeData:data];
                    data.length = 2048;
                }
                [read finishedReading];
                [handle closeFile];
            }
            
            [unzipFile goToNextFileInZip];
        }
        
        [unzipFile close];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *jsonFilePath = [NSString stringWithFormat:@"%@/form/%@", folderToUnzipTo, @"form.json"];
        NSLog(@"json file path %@", jsonFilePath);
        if ( [fileManager fileExistsAtPath:jsonFilePath] && error == nil)
        {
            NSString *jsonString = [[NSString alloc] initWithContentsOfFile:jsonFilePath encoding:NSUTF8StringEncoding error:NULL];
            NSError *error;
            
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
            json = AFJSONObjectByRemovingKeysWithNullValues(json, NSJSONReadingAllowFragments);

            [defaults setObject:json forKey:@"form"];
        }
        
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:stringPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:[stringPath stringByDeletingLastPathComponent] withIntermediateDirectories:NO attributes:nil error:&error];
    
    [[NSFileManager defaultManager] createFileAtPath:stringPath contents:nil attributes:nil];
    operation.responseSerializer = [AFHTTPResponseSerializer serializer];
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:stringPath append:NO];
    return operation;
    
}

@end
