//
//  ESSYouTubeWindowController.m
//  Zlidez
//
//  Created by Matthias Gansrigler on 04.11.11.
//  Copyright (c) 2011 Eternal Storms Software. All rights reserved.
//

#import "ESSYouTubeWindowController.h"
#import "ESSYouTube.h"

@implementation ESSYouTubeWindowController
@synthesize loginView;
@synthesize usernameField;
@synthesize passwordField;
@synthesize signInButton;
@synthesize signingInStatusField;
@synthesize signingInProgWheel;
@synthesize loginCancelButton;
@synthesize uploadView;
@synthesize uploadUsernameField;
@synthesize categoryPopUpButton;
@synthesize titleField;
@synthesize descriptionField;
@synthesize tagsTokenField;
@synthesize makePrivateButton;
@synthesize uploadNextButton;
@synthesize licenseView;
@synthesize licenseTextView;
@synthesize uploadProgressView;
@synthesize uploadProgressBar;
@synthesize uploadStatusField;
@synthesize duringUploadCancelButton;
@synthesize doneView;
@synthesize doneImageView;
@synthesize doneStatusField;
@synthesize viewOnYouTubeButton;

@synthesize delegate,videoURL;

- (id)initWithDelegate:(id)del videoURL:(NSURL *)url
{
	if (self = [super initWithWindowNibName:@"ESSYouTubeWindow"])
	{
		self.delegate = del;
		self.videoURL = url;
		
		return self;
	}
	
	return nil;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)setupCategoriesPopUpButtonWithCategoriesDictionary:(NSDictionary *)catDict
{
	NSMenu *men = self.categoryPopUpButton.menu;
	[men removeAllItems];
	NSArray *arr = [[catDict allKeys] sortedArrayUsingSelector:@selector(compare:)];
	for (NSString *key in arr)
	{
		NSMenuItem *it = [[NSMenuItem alloc] initWithTitle:key action:nil keyEquivalent:@""];
		[it setRepresentedObject:[catDict objectForKey:key]];
		[men addItem:it];
		[it release];
	}
	[self.uploadNextButton setEnabled:YES];
}

- (void)switchToLoginWithAnimation:(BOOL)shouldAnimate //show username and password prompt
{
	[self.uploadView removeFromSuperview];
	
	self.usernameField.stringValue = @"";
	self.passwordField.stringValue = @"";
	[self.loginView setFrameOrigin:NSZeroPoint];
	[self.loginCancelButton setHidden:NO];
	[self.signingInProgWheel stopAnimation:nil];
	[self.signingInProgWheel setHidden:YES];
	[self.signingInStatusField setHidden:YES];
	
	if (!shouldAnimate)
	{		
		[self.window setContentSize:NSMakeSize(self.loginView.frame.size.width,self.loginView.frame.size.height+40)];
		
		[self.window.contentView addSubview:self.loginView];
	} else
	{
		self.loginView.alphaValue = 0.0;
		
		[self.window.contentView addSubview:self.loginView];
		
		[self.loginView.animator setAlphaValue:1.0];
		
		[self.window setFrame:NSMakeRect(self.window.frame.origin.x,self.window.frame.origin.y,self.loginView.frame.size.width,self.loginView.frame.size.height+40)
					  display:YES
					  animate:YES];
	}
}

- (void)switchToUploadWithAnimation:(BOOL)shouldAnimate //show title,description etc. prompt
{
	[self.loginView removeFromSuperview];
	
	if (self.titleField.stringValue.length == 0)
		self.titleField.stringValue = ESSLocalizedString(@"ESSYouTubeDefaultTitle", nil);
	[self.signingInProgWheel setHidden:YES];
	[self.uploadView setFrameOrigin:NSZeroPoint];
	
	if (!shouldAnimate)
	{		
		[self.window setContentSize:NSMakeSize(self.uploadView.frame.size.width, self.uploadView.frame.size.height+40)];
		
		[self.window.contentView addSubview:self.uploadView];
	} else
	{
		self.uploadView.alphaValue = 0.0;
		[self.window.contentView addSubview:self.uploadView];
		
		[self.uploadView.animator setAlphaValue:1.0];
		
		[self.window setFrame:NSMakeRect(self.window.frame.origin.x,self.window.frame.origin.y,self.uploadView.frame.size.width,self.uploadView.frame.size.height+40)
					  display:YES
					  animate:YES];
	}
}

- (void)uploadStarted //show progress prompt
{
	self.uploadStatusField.stringValue = ESSLocalizedString(@"ESSYouTubeInizializingUpload",nil);
	[self.licenseView removeFromSuperview];
	[self.uploadProgressBar startAnimation:nil];
	[self.uploadProgressBar setIndeterminate:YES];
	
	[self.uploadProgressView setFrameOrigin:NSZeroPoint];
	self.uploadProgressView.alphaValue = 0.0;
	[self.window.contentView addSubview:self.uploadProgressView];
	
	[self.uploadProgressView.animator setAlphaValue:1.0];
	
	[self.window setFrame:NSMakeRect(self.window.frame.origin.x,self.window.frame.origin.y,self.uploadProgressView.frame.size.width,self.uploadProgressView.frame.size.height+40)
				  display:YES
				  animate:YES];
}

