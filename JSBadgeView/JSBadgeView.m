/*
 Copyright (c) 2013 Javier Soto.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "JSBadgeView.h"
#import <FontAwesomeKit/FontAwesomeKit.h>
//#import <QuartzCore/QuartzCore.h>
#include <mach-o/dyld.h>

#if !__has_feature(objc_arc)
#error JSBadgeView must be compiled with ARC.
#endif

// Silencing some deprecation warnings if your deployment target is iOS7 that can only be fixed by using methods that
// Are only available on iOS7.
// Soon JSBadgeView will require iOS 7 and we'll be able to use the new methods.
#if  __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_7_0
    #define JSBadgeViewSilenceDeprecatedMethodStart()   _Pragma("clang diagnostic push") \
                                                        _Pragma("clang diagnostic ignored \"-Wdeprecated-declarations\"")
    #define JSBadgeViewSilenceDeprecatedMethodEnd()     _Pragma("clang diagnostic pop")
#else
    #define JSBadgeViewSilenceDeprecatedMethodStart()
    #define JSBadgeViewSilenceDeprecatedMethodEnd()
#endif

//static const CGFloat JSBadgeViewShadowRadius = 1.0f;
//static const CGFloat JSBadgeViewHeight = 16.0f;
//static const CGFloat JSBadgeViewTextSideMargin = 8.0f;
//static const CGFloat JSBadgeViewCornerRadius = 10.0f;

static const CGFloat JSBadgeViewShadowRadius = 1.0f;
//static const CGFloat JSBadgeViewHeight = 20.0f;
static const CGFloat JSBadgeViewTextSideMargin = 11.0f;
static const CGFloat JSBadgeViewCornerRadius = 10.0f;


// Thanks to Peter Steinberger: https://gist.github.com/steipete/6526860
static BOOL JSBadgeViewIsUIKitFlatMode(void)
{
    static BOOL isUIKitFlatMode = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#ifndef kCFCoreFoundationVersionNumber_iOS_7_0
#define kCFCoreFoundationVersionNumber_iOS_7_0 847.2
#endif
#ifndef UIKitVersionNumber_iOS_7_0
#define UIKitVersionNumber_iOS_7_0 0xB57
#endif
        // We get the modern UIKit if system is running >= iOS 7 and we were linked with >= SDK 7.
        if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0) {
            isUIKitFlatMode = (NSVersionOfLinkTimeLibrary("UIKit") >> 16) >= UIKitVersionNumber_iOS_7_0;
        }
    });

    return isUIKitFlatMode;
}

@implementation UIColor (LightAndDark)

- (UIColor *)lighterColor
{
    CGFloat h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:MIN(b * 1.3, 1.0)
                               alpha:a];
    return nil;
}

- (UIColor *)darkerColor
{
    CGFloat h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:b * 0.75
                               alpha:a];
    return nil;
}
@end

@implementation JSBadgeView {
    CGFloat JSBadgeViewHeight;
    CGFloat voicenoteSize;
    CGFloat cameraSize;
    CGFloat textnoteSize;
    CGSize newSize;
}

+ (void)applyCommonStyle
{
    JSBadgeView *badgeViewAppearanceProxy = JSBadgeView.appearance;

    badgeViewAppearanceProxy.backgroundColor = UIColor.clearColor;
    badgeViewAppearanceProxy.badgeAlignment = JSBadgeViewAlignmentTopRight;
    badgeViewAppearanceProxy.badgeBackgroundColor = UIColor.clearColor;
    badgeViewAppearanceProxy.badgeTextFont = [UIFont boldSystemFontOfSize:UIFont.systemFontSize];
    badgeViewAppearanceProxy.badgeTextColor = UIColor.whiteColor;
    
}

+ (void)applyLegacyStyle
{
    JSBadgeView *badgeViewAppearanceProxy = JSBadgeView.appearance;

    badgeViewAppearanceProxy.badgeOverlayColor = [UIColor colorWithWhite:1.0f alpha:0.3];
    badgeViewAppearanceProxy.badgeTextShadowColor = UIColor.clearColor;
    badgeViewAppearanceProxy.badgeShadowColor = [UIColor colorWithWhite:0.0f alpha:0.4f];
    badgeViewAppearanceProxy.badgeShadowSize = CGSizeMake(0.0f, 3.0f);
    badgeViewAppearanceProxy.badgeStrokeWidth = 2.0f;
    badgeViewAppearanceProxy.badgeStrokeColor = UIColor.whiteColor;
}

+ (void)applyIOS7Style
{
    JSBadgeView *badgeViewAppearanceProxy = JSBadgeView.appearance;

    badgeViewAppearanceProxy.badgeOverlayColor = UIColor.clearColor;
    badgeViewAppearanceProxy.badgeTextShadowColor = UIColor.clearColor;
    badgeViewAppearanceProxy.badgeShadowColor = UIColor.clearColor;
    badgeViewAppearanceProxy.badgeStrokeWidth = 0.0f;
    badgeViewAppearanceProxy.badgeStrokeColor = badgeViewAppearanceProxy.badgeBackgroundColor;
}

+ (void)initialize
{
    if (self == JSBadgeView.class)
    {
        [self applyCommonStyle];
//        [self applyLegacyStyle];

        if (JSBadgeViewIsUIKitFlatMode())
        {
            [self applyIOS7Style];
        }
        else
        {
            [self applyLegacyStyle];
        }
    }
}

- (id)initWithParentView:(UIView *)parentView alignment:(JSBadgeViewAlignment)alignment
{
    if ((self = [self initWithFrame:CGRectZero]))
    {
        self.badgeAlignment = alignment;
        [parentView addSubview:self];
    }
    
    return self;
}

#pragma mark - Layout

- (CGFloat)marginToDrawInside
{
    return self.badgeStrokeWidth * 2.0f;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGRect newFrame = self.frame;
    const CGRect superviewBounds = CGRectIsEmpty(_frameToPositionInRelationWith) ? self.superview.bounds : _frameToPositionInRelationWith;
    
    const CGFloat textWidth = [self sizeOfTextForCurrentSettings].width;

    const CGFloat marginToDrawInside = [self marginToDrawInside];
    const CGFloat viewWidth = textWidth + JSBadgeViewTextSideMargin + (marginToDrawInside * 2);
    if ([self.badgeText isEqualToString:@" "]) {
        JSBadgeViewHeight = 16;
    } else {
        JSBadgeViewHeight = 20;
    }
    
    if (_isSegmentBadge) {
        JSBadgeViewHeight += 2;
    }
    if (_isNumber) {
        JSBadgeViewHeight -= 1;
    }
    
    newSize = CGSizeMake(60.f, 26.f);
    voicenoteSize = 20;
    cameraSize = 24;
    textnoteSize = 22;
    
    
    const CGFloat viewHeight = JSBadgeViewHeight + (marginToDrawInside * 2);
    
    const CGFloat superviewWidth = superviewBounds.size.width;
    const CGFloat superviewHeight = superviewBounds.size.height;
    
    newFrame.size.width = viewWidth;
    newFrame.size.height = viewHeight;
    
    switch (self.badgeAlignment) {
        case JSBadgeViewAlignmentTopLeft:
            newFrame.origin.x = -viewWidth / 2.0f;
            newFrame.origin.y = -viewHeight / 2.0f;
            break;
        case JSBadgeViewAlignmentTopRight:
            newFrame.origin.x = superviewWidth - (viewWidth / 2.0f);
            newFrame.origin.y = -viewHeight / 2.0f;
            break;
        case JSBadgeViewAlignmentTopCenter:
            newFrame.origin.x = (superviewWidth - viewWidth) / 2.0f;
            newFrame.origin.y = -viewHeight / 2.0f;
            break;
        case JSBadgeViewAlignmentCenterLeft:
            newFrame.origin.x = -viewWidth / 2.0f;
            newFrame.origin.y = (superviewHeight - viewHeight) / 2.0f;
            break;
        case JSBadgeViewAlignmentCenterRight:
            newFrame.origin.x = superviewWidth - (viewWidth / 2.0f);
            newFrame.origin.y = (superviewHeight - viewHeight) / 2.0f;
            break;
        case JSBadgeViewAlignmentBottomLeft:
            newFrame.origin.x = -viewWidth / 2.0f;
            newFrame.origin.y = superviewHeight - (viewHeight / 2.0f);
            break;
        case JSBadgeViewAlignmentBottomRight:
            newFrame.origin.x = superviewWidth - (viewWidth / 2.0f);
            newFrame.origin.y = superviewHeight - (viewHeight / 2.0f);
            break;
        case JSBadgeViewAlignmentBottomCenter:
            newFrame.origin.x = (superviewWidth - viewWidth) / 2.0f;
            newFrame.origin.y = superviewHeight - (viewHeight / 2.0f);
            break;
        case JSBadgeViewAlignmentCenter:
            newFrame.origin.x = (superviewWidth - viewWidth) / 2.0f;
            newFrame.origin.y = (superviewHeight - viewHeight) / 2.0f;
            break;
        default:
            NSAssert(NO, @"Unimplemented JSBadgeAligment type %lu", self.badgeAlignment);
    }
    
    newFrame.origin.x += _badgePositionAdjustment.x;
    newFrame.origin.y += _badgePositionAdjustment.y;
    
    // Do not set frame directly so we do not interfere with any potential transform set on the view.
    self.bounds = CGRectIntegral(CGRectMake(0, 0, CGRectGetWidth(newFrame), CGRectGetHeight(newFrame)));
    self.center = CGPointMake(ceilf(CGRectGetMidX(newFrame)), ceilf(CGRectGetMidY(newFrame)));
    
    [self setNeedsDisplay];
}

#pragma mark - Private

- (CGSize)sizeOfTextForCurrentSettings
{
    JSBadgeViewSilenceDeprecatedMethodStart();
    return [self.badgeText sizeWithFont:self.badgeTextFont];
    JSBadgeViewSilenceDeprecatedMethodEnd();
}

#pragma mark - Setters

- (void)setBadgeAlignment:(JSBadgeViewAlignment)badgeAlignment
{
    if (badgeAlignment != _badgeAlignment)
    {
        _badgeAlignment = badgeAlignment;

        [self setNeedsLayout];
    }
}

- (void)setBadgePositionAdjustment:(CGPoint)badgePositionAdjustment
{
    _badgePositionAdjustment = badgePositionAdjustment;
    
    [self setNeedsLayout];
}

- (void)setBadgeText:(NSString *)badgeText
{
    if (badgeText != _badgeText)
    {
        _badgeText = [badgeText copy];
        
        [self setNeedsLayout];
    }
}

- (void)setBadgeTextColor:(UIColor *)badgeTextColor
{
    if (badgeTextColor != _badgeTextColor)
    {
        _badgeTextColor = badgeTextColor;
        
        [self setNeedsDisplay];
    }
}

- (void)setBadgeTextShadowColor:(UIColor *)badgeTextShadowColor
{
    if (badgeTextShadowColor != _badgeTextShadowColor)
    {
        _badgeTextShadowColor = badgeTextShadowColor;
        
        [self setNeedsDisplay];
    }
}

- (void)setBadgeTextShadowOffset:(CGSize)badgeTextShadowOffset
{
    _badgeTextShadowOffset = badgeTextShadowOffset;
    
    [self setNeedsDisplay];
}

- (void)setBadgeTextFont:(UIFont *)badgeTextFont
{
    if (badgeTextFont != _badgeTextFont)
    {
        _badgeTextFont = badgeTextFont;
        
        [self setNeedsDisplay];
    }
}

- (void)setBadgeBackgroundColor:(UIColor *)badgeBackgroundColor
{
    if (badgeBackgroundColor != _badgeBackgroundColor)
    {
        _badgeBackgroundColor = badgeBackgroundColor;
        
        [self setNeedsDisplay];
    }
}

- (void)setBadgeStrokeWidth:(CGFloat)badgeStrokeWidth
{
    if (badgeStrokeWidth != _badgeStrokeWidth)
    {
        _badgeStrokeWidth = badgeStrokeWidth;

        [self setNeedsLayout];
        [self setNeedsDisplay];
    }
}

- (void)setBadgeStrokeColor:(UIColor *)badgeStrokeColor
{
    if (badgeStrokeColor != _badgeStrokeColor)
    {
        _badgeStrokeColor = badgeStrokeColor;
        
        [self setNeedsDisplay];
    }
}

- (void)setBadgeShadowColor:(UIColor *)badgeShadowColor
{
    if (badgeShadowColor != _badgeShadowColor)
    {
        _badgeShadowColor = badgeShadowColor;
        
        [self setNeedsDisplay];
    }
}

- (void)setBadgeShadowSize:(CGSize)badgeShadowSize
{
    if (!CGSizeEqualToSize(badgeShadowSize, _badgeShadowSize))
    {
        _badgeShadowSize = badgeShadowSize;

        [self setNeedsDisplay];
    }
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    const BOOL anyTextToDraw = (self.badgeText.length > 0);
    
    if (anyTextToDraw)
    {
        CGContextRef ctx = UIGraphicsGetCurrentContext();

        const CGFloat marginToDrawInside = [self marginToDrawInside];
        const CGRect rectToDraw = CGRectInset(rect, marginToDrawInside, marginToDrawInside);
        
        UIBezierPath *borderPath = [UIBezierPath bezierPathWithRoundedRect:rectToDraw byRoundingCorners:(UIRectCorner)UIRectCornerAllCorners cornerRadii:CGSizeMake(JSBadgeViewCornerRadius, JSBadgeViewCornerRadius)];
        
        /* Background and shadow */
        CGContextSaveGState(ctx);
        {
            CGContextAddPath(ctx, borderPath.CGPath);
            
            CGContextSetFillColorWithColor(ctx, self.badgeBackgroundColor.CGColor);
            CGContextSetShadowWithColor(ctx, self.badgeShadowSize, JSBadgeViewShadowRadius, self.badgeShadowColor.CGColor);
            
            CGContextDrawPath(ctx, kCGPathFill);
        }
        CGContextRestoreGState(ctx);
        
        const BOOL colorForOverlayPresent = self.badgeOverlayColor && ![self.badgeOverlayColor isEqual:[UIColor clearColor]];
        
        if (colorForOverlayPresent)
        {
            /* Gradient overlay */
            CGContextSaveGState(ctx);
            {
                CGContextAddPath(ctx, borderPath.CGPath);
                CGContextClip(ctx);
                
                const CGFloat height = rectToDraw.size.height;
                const CGFloat width = rectToDraw.size.width;
                
                const CGRect rectForOverlayCircle = CGRectMake(rectToDraw.origin.x,
                                                               rectToDraw.origin.y - ceilf(height * 0.5),
                                                               width,
                                                               height);

                CGContextAddEllipseInRect(ctx, rectForOverlayCircle);
                CGContextSetFillColorWithColor(ctx, self.badgeOverlayColor.CGColor);

                CGContextDrawPath(ctx, kCGPathFill);
            }
            CGContextRestoreGState(ctx);
        }
        
        /* Stroke */
        CGContextSaveGState(ctx);
        {
            CGContextAddPath(ctx, borderPath.CGPath);
            
            CGContextSetLineWidth(ctx, self.badgeStrokeWidth);
            CGContextSetStrokeColorWithColor(ctx, self.badgeStrokeColor.CGColor);
            
            CGContextDrawPath(ctx, kCGPathStroke);
        }
        CGContextRestoreGState(ctx);
        
        if (self.badgeText.length > 2) {
            if ([self.badgeText isEqualToString:@"VVV"]) {
                [self voicenoteOnly:ctx withRect:rectToDraw];
            } else if ([self.badgeText isEqualToString:@"CCC"]) {
                [self cameraOnly:ctx withRect:rectToDraw];
            } else if ([self.badgeText isEqualToString:@"TTT"]) {
                [self textnoteOnly:ctx withRect:rectToDraw];
            } else if ([self.badgeText isEqualToString:@"VVcc"]) {
                [self voicenoteCamera:ctx withRect:rectToDraw];
            } else if ([self.badgeText isEqualToString:@"VVTt"]) {
                [self voicenoteTextnote:ctx withRect:rectToDraw];
            } else if ([self.badgeText isEqualToString:@"CCTT"]) {
                [self cameraTextnote:ctx withRect:rectToDraw];
            } else if ([self.badgeText isEqualToString:@"Vvcctt"]) {
                [self allNotes:ctx withRect:rectToDraw];
            }
        }
        
        if (_isNumber && _badgeText.length > 0) {
            
            /* Text */
            
            CGContextSaveGState(ctx);
            {
                CGContextSetFillColorWithColor(ctx, self.badgeTextColor.CGColor);
                CGContextSetShadowWithColor(ctx, self.badgeTextShadowOffset, 1.0, self.badgeTextShadowColor.CGColor);
                
                CGRect textFrame = rectToDraw;
                const CGSize textSize = [self sizeOfTextForCurrentSettings];
                
                textFrame.size.height = textSize.height;
                textFrame.origin.y = rectToDraw.origin.y + ceilf((rectToDraw.size.height - textFrame.size.height) / 2.0f);
                
                JSBadgeViewSilenceDeprecatedMethodStart();
                [self.badgeText drawInRect:textFrame
                                  withFont:self.badgeTextFont
                             lineBreakMode:NSLineBreakByClipping
                                 alignment:NSTextAlignmentCenter];
                JSBadgeViewSilenceDeprecatedMethodEnd();
            }
            CGContextRestoreGState(ctx);
        }
    }
}

