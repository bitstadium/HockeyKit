//
//  BWGlobal.h
//
//  Created by Andreas Linde on 08/17/10.
//  Copyright 2010-2011 Andreas Linde, Peter Steinberger. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "BWHockeyManager.h"
#import "BWApp.h"

#define HOCKEYKIT_VERSION_MAJOR 2
#define HOCKEYKIT_VERSION_MINOR 0

// uncomment this line to enable NSLog-debugging output
//#define kHockeyDebugEnabled

#define kArrayOfLastHockeyCheck		@"ArrayOfLastHockeyCheck"
#define kDateOfLastHockeyCheck		@"DateOfLastHockeyCheck"
#define kDateOfVersionInstallation	@"DateOfVersionInstallation"
#define kUsageTimeOfCurrentVersion	@"UsageTimeOfCurrentVersion"
#define kUsageTimeForVersionString	@"kUsageTimeForVersionString"
#define kHockeyAutoUpdateSetting	@"HockeyAutoUpdateSetting"
#define kHockeyAllowUserSetting		@"HockeyAllowUserSetting"
#define kHockeyAllowUsageSetting	@"HockeyAllowUsageSetting"
#define kHockeyAutoUpdateSetting	@"HockeyAutoUpdateSetting"
#define kHockeyAuthorizedVersion	@"HockeyAuthorizedVersion"
#define kHockeyAuthorizedToken		@"HockeyAuthorizedToken"

#define kHockeyBundleName @"Hockey.bundle"

// Notification message which HockeyManager is listening to, to retry requesting updated from the server
#define BWHockeyNetworkBecomeReachable @"NetworkDidBecomeReachable"


#ifdef kHockeyDebugEnabled
#define BWHockeyLog(fmt, ...) NSLog((@"[HockeyLib] %s/%d " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#define BWHockeyLog(...)
#endif

NSBundle *hockeyBundle(void);
NSString *BWmd5(NSString *str);

#define BWHockeyLocalize(StringToken) NSLocalizedStringFromTableInBundle(StringToken, @"Hockey", hockeyBundle(), @"")


// compatibility helper
#ifndef kCFCoreFoundationVersionNumber_iPhoneOS_3_2
#define kCFCoreFoundationVersionNumber_iPhoneOS_3_2 478.61
#endif
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 32000
#define IF_3_2_OR_GREATER(...) \
if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iPhoneOS_3_2) \
{ \
__VA_ARGS__ \
}
#else
#define IF_3_2_OR_GREATER(...)
#endif
#define IF_PRE_3_2(...) \
if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iPhoneOS_3_2) \
{ \
__VA_ARGS__ \
}

#ifndef kCFCoreFoundationVersionNumber_iPhoneOS_4_0
#define kCFCoreFoundationVersionNumber_iPhoneOS_4_0 550.32
#endif
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
#define IF_IOS4_OR_GREATER(...) \
if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iPhoneOS_4_0) \
{ \
__VA_ARGS__ \
}
#else
#define IF_IOS4_OR_GREATER(...)
#endif

#define IF_PRE_IOS4(...)  \
if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iPhoneOS_4_0)  \
{ \
__VA_ARGS__ \
}
