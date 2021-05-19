//
//  MRZScanner.m
//  MRZScanner
//
//  Created by Alex Chang on 2021/5/19.
//

#import "MRZScanner.h"
#import <MRZEngine/MRZEngine.h>

@implementation MRZScanner

+(BOOL)initialize {
    return [MRZEngine EngineMRZ_Init];
}

+(void)release {
    [MRZEngine EngineMRZ_Release];
}

+(NSString*)scanMRZ:(UIImage*)image mode:(NSInteger)mode {
    return [MRZEngine EngineMRZ_scanMRZ:image mode:mode];
}

@end