-(UIColor*)voicenoteColor {
//    if (_dimVoiceIcon == YES) {
//        NSLog(@"voice Icon returning dimmed");
////        return [self.badgeTextColor darkerColor];
//        self.badgeTextColor = [UIColor colorWithWhite:0.2f alpha:0.5f];
//        return [UIColor colorWithWhite:0.2f alpha:0.5f];
//    } else {
        return self.badgeTextColor;
//    }
}

-(UIColor*)cameraColor {
//    if (_dimCameraIcon == YES) {
//        NSLog(@"camera Icon returning dimmed");
//        self.badgeTextColor = [UIColor colorWithWhite:0.2f alpha:0.5f];
//        return [UIColor colorWithWhite:0.2f alpha:0.5f];
////        return [self.badgeTextColor darkerColor];
//    } else {
        return self.badgeTextColor;
//    }
}

-(UIColor*)textnoteColor {
//    if (_dimTextIcon == YES) {
////        return [self.badgeTextColor darkerColor];
//        NSLog(@"text Icon returning dimmed");
//        self.badgeTextColor = [UIColor colorWithWhite:0.2f alpha:0.5f];
//        return [UIColor colorWithWhite:0.2f alpha:0.5f];
//    } else {
        return self.badgeTextColor;
//    }
}

