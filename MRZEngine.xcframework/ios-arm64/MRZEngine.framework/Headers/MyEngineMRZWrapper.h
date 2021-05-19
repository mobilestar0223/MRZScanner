bool EngineMRZ_Init(unsigned char* pDic, int lenDic, unsigned char* pDicG, int lenDicG);
void EngineMRZ_Release();

char* EngineMRZ_mrzScan1(unsigned char* pbyImgRGB, int w, int h);
char* EngineMRZ_mrzScan2(unsigned char* pbyImgRGB, int w, int h);
bool CheckImageGlare(unsigned char* pbyImgRGB, int w, int h);
bool CheckImageBlur(unsigned char* pbyImgRGB, int w, int h, int threshold);
