//
//  MRZScanner.m
//  MRZScanner
//
//  Created by Alex Chang on 2021/5/19.
//

#import "MRZScanner.h"
#import "Utils.h"

@implementation MRZScanner

+(BOOL)initialize {
    NSURL *url1 = [[NSBundle mainBundle] URLForResource:@"pattern" withExtension:@"dic"];
    NSURL *url2 = [[NSBundle mainBundle] URLForResource:@"pattern_g" withExtension:@"dic"];

    NSData *patternData1 = [NSData dataWithContentsOfURL:url1];
    NSData *patternData2 = [NSData dataWithContentsOfURL:url2];

    unsigned char* pattern = (unsigned char*)[patternData1 bytes];
    unsigned char* pattern_g = (unsigned char*)[patternData2 bytes];
    int lenDic = (int)[patternData1 length];
    int lenDicG = (int)[patternData2 length];

    return [MyEngineMRZWrapper EngineMRZ_Init:pattern_g lenDic:lenDicG pDicG:pattern lenDicG:lenDic];
}

+(void)release {
    [MyEngineMRZWrapper EngineMRZ_Release];
}

+(NSString*)scanMRZ:(UIImage*)image mode:(NSInteger)mode {
    unsigned char* byteArray = [Utils convertUIImageToBitmapRGB:image];
    int width = (int)image.size.width;
    int height = (int)image.size.height;

    char* result;

    if (mode == 0) {
        result = [MyEngineMRZWrapper EngineMRZ_mrzScan1:byteArray width:width height:height];
    } else {
        result = [MyEngineMRZWrapper EngineMRZ_mrzScan2:byteArray width:width height:height];
    }

    if (result == NULL) {
        return @"the mrz data can not be detected";
    }

    return [[NSString alloc] initWithUTF8String:result];
}

@end