-(void)voicenoteOnly:(CGContextRef)ctx withRect:(CGRect)rect {
    NSInteger xF = -11;
    NSInteger yF = -3;
    if (_isSegmentBadge) {
        xF += 2;
        yF += 3;
    }
    
    FAKIonIcons* mic = [FAKIonIcons micAIconWithSize:voicenoteSize + 1];
    [mic addAttribute:NSForegroundColorAttributeName value:[self voicenoteColor]];
    UIImage *micImage = [mic imageWithSize:newSize];
    CGContextSaveGState(ctx); {
        [micImage drawInRect:CGRectMake(xF,yF,newSize.width,newSize.height)];
        UIGraphicsEndImageContext();
    }
    CGContextRestoreGState(ctx);
}

-(void)cameraOnly:(CGContextRef)ctx withRect:(CGRect)rect {
    NSInteger xF = -9;
    NSInteger yF = -3;
    if (_isSegmentBadge) {
        xF += 2;
        yF += 2;
    }
    
    FAKIonIcons* camera = [FAKIonIcons iosCameraIconWithSize:cameraSize + 1];
    [camera addAttribute:NSForegroundColorAttributeName value:[self cameraColor]];
    UIImage *image = [camera imageWithSize:newSize];
    CGContextSaveGState(ctx); {
        [image drawInRect:CGRectMake(xF,yF,newSize.width,newSize.height)];
        UIGraphicsEndImageContext();
    }
    CGContextRestoreGState(ctx);
}

