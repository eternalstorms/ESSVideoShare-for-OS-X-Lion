//
//  ESSVimeoWindowController.m
//  Zlidez
//
//  Created by Matthias Gansrigler on 21.11.11.
//  Copyright (c) 2011 Eternal Storms Software. All rights reserved.
//

#import "ESSVimeoWindowController.h"
#import "ESSVimeo.h"

@implementation ESSVimeoWindowController
@synthesize doneView;
@synthesize doneImageView;
@synthesize doneField;
@synthesize viewOnVimeoButton;
@synthesize uploadProgressView;
@synthesize uploadProgressBar;
@synthesize uploadStatusField;
@synthesize cancelUploadButton;
@synthesize licenseView;
@synthesize noUploadSpaceView;
@synthesize noSpaceImageView;
@synthesize noSpaceStatusField;
@synthesize uploadView;
@synthesize usernameField;
@synthesize titleField;
@synthesize descriptionField;
@synthesize tagsField;
@synthesize makePrivateButton;
@synthesize loginView;
@synthesize loginStatusField;
@synthesize loginStatusProgressIndicator;
@synthesize authorizeButton,delegate,videoURL;

- (id)initWithVideoURL:(NSURL *)url
			  delegate:(id)del
{
	if (self = [super initWithWindowNibName:@"essvimeoWindow"])
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

- (void)awakeFromNib
{
	[self.loginStatusProgressIndicator setHidden:NO];
}

- (void)switchToLoginViewWithAnimation:(BOOL)shouldAnimate
{
	[self.delegate _deauthorize];
	
	[self.loginStatusField setHidden:YES];
	[self.loginStatusProgressIndicator setHidden:YES];
	[self.authorizeButton setEnabled:YES];
	[self.authorizeButton setHidden:NO];
	
	[self.uploadView removeFromSuperview];
	[self.loginView setFrameOrigin:NSZeroPoint];
	
	if (!shouldAnimate)
	{		
		[self.window setContentSize:NSMakeSize(NSWidth(self.loginView.frame),38+NSHeight(self.loginView.frame))];
		[self.loginView.animator setAlphaValue:1.0];
		[self.window.contentView addSubview:self.loginView];
	} else //shouldanimate
	{
		[self.window setFrame:NSMakeRect(0, 0, NSWidth(self.loginView.frame), 38+NSHeight(self.loginView.frame)) display:YES animate:YES];
		[self.loginView setAlphaValue:0.0];
		[self.window.contentView addSubview:self.loginView];
		[self.loginView.animator setAlphaValue:1.0];
	}
}

- (void)switchToUploadViewWithAnimation:(BOOL)shouldAnimate
{
	[self.loginStatusField setHidden:YES];
	[self.loginStatusProgressIndicator setHidden:YES];
	[self.authorizeButton setEnabled:YES];
	[self.authorizeButton setHidden:NO];
	
	[self.loginView removeFromSuperview];
	[self.uploadView setFrameOrigin:NSZeroPoint];
	
	if (!shouldAnimate)
	{
		[self.window setContentSize:NSMakeSize(NSWidth(self.uploadView.frame),38+NSHeight(self.uploadView.frame))];
		[self.uploadView.animator setAlphaValue:1.0];
		[self.window.contentView addSubview:self.uploadView];
	} else //shouldanimate
	{
		[self.window setFrame:NSMakeRect(0, 0, NSWidth(self.uploadView.frame), 38+NSHeight(self.uploadView.frame)) display:YES animate:YES];
		self.uploadView.alphaValue = 1.0;
		[self.window.contentView addSubview:self.uploadView];
	}
}

- (IBAction)authorize:(id)sender
{
	[self.authorizeButton setHidden:YES];
	[self.authorizeButton setEnabled:NO];
	[self.loginStatusField setHidden:NO];
	[self.loginStatusProgressIndicator startAnimation:nil];
	[self.loginStatusProgressIndicator setHidden:NO];
	
	[self.delegate _startAuthorization];
}

- (IBAction)cancelAuthorization:(id)sender
{
	[self done:sender];
}

- (IBAction)cancelBeforeUpload:(id)sender
{
	[self done:sender];
}

- (IBAction)startUpload:(id)sender
{
	[self.uploadView removeFromSuperview];
	[self.licenseView setFrameOrigin:NSZeroPoint];
	[self.window setFrame:NSMakeRect(0, 0, NSWidth(self.licenseView.frame), 38+NSHeight(self.licenseView.frame)) display:YES animate:YES];
	self.licenseView.alphaValue = 0.0;
	[self.window.contentView addSubview:self.licenseView];
	[self.licenseView.animator setAlphaValue:1.0];
}

- (IBAction)changeAccount:(id)sender
{
	[self.delegate _deauthorize];
	
	[self switchToLoginViewWithAnimation:YES];
}

- (IBAction)cancelNoSpace:(id)sender
{
	[self done:sender];
}

- (IBAction)cancelLicense:(id)sender
{
	[self done:sender];
}

- (IBAction)backToUploadView:(id)sender
{
	[self.licenseView removeFromSuperview];
	[self.uploadView setFrameOrigin:NSZeroPoint];
	[self.window setFrame:NSMakeRect(0, 0, NSWidth(self.uploadView.frame), 38+NSHeight(self.uploadView.frame)) display:YES animate:YES];
	self.uploadView.alphaValue = 0.0;
	[self.window.contentView addSubview:self.uploadView];
	[self.uploadView.animator setAlphaValue:1.0];
}

- (IBAction)uploadNow:(id)sender
{
	[self.uploadProgressBar setIndeterminate:YES];
	[self.uploadProgressBar startAnimation:nil];
	
	self.uploadStatusField.stringValue = ESSLocalizedString(@"ESSVimeoInitializingUpload", nil);
	
	[self.licenseView removeFromSuperview];
	[self.uploadProgressView setFrameOrigin:NSZeroPoint];
	[self.window setFrame:NSMakeRect(0, 0, NSWidth(self.uploadProgressView.frame), 38+NSHeight(self.uploadProgressView.frame)) display:YES animate:YES];
	self.uploadProgressView.alphaValue = 0.0;
	[self.window.contentView addSubview:self.uploadProgressView];
	[self.uploadProgressView.animator setAlphaValue:1.0];
	
	[self.delegate _uploadVideoAtURL:self.videoURL
							  title:self.titleField.stringValue
						description:self.descriptionField.stringValue
							   tags:self.tagsField.stringValue
						makePrivate:(self.makePrivateButton.state == NSOnState)];
}

- (IBAction)cancelDuringUpload:(id)sender
{
	[self done:sender];
}

- (IBAction)viewOnVimeo:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[sender alternateTitle]]];
}

