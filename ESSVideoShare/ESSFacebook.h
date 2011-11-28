//
//  ESSFacebook.h
//  FacebookMac
//
//  Created by Matthias Gansrigler on 29.10.11.
//  Copyright (c) 2011 Eternal Storms Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ESSFacebookWindowController.h"

#define ESSLocalizedString(key, comment) NSLocalizedStringFromTableInBundle((key),nil,[NSBundle bundleForClass:[self class]],(comment))

@class ESSFacebook;

@protocol ESSFacebookDelegate <NSObject>

@required
- (NSWindow *)ESSFacebookNeedsWindowToAttachTo:(ESSFacebook *)facebook;

@optional
- (void)ESSFacebookDidFinish:(ESSFacebook *)fb; //sent so user of this class can release their fb object

@end

@interface ESSFacebook : NSObject <ESSFacebookWindowControllerDelegate,NSURLConnectionDelegate>

@property (assign) id delegate;
@property (retain) NSURLConnection *_uploader;
@property (retain) NSString *appID;
@property (retain) NSString *appSecret;
@property (retain) NSString *_uploadedObjectID;
@property (retain) ESSFacebookWindowController *_fbWinCtr;
@property (retain) NSMutableData *_receivedData;

@property (retain) NSString *_accessToken;
@property (retain) NSString *_username;

- (id)initWithDelegate:(id)del
				 appID:(NSString *)anID
			 appSecret:(NSString *)secret;

- (void)uploadVideoAtURL:(NSURL *)videoURL;

//private
- (void)_authorize; //looks if we have a token in defaults. if so, use that. if not, open up authorize webview
- (void)_deauthorize;
- (void)_uploadVideoAtURL:(NSURL *)videoURL
					title:(NSString *)title
			  description:(NSString *)description
				isPrivate:(BOOL)isPrivate;

@end
