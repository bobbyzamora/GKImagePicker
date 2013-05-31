//
//  GKImageCropView.m
//  GKImagePicker
//
//  Created by Georg Kitz on 6/1/12.
//  Copyright (c) 2012 Aurora Apps. All rights reserved.
//

#import "GKImageCropView.h"
#import "GKImageCropOverlayView.h"
#import "GKResizeableCropOverlayView.h"

#import <QuartzCore/QuartzCore.h>

#define rad(angle) ((angle) / 180.0 * M_PI)

static CGRect GKScaleRect(CGRect rect, CGFloat scale) {
    return CGRectMake(rect.origin.x * scale, rect.origin.y * scale, rect.size.width * scale, rect.size.height * scale);
}

@interface ScrollView : UIScrollView
@end

@implementation ScrollView

- (void)layoutSubviews {
    [super layoutSubviews];

    UIView *zoomView = [self.delegate viewForZoomingInScrollView:self];

    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = zoomView.frame;

    // center horizontally
    if (frameToCenter.size.width < boundsSize.width) frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else frameToCenter.origin.x = 0;

    // center vertically
    if (frameToCenter.size.height < boundsSize.height) frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else frameToCenter.origin.y = 0;

    zoomView.frame = frameToCenter;
}

@end

@interface GKImageCropView () <UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) GKImageCropOverlayView *cropOverlayView;
@property (nonatomic, assign) CGFloat xOffset;
@property (nonatomic, assign) CGFloat yOffset;

- (CGAffineTransform)_orientationTransformedRectOfImage:(UIImage *)image;
@end

@implementation GKImageCropView

#pragma mark - Getter/Setter

@synthesize scrollView, imageView, cropOverlayView, resizableCropArea, xOffset, yOffset;

- (void)setImageToCrop:(UIImage *)imageToCrop {
    self.imageView.image = imageToCrop;
    [self updateZoomScale];
}

- (UIImage *)imageToCrop {
    return self.imageView.image;
}

- (void)setCropSize:(CGSize)cropSize {
    if (self.cropOverlayView == nil) {
        if (self.resizableCropArea) self.cropOverlayView = [[GKResizeableCropOverlayView alloc] initWithFrame:self.bounds andInitialContentSize:CGSizeMake(cropSize.width, cropSize.height)];
        else self.cropOverlayView = [[GKImageCropOverlayView alloc] initWithFrame:self.bounds];

        [self addSubview:self.cropOverlayView];
    }
    self.cropOverlayView.cropSize = cropSize;
}

- (CGSize)cropSize {
    return self.cropOverlayView.cropSize;
}

#define floorRect(rect) CGRectMake(floorf(rect.origin.x), floorf(rect.origin.y), floorf(rect.size.width), floorf(rect.size.height))

#pragma mark - Public Methods

- (UIImage *)croppedImage {
    //renders the the zoomed area into the cropped image
    if (self.resizableCropArea) {
        GKResizeableCropOverlayView *resizeableView = (GKResizeableCropOverlayView *)self.cropOverlayView;
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(resizeableView.contentView.frame.size.width, resizeableView.contentView.frame.size.height), self.scrollView.opaque, 0.0);
        CGContextRef ctx = UIGraphicsGetCurrentContext();

        CGFloat xPositionInScrollView = resizeableView.contentView.frame.origin.x + self.scrollView.contentOffset.x - self.xOffset;
        CGFloat yPositionInScrollView = resizeableView.contentView.frame.origin.y + self.scrollView.contentOffset.y - self.yOffset;
        CGContextTranslateCTM(ctx, -(xPositionInScrollView), -(yPositionInScrollView));

        [self.scrollView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return viewImage;
    } else {
        //scaled width/height in regards of real width to crop width
        CGFloat scaleWidth = self.imageToCrop.size.width / self.cropSize.width;
        CGFloat scaleHeight = self.imageToCrop.size.height / self.cropSize.height;
        CGFloat scale = MAX(scaleWidth, scaleHeight);

        //extract visible rect from scrollview and scale it
        CGRect visibleRect = [scrollView convertRect:scrollView.bounds toView:imageView];
        if (visibleRect.origin.x < 0) {
            visibleRect.origin.x = 0;
        }
        if (visibleRect.origin.y < 0) {
            visibleRect.origin.y = 0;
        }
        visibleRect = floorRect(GKScaleRect(visibleRect, scale));

        //transform visible rect to image orientation
        CGAffineTransform rectTransform = [self _orientationTransformedRectOfImage:self.imageToCrop];
        visibleRect = CGRectApplyAffineTransform(visibleRect, rectTransform);

        //finally crop image
        CGImageRef imageRef = CGImageCreateWithImageInRect([self.imageToCrop CGImage], visibleRect);
        UIImage *result = [UIImage imageWithCGImage:imageRef scale:self.imageToCrop.scale orientation:self.imageToCrop.imageOrientation];
        CGImageRelease(imageRef);

        return result;
    }
}

