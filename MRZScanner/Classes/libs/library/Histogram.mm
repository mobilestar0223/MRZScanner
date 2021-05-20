// Histogram.cpp: implementation of the CHistogram class.
//
//////////////////////////////////////////////////////////////////////

#include "StdAfx.h"
#include "Histogram.h"

#ifdef _ANDROID
#ifdef _DEBUG
#undef THIS_FILE
static char THIS_FILE[]=__FILE__;
#define new DEBUG_NEW
#endif
#endif

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

CHistogram::CHistogram()
{

}

CHistogram::~CHistogram()
{

}
void CHistogram::GetHistogram(BYTE *pImg, int w, int h, int *hist)
{
	int  i, N;

	for (i=0; i<256; i++) hist[i] = 0;
	N = w * h;
	for (i=0; i<N; i++) hist[pImg[i]]++;
}
int* CHistogram::GetHistogram(BYTE *pImg, int w, int h)
{
	if (!pImg)
		return NULL;
	int* pHist = new int[256];
	memset(pHist,0,sizeof(int)*256);
	int i,j;
	for (i=0; i<h;i++)
		for (j=0;j<w;j++)
			pHist[pImg[i*w+j]]++;
	
	return pHist;
}
void CHistogram::GetHistogram(BYTE *pImg, int w, int h, CRect subRt,int Hist[256],int& tmin,int& tmax)
{
	int x0=subRt.left,x1=subRt.right,y0=subRt.top,y1=subRt.bottom;
	int	wid = x1-x0,high = y1-y0 ;
	int i,j,k=0;
	int Th = wid;//*2;
	
	memset(Hist,0,sizeof(int)*256);
	for(i=y0;i<y1;i++)for(j=x0;j<x1;j++) Hist[pImg[i*w+j]]++;
	k = 0;
	for(i=0;i<256;i++){
		k+=Hist[i];
		if(k>(Th)) {tmin=i;break;}// min gray level 
	}
	k = 0;
	for(i=255;i>=0;i--){
		k+=Hist[i];
		if(k>(Th)) {tmax=i;break;}// max gray level
	}
}
int* CHistogram::GetHistogram(BYTE *pImg, int w, int h, CRect subrect)
{
	if (!pImg)
		return NULL;
	int i,j;
	int* pHist = new int[256];
	memset(pHist,0,sizeof(int)*256);
	subrect &= CRect(0,0,w,h);
	for (i=subrect.top; i<subrect.bottom; i++)
		for (j=subrect.left; j<subrect.right; j++)
			pHist[pImg[i*w+j]]++;
	return pHist;
}
void CHistogram::GetHistogramFromFolat(float *data, int w, int h, int *hist)
{
	int i,j;
	for (i=0; i<256; i++) hist[i] = 0;
	for (i=0; i<h; i++)for (j=0; j<w; j++)
		hist[(int)(data[i * w + j])] += 1;
}

int CHistogram::GetPercentValue(int *hist,int size,float percent)
{
	int i;
	long N = 0;
	for(i=0;i<size;i++)
		N += hist[i];
	return GetPercentValue(hist,size, N, percent);
}
int CHistogram::GetPercentValue(int *hist,int size, int N, float percent)
{
	int i,j=0,m; 
	int val = -1;
	m = (int)(percent / 100.0 * N);
	for (i=0; i<size; i++)
	{
		j += hist[i];
		if (j>=m)
		{
			val = i;
			break;
		}
	}
	return val;
}

int CHistogram::GetPeaksFromSmoothedHistogram(int *hist,int size)
{
	int	n_cluster;
	int	i;
	int* tmphist = new int[size +1];
	peaklisti	peaklist[MAXPEAKS];

	for ( i=0 ; i<size ; i++ )  tmphist[i] = (int)hist[i];
	tmphist[size] = 0;

	Histogram_Average7x(tmphist, size);
	/* hysteresis smoothing */
	Histogram_Smoothing(tmphist, size);
	/* peak detection */
	n_cluster = GetPeaksFromHistogram(tmphist,size+1,peaklist,MAXPEAKS,0,0x7fffffff);
	return(n_cluster);
}

