//
//  ESSFlickr.h
//  Zlidez
//
//  Created by Matthias Gansrigler on 07.11.11.
//  Copyright (c) 2011 Eternal Storms Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAuthConsumer.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
#import "ESSFlickrWindowController.h"
#else
#import "ESSFlickriOSViewController.h"
#endif

#define ESSLocalizedString(key, comment) NSLocalizedStringFromTableInBundle((key),nil,[NSBundle bundleForClass:[self class]],(comment))

@class ESSFlickr;

@protocol ESSFlickrDelegate <NSObject>

@required
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
- (NSWindow *)ESSFlickrNeedsWindowToAttachTo:(ESSFlickr *)flickr;
#else
- (UIViewController *)ESSFlickrNeedsViewController:(ESSFlickr *)flickr;
#endif
- (void)ESSFlickrDidFinish:(ESSFlickr *)flickr;

@end

#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
@interface ESSFlickr : NSObject <NSURLConnectionDelegate,ESSFlickrWindowControllerDelegate>
#else
@interface ESSFlickr : NSObject <NSURLConnectionDelegate,ESSFlickriOSViewControllerDelegate>
#endif

@property (assign) id delegate;
@property (retain) OAConsumer *_oaconsumer;
@property (retain) OAPlaintextSignatureProvider *_sigProv;
@property (retain) OAToken *_authToken;
@property (retain) OAToken *_requestToken;
#if (!TARGET_OS_IPHONE && !TARGET_OS_EMBEDDED && !TARGET_IPHONE_SIMULATOR)
@property (retain) ESSFlickrWindowController *_flWinCtr;
#else
@property (retain) ESSFlickriOSViewController *_viewCtr;
#endif
@property (retain) NSURLConnection *_uploader;
@property (retain) NSMutableData *_resultData;

- (id)initWithDelegate:(id)del
		applicationKey:(NSString *)key
	 applicationSecret:(NSString *)secret;

- (void)uploadVideoAtURL:(NSURL *)url;

#if (TARGET_OS_IPHONE || TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR)
- (void)handleOpenURL:(NSURL *)url;
#endif

//private
- (void)_authorize;

- (void)_deauthorize;

- (BOOL)_canUploadVideosKeyInvalidCheck:(BOOL *)keyInvalid errorConnecting:(BOOL *)errorConnecting;

- (NSString *)_unescapedString:(NSString *)aString;

- (void)_uploadVideoAtURL:(NSURL *)url
					title:(NSString *)title
			  description:(NSString *)description
					 tags:(NSString *)tags
			  makePrivate:(BOOL)makePrivate;

- (void)_checkPhotoID:(NSString *)photoID;

@end