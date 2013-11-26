//
//  GKImageCropViewController.m
//  GKImagePicker
//
//  Created by Georg Kitz on 6/1/12.
//  Copyright (c) 2012 Aurora Apps. All rights reserved.
//

#import "GKImageCropViewController.h"
#import "GKImageCropView.h"

#define PINK_COLOR     [UIColor colorWithRed:229/255.0 green:31/255.0 blue:93/255.0 alpha:1.0]

@interface GKImageCropViewController ()

@property (nonatomic, strong) GKImageCropView *imageCropView;
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *useButton;

- (void)_actionCancel;
- (void)_actionUse;
- (void)_setupNavigationBar;
- (void)_setupCropView;

@end

@implementation GKImageCropViewController

#pragma mark -
#pragma mark Getter/Setter

@synthesize sourceImage, cropSize, delegate;
@synthesize imageCropView;
@synthesize toolbar;
@synthesize cancelButton, useButton, resizeableCropArea;

#pragma mark -
#pragma Private Methods


- (void)_actionCancel {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)_actionUse {
    _croppedImage = [self.imageCropView croppedImage];
    [self.delegate imageCropController:self didFinishWithCroppedImage:_croppedImage];
}

- (void)_setupNavigationBar {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                          target:self
                                                                                          action:@selector(_actionCancel)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"GKIuse", @"")
                                                                              style:UIBarButtonItemStyleBordered
                                                                             target:self
                                                                             action:@selector(_actionUse)];
}

- (void)_setupCropView {
    self.imageCropView = [[GKImageCropView alloc] initWithFrame:self.view.bounds];
    [self.imageCropView setImageToCrop:sourceImage];
    [self.imageCropView setResizableCropArea:self.resizeableCropArea];
    [self.imageCropView setCropSize:cropSize];
    [self.view addSubview:self.imageCropView];
}

- (void)_setupCancelButton {
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [self.cancelButton setBackgroundImage:[[UIImage imageNamed:@"PLCameraSheetButton.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:0] forState:UIControlStateNormal];
    [self.cancelButton setBackgroundImage:[[UIImage imageNamed:@"PLCameraSheetButtonPressed.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:0] forState:UIControlStateHighlighted];
    
    [[self.cancelButton titleLabel] setFont:[UIFont fontWithName:@"HelveticaNeue" size:12.0]];
    [self.cancelButton setFrame:CGRectMake(0, 0, 90, 30)];
    [self.cancelButton setTitle:NSLocalizedString(@"GKIcancel", @"") forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(_actionCancel) forControlEvents:UIControlEventTouchUpInside];
}

- (void)_setupUseButton {
    self.useButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [self.useButton setBackgroundImage:[[UIImage imageNamed:@"PLCameraSheetDoneButton.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:0] forState:UIControlStateNormal];
    [self.useButton setBackgroundImage:[[UIImage imageNamed:@"PLCameraSheetDoneButtonPressed.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:0] forState:UIControlStateHighlighted];
    
    [[self.useButton titleLabel] setFont:[UIFont fontWithName:@"HelveticaNeue" size:12.0]];
    [self.useButton setFrame:CGRectMake(0, 0, 70, 30)];
    [self.useButton setTitle:NSLocalizedString(@"GKIuse", @"") forState:UIControlStateNormal];
    [self.useButton addTarget:self action:@selector(_actionUse) forControlEvents:UIControlEventTouchUpInside];
}

- (void)_setupCancelButtonIos7Style {
    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.cancelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [[self.cancelButton titleLabel] setFont:[UIFont fontWithName:@"HelveticaNeue" size:17.0]];
    [self.cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal&UIControlStateHighlighted];
    [self.cancelButton setFrame:CGRectMake(0, 0, 90, 30)];
    [self.cancelButton setTitle:NSLocalizedString(@"GKIcancel", @"") forState:UIControlStateNormal];
    [self.cancelButton addTarget:self action:@selector(_actionCancel) forControlEvents:UIControlEventTouchUpInside];
}

- (void)_setupUseButtonIos7Style {
    self.useButton = [UIButton buttonWithType:UIButtonTypeCustom];
self.useButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [[self.useButton titleLabel] setFont:[UIFont fontWithName:@"HelveticaNeue" size:17.0]];
    [self.useButton setTitleColor:PINK_COLOR forState:UIControlStateNormal&UIControlStateHighlighted];
    [self.useButton setFrame:CGRectMake(0, 0, 70, 30)];
    [self.useButton setTitle:NSLocalizedString(@"GKIuse", @"") forState:UIControlStateNormal];
    [self.useButton addTarget:self action:@selector(_actionUse) forControlEvents:UIControlEventTouchUpInside];
}


- (UIImage *)_toolbarBackgroundImage {
    CGFloat components[] = {
        1.,          1.,         1.,          1.,
        123. / 255., 125 / 255., 132. / 255., 1.
    };
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(320, 54), YES, 0.0);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, NULL, 2);
    
    CGContextDrawLinearGradient(ctx, gradient, CGPointMake(0, 0), CGPointMake(0, 54), kCGImageAlphaNoneSkipFirst);
    
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    
    CGGradientRelease(gradient);
    UIGraphicsEndImageContext();
    
    return viewImage;
}

- (void)_setupToolbar {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {

        //configure toolbar for ios 7 style
        NSString *version = [[UIDevice currentDevice] systemVersion];
        int ver = [version intValue];
        if (ver >= 7){
            self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
            self.toolbar.barStyle = UIBarStyleDefault;
            self.toolbar.translucent = YES;
            [self _setupUseButtonIos7Style];
            [self _setupCancelButtonIos7Style];
        }
        else {
            self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
            [self.toolbar setBackgroundImage:[self _toolbarBackgroundImage] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
            [self _setupUseButton];
            [self _setupCancelButton];
        }




        [self.view addSubview:self.toolbar];

        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithCustomView:self.cancelButton];
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *use = [[UIBarButtonItem alloc] initWithCustomView:self.useButton];

        [self.toolbar setItems:[NSArray arrayWithObjects:cancel, flex, flex, use, nil]];
    }
}

#pragma mark -
#pragma Super Class Methods

- (id)init {
    self = [super init];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = NSLocalizedString(@"GKIchoosePhoto", @"");
    
    [self _setupNavigationBar];
    [self _setupCropView];
    [self _setupToolbar];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController setNavigationBarHidden:YES];
    } else {
        [self.navigationController setNavigationBarHidden:NO];
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.imageCropView.frame = self.view.bounds;
    self.toolbar.frame = CGRectMake(0, CGRectGetHeight(self.view.frame) - 54, 320, 54);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
