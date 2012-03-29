//
//  ESSYouTube.h
//  Zlidez
//
//  Created by Matthias Gansrigler on 04.11.11.
//  Copyright (c) 2011 Eternal Storms Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
#import "ESSYouTubeWindowController.h"
#else
#import "ESSYouTubeiOSViewController.h"
#endif

#define ESSLocalizedString(key, comment) NSLocalizedStringFromTableInBundle((key),nil,[NSBundle bundleForClass:[self class]],(comment))

@class ESSYouTube;

@protocol ESSYouTubeDelegate <NSObject>

@required
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
- (NSWindow *)ESSYouTubeNeedsWindowToAttachTo:(ESSYouTube *)youtube;
#else
- (UIViewController *)ESSYouTubeNeedsCurrentViewControllerToAttachTo:(ESSYouTube *)youtube;
#endif
- (void)ESSYouTubeDidFinish:(ESSYouTube *)youtube;

@end

#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
@interface ESSYouTube : NSObject <NSURLConnectionDelegate,ESSYouTubeWindowControllerDelegate>
#else
@interface ESSYouTube : NSObject <NSURLConnectionDelegate,ESSYouTubeiOSViewControllerDelegate>
#endif

@property (assign) id delegate;
@property (retain) NSString *developerKey;
@property (retain) NSString *_authToken;
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
@property (retain) ESSYouTubeWindowController *_ytWinCtr;
#else
@property (retain) ESSYouTubeiOSViewController *_ytViewCtr;
#endif
@property (retain) NSURLConnection *_uploader;
@property (retain) NSMutableData *_receivedData;

- (id)initWithDelegate:(id)del
		  developerKey:(NSString *)key;

- (void)uploadVideoAtURL:(NSURL *)url;

//private
- (void)_authorize; //checks if we have a token saved. if so, skip ahead to upload view of windowcontroller. if not, present user with login in windowcontroller.

- (void)_authorizeWithUsername:(NSString *)username
					  password:(NSString *)password; //does the actual authorization

- (void)_deauthorize; //removes authorization token from userdefaults

- (NSString *)_nameForLoggedInUser;

- (void)_uploadVideoAtURL:(NSURL *)url
				withTitle:(NSString *)title
			  description:(NSString *)description
			  makePrivate:(BOOL)makePrivate
				 keywords:(NSString *)keywords
				 category:(NSString *)category;

- (BOOL)_videoUploadWithID:(NSString *)videoID
	   isFinishedWithError:(BOOL *)uploadFailed;

- (NSDictionary *)_categoriesDictionary;
- (void)_checkProcessingOnYouTubeWithVideoID:(NSString *)vidID;

@end
