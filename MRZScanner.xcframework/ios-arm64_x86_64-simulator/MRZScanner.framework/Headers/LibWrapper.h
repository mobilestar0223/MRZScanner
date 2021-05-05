//
//  LibWrapper.h
//  MrzScanner
//
//  Created by Alex Chang on 2021/1/4.
//  Copyright © 2021 biomild. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MyEngineMRZWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface LibWrapper : NSObject

+(BOOL)EngineMRZ_Init;
+(void)EngineMRZ_Release;
+(NSString*)EngineMRZ_scanMRZ:(UIImage*)image mode:(NSInteger)mode;

@end

NS_ASSUME_NONNULL_END
