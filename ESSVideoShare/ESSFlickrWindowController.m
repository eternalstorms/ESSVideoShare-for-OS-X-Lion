//
//  ESSFlickrWindowController.m
//  Zlidez
//
//  Created by Matthias Gansrigler on 07.11.11.
//  Copyright (c) 2011 Eternal Storms Software. All rights reserved.
//

#import "ESSFlickrWindowController.h"
#import "ESSFlickr.h"

@implementation ESSFlickrWindowController
@synthesize loginView;
@synthesize authorizeButton;
@synthesize loginProgInd;
@synthesize loginStatusField;
@synthesize uploadView;
@synthesize usernameField;
@synthesize descriptionField;
@synthesize tagsField;
@synthesize privateButton;
@synthesize titleField;
@synthesize uploadProgressView;
@synthesize uploadProgressBar;
@synthesize uploadStatusField;
@synthesize uploadProgressCancelButton;
@synthesize doneView;
@synthesize doneImageView;
@synthesize doneStatusField;
@synthesize viewOnFlickrButton,videoURL,delegate;

- (id)initWithDelegate:(id)del videoURL:(NSURL *)url
{
	if (self = [super initWithWindowNibName:@"ESSFlickrWindow"])
	{
		self.delegate = del;
		self.videoURL = url;
		
		return self;
	}
	
	return nil;
}

- (void)switchToAuthorizeViewWithAnimation:(BOOL)shouldAnimate
{
	[self.uploadView removeFromSuperview];
	[self.loginView setFrameOrigin:NSZeroPoint];
	
	[self.loginProgInd stopAnimation:self];
	[self.loginProgInd setHidden:YES];
	[self.loginStatusField setHidden:YES];
	[self.authorizeButton setHidden:NO];
	[self.authorizeButton setEnabled:YES];
	[self.authorizeButton setAlphaValue:1.0];
	
	if (!shouldAnimate)
	{		
		[self.window setContentSize:NSMakeSize(self.loginView.frame.size.width, self.loginView.frame.size.height+38)];
		[self.window.contentView addSubview:self.loginView];
	} else
	{
		[self.window setFrame:NSMakeRect(self.window.frame.origin.x, self.window.frame.origin.y, self.loginView.frame.size.width, self.loginView.frame.size.height+38) display:YES animate:YES];
		[self.loginView setAlphaValue:0.0];
		[self.window.contentView addSubview:self.loginView];
		[self.loginView.animator setAlphaValue:1.0];
	}
}

- (void)switchToUploadViewWithAnimation:(BOOL)shouldAnimate
{
	[self.loginView removeFromSuperview];
	[self.uploadView setFrameOrigin:NSZeroPoint];
	
	if (self.titleField.stringValue.length == 0)
		self.titleField.stringValue = ESSLocalizedString(@"ESSFlickrDefaultTitle", nil);
	
	if (!shouldAnimate)
	{
		[self.window setContentSize:NSMakeSize(self.uploadView.frame.size.width, self.uploadView.frame.size.height+38)];
		[self.window.contentView addSubview:self.uploadView];
	} else
	{
		[self.window setFrame:NSMakeRect(self.window.frame.origin.x, self.window.frame.origin.y, self.uploadView.frame.size.width, self.uploadView.frame.size.height+38) display:YES animate:YES];
		[self.uploadView setAlphaValue:0.0];
		[self.window.contentView addSubview:self.uploadView];
		[self.uploadView.animator setAlphaValue:1.0];
	}
}

- (IBAction)authorize:(id)sender
{
	[(ESSFlickr *)self.delegate _authorize];
	
	//show authstatusfield,authstatusprogind, hide auth button
	[sender setEnabled:NO];
	[((NSButton *)sender).animator setAlphaValue:0.0];
	
	[self.loginProgInd setAlphaValue:0.0];
	[self.loginStatusField setAlphaValue:0.0];
	[self.loginProgInd startAnimation:self];
	[self.loginProgInd setHidden:NO];
	[self.loginStatusField setHidden:NO];
	[self.loginProgInd.animator setAlphaValue:1.0];
	[self.loginStatusField.animator setAlphaValue:1.0];
}

- (IBAction)cancel:(id)sender
{
	[sender setEnabled:NO];
	if (self.window.parentWindow != nil)
		[NSApp endSheet:self.window];
	[self.window orderOut:nil];
	
	double delayInSeconds = 0.55;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[self.delegate flickrWindowDidCancel:self];
	});
}

- (IBAction)changeAccount:(id)sender
{
	[(ESSFlickr *)self.delegate _deauthorize];
	[self switchToAuthorizeViewWithAnimation:YES];
}