#pragma mark - Override Methods

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor blackColor];
        self.scrollView = [[ScrollView alloc] initWithFrame:self.bounds ];
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.delegate = self;
        self.scrollView.clipsToBounds = NO;
        self.scrollView.decelerationRate = 0.0;
        self.scrollView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.scrollView];

        self.imageView = [[UIImageView alloc] initWithFrame:self.scrollView.frame];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.backgroundColor = [UIColor yellowColor];
        [self.scrollView addSubview:self.imageView];

        self.scrollView.minimumZoomScale = CGRectGetWidth(self.scrollView.frame) / CGRectGetWidth(self.imageView.frame);
        self.scrollView.maximumZoomScale = 20.0;
        self.scrollView.minimumZoomScale = 1.0;
        [self updateZoomScale];
    }
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.resizableCropArea) return self.scrollView;

    GKResizeableCropOverlayView *resizeableCropView = (GKResizeableCropOverlayView *)self.cropOverlayView;

    CGRect outerFrame = CGRectInset(resizeableCropView.cropBorderView.frame, -10, -10);
    if (CGRectContainsPoint(outerFrame, point)) {
        if (resizeableCropView.cropBorderView.frame.size.width < 60 || resizeableCropView.cropBorderView.frame.size.height < 60) return [super hitTest:point withEvent:event];

        CGRect innerTouchFrame = CGRectInset(resizeableCropView.cropBorderView.frame, 30, 30);
        if (CGRectContainsPoint(innerTouchFrame, point)) return self.scrollView;

        CGRect outBorderTouchFrame = CGRectInset(resizeableCropView.cropBorderView.frame, -10, -10);
        if (CGRectContainsPoint(outBorderTouchFrame, point)) return [super hitTest:point withEvent:event];

        return [super hitTest:point withEvent:event];
    }
    return self.scrollView;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGSize size = self.cropSize;
    CGFloat toolbarSize = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 0 : 54;
    self.xOffset = floor((CGRectGetWidth(self.bounds) - size.width) * 0.5);
    self.yOffset = floor((CGRectGetHeight(self.bounds) - toolbarSize - size.height) * 0.5); //fixed

    CGFloat height = self.imageToCrop.size.height;
    CGFloat width = self.imageToCrop.size.width;

    CGFloat faktor = 0.f;
    CGFloat faktoredHeight = 0.f;
    CGFloat faktoredWidth = 0.f;

    if (width > height) {
        faktor = width / size.width;
        faktoredWidth = size.width;
        faktoredHeight =  height / faktor;
    } else {
        faktor = height / size.height;
        faktoredWidth = width / faktor;
        faktoredHeight =  size.height;
    }

    self.cropOverlayView.frame = self.bounds;
    self.scrollView.frame = CGRectMake(xOffset, yOffset, size.width, size.height);
    self.scrollView.contentSize = CGSizeMake(size.width, size.height);
    self.imageView.frame = CGRectMake(0, floor((size.height - faktoredHeight) * 0.5), faktoredWidth, faktoredHeight);

    [self updateZoomScale];
}

#pragma mark - UIScrollViewDelegate Methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

#pragma mark - Private Methods

- (void)updateZoomScale {
    CGFloat scale = self.scrollView.frame.size.width / self.imageView.frame.size.width;
    if (self.imageView.frame.size.height * scale < self.scrollView.frame.size.height) {
        scale = self.scrollView.frame.size.height / self.imageView.frame.size.height;
    }
    self.scrollView.minimumZoomScale = scale;
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
}

- (CGAffineTransform)_orientationTransformedRectOfImage:(UIImage *)img {
    CGAffineTransform rectTransform;
    switch (img.imageOrientation) {
        case UIImageOrientationLeft:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(90)), 0, -img.size.height);
            break;
        case UIImageOrientationRight:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-90)), -img.size.width, 0);
            break;
        case UIImageOrientationDown:
            rectTransform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(rad(-180)), -img.size.width, -img.size.height);
            break;
        default:
            rectTransform = CGAffineTransformIdentity;
    }

    return CGAffineTransformScale(rectTransform, img.scale, img.scale);
}

@end