int CHistogram::GetPeaksFromHistogram(int *hist,int size,peaklisti *pks,int listsize,int thlow,int thhigh)
{
	int	ix,l;
	int	dx,dx0,x0;
	int	count;
	count = 0;
	l = 0;
	x0 = dx0 = 0;
	for ( ix=0 ; ix<size ; ++ix ){
		dx = hist[ix] - x0;
		if ( dx == 0 ){
			if ( dx0 > 0 )  ++l;  else  l = 0;
		}
		else{if ( dx < 0 ){
				if ( l != 0 ){
					if ( (x0 >= thlow) && (x0 <= thhigh) ){
						if ( (++count) > listsize )  break;
						pks->pos = ix - ((l+1)/2) -1;
						pks->value = x0;
						++pks;
					}
					l = 0;
				}
				else{	if ( dx0 > 0 ){
						if ( (x0 >= thlow) && (x0 <= thhigh) ){
							if ( (++count) > listsize )  break;
							pks->pos = ix -1;
							pks->value = x0;
							++pks;
						}
					}
				}
			}
			else{	l = 0;
			}
			dx0 = dx;
		}
		x0 = hist[ix];
	}  
	return (count);
}

int CHistogram::Histogram_Smoothing(int *hist,int size)
{
	if(hist == NULL || size<1) return(-1);
	int	i,c,l;
	int	cw = MinCursorWidth;	/* cursor width */
	/* hysteresis smoothing */
	c = 0;  l = 0;
	for ( i=0 ; i<size ; i++ ){
		cw = (int)(0.2 * (double)hist[i]);
		if ( cw < MinCursorWidth )  cw = MinCursorWidth;

		/* force drop to background level for very long roof */
		if ( ++l > 16 ){
			c = hist[i];
			l = 0;
		}

		if ( hist[i] < c - cw ){
			c = hist[i] + cw;
			l = 0;
		}
		if ( hist[i] > c + cw ){
			c = hist[i] - cw;
			l = 0;
		}
		hist[i] = c;
	}

	return (0);
}
int CHistogram::Histogram_Filtering(int *hist,int size,double* filter,int filtersize) //filtersize is odd integer
{
	if(hist==NULL || filter==NULL) return(-1);
	if(size<1 || filtersize<1)     return(-1);
	if((filtersize & 0x01) != 0x01)  return(-1);
	int halfsize = filtersize/2;
	int	i,j;
	double	sum;
	int	*tmphist;
	if ( 0 == (tmphist = new int[size + filtersize-1]) )  return(-1);
	memcpy((void *)(tmphist + halfsize),(void *)hist,sizeof(int) * size);
	for(i=0 ; i<halfsize ; i++)                       tmphist[i] = hist[0];
	for(i=size+filtersize-2 ; i>=size+halfsize; i--)  tmphist[i] = hist[size-1];

	for(i=0 ;i<size ;i++){
		sum = 0;
		for (j=0 ;j<filtersize ; j++ )  sum += tmphist[i+j]*filter[j];
		hist[i] = (int)(sum+.5);
	}
	delete []tmphist;
	return(0);
}
int CHistogram::Histogram_Gaussian5x(int *hist,int size/*=256*/,double alpha/*=0.375*/ )
{
//alpha:alpha of Gaussian filter(0.25-alpha/2,  0.25,  alpha,  0.25,  0.25-alpha/2)
	double Gaussian[5]={0.25-alpha/2,  0.25,  alpha,  0.25,  0.25-alpha/2};
	return Histogram_Filtering(hist,size,Gaussian,5);
}
int CHistogram::Histogram_Average7x(int *hist,int size/*=256*/)
{
	if(hist == NULL || size<1) return(-1);
	int	i,j;
	int	sum;
	int	*tmphist;
	if ( 0 == (tmphist = new int[size +6]) )  return(-1);
	memcpy((void *)(tmphist + 3),(void *)hist,sizeof(int) * size);
	for ( i=0 ; i<3 ; i++ )  tmphist[i] = tmphist[3];
	for ( i=size +5 ; i>=size +3; i-- )
		tmphist[i] = tmphist[size +2];
	for ( i=0 ; i<size ; i++ ){
		sum = 0;
		for ( j=0 ; j<7 ; j++ )  sum += tmphist[i+j];
		hist[i] = sum;
	}
	delete []tmphist;
	return(0);
}
int CHistogram::Histogram_Median5x(int *hist,int size/*=256*/)
{
	if(hist == NULL || size<1) return(-1);
	int i,n,x,q,k;
	int c[5];
	int* tmphist = new int[size];
	q = 2;
	for(k=0; k<size; k++)
	{
		n =0;
		for(i=-q; i<=q; i++)
		{
			x = k - i;
			if(x < 0 || x > size) c[n]=0;
			else		c[n] = hist[x];
			n++;
		}
		tmphist[k] = median(c);
	}
	for(i=0; i<size; i++) hist[i] = tmphist[i];
	delete[] tmphist;
	 return(0);
}


int CHistogram::median(int c[5])
{
	int i,j,buf;
	buf = 0;
	for(i=0;i<4;++i){
		for(j=i+1;j<5;++j){
			if(c[i] > c[j]){
				buf = c[i];c[i] = c[j];c[j]=buf;
			}
		}
	}
	return c[2];
}


















