//
//  MRZScanner.h
//  MRZScanner
//
//  Created by Alex Chang on 2021/5/19.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MyEngineMRZWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface MRZScanner : NSObject

+(BOOL)initialize;
+(void)release;
+(NSString*)scanMRZ:(UIImage*)image mode:(NSInteger)mode;

@end

NS_ASSUME_NONNULL_END
