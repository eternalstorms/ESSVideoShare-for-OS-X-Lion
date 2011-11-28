//
//  ESSFlickrWindowController.h
//  Zlidez
//
//  Created by Matthias Gansrigler on 07.11.11.
//  Copyright (c) 2011 Eternal Storms Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ESSFlickrWindowController;

@protocol ESSFlickrWindowControllerDelegate <NSObject>

@required
- (void)flickrWindowDidCancel:(ESSFlickrWindowController *)flickrWinCtr;

@end

@interface ESSFlickrWindowController : NSWindowController

@property (retain) NSURL *videoURL;
@property (assign) id delegate;

@property (retain) IBOutlet NSView *loginView;
@property (assign) IBOutlet NSButton *authorizeButton;
@property (assign) IBOutlet NSProgressIndicator *loginProgInd;
@property (assign) IBOutlet NSTextField *loginStatusField;

@property (retain) IBOutlet NSView *uploadView;
@property (assign) IBOutlet NSTextField *usernameField;
@property (assign) IBOutlet NSTextField *descriptionField;
@property (assign) IBOutlet NSTokenField *tagsField;
@property (assign) IBOutlet NSButton *privateButton;
@property (assign) IBOutlet NSTextField *titleField;

@property (assign) IBOutlet NSView *uploadProgressView;
@property (assign) IBOutlet NSProgressIndicator *uploadProgressBar;
@property (assign) IBOutlet NSTextField *uploadStatusField;
@property (assign) IBOutlet NSButton *uploadProgressCancelButton;

@property (assign) IBOutlet NSView *doneView;
@property (assign) IBOutlet NSImageView *doneImageView;
@property (assign) IBOutlet NSTextField *doneStatusField;
@property (assign) IBOutlet NSButton *viewOnFlickrButton;

- (id)initWithDelegate:(id)del videoURL:(NSURL *)url;

- (void)switchToAuthorizeViewWithAnimation:(BOOL)shouldAnimate;
- (void)switchToUploadViewWithAnimation:(BOOL)shouldAnimate;

- (IBAction)authorize:(id)sender;
- (IBAction)cancel:(id)sender;

- (IBAction)changeAccount:(id)sender;
- (IBAction)startUpload:(id)sender;

- (IBAction)viewOnFlickr:(id)sender;
- (IBAction)done:(id)sender;

- (void)uploadUpdatedWithBytes:(NSUInteger)bytesLoaded ofTotal:(NSUInteger)totalBytes;
- (void)uploadFinishedWithFlickrURL:(NSURL *)url success:(BOOL)success;
@end
