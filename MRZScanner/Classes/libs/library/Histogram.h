// Histogram.h: interface for the CHistogram class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(_HISTOGRAM_H__)
#define _HISTOGRAM_H__

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#define		MinCursorWidth	10
#define		MAXPEAKS        64

typedef struct {
	int	pos;
	int	value;
} peaklisti;


class CHistogram  
{
public:
	CHistogram();
	virtual ~CHistogram();

public:
	static void   GetHistogram(BYTE *pImg, int w, int h, int *hist);
	static void   GetHistogramFromFolat(float *data, int w, int h, int *hist);
	static int*   GetHistogram(BYTE *pImg, int w, int h);
	static int*   GetHistogram(BYTE *pImg, int w, int h, CRect subrect);
	static	void	GetHistogram(BYTE *pImg, int w, int h, CRect subRt,int Hist[256],int& tmin,int& tmax);

	static int    Histogram_Filtering(int *hist,int size,double* filter,int filtersize); //filtersize is odd integer
	static int    Histogram_Smoothing(int *hist,int size=256);
	static int    Histogram_Gaussian5x(int *hist,int size=256,double alpha=0.375);
	static int    Histogram_Average7x(int *hist,int size=256);
	static int    Histogram_Median5x(int *hist,int size=256);
private:
	static int    median(int c[5]);
public:
	static int    GetPercentValue(int *hist,int size, float percent);
	static int    GetPercentValue(int *hist,int size, int N, float percent);

	static int    GetPeaksFromSmoothedHistogram(int *hist,int size=256);
	static int    GetPeaksFromHistogram(int *hist,int size, peaklisti *pks,int listsize,int thlow,int thhigh);

};

#endif // !defined(_HISTOGRAM_H__)





















