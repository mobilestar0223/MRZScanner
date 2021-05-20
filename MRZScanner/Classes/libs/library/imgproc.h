#ifndef IMG_PROC_H
#define IMG_PROC_H

#include "StdAfx.h"

#define	PI				3.141592653589793

#ifndef max
#define max(a,b)            (((a) > (b)) ? (a) : (b))
#endif

#ifndef min
#define min(a,b)            (((a) < (b)) ? (a) : (b))
#endif

typedef struct tagPoint2D32f
{
	float x;
	float y;
} Point2D32f;

typedef struct tagPoint2D
{
	int x;
	int y;
} Point2D;

typedef struct tagIPOINT
{
	int  x;
	int  y;
} IPOINT;

typedef struct tagSizeInfo
{
	int width;
	int height;
}SizeInfo;

inline  SizeInfo  getSizeInfo( int width, int height )
{
	SizeInfo s;
	s.width = width;
	s.height = height;
	return s;
}

inline  Point2D32f  getPoint2D32f( float x, float y )
{
	Point2D32f pos;
	pos.x = x;
	pos.y = y;
	return pos;
}

inline  Point2D  getPoint2D( int x, int y )
{
	Point2D pos;
	pos.x = x;
	pos.y = y;
	return pos;
}

template<typename T>
inline T limit(const T& value)
{
	return ( (value > 255) ? 255 : ((value < 0) ? 0 : value) );
}

inline  int  Round( double value )
{
	return (int)(value + (value >= 0 ? 0.5 : -0.5));
}


//filter
void im_blur(BYTE* pImg, BYTE* pOut, int nW, int nH, int nC);
void im_binary(BYTE* pbGray, BYTE* pOut, int nW, int nH, int nThres);
void im_AdaptiveThreshold(BYTE* pbyGray, BYTE* pbyOut, int nW, int nH, int S, float T);
void im_binary_windows(BYTE* pImg, BYTE* pOut, int w, int h, int nWinSize);
void im_binary_otsu(BYTE *pImg, BYTE* pOut, int w, int h);
void im_RGB2Gray(BYTE *pbRGB, BYTE *pbGray, int nWidth, int nHeight, int nChannel = 3);
void im_RGB2HSL(BYTE nR, BYTE nG, BYTE nB, BYTE& nH, BYTE& nS, BYTE& nL);
void im_NegativeImage(BYTE* pbImg, int nW, int nH, RECT* pRt, int nCol);
void im_EnhanceImage(BYTE *pbImg, int nW, int nH, int nC);
void im_dilate(BYTE* pbImg, BYTE* pbOut, int nW, int nH, int Ksize = 3);
void im_erode(BYTE* pbImg, BYTE* pbOut, int nW, int nH, int Ksize = 3);
void im_edge(BYTE* pbImg, BYTE* pbOut, int nW, int nH, int Ksize = 2);
void im_filter(BYTE* pbImg, BYTE* pbOut, int nW, int nH, int* pnT, int nSize, int nFactor, int nOffset);
void im_Extend(BYTE* pbImg, BYTE* pbOut, int &nW, int &nH, int nExt, int nBK);
bool im_isBlurredImage(BYTE* pbImg, int nW, int nH);

//histogram
void im_MaxMin(int* src, int len, int* max, int* min, int* total);
void im_Histogram(BYTE* src, int width, int height, int* hist);

#define HORI	100
#define VERT	200
void im_CoHistogram(BYTE* bySrc, int nW, int nH, int nBin, BYTE byVal, int* pnHist, int nFlag);

//threshold
int get_mean_threshold(BYTE *pbImg, int nW, int nH);
int get_optical_threshold(BYTE *pbImg, int nW, int nH);
int get_otsu_threshold(BYTE* pImg, int w, int h);

//transform
void im_Resize(BYTE *pSrc, int nSrcW, int nSrcH, int nC, BYTE *pDst, int nDstW, int nDstH);
void im_Crop(BYTE* pSrc, int nSrcW, int nSrcH, BYTE* pDst, int cx, int cy, int cw, int ch, int nc = 1);
void im_Rotate(BYTE* pSrc, int nSrcW, int nSrcH, BYTE* pdst, int nW, int nH, IPOINT center, float rotateang, int nc = 1);
//void im_Skew(BYTE* lpIn, int nInW, int nInH, int x0, int y0, BYTE* lpOut, int nWidth, int nHeight, float fAngX, float fAngY, BYTE nSpaceCol);

//integrated sum image
void im_IntImage(BYTE* pbyGray, int *pnSum, int nWidth, int nHeight);

//perspective
int calculate_equation(double **a, double *b, int order_cnt, double *solution);
int get_interpolation_equation_coefficient(Point2D32f *input_pos, Point2D32f *out_pos, int point_cnt, int order, int order_cnt,
	double **coff_x, double **coff_y, double *bx, double *by);
int calculate_dst_coordinate(Point2D32f input_pos, Point2D32f *out_pos, int order_cnt, float *solution_x, float *solution_y);
double cubic_interpolation(double v1, double v2, double v3, double v4, double d);
void get_pixelvalue_by_cubic(BYTE *src_data, SizeInfo img_size, Point2D32f scan_pos, BYTE *img_val, int nc = 1, int nk = 0);
int get_pixelvalue_by_linear(BYTE *src_data, SizeInfo img_size, Point2D32f scan_pos, BYTE *img_val);

int calculate_linear_equation(IPOINT *pData, int nPointCnt, double *a, double *b);

#endif //IMG_PROC_H
