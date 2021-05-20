// ImageFilter.h: interface for the CImageFilter class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(_IMAGEFILTER_H__)
#define _IMAGEFILTER_H__


class CImageFilter  
{
public:
	CImageFilter();
	virtual ~CImageFilter();

	static BOOL    RemoveNoizeDib(BYTE *pDib,CSize ThSz,int ThAs);
	static BOOL    RemoveNoizeBinDib(BYTE *pDib,CSize ThSz,int ThAs);
    static BOOL    RemoveNoizeBinImg_CCH(BYTE *pImg, int w, int h, BOOL bzoom=FALSE);
	static BOOL    RemoveNoizeBinImg(BYTE *pImg, int w, int h, CSize ThSz, int ThAs);
	static void    RemoveNoisebyMedian(BYTE* pImg,int w,int h,int mode,CRect rt);


	// Morphology operations
	static BOOL    MorphoErosionDib(BYTE *pDib);
	static BOOL    MorphoErosionBinDib(BYTE *pDib);
	static BOOL    MorphoErosionGrayDib(BYTE *pDib);
	static BOOL    MorphoErosion24Dib(BYTE *pDib);

	static BOOL    MorphoDilationDib(BYTE *pDib);
	static BOOL    MorphoDilationBinDib(BYTE *pDib);
	static BOOL    MorphoDilationGrayDib(BYTE *pDib);
	static BOOL    MorphoDilation24Dib(BYTE *pDib);

	static BYTE*    MorphoErosion(BYTE *pImg,int w,int h);
	BYTE*   MorphoErosion(BYTE *pImg, int w, int h,int groupSize,int* Mask);
	BYTE*   MorphoDilation(BYTE *pImg, int w, int h, int groupSize,int* Mask);
	BYTE*   MorphoOpening(BYTE *pImg, int w, int h, int groupSize,int* Mask);
	BYTE*   MorphoClosing(BYTE *pImg, int w, int h, int groupSize,int* Mask);

	static BYTE*   FilteringImage(BYTE *pImg, int w, int h, int groupSize,double* Filter);
	static BYTE*   FilteringImage(BYTE *pImg, int w, int h, double* Filter, int f_w, int f_h);
	unsigned int*	MakeIntegralImg(BYTE* pImg,int w,int h);
	static  BYTE*	MeanFilter(BYTE* pImg,int w,int h,int nWinSize);
	static  void    MeanFilter(BYTE* pImg,int w,int h);
	static  void    MedianFilter(BYTE* pImg,int w,int h);

	static  BOOL	CorrectBrightForCameraImg(BYTE* pImg,int w,int h);
	static  BYTE*	CorrectBrightForCameraDib(BYTE* pDib);
	//
	static  float	GetPixelWidth(BYTE* pImg,int w,CRect rt);
	static  void	EnhanceVertLine(BYTE *pImg, int w, int h);
	static  void	My_pre_process(BYTE *buffer, int width, int height);
    static  BYTE*	EnhancedFilter(BYTE *pImg, int w, int h, CSize WinSZ);
    static  BYTE*	LinearEnhancedFilter(BYTE *pImg, int w, int h, int divW,int divH);
    static  BOOL	GetEdgeExtractionImg_V_Sobel(BYTE* pImg,int w,int h,int* Edge,int Pecent);
    static  void	RemoveLongAndShortLine_speed(BYTE *pImg, int w, int h,int Th_short,int Th_long);
    static  void	GetSortValueOrder(float* fValue,int* Ord,int n,int Direct=0);
    static  void	FindMultiCarPlate(BYTE *pImg, int w, int h, CSize defPlateSz,CRect defPlateRt,CRect* Rts,int& nNum,float* Score);

	static  BYTE*	GetEdgeExtractionImgWindow(BYTE* pImg,int w,int h,int Th);
	static  BOOL	GetEdgeExtractionImg(BYTE* pImg,int w,int h,int Th,CRect SubRt,int* Edge);
	static  BOOL	GetSharpnessQuantity(BYTE* pImg,int w,int h);

	static	BOOL	Contrast_Enhancement(BYTE* Img,int w,int h);
	static	BOOL	Contrast_EnhancementInSubRt(BYTE* Img,int w,int h,CRect subRt,BOOL bAllArea=TRUE,BOOL bForce = TRUE);
	static	BOOL	Contrast_EnhancementInSubRt(BYTE* Img,int w,int h,CRect subRt,int& tmin,int& tmax,BOOL bAllArea=TRUE,BOOL bForce = TRUE);
	static	BOOL	Shade_Enhancement(BYTE* Img,int w,int h,CRect subRt);

	static	void	BoldImg(BYTE *Img1,int w,int h);

	/////////////////////////////
	static void imDilate(BYTE* pbImg, BYTE* pbOut, int nW, int nH, int Ksize);
	static void imErode(BYTE* pbImg, BYTE* pbOut, int nW, int nH, int Ksize);
};

#endif // !defined(_IMAGEFILTER_H__)
