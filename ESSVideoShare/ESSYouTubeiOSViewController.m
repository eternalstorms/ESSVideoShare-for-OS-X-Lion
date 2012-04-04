//
//  ESSYouTubeiOSViewController.m
//  essvideoshareiostest
//
//  Created by Matthias Gansrigler on 27.03.12.
//  Copyright (c) 2012 Eternal Storms Software. All rights reserved.
//

#import "ESSYouTubeiOSViewController.h"
#import "ESSYouTube.h"

@interface ESSYouTubeiOSViewController ()

@end

@implementation ESSYouTubeiOSViewController

@synthesize videoInfoViewController,termsViewController,uploadingViewController,uploadProgressView,uploadLabel,doneViewController,doneImageView,doneLabel,viewButton,delegate,videoURL,username,navContr,categoriesDict,titleTVCell,descriptionTVCell,tagsTVCell,privacyTVCell,picker,categoryTVCell;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (id)initWithDelegate:(id)del videoURL:(NSURL *)url
{
	NSString *nibName = @"ESSYouTubeiOSView_iPhone";
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
	{
		nibName = @"ESSYouTubeiOSView_iPad";
		self.modalPresentationStyle = UIModalPresentationFormSheet;
		self.videoInfoViewController.modalPresentationStyle = UIModalPresentationFormSheet;
		self.termsViewController.modalPresentationStyle = UIModalPresentationFormSheet;
		self.uploadingViewController.modalPresentationStyle = UIModalPresentationFormSheet;
		self.doneViewController.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	
	if (self = [super initWithNibName:nibName bundle:nil])
	{
		self.delegate = del;
		self.videoURL = url;
		
		return self;
	}
	
	return nil;
}

- (void)cancel
{
	if ([self.delegate respondsToSelector:@selector(youtubeiOSViewControllerDidDismiss:)])
		[self.delegate youtubeiOSViewControllerDidDismiss:self];
}

- (void)login:(id)sender
{	
	UITableViewCell *cell = [((UITableView *)self.view) cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
	UITextField *usernameField = nil;
	for (UIView *view in cell.subviews)
	{
		if ([view isKindOfClass:[UITextField class]])
		{
			usernameField = (UITextField *)view;
			break;
		}
	}
	[usernameField resignFirstResponder];
	NSString *user = usernameField.text;
	
	cell = [((UITableView *)self.view) cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
	UITextField *pwField = nil;
	for (UIView *view in cell.subviews)
	{
		if ([view isKindOfClass:[UITextField class]])
		{
			pwField = (UITextField *)view;
			break;
		}
	}
	[pwField resignFirstResponder];
	NSString *pass = pwField.text;
	
	if (user.length == 0)
	{
		[usernameField becomeFirstResponder];
		return;
	} else if (pass.length == 0)
	{
		[pwField becomeFirstResponder];
		return;
	}
	
	((UIBarButtonItem *)sender).enabled = NO;
	self.navigationItem.leftBarButtonItem.enabled = NO;
	
	[(ESSYouTube *)self.delegate _authorizeWithUsername:user
											   password:pass];
}

- (void)beginUploadProcess
{
	//if cateogry !=? nil, title != nil, desc != nil & tags != nil
	UITableViewCell *cell = self.titleTVCell;
	UITextField *videoTitleField = nil;
	for (UIView *view in cell.subviews)
	{
		if ([view isKindOfClass:[UITextField class]])
		{
			videoTitleField = (UITextField *)view;
			break;
		}
	}
	[videoTitleField resignFirstResponder];
	NSString *title = videoTitleField.text;
	
	if (title.length == 0)
	{
		[videoTitleField becomeFirstResponder];
		return;
	}
	
	if (self.categoryTVCell.detailTextLabel.text.length == 0)
	{
		[(UITableView *)self.videoInfoViewController.view selectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
		return;
	}
	
	cell = self.descriptionTVCell;
	UITextField *videoDescField = nil;
	for (UIView *view in cell.subviews)
	{
		if ([view isKindOfClass:[UITextField class]])
		{
			videoDescField = (UITextField *)view;
			break;
		}
	}
	[videoDescField resignFirstResponder];
	NSString *description = videoDescField.text;
	
	if (description.length == 0)
	{
		[videoDescField becomeFirstResponder];
		return;
	}
	
	cell = self.tagsTVCell;
	UITextField *videoTags = nil;
	for (UIView *view in cell.subviews)
	{
		if ([view isKindOfClass:[UITextField class]])
		{
			videoTags = (UITextField *)view;
			break;
		}
	}
	[videoTags resignFirstResponder];
	NSString *tags = videoTags.text;
	
	if (tags.length == 0)
	{
		[videoTags becomeFirstResponder];
		return;
	}
	
	/*cell = [((UITableView *)self.videoInfoViewController.view) cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
	 UISwitch *aSwitch = nil;
	 for (UIView *view in cell.subviews)
	 {
	 if ([view isKindOfClass:[UISwitch class]])
	 {
	 aSwitch = (UISwitch *)view;
	 break;
	 }
	 }
	 
	 BOOL isPrivate = aSwitch.on;*/
	
	//switch to agreement
	[self.navContr pushViewController:self.termsViewController animated:YES];
	
	self.termsViewController.navigationItem.title = @"YouTube";
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSYouTubeiOSUploadButtonTitle", nil) style:UIBarButtonItemStyleDone target:self action:@selector(startUpload)];
	self.termsViewController.navigationItem.rightBarButtonItem = button;
	[button release];
	button = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSYouTubeiOSCancelButtonTitle", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(cancel)];
	self.termsViewController.navigationItem.leftBarButtonItem = button;
	[button release];
}

- (void)startUpload
{
	UITableViewCell *cell = self.titleTVCell;
	UITextField *videoTitleField = nil;
	for (UIView *view in cell.subviews)
	{
		if ([view isKindOfClass:[UITextField class]])
		{
			videoTitleField = (UITextField *)view;
			break;
		}
	}
	[videoTitleField resignFirstResponder];
	NSString *title = videoTitleField.text;
	
	if (title.length == 0)
	{
		[videoTitleField becomeFirstResponder];
		return;
	}
	
	NSString *category = [self.categoriesDict objectForKey:self.categoryTVCell.detailTextLabel.text];
	
	cell = self.descriptionTVCell;
	UITextField *videoDescField = nil;
	for (UIView *view in cell.subviews)
	{
		if ([view isKindOfClass:[UITextField class]])
		{
			videoDescField = (UITextField *)view;
			break;
		}
	}
	[videoDescField resignFirstResponder];
	NSString *description = videoDescField.text;
	
	cell = self.tagsTVCell;
	UITextField *videoTags = nil;
	for (UIView *view in cell.subviews)
	{
		if ([view isKindOfClass:[UITextField class]])
		{
			videoTags = (UITextField *)view;
			break;
		}
	}
	[videoTags resignFirstResponder];
	NSString *tags = videoTags.text;
	
	cell = [((UITableView *)self.videoInfoViewController.view) cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
	UISwitch *aSwitch = nil;
	for (UIView *view in cell.subviews)
	{
		if ([view isKindOfClass:[UISwitch class]])
		{
			aSwitch = (UISwitch *)view;
			break;
		}
	}
	
	BOOL isPrivate = aSwitch.on;
	
	[self uploadStarted];
	
	[(ESSYouTube *)self.delegate _uploadVideoAtURL:self.videoURL
										 withTitle:title
									   description:description
									   makePrivate:isPrivate
										  keywords:tags
										  category:category];
}

- (void)updateUsername:(NSString *)name
{
	self.username = name;
	
	[(UITableView *)self.videoInfoViewController.view reloadData];
}

- (void)updateCategories:(NSDictionary *)dict
{
	self.categoriesDict = dict;
	[(UITableView *)self.videoInfoViewController.view reloadData];
	[self.picker reloadAllComponents];
}

- (void)resetLoginInfo ////used when login fails, enable login button, delete username and password
{
	self.navigationItem.leftBarButtonItem.enabled = YES;
	self.navigationItem.rightBarButtonItem.enabled = YES;
	[(UITableView *)self.view reloadData];
}

- (IBAction)showOnYouTube:(id)sender
{
	NSURL *url = [NSURL URLWithString:[self.viewButton titleForState:UIControlStateDisabled]];
	
	[[UIApplication sharedApplication] openURL:url];
}

- (void)switchToLoginViewWithAnimation:(BOOL)animate
{
	[self.navContr popToViewController:self animated:animate];
	
	self.navigationItem.title = @"YouTube";
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSYouTubeiOSLoginButtonTitle", nil) style:UIBarButtonItemStyleDone target:self action:@selector(login:)];
	self.navigationItem.rightBarButtonItem = button;
	[button release];
	button = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSYouTubeiOSCancelButtonTitle", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(cancel)];
	self.navigationItem.leftBarButtonItem = button;
	[button release];
}

- (void)switchToInfoViewWithAnimation:(BOOL)animate
{
	[self.navContr pushViewController:self.videoInfoViewController animated:animate];
	
	self.videoInfoViewController.navigationItem.title = @"YouTube";
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSYouTubeiOSUploadButtonTitle", nil) style:UIBarButtonItemStyleDone target:self action:@selector(beginUploadProcess)];
	self.videoInfoViewController.navigationItem.rightBarButtonItem = button;
	[button release];
	button = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSYouTubeiOSCancelButtonTitle", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(cancel)];
	self.videoInfoViewController.navigationItem.leftBarButtonItem = button;
	[button release];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (tableView == self.view) //login view
		return 2; ///username and password
	else if (tableView == self.videoInfoViewController.view) //video info table view
	{
		if (section == 0) //account info
			return 1; //logged in name
		if (section == 1) //video info
			return 4; //category, title, description, tags
		if (section == 2) //privacy
			return 1; //isPrivate
	}
	
	return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (tableView == self.view) //login view
		return 1; //just login
	else if (tableView == self.videoInfoViewController.view) //video info table view
		return 3; //account info, video info, privacy
	
	return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (tableView == self.view) //login view
		return ESSLocalizedString(@"ESSYouTubeiOSLoginTableViewFooter", nil);
	else if (tableView == self.videoInfoViewController.view) //video info table view
	{
		if (section == 0)
			return ESSLocalizedString(@"ESSYouTubeiOSAccountInfoTableViewFooter", nil);
		else if (section == 1)
			return ESSLocalizedString(@"ESSYouTubeiOSVideoInfoTableViewFooter", nil);
		else if (section == 2)
			return ESSLocalizedString(@"ESSYouTubeiOSPrivacyTableViewFooter", nil);
	}
	
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if (tableView == self.view) //login view
		return ESSLocalizedString(@"ESSYouTubeiOSLoginTableViewHeader", nil);
	else if (tableView == self.videoInfoViewController.view) //video info table view
	{
		if (section == 0)
			return ESSLocalizedString(@"ESSYouTubeiOSAccountInfoTableViewHeader", nil);
		else if (section == 1)
			return ESSLocalizedString(@"ESSYouTubeiOSVideoInfoTableViewHeader", nil);
		else if (section == 2)
			return ESSLocalizedString(@"ESSYouTubeiOSPrivacyTableViewHeader", nil);
	}
	
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.view) //login view
	{
		UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"loginViewCell"];
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		UITextField *editableTextField = nil;
		if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad)
			editableTextField = [[UITextField alloc] initWithFrame:CGRectMake(120,11,186,22)];
		else
			editableTextField = [[UITextField alloc] initWithFrame:CGRectMake(145,11,360,22)];
		editableTextField.adjustsFontSizeToFitWidth = YES;
		editableTextField.textColor = [UIColor colorWithRed:0.22 green:0.33 blue:0.53 alpha:1];
		editableTextField.backgroundColor = cell.backgroundColor;
		editableTextField.autocorrectionType = UITextAutocorrectionTypeDefault;
		editableTextField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
		editableTextField.textAlignment = UITextAlignmentLeft;
		editableTextField.tag = 0;
		editableTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
		editableTextField.enabled = YES;
		editableTextField.keyboardType = UIKeyboardTypeDefault;
		editableTextField.delegate = self;
		[cell addSubview:editableTextField];
		
		if ([indexPath indexAtPosition:1] == 0) //username
		{
			editableTextField.returnKeyType = UIReturnKeyDone;
			cell.textLabel.text = ESSLocalizedString(@"ESSYouTubeiOSUsernameCellTitle",nil);
			editableTextField.placeholder = ESSLocalizedString(@"required", nil);
		} else if ([indexPath indexAtPosition:1] == 1) //password
		{
			editableTextField.returnKeyType = UIReturnKeyDone;
			cell.textLabel.text = ESSLocalizedString(@"ESSYouTubeiOSPasswordCellTitle",nil);
			editableTextField.placeholder = ESSLocalizedString(@"required", nil);
			editableTextField.secureTextEntry = YES;
		}
		
		[editableTextField release];
		return [cell autorelease];
	} else if (tableView == self.videoInfoViewController.view) //video info table view
	{
		if ([indexPath indexAtPosition:0] == 0) //account info section
		{
			UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"userNameCell"];
			cell.textLabel.text = ESSLocalizedString(@"ESSYouTubeiOSUsernameCellTitle",nil);
			cell.detailTextLabel.text = self.username;
			return [cell autorelease];
		} else if ([indexPath indexAtPosition:0] == 1) //video info section
		{
			if ([indexPath indexAtPosition:1] == 0)
			{
				if (self.titleTVCell == nil)
					self.titleTVCell = [self customTVCellForIndexPath:indexPath];
				
				return self.titleTVCell;
			} else if ([indexPath indexAtPosition:1] == 2)
			{
				if (self.descriptionTVCell == nil)
					self.descriptionTVCell = [self customTVCellForIndexPath:indexPath];
				
				return self.descriptionTVCell;
			} else if ([indexPath indexAtPosition:1] == 3)
			{
				if (self.tagsTVCell == nil)
					self.tagsTVCell = [self customTVCellForIndexPath:indexPath];
				
				return self.tagsTVCell;
			} else if ([indexPath indexAtPosition:1] == 1) //category
			{
				if (self.categoryTVCell == nil)
				{
					self.categoryTVCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"categoryCell"] autorelease];
					self.categoryTVCell.textLabel.text = ESSLocalizedString(@"ESSYouTubeiOSCategoryCellTitle",nil);
					self.categoryTVCell.detailTextLabel.text = @"";
				}
				
				return self.categoryTVCell;
			}
		} else if ([indexPath indexAtPosition:0] == 2) //privacy
		{
			if (self.privacyTVCell == nil)
			{
				self.privacyTVCell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"privacyCell"] autorelease];
				self.privacyTVCell.accessoryType = UITableViewCellAccessoryNone;
				self.privacyTVCell.selectionStyle = UITableViewCellSelectionStyleNone;
				self.privacyTVCell.textLabel.text = ESSLocalizedString(@"ESSYouTubeiOSPrivateCellTitle",nil);
				
				UISwitch *aSwitch = nil;
				if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad)
					aSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(222,10,186,20)];
				else //iPad
					aSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(420,10,186,20)];
				aSwitch.on = YES;
				
				[self.privacyTVCell addSubview:aSwitch];
				[aSwitch release];
			}
			
			return self.privacyTVCell;
		}
	}
	
	return nil;
}