- (IBAction)done:(id)sender
{
	[sender setEnabled:NO];
	
	[self.window orderOut:nil];
	//if (self.window.parentWindow != nil)
		[NSApp endSheet:self.window];
	
	if ([self.delegate respondsToSelector:@selector(vimeoWindowIsFinished:)])
	{
		double delayInSeconds = 0.6;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[self.delegate vimeoWindowIsFinished:self];
		});
	}
}

- (void)showNoSpaceLeftWarning
{
	[self.loginView removeFromSuperview];
	[self.noUploadSpaceView setFrameOrigin:NSZeroPoint];
	[self.window setFrame:NSMakeRect(0, 0, NSWidth(self.noUploadSpaceView.frame), 38+NSHeight(self.noUploadSpaceView.frame)) display:YES animate:YES];
	self.noUploadSpaceView.alphaValue = 0.0;
	[self.window.contentView addSubview:self.noUploadSpaceView];
	[self.noUploadSpaceView.animator setAlphaValue:1.0];
	NSString *imgPath = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns";
	NSImage *img = [[[NSImage alloc] initWithContentsOfFile:imgPath] autorelease];
	self.noSpaceImageView.image = img;
	self.noSpaceStatusField.stringValue = ESSLocalizedString(@"ESSVimeoNoSpaceLeft", nil);
}

