//
//  ESSFlickriOSViewController.h
//  essvideoshareiostest
//
//  Created by Matthias Gansrigler on 31.03.12.
//  Copyright (c) 2012 Eternal Storms Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ESSFlickriOSViewController;

@protocol ESSFlickriOSViewControllerDelegate <NSObject>

@required
- (void)flickrDidCancel:(ESSFlickriOSViewController *)flickrCtr;

@end

@interface ESSFlickriOSViewController : UIViewController <UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate>

@property (assign) id delegate;
@property (retain) NSURL *videoURL;

@property (retain) UINavigationController *navCtr;

@property (retain) NSString *username;

@property (retain) IBOutlet UIViewController *videoInfoViewController;

@property (retain) IBOutlet UIViewController *uploadingViewController;
@property (assign) IBOutlet UILabel *uploadingLabel;
@property (assign) IBOutlet UIProgressView *uploadingProgressView;

@property (retain) IBOutlet UIViewController *doneViewController;
@property (retain) IBOutlet UIImageView *doneImageView;
@property (retain) IBOutlet UILabel *doneLabel;
@property (retain) IBOutlet UIButton *doneButton;

@property (retain) UITableViewCell *titleTVCell;
@property (retain) UITableViewCell *descriptionTVCell;
@property (retain) UITableViewCell *tagsTVCell;
@property (retain) UITableViewCell *privacyTVCell;

- (id)initWithDelegate:(id)del videoURL:(NSURL *)url;

- (void)updateUsername:(NSString *)name;

- (void)switchToLoginViewWithAnimation:(BOOL)animate;
- (void)switchToUploadViewWithAnimation:(BOOL)animate;

- (void)login:(id)sender;
- (void)cancel:(id)sender;
- (void)startUpload:(id)sender;

- (void)uploadUpdatedWithUploadedBytes:(NSInteger)uploadedBytes ofTotalBytes:(NSInteger)totalBytes;
- (void)uploadFinishedWithURL:(NSURL *)url;

- (IBAction)showOnFlickr:(id)sender;

- (UITableViewCell *)customTVCellForIndexPath:(NSIndexPath *)indexPath;

@end
