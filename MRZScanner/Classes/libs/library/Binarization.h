// Binarization.h: interface for the CBinarization class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(__BINARIZATION_H__)
#define __BINARIZATION_H__


////////Binatization Mode///////////////////////////////////////////////////////
#define    BIN_OTSU               0
#define    BIN_FUZZY_YAGER        1
#define    BIN_FUZZY_ENTROPY      2
#define    BIN_EDGE_PIXELS        3
#define    BIN_ENTROPY_JOH        4
#define    BIN_ENTROPY_KAPUR      5
#define    BIN_ENTROPY_PUN        6
#define    BIN_INTERATIVE_SELECT  7
#define    BIN_MIN_ERROR          8
#define    BIN_MOVING_AVERAGES    9
#define    BIN_JJH               10
#define    BIN_HJI               11

//////////////////////////////////////////////////////////////////////////

#define    BIN_OTSU               0
#define    BIN_FUZZY_YAGER        1
#define    BIN_FUZZY_ENTROPY      2
//////////////////////////////////////////////////////////////////////////
#define     ENTROPY 1
#define     YAGER 2

#define		DilateCounts		8

#define	    HIGH_LEVEL		0
#define	    LOW_LEVEL		1//255

////////// SpecialMode of Binarization_DynamicThreshold /////////////////////////////////////
#define    SMODE_NON                         0
#define    SMODE_SMALL_DIST                  1
#define    SMODE_GLOBAL_OTSU                 2
#define    SMODE_SMALL_DIST_GLOBAL_OTSU      3
//////////////////////////////////////////////////////////////////////////

class CBinarization  
{

public:
	CBinarization();
	virtual ~CBinarization();

public:	
	static	BYTE*  Binarization_By_Th(BYTE *pImg, int w, int h, double th);

	static	BYTE*  Binarization(BYTE* pImg,int w,int h, int nMode = 0/*BIN_OTSU*/);

public:
	static	BYTE*  Binarization_Otsu(BYTE *pImg, int w, int h);
	static	BYTE*  Binarization_Otsu_SubRect(BYTE *pImg, int w, int h,CRect rect);
	static	int	   BinarizationBySubRectOfOtsu(BYTE *srcF,CSize totalSz,BYTE* destF,CRect SubRt,float &stad,float &ave);
	static	BYTE*  Binarization_Camera(BYTE *pImg, int w, int h);
	static	BYTE*  Binarization_Fuzzy_Yager(BYTE* pImg,int w,int h);
	static	BYTE*  Binarization_Fuzzy_Entropy(BYTE *pImg, int w, int h);
	static	BYTE*  Binarization_EdgePixels(BYTE *pImg, int w, int h);
	static	BYTE*  Binarization_Entropy_Joh(BYTE *pImg, int w, int h);
	static	BYTE*  Binarization_Entropy_Kapur(BYTE *pImg, int w, int h);
	static	BYTE*  Binarization_Entropy_Pun(BYTE *pImg, int w, int h);
	static	BYTE*  Binarization_IterativeSelect(BYTE *pImg, int w, int h);
	static	BYTE*  Binarization_Minium_Error(BYTE *pImg, int w, int h);
	static	BYTE*  Binarization_MovingAverages(BYTE *pImg, int w, int h);
	static	BYTE*  Binarization_Maximum_Separability_Axis(BYTE *_24Dib);
	static	BYTE*  Binarization_HJI(BYTE *pImg, int w, int h);
	static	BYTE*  Binarization_JJH(BYTE* pImg,int w,int h);


	static	BYTE*  Binarization_DynamicThreshold(BYTE* pImg,int w,int h,CSize WinSize,int special_mode=SMODE_NON);
	static	BYTE*  Binarization_DynamicThreshold(BYTE* pImg,int w,int h,int nGridX,int nGridY,int special_mode=SMODE_NON);
	static	BYTE*  Binarization_DynamicThreshold(BYTE* pImg,int w,int h,int winX, int winY,int nGridX,int nGridY,int special_mode=SMODE_NON);
    static	BYTE*  Binarization_OtsuAdaptive(BYTE *src,int width,int height, int csize);
	
	static	BYTE*  Binarization_Windows(BYTE* pImg,int w,int h,int nWinSize = 2);
	
	static	BYTE*  Binarization_Tonggeguk(BYTE* pImg,int w,int h);
	
public:
	static	double  GetThreshold(BYTE* pImg, int w, int h, int nMode=0);

	static	double  GetThreshold_Otsu(BYTE *pImg, int w, int h);
	static	double  GetThreshold_Otsu(BYTE *pImg, int w, int h, CRect subrect);
	static	double  GetThreshold_Otsu(BYTE *pImg, int w, int h, double& dist);
	static	double  GetThreshold_Otsu(BYTE *pImg, int w, int h, double& dist, CRect subrect);
	static	double  GetThreshold_Otsu_From_Histogram(int* Hist, double& dist);
	static	double  GetThreshold_Fuzzy(BYTE *pImg, int w, int h, int method);
	static	double  GetThreshold_EdgePixels(BYTE *pImg, int w, int h);
	static	double  GetThreshold_Entropy_Joh(BYTE *pImg, int w, int h);
	static	double  GetThreshold_Entropy_Kapur(BYTE *pImg, int w, int h);
	static	double  GetThreshold_Entropy_Pun(BYTE *pImg, int w, int h);
	static	double  GetThreshold_IterativeSelect(BYTE *pImg, int w, int h);
	static	double  GetThreshold_Minium_Error(BYTE *pImg, int w, int h);
	
private:
	static	int    fix_tharray1(double **tharray,int mwidth,int mheight);
	static	int    fix_tharray(double **tharray,int mwidth,int mheight);
	static	int    dealloc_double2D(double **a);
	static	double** alloc_double2D(int w,int h);



private:
	static	void     Laplacian(BYTE *pImg, float *output, int w, int h);
	static	int      peaks_threshold(BYTE *pImg, int w, int h, int *hist, float *lap, int lval);
	static	float    flog(float x);
	static	float    entropy(float *h, int a);
	static	float    entropy(float h);
	static	float    entropy(float *h, int a, float p);
	static	double   fuzzy(int *hist, int u0, int u1, int t, int method);
	static	double   Shannon(double x);
	static	double   Ux(int g, int u0, int u1, int t);
	static	double   Yager(int u0, int u1, int t);
	static	float    maxtot(float *h, int i);
	static	float    maxfromt(float *h, int i);
	static	double   ProjectRGBToAxis(BYTE r, BYTE g, BYTE b, double *axis);
	static	double*  ProjectVector(double *A, double *B, int size);
	static	double   ScalarProduct(double *V1, double *V2, int size);
	static	RGBQUAD* MakeRGBFrom24DIB(BYTE *pDib, int& w,int& h);
};

#endif // !defined(__BINARIZATION_H__)
