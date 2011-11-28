//
//  ESSFacebookLoginWindowController.h
//  FacebookMac
//
//  Created by Matthias Gansrigler on 29.10.11.
//  Copyright (c) 2011 Eternal Storms Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class ESSFacebookWindowController;

@protocol ESSFacebookWindowControllerDelegate <NSObject>

@required
- (void)facebookLogin:(ESSFacebookWindowController *)login returnedAccessToken:(NSString *)token expirationDate:(NSDate *)expDate;

@end

@interface ESSFacebookWindowController : NSWindowController

@property (retain) IBOutlet WebView *webView;
@property (assign) IBOutlet NSButton *uploadButton;
@property (retain) IBOutlet NSView *uploadView;
@property (assign) IBOutlet NSTextField *usernameField;
@property (assign) IBOutlet NSTextField *titleField;
@property (assign) IBOutlet NSTextField *descriptionField;
@property (assign) IBOutlet NSButton *makePrivateButton;
@property (assign) IBOutlet NSProgressIndicator *uploadProgressBar;
@property (assign) IBOutlet NSTextField *uploadProgressField;
@property (assign) IBOutlet NSView *uploadProgressView;
@property (assign) IBOutlet NSView *uploadResultView;
@property (assign) IBOutlet NSImageView *resultImageView;
@property (assign) IBOutlet NSTextField *resultTextField;
@property (assign) IBOutlet NSButton *cancelButton;
@property (assign) IBOutlet NSButton *viewOnFBButton;

@property (assign) id delegate;
@property (assign) BOOL reactToCancel;
@property (retain) NSString *appID;
@property (retain) NSMutableArray *temporaryCookies;
@property (retain) NSURL *videoURL;

- (id)initWithDelegate:(id)del appID:(NSString *)appIDString videoURL:(NSURL *)url;

- (void)openAuthorizationURLWithAppID:(NSString *)anID;

- (void)switchToUploadViewWithAnimation:(BOOL)shouldAnimate;
- (void)switchToLoginViewWithAnimation:(BOOL)shouldAnimate;

- (IBAction)cancel:(id)sender;
- (IBAction)changeAccount:(id)sender;
- (IBAction)startUpload:(id)sender;
- (IBAction)viewOnFacebook:(id)sender;

- (void)temporarilyDeleteFacebookCookies;
- (void)restoreTemporarilyDeletedFacebookCookies;

- (void)uploadStarted;
- (void)uploadUpdatedWithBytes:(NSInteger)bytesUploaded ofTotalBytes:(NSInteger)totalBytes;
- (void)uploadFinishedWithFacebookVideoURL:(NSURL *)url;

@end
