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
#import "ObservationFetchService.h"
#import "MageServer.h"

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

+ (NSOperation *) operationToPullFormWithManagedObjectContext: (NSManagedObjectContext *) context complete:(void (^) (BOOL success)) complete {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* formId = [defaults objectForKey: @"formId"];
    NSString *url = [NSString stringWithFormat:@"%@/%@/%@.zip", [MageServer baseURL], @"api/forms", formId];
    
    NSString *stringPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:@"/Form.zip"];
    
    NSString *folderToUnzipTo = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat: @"/form-%@", formId]];
    
    HttpManager *http = [HttpManager singleton];
    
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
        if ( [fileManager fileExistsAtPath:jsonFilePath] && error == nil)
        {
            NSString *jsonString = [[NSString alloc] initWithContentsOfFile:jsonFilePath encoding:NSUTF8StringEncoding error:NULL];
            NSError *error;
            
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
            json = AFJSONObjectByRemovingKeysWithNullValues(json, NSJSONReadingAllowFragments);

            [defaults setObject:json forKey:@"form"];
        }
        
        complete(YES);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        complete(NO);
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
