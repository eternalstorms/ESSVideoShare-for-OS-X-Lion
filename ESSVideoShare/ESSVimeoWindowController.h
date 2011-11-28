//
//  ESSVimeoWindowController.h
//  Zlidez
//
//  Created by Matthias Gansrigler on 21.11.11.
//  Copyright (c) 2011 Eternal Storms Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ESSVimeoWindowController;

@protocol ESSVimeoWindowDelegate <NSObject>

@required
- (void)vimeoWindowIsFinished:(ESSVimeoWindowController *)ctr;

@end

@interface ESSVimeoWindowController : NSWindowController

@property (assign) id delegate;
@property (retain) NSURL *videoURL;

- (id)initWithVideoURL:(NSURL *)url delegate:(id)del;

@property (retain) IBOutlet NSView *loginView;
@property (assign) IBOutlet NSTextField *loginStatusField;
@property (assign) IBOutlet NSProgressIndicator *loginStatusProgressIndicator;
@property (assign) IBOutlet NSButton *authorizeButton;
- (IBAction)authorize:(id)sender;
- (IBAction)cancelAuthorization:(id)sender;

@property (retain) IBOutlet NSView *uploadView;
@property (assign) IBOutlet NSTextField *usernameField;
@property (assign) IBOutlet NSTextField *titleField;
@property (assign) IBOutlet NSTextField *descriptionField;
@property (assign) IBOutlet NSTokenField *tagsField;
@property (assign) IBOutlet NSButton *makePrivateButton;
- (IBAction)cancelBeforeUpload:(id)sender;
- (IBAction)startUpload:(id)sender;
- (IBAction)changeAccount:(id)sender;

@property (assign) IBOutlet NSView *noUploadSpaceView;
@property (assign) IBOutlet NSImageView *noSpaceImageView;
@property (assign) IBOutlet NSTextField *noSpaceStatusField;
- (IBAction)cancelNoSpace:(id)sender;

@property (retain) IBOutlet NSView *licenseView;
- (IBAction)cancelLicense:(id)sender;
- (IBAction)backToUploadView:(id)sender;
- (IBAction)uploadNow:(id)sender;

@property (assign) IBOutlet NSView *uploadProgressView;
@property (assign) IBOutlet NSProgressIndicator *uploadProgressBar;
@property (assign) IBOutlet NSTextField *uploadStatusField;
@property (assign) IBOutlet NSButton *cancelUploadButton;
- (IBAction)cancelDuringUpload:(id)sender;

@property (assign) IBOutlet NSView *doneView;
@property (assign) IBOutlet NSImageView *doneImageView;
@property (assign) IBOutlet NSTextField *doneField;
@property (assign) IBOutlet NSButton *viewOnVimeoButton;
- (IBAction)viewOnVimeo:(id)sender;
- (IBAction)done:(id)sender;

- (void)switchToLoginViewWithAnimation:(BOOL)shouldAnimate;
- (void)switchToUploadViewWithAnimation:(BOOL)shouldAnimate;

- (void)showNoSpaceLeftWarning;
- (void)showNoPlusAccountWarning;

- (void)uploadUpdatedWithBytes:(NSUInteger)uploaded ofTotal:(NSUInteger)total;
- (void)uploadFinishedWithURL:(NSURL *)vimeoURL;

@end
