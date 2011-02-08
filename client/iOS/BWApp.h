//
//  BWApp.h
//  HockeyDemo
//
//  Created by Peter Steinberger on 04.02.11.
//  Copyright 2011 Buzzworks. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BWApp : NSObject {
  NSString *name_;
  NSString *version_;
  NSString *shortVersion_;
  NSString *notes_;
  NSDate *date_;
  NSNumber *size_;
}
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *shortVersion;
@property (nonatomic, copy) NSString *notes;
@property (nonatomic, copy) NSDate *date;
@property (nonatomic, copy) NSNumber *size;

- (NSString *)versionString;
- (NSString *)dateString;
- (NSString *)sizeInMB;
- (void)setDateWithTimestamp:(NSTimeInterval)timestamp;
- (BOOL)isValid;

+ (BWApp *)appFromDict:(NSDictionary *)dict;

@end