- (void)showNoPlusAccountWarning
{
	[self.loginView removeFromSuperview];
	[self.noUploadSpaceView setFrameOrigin:NSZeroPoint];
	[self.window setFrame:NSMakeRect(0, 0, NSWidth(self.noUploadSpaceView.frame), 38+NSHeight(self.noUploadSpaceView.frame)) display:YES animate:YES];
	self.noUploadSpaceView.alphaValue = 0.0;
	[self.window.contentView addSubview:self.noUploadSpaceView];
	[self.noUploadSpaceView.animator setAlphaValue:1.0];
	NSString *imgPath = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns";
	NSImage *img = [[[NSImage alloc] initWithContentsOfFile:imgPath] autorelease];
	self.noSpaceImageView.image = img;
	self.noSpaceStatusField.stringValue = ESSLocalizedString(@"ESSVimeoNoPlusAccount", nil);
}

- (void)uploadUpdatedWithBytes:(NSUInteger)uploaded ofTotal:(NSUInteger)total
{
	[self.uploadProgressBar setIndeterminate:NO];
	[self.uploadProgressBar startAnimation:nil];
	self.uploadProgressBar.minValue = 0;
	self.uploadProgressBar.maxValue = total;
	self.uploadProgressBar.doubleValue = uploaded;
	
	double percentDone = uploaded*100/total;
	percentDone = round(percentDone);
	
	self.uploadStatusField.stringValue = [NSString stringWithFormat:ESSLocalizedString(@"ESSVimeoUploadPercentageDone",nil),(NSUInteger)percentDone];
	
	if (uploaded == total)
	{
		[self.uploadProgressBar setIndeterminate:YES];
		[self.uploadProgressBar startAnimation:nil];
		[self.cancelUploadButton setEnabled:NO];
		self.uploadStatusField.stringValue = ESSLocalizedString(@"ESSVimeoWaitingForVimeoToVerifyVideo",nil);
	}
}

- (void)uploadFinishedWithURL:(NSURL *)vimeoURL
{
	if (vimeoURL == nil)
	{
		[self.viewOnVimeoButton setEnabled:NO];
		[self.viewOnVimeoButton setHidden:YES];
		self.doneField.stringValue = ESSLocalizedString(@"ESSVimeoUploadFailed",nil);
		NSString *imgPath = @"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AlertStopIcon.icns";
		NSImage *img = [[[NSImage alloc] initWithContentsOfFile:imgPath] autorelease];
		self.doneImageView.image = img;
	} else
	{
		[self.viewOnVimeoButton setEnabled:YES];
		[self.viewOnVimeoButton setHidden:NO];
		self.doneField.stringValue = ESSLocalizedString(@"ESSVimeoUploadSucceeded",nil);
		NSString *imgPath = @"/System/Library/CoreServices/Installer.app/Contents/PlugIns/Summary.bundle/Contents/Resources/Success.png";
		NSImage *img = [[[NSImage alloc] initWithContentsOfFile:imgPath] autorelease];
		self.doneImageView.image = img;
	}
	
	[self.viewOnVimeoButton setAlternateTitle:[vimeoURL absoluteString]];
	
	[self.uploadProgressView removeFromSuperview];
	[self.doneView setFrameOrigin:NSZeroPoint];
	[self.window setFrame:NSMakeRect(0, 0, NSWidth(self.doneView.frame), 38+NSHeight(self.doneView.frame)) display:YES animate:YES];
	self.doneView.alphaValue = 0.0;
	[self.window.contentView addSubview:self.doneView];
	[self.doneView.animator setAlphaValue:1.0];
}

- (void)dealloc
{
	self.loginView = nil;
	self.uploadView = nil;
	self.delegate = nil;
	self.videoURL = nil;
	self.licenseView = nil;
	
	[super dealloc];
}

@end
