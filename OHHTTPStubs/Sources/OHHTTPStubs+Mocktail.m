//
//  OHHTTPStubs+Mocktail.m
//  CardCompanion
//
//  Created by Wang, Sunny on 7/30/15.
//  Copyright (c) 2015 Capital One. All rights reserved.
//

#import "OHHTTPStubs+Mocktail.h"

@class OHHTTPStubsDescriptor;

@implementation OHHTTPStubs (Mocktail)


+(NSArray *)stubRequestsUsingMocktailsAt:(NSURL *)dirURL{
    //make sure path points to a directory
    BOOL isDir = NO, exists = NO;
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    exists = [fileManager fileExistsAtPath:dirURL.path isDirectory:&isDir];
    if(!dirURL || !exists){
        NSLog(@"Error opening %@: %@", dirURL.absoluteString, error);
        return nil;
    }
    
    //read the content of the directory
    NSArray *fileURLs = [fileManager contentsOfDirectoryAtURL:dirURL includingPropertiesForKeys:nil options:0 error:&error];
    if (error) {
        NSLog(@"Error opening %@: %@", dirURL.absoluteString, error);
        return nil;
    }
    
    //stub the Mocktail-formatted requests
    NSMutableArray *descriptorArray = [[NSMutableArray alloc] initWithCapacity:fileURLs.count];
    for (NSURL *fileURL in fileURLs) {
        if (![[fileURL absoluteString] hasSuffix:@".tail"]) {
            continue;
        }
        id<OHHTTPStubsDescriptor> descriptor = [[self class] stubRequestsUsingMocktail:fileURL];
        if(descriptor){
            [descriptorArray addObject:descriptor];
        }
    }
    
    return descriptorArray;
}

+(id<OHHTTPStubsDescriptor>)stubRequestsUsingMocktailNamed:(NSString *)fileName{
    NSString *path = OHPathForFile(fileName, [self class]);
    if(!path || ![[NSFileManager defaultManager] fileExistsAtPath:path]){
        NSLog(@"File not exists at:%@", path);
        return nil;
    } else {
        return [[self class] stubRequestsUsingMocktail:[NSURL fileURLWithPath:path]];
    }
}

+(id<OHHTTPStubsDescriptor>)stubRequestsUsingMocktail:(NSURL *)fileURL{
    NSError *error = nil;
    NSStringEncoding originalEncoding;
    NSString *contentsOfFile = [NSString stringWithContentsOfURL:fileURL usedEncoding:&originalEncoding error:&error];
    
    if (!contentsOfFile || error) {
        return nil;
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:contentsOfFile];
    NSString *headerMatter = nil;
    [scanner scanUpToString:@"\n\n" intoString:&headerMatter];
    NSArray *lines = [headerMatter componentsSeparatedByString:@"\n"];
    if ([lines count] < 4) {
        if (error) {
            error = [NSError errorWithDomain:@"Mocktail" code:0 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Invalid amount of lines: %u", (unsigned)[lines count]]}];
        }
        return nil;
    }
    
    /*handle Mocktail format, adapted from Mocktail implementation, for more details on the file format, check out: https://github.com/square/objc-Mocktail*/
    NSRegularExpression *methodRegex = [NSRegularExpression regularExpressionWithPattern:lines[0] options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSRegularExpression *absoluteURLRegex = [NSRegularExpression regularExpressionWithPattern:lines[1] options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSInteger statusCode = [lines[2] integerValue];
    
    NSMutableDictionary *headers = @{@"Content-Type":lines[3]}.mutableCopy;
    
    // From line 5 to '\n\n', expect HTTP response headers.
    NSRegularExpression *headerPattern = [NSRegularExpression regularExpressionWithPattern:@"^([^:]+):\\s+(.*)" options:0 error:NULL];
    for (NSUInteger line = 4; line < lines.count; line ++) {
        NSString *headerLine = lines[line];
        NSTextCheckingResult *match = [headerPattern firstMatchInString:headerLine options:0 range:NSMakeRange(0, headerLine.length)];
        
        if (match) {
            NSString *key = [headerLine substringWithRange:[match rangeAtIndex:1]];
            NSString *value = [headerLine substringWithRange:[match rangeAtIndex:2]];
            headers[key] = value;
        } else {
            if (error) {
                error = [NSError errorWithDomain:@"Mocktail" code:0 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Invalid header line: %@", headerLine]}];
            }
            return nil;
        }
    }
    
    return [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        NSString *absoluteURL = [request.URL absoluteString];
        NSString *method = request.HTTPMethod;
        
        if ([absoluteURLRegex numberOfMatchesInString:absoluteURL options:0 range:NSMakeRange(0, absoluteURL.length)] > 0) {
            if ([methodRegex numberOfMatchesInString:method options:0 range:NSMakeRange(0, method.length)] > 0) {
                return YES;
            }
        }
        
        return NO;
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        OHHTTPStubsResponse *response = [OHHTTPStubsResponse responseWithFileAtPath:fileURL.path
                                                                         statusCode:(int)statusCode headers:headers];
        response.bodyOffset = [headerMatter dataUsingEncoding:NSUTF8StringEncoding].length + 2;
        return response;
    }];
}

@end
