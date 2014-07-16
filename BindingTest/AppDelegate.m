//
//  AppDelegate.m
//  BindingTest
//
//  Created by m0a on 2014/07/15.
//  Copyright (c) 2014年 m0a. All rights reserved.
//


#import "AppDelegate.h"
#import <RestKit/RestKit.h>
#import "RKTUser.h"
#import "RKTweet.h"

@interface AppDelegate()
@property (weak) IBOutlet NSArrayController *statuses;
@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    RKLogConfigureByName("RestKit/Network*", RKLogLevelTrace);
    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);
    
    // Initialize HTTPClient
    NSURL *baseURL = [NSURL URLWithString:@"https://twitter.com"];
    AFHTTPClient* client = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    
    // HACK: Set User-Agent to Mac OS X so that Twitter will let us access the Timeline
    [client setDefaultHeader:@"User-Agent" value:[NSString stringWithFormat:@"%@/%@ (Mac OS X %@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] ?: [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey], [[NSProcessInfo processInfo] operatingSystemVersionString]]];
    
    //we want to work with JSON-Data
    [client setDefaultHeader:@"Accept" value:RKMIMETypeJSON];
    
    // Initialize RestKit
    RKObjectManager *objectManager = [[RKObjectManager alloc] initWithHTTPClient:client];
    
    // Setup our object mappings
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{
                                                      @"id" : @"userID",
                                                      @"screen_name" : @"screenName",
                                                      @"name" : @"name"
                                                      }];
    
    RKObjectMapping *statusMapping = [RKObjectMapping mappingForClass:[RKTweet class]];
    [statusMapping addAttributeMappingsFromDictionary:@{
                                                        @"id" : @"statusID",
                                                        @"created_at" : @"createdAt",
                                                        @"text" : @"text",
                                                        @"url" : @"urlString",
                                                        @"in_reply_to_screen_name" : @"inReplyToScreenName",
                                                        @"favorited" : @"isFavorited",
                                                        }];
    RKRelationshipMapping* relationShipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"user"
                                                                                             toKeyPath:@"user"
                                                                                           withMapping:userMapping];
    [statusMapping addPropertyMapping:relationShipMapping];
    
    // Update date format so that we can parse Twitter dates properly
    // Wed Sep 29 15:31:08 +0000 2010
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"E MMM d HH:mm:ss Z y";
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    [[RKValueTransformer defaultValueTransformer] insertValueTransformer:dateFormatter atIndex:0];
    
    // Register our mappings with the provider using a response descriptor
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:statusMapping
                                                                                            method:RKRequestMethodGET
                                                                                       pathPattern:@"/status/user_timeline/:username"
                                                                                           keyPath:nil
                                                                                       statusCodes:[NSIndexSet indexSetWithIndex:200]];
    [objectManager addResponseDescriptor:responseDescriptor];
    [self loadTimeline];
    
}

- (void)loadTimeline
{
    // Load the object model via RestKit
    RKObjectManager *objectManager = [RKObjectManager sharedManager];
    
    [objectManager getObjectsAtPath:@"/status/user_timeline/RestKit"
                         parameters:nil
                            success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                NSArray* statuses = [mappingResult array];
                                [self.statuses addObjects:statuses]; //ここで追加していくだけでTableに反映される
                            }
                            failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                NSLog(@"Hit error: %@", error);
                            }];
}
@end