-(void)textnoteOnly:(CGContextRef)ctx withRect:(CGRect)rect {
    NSInteger xF = -10;
    NSInteger yF = -3;
    if (_isSegmentBadge) {
        xF += 2;
        yF += 3;
    }
    
    FAKIonIcons* textNote = [FAKIonIcons iosComposeIconWithSize:textnoteSize + 1];
    [textNote addAttribute:NSForegroundColorAttributeName value:[self textnoteColor]];
    UIImage *textNoteImage = [textNote imageWithSize:newSize];
    CGContextSaveGState(ctx); {
        [textNoteImage drawInRect:CGRectMake(xF,yF,newSize.width,newSize.height)];
        UIGraphicsEndImageContext();
    }
    CGContextRestoreGState(ctx);
}

-(void)voicenoteCamera:(CGContextRef)ctx withRect:(CGRect)rect {
    NSInteger xFvoice = -18;
    NSInteger yFvoice = -3;
    NSInteger xFcamera = 1;
    NSInteger yFcamera = -3;
    if (_isSegmentBadge) {
        xFvoice += 2;
        yFvoice += 3;
        xFcamera += 2;
        yFcamera += 3;
    }
    
    FAKIonIcons* plus = [FAKIonIcons iosCameraIconWithSize:cameraSize];
    [plus addAttribute:NSForegroundColorAttributeName value:[self cameraColor]];

    UIImage *image = [plus imageWithSize:newSize];
    CGContextSaveGState(ctx); {
        FAKIonIcons* mic = [FAKIonIcons micAIconWithSize:voicenoteSize];
        [mic addAttribute:NSForegroundColorAttributeName value:[self voicenoteColor]];
        UIImage *micImage = [mic imageWithSize:newSize];
        [micImage drawInRect:CGRectMake(xFvoice,yFvoice,newSize.width,newSize.height)];
        
        [image drawInRect:CGRectMake(xFcamera,yFcamera,newSize.width,newSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        [newImage drawInRect:rect];
        UIGraphicsEndImageContext();
    }
    CGContextRestoreGState(ctx);
}

-(void)voicenoteTextnote:(CGContextRef)ctx withRect:(CGRect)rect {
    NSInteger xFvoice = -18;
    NSInteger yFvoice = -3;
    NSInteger xFtext = -1;
    NSInteger yFtext = -3;
    NSInteger textIconScaleFactor = 0;
    if (_isSegmentBadge) {
        xFvoice += 2;
        yFvoice += 3;
        xFtext += 2;
        yFtext += 3;
        textIconScaleFactor = -1;
    }
    
    FAKIonIcons* plus = [FAKIonIcons iosComposeIconWithSize:textnoteSize + textIconScaleFactor];
    [plus addAttribute:NSForegroundColorAttributeName value:[self textnoteColor]];
    UIImage *image = [plus imageWithSize:newSize];
    CGContextSaveGState(ctx); {
        FAKIonIcons* mic = [FAKIonIcons micAIconWithSize:voicenoteSize];
        [mic addAttribute:NSForegroundColorAttributeName value:[self voicenoteColor]];
        UIImage *micImage = [mic imageWithSize:newSize];
        [micImage drawInRect:CGRectMake(xFvoice,yFvoice,newSize.width,newSize.height)];
        
        [image drawInRect:CGRectMake(xFtext,yFtext,newSize.width,newSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        [newImage drawInRect:rect];
        UIGraphicsEndImageContext();
    }
    CGContextRestoreGState(ctx);
    
}

-(void)cameraTextnote:(CGContextRef)ctx withRect:(CGRect)rect {
    NSInteger xFcamera = -14;
    NSInteger yFcamera = -3;
    NSInteger xFtext = 5;
    NSInteger yFtext = -3;
    if (_isSegmentBadge) {
        xFcamera += 2;
        yFcamera += 3;
        xFtext += 2;
        yFtext += 3;
    }
    
    FAKIonIcons* plus = [FAKIonIcons iosComposeIconWithSize:textnoteSize];
    [plus addAttribute:NSForegroundColorAttributeName value:[self textnoteColor]];
    UIImage *image = [plus imageWithSize:newSize];
    CGContextSaveGState(ctx); {
        FAKIonIcons* mic = [FAKIonIcons iosCameraIconWithSize:cameraSize];
        [mic addAttribute:NSForegroundColorAttributeName value:[self cameraColor]];
        UIImage *micImage = [mic imageWithSize:newSize];
        [micImage drawInRect:CGRectMake(xFcamera,yFcamera,newSize.width,newSize.height)];
        
        [image drawInRect:CGRectMake(xFtext,yFtext,newSize.width,newSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        [newImage drawInRect:rect];
        UIGraphicsEndImageContext();
    }
    CGContextRestoreGState(ctx);
    
}

-(void)allNotes:(CGContextRef)ctx withRect:(CGRect)rect {
    
    NSInteger xFvoice = -20;
    NSInteger yFvoice = -3;
    NSInteger xFcamera = 11;
    NSInteger yFcamera = -3;
    NSInteger xFtext = -5;
    NSInteger yFtext = -3;
    NSInteger voiceIconScaleFactor = 0;
    if (_isSegmentBadge) {
        xFvoice += 1;
        yFvoice += 3;
        xFcamera += 1.5;
        yFcamera += 3;
        xFtext += 1;
        yFtext += 3;
        voiceIconScaleFactor = -1;
    }
    
    FAKIonIcons* plus = [FAKIonIcons iosCameraIconWithSize:cameraSize - 1];
    [plus addAttribute:NSForegroundColorAttributeName value:[self cameraColor]];
    UIImage *image = [plus imageWithSize:newSize];
    CGContextSaveGState(ctx); {
        
        FAKIonIcons* mic = [FAKIonIcons micAIconWithSize:voicenoteSize + voiceIconScaleFactor];
        [mic addAttribute:NSForegroundColorAttributeName value:[self voicenoteColor]];
        UIImage *micImage = [mic imageWithSize:newSize];
        [micImage drawInRect:CGRectMake(xFvoice,yFvoice,newSize.width,newSize.height)];
        
        FAKIonIcons* textNote = [FAKIonIcons iosComposeIconWithSize:textnoteSize - 1];
        [textNote addAttribute:NSForegroundColorAttributeName value:[self textnoteColor]];
        UIImage *textNoteImage = [textNote imageWithSize:newSize];
        [textNoteImage drawInRect:CGRectMake(xFtext,yFtext,newSize.width,newSize.height)];
        
        [image drawInRect:CGRectMake(xFcamera,yFcamera,newSize.width,newSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        [newImage drawInRect:rect];
        UIGraphicsEndImageContext();
    }
    CGContextRestoreGState(ctx);
    
}
@end