- (UITableViewCell *)customTVCellForIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"videoInfoCell"];
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	UITextField *editableTextField = nil;
	if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad)
		editableTextField = [[UITextField alloc] initWithFrame:CGRectMake(120,11,186,22)];
	else
		editableTextField = [[UITextField alloc] initWithFrame:CGRectMake(145,11,360,22)];
	editableTextField.adjustsFontSizeToFitWidth = YES;
	editableTextField.textColor = [UIColor colorWithRed:0.22 green:0.33 blue:0.53 alpha:1];
	editableTextField.backgroundColor = cell.backgroundColor;
	editableTextField.autocorrectionType = UITextAutocorrectionTypeDefault;
	editableTextField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
	editableTextField.textAlignment = UITextAlignmentLeft;
	editableTextField.tag = 0;
	editableTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	editableTextField.enabled = YES;
	editableTextField.keyboardType = UIKeyboardTypeDefault;
	editableTextField.delegate = self;
	[cell addSubview:editableTextField];
	editableTextField.returnKeyType = UIReturnKeyDone;
	
	if ([indexPath indexAtPosition:1] == 0)
	{
		cell.textLabel.text = ESSLocalizedString(@"ESSYouTubeiOSTitleCellTitle",nil);
		editableTextField.placeholder = ESSLocalizedString(@"required", nil);
	} else if ([indexPath indexAtPosition:1] == 2) //desc
	{
		cell.textLabel.text = ESSLocalizedString(@"ESSYouTubeiOSDescriptionCellTitle",nil);
		editableTextField.placeholder = ESSLocalizedString(@"required", nil);
	} else if ([indexPath indexAtPosition:1] == 3) //tags
	{
		cell.textLabel.text = ESSLocalizedString(@"ESSYouTubeiOSTagsCellTitle",nil);
		editableTextField.placeholder = ESSLocalizedString(@"required", nil);
	}
	[editableTextField release];
	
	return [cell autorelease];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (tableView == self.videoInfoViewController.view) //video info table view
	{
		if ([indexPath indexAtPosition:0] == 0)
		{
			//deauthorize and login again
			[(ESSYouTube *)self.delegate _deauthorize];
			[self switchToLoginViewWithAnimation:YES];
		} else if ([indexPath indexAtPosition:1] == 1)
		{
			//change category
			UIPickerView *ourPicker = [[[UIPickerView alloc] initWithFrame:CGRectMake(0,92,self.view.frame.size.width/2,215)] autorelease];
			ourPicker.delegate = self;
			ourPicker.dataSource = self;
			[ourPicker reloadAllComponents];
			if (self.categoryTVCell.detailTextLabel.text.length > 0)
			{
				NSUInteger index = 0;
				for (NSString *category in self.categoriesDict.allKeys)
				{
					if ([self.categoryTVCell.detailTextLabel.text isEqualToString:category])
					{
						index = [self.categoriesDict.allKeys indexOfObject:category];
						break;
					}
				}
				
				[ourPicker selectRow:index inComponent:0 animated:NO];
			}
			ourPicker.showsSelectionIndicator = YES;
			self.picker = ourPicker;
			
			if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad)
			{
				UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@""
																   delegate:self
														  cancelButtonTitle:ESSLocalizedString(@"ESSYouTubeiOSSelectCategoryButton", nil)
													 destructiveButtonTitle:nil
														  otherButtonTitles:nil];
				[ourPicker setFrame:CGRectMake(0, 92, self.view.frame.size.width, 215)];
				[sheet addSubview:ourPicker];
				[sheet showInView:self.videoInfoViewController.view];
				[sheet setBounds:CGRectMake(0, 0, self.view.frame.size.width, 411)];
				[sheet release];
			} else
			{
				UIViewController *vCtr = [[UIViewController alloc] init];
				vCtr.view = ourPicker;
				UIPopoverController *popContr = [[UIPopoverController alloc] initWithContentViewController:vCtr];
				[vCtr release];
				popContr.delegate = self;
				popContr.popoverContentSize = CGSizeMake(self.view.frame.size.width/2,180);
				[popContr presentPopoverFromRect:CGRectMake(0,0,self.categoryTVCell.frame.size.width,self.categoryTVCell.frame.size.height)
										  inView:self.categoryTVCell
						permittedArrowDirections:UIPopoverArrowDirectionUp
										animated:YES];
			}
		}
	}
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	self.categoryTVCell.detailTextLabel.text = [self.categoriesDict.allKeys objectAtIndex:[self.picker selectedRowInComponent:0]];
	[(UITableView *)self.videoInfoViewController.view reloadData];
	self.picker = nil;
	[popoverController autorelease];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return [self.categoriesDict count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	return [self.categoriesDict.allKeys objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	//find textField
	self.categoryTVCell.detailTextLabel.text = [self.categoriesDict.allKeys objectAtIndex:row];
	[(UITableView *)self.videoInfoViewController.view reloadData];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	self.categoryTVCell.detailTextLabel.text = [self.categoriesDict.allKeys objectAtIndex:[self.picker selectedRowInComponent:0]];
	[(UITableView *)self.videoInfoViewController.view reloadData];
	self.picker = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (void)uploadStarted
{
	[self.navContr pushViewController:self.uploadingViewController animated:YES];
	
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSYouTubeiOSCancelButtonTitle", nil)
															   style:UIBarButtonItemStyleBordered
															  target:self
															  action:@selector(cancel)];
	self.uploadingViewController.navigationItem.leftBarButtonItem = button;
	[button release];
	self.uploadingViewController.navigationItem.rightBarButtonItem = nil;
	self.uploadingViewController.navigationItem.title = @"YouTube";
	self.uploadProgressView.progress = 0.0;
}

- (void)uploadUpdatedWithUploadedBytes:(NSInteger)uploadedBytes ofTotalBytes:(NSInteger)totalBytes
{
	[self.uploadProgressView setProgress:(CGFloat)((CGFloat)uploadedBytes/(CGFloat)totalBytes) animated:YES];
	double percentDone = uploadedBytes*100/totalBytes;
	percentDone = round(percentDone);
	
	self.uploadLabel.text = [NSString stringWithFormat:ESSLocalizedString(@"ESSYouTubeUploadPercentageDone", nil),(NSUInteger)percentDone];
	
	if (uploadedBytes == totalBytes)
		self.uploadLabel.text = ESSLocalizedString(@"ESSYouTubeWaitingForYouTubeToProcessVideo", nil);
}

- (void)uploadFinishedWithYouTubeVideoURL:(NSURL *)url
{
	if (url == nil)
	{
		self.doneLabel.text = ESSLocalizedString(@"ESSYouTubeUploadFailed", nil);
		self.viewButton.hidden = YES;
	} else
	{
		self.doneLabel.text = ESSLocalizedString(@"ESSYouTubeUploadSucceeded", nil);
		self.viewButton.hidden = NO;
	}
	
	self.viewButton.enabled = YES;
	[self.viewButton setTitle:url.absoluteString forState:UIControlStateDisabled]; //must never be disabled
	
	[self.navContr pushViewController:self.doneViewController animated:YES];
	self.doneViewController.navigationItem.title = @"YouTube";
	
	UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSYouTubeiOSCancelButtonTitle",nil) style:UIBarButtonItemStyleBordered target:nil action:nil];
	button.enabled = NO;
	self.doneViewController.navigationItem.leftBarButtonItem = button;
	[button release];
	
	button = [[UIBarButtonItem alloc] initWithTitle:ESSLocalizedString(@"ESSYouTubeiOSDoneButtonTitle",nil) style:UIBarButtonItemStyleDone target:self action:@selector(cancel:)];
	self.doneViewController.navigationItem.rightBarButtonItem = button;
	[button release];
}

- (void)dealloc
{
	self.videoInfoViewController = nil;
	self.termsViewController = nil;
	self.uploadingViewController = nil;
	self.doneViewController = nil;
	self.delegate = nil;
	self.videoURL = nil;
	self.username = nil;
	self.navContr = nil;
	self.categoriesDict = nil;
	self.titleTVCell = nil;
	self.descriptionTVCell = nil;
	self.tagsTVCell = nil;
	self.privacyTVCell = nil;
	self.picker = nil;
	self.categoryTVCell = nil;
	
	[super dealloc];
}

@end