- (void)uploadUpdatedWithUploadedBytes:(NSInteger)uploadedBytes ofTotalBytes:(NSInteger)totalBytes
{
	[self.uploadProgressBar setIndeterminate:NO];
	self.uploadProgressBar.minValue = 0;
	self.uploadProgressBar.maxValue = totalBytes;
	self.uploadProgressBar.doubleValue = uploadedBytes;
	
	double percentDone = uploadedBytes*100/totalBytes;
	percentDone = round(percentDone);
	
	self.uploadStatusField.stringValue = [NSString stringWithFormat:ESSLocalizedString(@"ESSYouTubeUploadPercentageDone",nil),(NSUInteger)percentDone]; //@"%ld%% uploaded
	
	if (uploadedBytes == totalBytes)
	{
		[self.uploadProgressBar setIndeterminate:YES];
		[self.uploadProgressBar startAnimation:nil];
		[self.duringUploadCancelButton setEnabled:NO];
		self.uploadStatusField.stringValue = ESSLocalizedString(@"ESSYouTubeWaitingForYouTubeToProcessVideo",nil);
	}
}

- (void)uploadFinishedWithYouTubeVideoURL:(NSURL *)url
{
	if (url == nil)
		[self.viewOnYouTubeButton setHidden:YES];
	else
		[self.viewOnYouTubeButton setHidden:NO];
	self.viewOnYouTubeButton.alternateTitle = [url absoluteString];
	
	//switch to done view
	[self.uploadProgressView removeFromSuperview];
	
	[self.doneView setFrameOrigin:NSZeroPoint];
	self.doneView.alphaValue = 0.0;
	[self.window.contentView addSubview:self.doneView];
	
	[self.doneView.animator setAlphaValue:1.0];
	
	[self.window setFrame:NSMakeRect(self.window.frame.origin.x,self.window.frame.origin.y,self.doneView.frame.size.width,self.doneView.frame.size.height+40)
				  display:YES
				  animate:YES];
}

- (IBAction)cancelLoginOrBeforeUpload:(id)sender
{
	[sender setEnabled:NO];
	if (self.window.parentWindow != nil)
		[NSApp endSheet:self.window];
	[self.window orderOut:nil];
	
	if ([self.delegate respondsToSelector:@selector(youtubeWindowControllerDidDismiss:)])
	{
		double delayInSeconds = 0.6;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
		{
			[self.delegate youtubeWindowControllerDidDismiss:self];
		});
	}
}

- (IBAction)cancelDuringUpload:(id)sender
{
	[self cancelLoginOrBeforeUpload:sender];
}

- (IBAction)back:(id)sender //if license, show upload, if upload show login
{
	if ([sender superview] == self.uploadView) //change... button pressed
	{
		[(ESSYouTube *)self.delegate _deauthorize];
		[self switchToLoginWithAnimation:YES];
	} else if ([sender superview] == self.licenseView)
	{
		[self.licenseView removeFromSuperview];
		
		[self.uploadView setFrameOrigin:NSZeroPoint];
		self.uploadView.alphaValue = 0.0;
		[self.window.contentView addSubview:self.uploadView];
		
		[self.uploadView.animator setAlphaValue:1.0];
		
		[self.window setFrame:NSMakeRect(self.window.frame.origin.x,self.window.frame.origin.y,self.uploadView.frame.size.width,self.uploadView.frame.size.height+40)
					  display:YES
					  animate:YES];
	}
}

- (IBAction)next:(id)sender //if login show upload, if upload show license, if license start upload
{
	if ([sender superview] == self.loginView) //perform login
	{
		if (self.usernameField.stringValue.length == 0 || self.passwordField.stringValue.length == 0)
		{
			NSBeep();
			return;
		}
		
		[self.loginCancelButton setHidden:YES];
		[self.signingInProgWheel startAnimation:nil];
		[self.signingInProgWheel setHidden:NO];
		[self.signingInStatusField setHidden:NO];
		[(NSButton *)sender setEnabled:NO];
		[(ESSYouTube *)self.delegate _authorizeWithUsername:self.usernameField.stringValue
												  password:self.passwordField.stringValue];
	} else if ([sender superview] == self.uploadView) //switch to license view
	{
		if (self.titleField.stringValue.length == 0 || self.descriptionField.stringValue.length == 0 || self.tagsTokenField.stringValue.length == 0)
		{
			NSBeep();
			return;
		}
		
		[self.uploadView removeFromSuperview];
		
		[self.licenseView setFrameOrigin:NSZeroPoint];
		self.licenseView.alphaValue = 0.0;
		[self.window.contentView addSubview:self.licenseView];
		
		[self.licenseView.animator setAlphaValue:1.0];
		
		[self.window setFrame:NSMakeRect(self.window.frame.origin.x,self.window.frame.origin.y,self.licenseView.frame.size.width,self.licenseView.frame.size.height+40)
					  display:YES
					  animate:YES];
	}
}

- (IBAction)startUpload:(id)sender
{
	if (self.titleField.stringValue.length == 0 || self.descriptionField.stringValue.length == 0 || self.tagsTokenField.stringValue.length == 0)
	{
		NSBeep();
		return;
	}
	
	[self uploadStarted];
	
	[(ESSYouTube *)self.delegate _uploadVideoAtURL:self.videoURL
										withTitle:self.titleField.stringValue
									  description:self.descriptionField.stringValue
									  makePrivate:(self.makePrivateButton.state == NSOnState)
										 keywords:self.tagsTokenField.stringValue
										 category:self.categoryPopUpButton.selectedItem.representedObject];
}

- (IBAction)viewOnYouTube:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:((NSButton *)sender).alternateTitle]];
}

- (void)dealloc
{
	self.delegate = nil;
	self.videoURL = nil;
	self.loginView = nil;
	self.uploadView = nil;
	self.licenseView = nil;
	self.uploadProgressView = nil;
	self.doneView = nil;
	
	[super dealloc];
}
@end
