//
//  Utils.h
//  MRZScanner
//
//  Created by Alex Chang on 2021/5/19.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Utils : NSObject

+ (unsigned char *) convertUIImageToBitmapRGBA8:(UIImage *) image;
+ (unsigned char *) convertUIImageToBitmapRGB:(UIImage *) image;
+ (CGContextRef) newBitmapRGBA8ContextFromImage:(CGImageRef) image;
+ (UIImage *) convertBitmapRGBA8ToUIImage:(unsigned char *) buffer withWidth:(int) width withHeight:(int) height;
+ (UIImage *) convertBitmapRGBToUIImage:(unsigned char *) buffer withWidth:(int) width withHeight:(int) height;

@end

NS_ASSUME_NONNULL_END
