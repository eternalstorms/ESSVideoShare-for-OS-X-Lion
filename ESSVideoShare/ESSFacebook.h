//
//  ESSFacebook.h
//  FacebookMac
//
//  Created by Matthias Gansrigler on 29.10.11.
//  Copyright (c) 2011 Eternal Storms Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
#import "ESSFacebookWindowController.h"
#else
#import "ESSFacebookiOSViewController.h"
#endif

#define ESSLocalizedString(key, comment) NSLocalizedStringFromTableInBundle((key),nil,[NSBundle bundleForClass:[self class]],(comment))

@class ESSFacebook;

@protocol ESSFacebookDelegate <NSObject>

@required
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
- (NSWindow *)ESSFacebookNeedsWindowToAttachTo:(ESSFacebook *)facebook;
#else
- (UIViewController *)ESSFacebookNeedsCurrentViewControllerToAttachTo:(ESSFacebook *)facebook;
#endif

@optional
- (void)ESSFacebookDidUploadVideoWithFacebookURL:(NSURL *)url;
- (void)ESSFacebookDidFinish:(ESSFacebook *)fb; //sent so user of this class can release their fb object

@end

#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
@interface ESSFacebook : NSObject <ESSFacebookWindowControllerDelegate,NSURLConnectionDelegate>
#else
@interface ESSFacebook : NSObject <ESSFacebookiOSViewControllerDelegate,NSURLConnectionDelegate>
#endif

@property (assign) id delegate;
@property (retain) NSURLConnection *_uploader;
@property (retain) NSString *appID;
@property (retain) NSString *appSecret;
@property (retain) NSString *_uploadedObjectID;
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
@property (retain) ESSFacebookWindowController *_fbWinCtr;
#else
@property (retain) ESSFacebookiOSViewController *_fbViewCtr;
#endif
@property (retain) NSMutableData *_receivedData;

@property (retain) NSString *_accessToken;
@property (retain) NSString *_username;

- (id)initWithDelegate:(id)del
				 appID:(NSString *)anID
			 appSecret:(NSString *)secret;

- (void)uploadVideoAtURL:(NSURL *)videoURL;

//private
- (void)_authorize; //checks if we have a token in defaults. if so, use that. if not, open up authorize webview
- (void)_deauthorize;
- (void)_uploadVideoAtURL:(NSURL *)videoURL
					title:(NSString *)title
			  description:(NSString *)description
				isPrivate:(BOOL)isPrivate;

@end
