//
//  ESSYouTubeWindowController.h
//  Zlidez
//
//  Created by Matthias Gansrigler on 04.11.11.
//  Copyright (c) 2011 Eternal Storms Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ESSYouTubeWindowController;

@protocol ESSYouTubeWindowControllerDelegate <NSObject>

@required
- (void)youtubeWindowControllerDidDismiss:(ESSYouTubeWindowController *)ytWCtr;

@end

@interface ESSYouTubeWindowController : NSWindowController

@property (assign) id delegate;
@property (retain) NSURL *videoURL;

@property (retain) IBOutlet NSView *loginView;
@property (assign) IBOutlet NSTextField *usernameField;
@property (assign) IBOutlet NSSecureTextField *passwordField;
@property (assign) IBOutlet NSButton *signInButton;
@property (assign) IBOutlet NSTextField *signingInStatusField;
@property (assign) IBOutlet NSProgressIndicator *signingInProgWheel;
@property (assign) IBOutlet NSButton *loginCancelButton;

@property (retain) IBOutlet NSView *uploadView;
@property (assign) IBOutlet NSTextField *uploadUsernameField;
@property (assign) IBOutlet NSPopUpButton *categoryPopUpButton;
@property (assign) IBOutlet NSTextField *titleField;
@property (assign) IBOutlet NSTextField *descriptionField;
@property (assign) IBOutlet NSTokenField *tagsTokenField;
@property (assign) IBOutlet NSButton *makePrivateButton;
@property (assign) IBOutlet NSButton *uploadNextButton;

@property (retain) IBOutlet NSView *licenseView;
@property (assign) IBOutlet NSTextView *licenseTextView;

@property (retain) IBOutlet NSView *uploadProgressView;
@property (assign) IBOutlet NSProgressIndicator *uploadProgressBar;
@property (assign) IBOutlet NSTextField *uploadStatusField;
@property (assign) IBOutlet NSButton *duringUploadCancelButton;

@property (retain) IBOutlet NSView *doneView;
@property (assign) IBOutlet NSImageView *doneImageView;
@property (assign) IBOutlet NSTextField *doneStatusField;
@property (assign) IBOutlet NSButton *viewOnYouTubeButton;

- (id)initWithDelegate:(id)del videoURL:(NSURL *)url;

- (void)switchToLoginWithAnimation:(BOOL)shouldAnimate; //show username and password prompt
- (void)switchToUploadWithAnimation:(BOOL)shouldAnimate; //show title,description etc. prompt

- (void)uploadStarted; //show progress prompt
- (void)uploadUpdatedWithUploadedBytes:(NSInteger)uploadedBytes ofTotalBytes:(NSInteger)totalBytes;
- (void)uploadFinishedWithYouTubeVideoURL:(NSURL *)url; //loop while checking for processing of file. if processing on yt is done, switch to done-View with either success or failure notice

- (IBAction)cancelLoginOrBeforeUpload:(id)sender;
- (IBAction)cancelDuringUpload:(id)sender;
- (IBAction)back:(id)sender; //if license, show upload, if upload show login
- (IBAction)next:(id)sender; //if login show upload, if upload show license, if license start upload
- (IBAction)startUpload:(id)sender;
- (IBAction)viewOnYouTube:(id)sender;

- (void)setupCategoriesPopUpButtonWithCategoriesDictionary:(NSDictionary *)catDict;

@end
