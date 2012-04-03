//
//  ESSVimeoiOSViewController.h
//  essvideoshareiostest
//
//  Created by Matthias Gansrigler on 29.03.12.
//  Copyright (c) 2012 Eternal Storms Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ESSVimeoiOSViewController;

@protocol ESSVimeoiOSViewControllerDelegate <NSObject>

@required
- (void)vimeoIsFinished:(ESSVimeoiOSViewController *)ctr;

@end

@interface ESSVimeoiOSViewController : UIViewController <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>

@property (assign) id delegate;
@property (retain) NSURL *videoURL;
@property (retain) NSString *username;

@property (retain) UINavigationController *navCtr;

@property (retain) IBOutlet UIViewController *videoInfoViewController;

@property (retain) IBOutlet UIViewController *warningViewController;
@property (assign) IBOutlet UIImageView *warningImageView;
@property (assign) IBOutlet UILabel *warningLabel;

@property (retain) IBOutlet UIViewController *termsViewController;

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

- (id)initWithVideoURL:(NSURL *)url delegate:(id)del;

- (void)switchToLoginViewWithAnimation:(BOOL)animate;
- (void)switchToUploadViewWithAnimation:(BOOL)animate;

- (void)showNoPlusAccountWarning;
- (void)showNoSpaceLeftWarning;

- (void)cancel:(id)sender;
- (void)login:(id)sender;
- (void)showTerms:(id)sender;
- (void)startUpload:(id)sender;
- (void)uploadStarted;

- (void)updateUsername:(NSString *)name;

- (void)resetLoginView; //activates the authorize button at the top right and the cancel button at the top left

- (void)uploadUpdatedWithUploadedBytes:(NSInteger)uploadedBytes ofTotalBytes:(NSInteger)totalBytes;
- (void)uploadFinishedWithURL:(NSURL *)url;

- (IBAction)showOnVimeo:(id)sender;

- (UITableViewCell *)customTVCellForIndexPath:(NSIndexPath *)indexPath;

@end
