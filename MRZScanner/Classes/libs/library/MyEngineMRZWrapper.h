//bool EngineMRZ_Init(unsigned char* pDic, int lenDic, unsigned char* pDicG, int lenDicG);
//void EngineMRZ_Release();
//
//char* EngineMRZ_mrzScan1(unsigned char* pbyImgRGB, int w, int h);
//char* EngineMRZ_mrzScan2(unsigned char* pbyImgRGB, int w, int h);
//bool CheckImageGlare(unsigned char* pbyImgRGB, int w, int h);
//bool CheckImageBlur(unsigned char* pbyImgRGB, int w, int h, int threshold);

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MyEngineMRZWrapper : NSObject

+ (bool) EngineMRZ_Init:(unsigned char *) pDic lenDic:(int) lenDic pDicG:(unsigned char*) pDicG lenDicG:(int) lenDicG;
+ (void) EngineMRZ_Release;
+ (char*) EngineMRZ_mrzScan1:(unsigned char*) pbyImgRGB width:(int) w height:(int) h;
+ (char*) EngineMRZ_mrzScan2:(unsigned char*) pbyImgRGB width:(int) w height:(int) h;
+ (bool) CheckImageGlare:(unsigned char*) pbyImgRGB width:(int) w height:(int) h;
+ (bool) CheckImageBlur:(unsigned char*) pbyImgRGB width:(int) w height:(int) h threshold:(int) t;

@end

NS_ASSUME_NONNULL_END