- (IBAction)startUpload:(id)sender
{
	//switch to upload view
	[self.uploadView removeFromSuperview];
	[self.uploadProgressBar setIndeterminate:YES];
	[self.uploadProgressBar startAnimation:nil];
	self.uploadStatusField.stringValue = ESSLocalizedString(@"ESSFlickrInitializingUpload",nil);

	[self.uploadProgressView setFrameOrigin:NSZeroPoint];
	[self.window setFrame:NSMakeRect(self.window.frame.origin.x, self.window.frame.origin.y, self.uploadProgressView.frame.size.width, self.uploadProgressView.frame.size.height+38) display:YES animate:YES];
	self.uploadProgressView.alphaValue = 0.0;
	[self.window.contentView addSubview:self.uploadProgressView];
	[self.uploadProgressView.animator setAlphaValue:1.0];
	
	//start upload
	NSString *title = self.titleField.stringValue;
	if (title == nil)
		title = @"";
	NSString *descr = self.descriptionField.stringValue;
	if (descr == nil)
		descr = @"";
	NSString *tags = self.tagsField.stringValue;
	if (tags == nil)
		tags = @"";
	
	[((ESSFlickr *)self.delegate) _uploadVideoAtURL:self.videoURL
											  title:title
										description:descr
											   tags:tags
										makePrivate:(self.privateButton.state == NSOnState)];
	
}

- (void)uploadUpdatedWithBytes:(NSUInteger)bytesLoaded ofTotal:(NSUInteger)totalBytes
{
	[self.uploadProgressBar setIndeterminate:NO];
	[self.uploadProgressBar startAnimation:nil];
	self.uploadProgressBar.minValue = 0;
	self.uploadProgressBar.maxValue = totalBytes;
	self.uploadProgressBar.doubleValue = bytesLoaded;
	
	double percentDone = bytesLoaded*100/totalBytes;
	percentDone = round(percentDone);
	
	self.uploadStatusField.stringValue = [NSString stringWithFormat:ESSLocalizedString(@"ESSFlickrUploadPercentageDone",nil),(NSUInteger)percentDone]; //@"%ld%% uploaded
	
	if (bytesLoaded == totalBytes)
	{
		[self.uploadProgressBar setIndeterminate:YES];
		[self.uploadProgressBar startAnimation:nil];
		[self.uploadProgressCancelButton setEnabled:NO];
		self.uploadStatusField.stringValue = ESSLocalizedString(@"ESSFlickrWaitingForFlickrToProcessVideo",nil);
	}
}

- (void)uploadFinishedWithFlickrURL:(NSURL *)url success:(BOOL)success
{
	if (url != nil)
	{
		[self.viewOnFlickrButton setHidden:NO];
		self.viewOnFlickrButton.alternateTitle = [url absoluteString];
	} else
		[self.viewOnFlickrButton setHidden:YES];
	
	NSString *statusString = nil;
	NSImage *image = nil;
	if (success)
	{
		//show success image and status text
		statusString = ESSLocalizedString(@"ESSFlickrUploadSucceeded", nil);
		NSString *imgPath = @"/System/Library/CoreServices/Installer.app/Contents/PlugIns/Summary.bundle/Contents/Resources/Success.png";
		image = [[[NSImage alloc] initWithContentsOfFile:imgPath] autorelease];
	} else
	{
		//show fail image and status text
		statusString = ESSLocalizedString(@"ESSFlickrUploadFailed", nil);
		NSString *imgPath = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns";
		image = [[[NSImage alloc] initWithContentsOfFile:imgPath] autorelease];
	}
	
	self.doneImageView.image = image;
	self.doneStatusField.stringValue = statusString;
	
	[self.uploadProgressView removeFromSuperview];
	[self.doneView setFrameOrigin:NSZeroPoint];
	[self.window setFrame:NSMakeRect(self.window.frame.origin.x, self.window.frame.origin.y, self.doneView.frame.size.width, self.doneView.frame.size.height+38) display:YES animate:YES];
	self.doneView.alphaValue = 0.0;
	[self.window.contentView addSubview:self.doneView];
	[self.doneView.animator setAlphaValue:1.0];
}

- (IBAction)viewOnFlickr:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:self.viewOnFlickrButton.alternateTitle]];
}

- (IBAction)done:(id)sender
{
	[self cancel:sender];
}

- (void)dealloc
{
	self.delegate = nil;
	self.videoURL = nil;
	self.loginView = nil;
	self.uploadView = nil;
	
	[super dealloc];
}
@end
