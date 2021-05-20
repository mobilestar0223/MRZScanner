//
//  MRZEngine.h
//  MRZEngine
//
//  Created by Alex Chang on 2021/5/19.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MyEngineMRZWrapper.h"

//! Project version number for MRZEngine.
FOUNDATION_EXPORT double MRZEngineVersionNumber;

//! Project version string for MRZEngine.
FOUNDATION_EXPORT const unsigned char MRZEngineVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <MRZEngine/PublicHeader.h>

@interface MRZEngine : NSObject

+(BOOL)EngineMRZ_Init;
+(void)EngineMRZ_Release;
+(NSString*)EngineMRZ_scanMRZ:(UIImage*)image mode:(NSInteger)mode;

@end
