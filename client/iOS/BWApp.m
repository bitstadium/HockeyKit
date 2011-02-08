//
//  BWApp.m
//  HockeyDemo
//
//  Created by Peter Steinberger on 04.02.11.
//  Copyright 2011 Buzzworks. All rights reserved.
//

#import "BWApp.h"
#import "BWGlobal.h"

@implementation BWApp

@synthesize name = name_;
@synthesize version = version_;
@synthesize shortVersion = shortVersion_;
@synthesize notes = notes_;
@synthesize date = date_;
@synthesize size = size_;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark static

+ (BWApp *)appFromDict:(NSDictionary *)dict {
    BWApp *app = [[[[self class] alloc] init] autorelease];

//    NSParameterAssert([dict isKindOfClass:[NSDictionary class]]);
    if ([dict isKindOfClass:[NSDictionary class]]) {
        app.name = [dict objectForKey:@"title"];
        app.version = [dict objectForKey:@"version"];
        app.shortVersion = [dict objectForKey:@"shortversion"];
        [app setDateWithTimestamp:[[dict objectForKey:@"timestamp"] doubleValue]];
        app.size = [dict objectForKey:@"appsize"];
        app.notes = [dict objectForKey:@"notes"];
    }

    return app;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSObject

- (void)dealloc {
    [name_ release];
    [version_ release];
    [shortVersion_ release];
    [notes_ release];
    [date_ release];
    [size_ release];

    [super dealloc];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSCoder

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.version forKey:@"version"];
    [encoder encodeObject:self.shortVersion forKey:@"shortVersion"];
    [encoder encodeObject:self.notes forKey:@"notes"];
    [encoder encodeObject:self.date forKey:@"date"];
    [encoder encodeObject:self.size forKey:@"size"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super init])) {
        self.name = [decoder decodeObjectForKey:@"name"];
        self.version = [decoder decodeObjectForKey:@"version"];
        self.shortVersion = [decoder decodeObjectForKey:@"shortVersion"];
        self.notes = [decoder decodeObjectForKey:@"notes"];
        self.date = [decoder decodeObjectForKey:@"date"];
        self.size = [decoder decodeObjectForKey:@"size"];
    }
    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Properties

- (NSString *)versionString {
    NSString *shortString = self.shortVersion ? [NSString stringWithFormat:@"%@ ", self.shortVersion] : @"";
    NSString *versionString = [shortString length] ? [NSString stringWithFormat:@"(%@)", self.version] : self.version;
    return [NSString stringWithFormat:@"%@ %@%@", BWLocalize(@"HockeyVersion"), shortString, versionString];
}

- (NSString *)dateString {
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateStyle:NSDateFormatterMediumStyle];

    return [formatter stringFromDate:self.date];
}

- (NSString *)sizeInMB {
    if ([size_ doubleValue]) {
        double appSizeInMB = [size_ doubleValue]/(1024*1024);
        NSString *appSizeString = [NSString stringWithFormat:@"%.1f MB", appSizeInMB];
        return appSizeString;
    }

    return nil;
}

- (void)setDateWithTimestamp:(NSTimeInterval)timestamp {
    if (timestamp) {
        NSDate *appDate = [NSDate dateWithTimeIntervalSince1970:timestamp];
        self.date = appDate;
    } else {
        self.date = nil;
    }
}

// a valid app needs at least following properties: name, version, date
- (BOOL)isValid {
    BOOL valid = [self.name length] && [self.version length] && [self.notes length];
    return valid;
}

@end
