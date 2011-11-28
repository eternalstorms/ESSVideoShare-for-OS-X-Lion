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
#import "ESSFlickrWindowController.h"

#define ESSLocalizedString(key, comment) NSLocalizedStringFromTableInBundle((key),nil,[NSBundle bundleForClass:[self class]],(comment))

@class ESSFlickr;

@protocol ESSFlickrDelegate <NSObject>

@required
- (NSWindow *)ESSFlickrNeedsWindowToAttachTo:(ESSFlickr *)flickr;
- (void)ESSFlickrDidFinish:(ESSFlickr *)flickr;

@end

@interface ESSFlickr : NSObject <NSURLConnectionDelegate,ESSFlickrWindowControllerDelegate>

@property (assign) id delegate;
@property (retain) OAConsumer *_oaconsumer;
@property (retain) OAPlaintextSignatureProvider *_sigProv;
@property (retain) OAToken *_authToken;
@property (retain) OAToken *_requestToken;
@property (retain) ESSFlickrWindowController *_flWinCtr;
@property (retain) NSURLConnection *_uploader;
@property (retain) NSMutableData *_resultData;

- (id)initWithDelegate:(id)del
		applicationKey:(NSString *)key
	 applicationSecret:(NSString *)secret;

- (void)uploadVideoAtURL:(NSURL *)url;

//private
- (void)_authorize;

- (void)_deauthorize;

- (BOOL)_canUploadVideosKeyInvalidCheck:(BOOL *)keyInvalid;

- (NSString *)_unescapedString:(NSString *)aString;

- (void)_uploadVideoAtURL:(NSURL *)url
					title:(NSString *)title
			  description:(NSString *)description
					 tags:(NSString *)tags
			  makePrivate:(BOOL)makePrivate;

- (void)_checkPhotoID:(NSString *)photoID;

@end