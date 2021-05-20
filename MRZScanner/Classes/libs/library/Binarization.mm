// Binarization.cpp: implementation of the CBinarization class.
//
//////////////////////////////////////////////////////////////////////
#include <float.h>
#include "StdAfx.h"
#include "Binarization.h"
#include "ImageFilter.h"
#include "Histogram.h"
#include "imgproc.h"


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

CBinarization::CBinarization()
{

}

CBinarization::~CBinarization()
{

}



BYTE* CBinarization::Binarization_By_Th(BYTE *pImg, int w, int h, double th)
{
	int i, j, pos_x;
	int size = w * h;
	BYTE *pBinImg = new BYTE[size];
	for (i = 0; i < h; i++) {
		pos_x = i * w;
		for (j = 0; j < w; j++) {
			if (pImg[pos_x + j] <= th)
				pBinImg[pos_x + j] = LOW_LEVEL;
			else
				pBinImg[pos_x + j] = HIGH_LEVEL;
		}
	}
	return pBinImg;
}
BYTE* CBinarization::Binarization(BYTE* pImg,int w,int h, int nMode)
{
	if(pImg == NULL)return NULL;
	BYTE *pBinImg = NULL;
	switch(nMode) 
	{
	case BIN_OTSU:
		pBinImg = Binarization_Otsu(pImg,  w, h);
		break;
	case BIN_FUZZY_YAGER:
		pBinImg = Binarization_Fuzzy_Yager(pImg, w, h);
		break;
	case BIN_FUZZY_ENTROPY:
		pBinImg = Binarization_Fuzzy_Entropy(pImg, w, h);
		break;
	case BIN_EDGE_PIXELS:
		pBinImg = Binarization_EdgePixels(pImg, w, h);
		break;
	case BIN_ENTROPY_JOH:
		pBinImg = Binarization_Entropy_Joh(pImg, w, h);
		break;
	case BIN_ENTROPY_KAPUR:
		pBinImg = Binarization_Entropy_Kapur(pImg, w, h);
		break;
	case BIN_ENTROPY_PUN:
		pBinImg = Binarization_Entropy_Pun(pImg, w, h);
		break;
	case BIN_INTERATIVE_SELECT:
		pBinImg = Binarization_IterativeSelect(pImg, w, h);
		break;
	case BIN_MIN_ERROR:
		pBinImg = Binarization_Minium_Error(pImg, w, h);
		break;
	case BIN_MOVING_AVERAGES:
		pBinImg = Binarization_MovingAverages(pImg, w, h);
		break;
	case BIN_JJH:
		pBinImg = Binarization_JJH(pImg, w, h);
		break;
	case BIN_HJI:
		pBinImg = Binarization_HJI(pImg, w, h);
		break;
	default:
		pBinImg = Binarization_Otsu(pImg, w, h);
	}
	return pBinImg;
}
double CBinarization::GetThreshold(BYTE* pImg, int w, int h, int nMode)
{
	if(pImg == NULL) return -1.0;
	double th;
	double dist;
	switch(nMode) 
	{
	case BIN_OTSU:
		th = GetThreshold_Otsu(pImg, w, h, dist);
		break;
	case BIN_FUZZY_YAGER:
		th = GetThreshold_Fuzzy(pImg, w, h, YAGER);
		break;
	case BIN_FUZZY_ENTROPY:
		th = GetThreshold_Fuzzy(pImg, w, h, ENTROPY);
		break;
	case BIN_EDGE_PIXELS:
		th = GetThreshold_EdgePixels(pImg, w, h);
		break;
	case BIN_ENTROPY_JOH:
		th = GetThreshold_Entropy_Joh(pImg, w, h);
		break;
	case BIN_ENTROPY_KAPUR:
		th = GetThreshold_Entropy_Kapur(pImg, w, h);
		break;
	case BIN_ENTROPY_PUN:
		th = GetThreshold_Entropy_Pun(pImg, w, h);
		break;
	case BIN_INTERATIVE_SELECT:
		th = GetThreshold_IterativeSelect(pImg, w, h);
		break;
	case BIN_MIN_ERROR:
		th = GetThreshold_Minium_Error(pImg, w, h);
		break;
	default:
		th = GetThreshold_Otsu(pImg, w, h, dist);
	}
	return th;
}


int CBinarization::fix_tharray1(double **tharray,int mwidth,int mheight){
	int	mx,my,i,j,count;
	double	sum;
	double	**tharray0;
	if ( 0 == (tharray0 = alloc_double2D(mwidth,mheight)) )  return(-1);

	/* copy original array to temporary array */
	for ( my=0 ; my<mheight ; my++ ){
		memcpy((void *)tharray0[my],(void *)tharray[my], \
			sizeof(double) * mwidth);
		tharray0[my][0] = tharray0[my][mwidth-1] = -1;
	}
	for ( mx=0 ; mx<mwidth ; mx++ ){
		tharray0[0][mx] = tharray0[1][mx];
		tharray0[mheight-1][mx] = tharray0[mheight-2][mx];
	}

	/* interpolate */
	for ( my=1 ; my < mheight -1 ; my++ ){
		for ( mx=1 ; mx < mwidth -1 ; mx++ ){
			if ( tharray0[my][mx] >= 0.0 )  continue;
			count = 0;
			sum = 0.0;
			for ( j = -1 ; j <= 1 ; j++ ){
				for ( i = -1 ; i <= 1 ; i++ ){
					if ( tharray0[my+j][mx+i] < 0.0 )  continue;
					sum += tharray0[my+j][mx+i];
					count++;
				}
			}
			if ( count ){
				tharray[my][mx] = sum / count;
			}
			/* else:  leave tharray[][] < 0 */
		}
	}
	dealloc_double2D(tharray0);
	return(0);
}

int CBinarization::fix_tharray(double **tharray,int mwidth,int mheight){
	int	mx,my,i,j,count;
	double	sum;
	double	**tharray0;

	/* dilate bilevel area */
	for ( i=0 ; i<DilateCounts ; i++ ){
		if ( 0 > fix_tharray1(tharray,mwidth,mheight) )  return(-1);
	}

	/* create a temporary array */
	if ( 0 == (tharray0 = alloc_double2D(mwidth,mheight)) )  return(-1);

	/* copy original array to temporary array */
	for ( my=0 ; my<mheight ; my++ ){
		memcpy((void *)tharray0[my],(void *)tharray[my], \
			sizeof(double) * mwidth);
		tharray0[my][0] = tharray0[my][mwidth-1] = -1;
	}
	for ( mx=0 ; mx<mwidth ; mx++ ){
		tharray0[0][mx] = tharray0[1][mx];
		tharray0[mheight-1][mx] = tharray0[mheight-2][mx];
	}

	/* interpolate */
	for ( my=1 ; my < mheight -1 ; my++ ){
		for ( mx=1 ; mx < mwidth -1 ; mx++ ){
			if ( tharray0[my][mx] >= 0.0 )  continue;
			count = 0;
			sum = 0.0;
			for ( j = -1 ; j <= 1 ; j++ ){
				for ( i = -1 ; i <= 1 ; i++ ){
					if ( tharray0[my+j][mx+i] < 0.0 )  continue;
					sum += tharray0[my+j][mx+i];
					count++;
				}
			}
			if ( count ){
				tharray[my][mx] = sum / count;
			}
			else{	tharray[my][mx] = 127.0;
				/* force inserting a medium threshold */
			}
		}
	}
	dealloc_double2D(tharray0);

	/* interpolate edge cells */
	for ( my=0 ; my<mheight ; my++ ){
		tharray[my][0] = tharray[my][mwidth-1] = -1;
	}
	for ( mx=0 ; mx<mwidth ; mx++ ){
		tharray[0][mx] = tharray[1][mx];
		tharray[mheight-1][mx] = tharray[mheight-2][mx];
	}

	return(0);
}
/*----------------------------------------------
    2-dim array allocation
----------------------------------------------*/

double** CBinarization::alloc_double2D(int w,int h)
{
	double	**a;
	double	*p;
	int	i;
	if ( w <= 0 || h <= 0 )  return(0);
	if ( 0 == (a = new double* [h]) )  return(0);
	if ( 0 == (p = new double [w*h]) ){
		delete []a;
		return(0);
	}
	for ( i=0 ; i<h ; i++ )  a[i] = p + (w*i);
	return(a);
}

int CBinarization::dealloc_double2D(double **a)
{
	if ( ! a )  return(0);
	delete []a[0];
	delete []a;
	return(0);
}

/*----------------------------------------------
    Adaptive binarization
----------------------------------------------*/

BYTE* CBinarization::Binarization_OtsuAdaptive(BYTE *pImg,int width,int height, int csize)
{
	int	mwidth,mheight;
	int	mx,my,x,y;
	int w,h;
	double	**tharray;

	if ( csize < 4 )  return NULL;

	mwidth  = (width  + csize -1) / csize + 2;
	mheight = (height + csize -1) / csize + 2;
	if ( 0 == (tharray = alloc_double2D(mwidth,mheight)) ){
		return NULL;
	}
	for ( my=1 ; my < mheight -1 ; my++ ){
		for ( mx=1 ; mx < mwidth -1 ; mx++ ){
			tharray[my][mx] = GetThreshold_Otsu(pImg, width, height,
				CRect((mx-1)*csize, (my-1)*csize, mx*csize, my*csize));
		}
	}
	fix_tharray(tharray,mwidth,mheight);

	BYTE* pBinImg = new BYTE[width*height];

	for ( my=0 ; my < mheight -1 ; my++ ){
		for ( mx=0 ; mx < mwidth -1 ; mx++ ){

			for ( y=0 ; y<csize ; y++ ){
				for ( x=0 ; x<csize ; x++ ){
					if ( (w = mx*csize+x ) > width -1 )  w = width -1;
					if ( (h = (my*csize+y)) > height-1 )  h = height-1;
					if ( pImg[h*width+w] > (int)tharray[my][mx])  
						pBinImg[h*width+w] = 0; 
					else  
						pBinImg[h*width+w] = 1;
				}
			}
		}
	}
	dealloc_double2D(tharray);
	return pBinImg;
}
//:Recognition of Identifiers from Shipping Container Image 
//         by Using Fuzzy Binarization and ART2-based RBF Network.
BYTE* CBinarization::Binarization_JJH(BYTE *pImg, int w, int h)
{
	int i,j;
	int sum = 0;
	int I_Max = 0;
	int I_Min = 255;

	BYTE* pNew = new BYTE[w*h];
	for (i=0;i<h;i++)
		for (j=0;j<w;j++)
		{
			sum += pImg[i*w+j];
			pNew[i*w+j] = 255;
			if (pImg[i*w+j] > I_Max) I_Max = pImg[i*w+j];
			if (pImg[i*w+j] < I_Min) I_Min = pImg[i*w+j];
		}

	int I_Mid = (int)(sum/(w*h));
	int I_Min_F = I_Mid - I_Min;
	int I_Max_F = I_Max - I_Mid;
	int I_Mid_F = 0;
	int sigma = 0;

	if (I_Mid>128) 
		I_Mid_F = 255 - I_Mid;
	else
		I_Mid_F = I_Mid;

	if (I_Mid_F > I_Max_F)
	{
		if (I_Min_F > I_Mid_F) sigma = I_Mid_F;
		else sigma = I_Min_F;
	}
	else
	{
		if (I_Max_F > I_Mid_F) sigma = I_Mid_F;
		else
			sigma = I_Max_F;
	}

	int I_Min_New = I_Mid - sigma;
	int I_Max_New = I_Mid + sigma;
	int I_Mid_New = I_Mid;
	
	for (i=0;i<h;i++)
	{
		for (j=0;j<w ;j++)
		{
			double u=0.0;

			int tmp = pImg[i*w+j];
			if (tmp >=  I_Min_New && tmp<I_Mid_New) u=1.0;
			else if (I_Mid_New <= tmp && tmp<I_Max_New)
				u = 1 - (double)(tmp-I_Mid_New)/(I_Max_New-I_Mid_New);
			
			if (u>=0.8) 
				pNew[i*w+j] = HIGH_LEVEL;
			else
				pNew[i*w+j] = LOW_LEVEL;
		}
	}
	return pNew;
}
BYTE* CBinarization::Binarization_EdgePixels(BYTE *pImg, int w, int h)
{
	double th = GetThreshold_EdgePixels(pImg, w, h);
/* Threshold */
	BYTE *pBinImg = Binarization_By_Th(pImg, w, h, th);
	return pBinImg;
}
double CBinarization::GetThreshold_EdgePixels(BYTE *pImg, int w, int h)
{
	float *Lap;
	int t, v,hist[256];
	float percent = 85.0;
/* Compute the Laplacian of 'im' */
	Lap = (float *)malloc(sizeof(float)*w*h);
	Laplacian (pImg, Lap, w, h);

/* Find the high 85% of the Laplacian values */
	CHistogram::GetHistogramFromFolat(Lap, w, h, hist);
	v = CHistogram::GetPercentValue(hist, 256, w*h, percent);

/* Construct histogram of the gray levels of hi Laplacian pixels */
	t = peaks_threshold(pImg, w, h, hist, Lap, v);
	free(Lap);
	return t;
}
void CBinarization::Laplacian(BYTE *pImg, float *output, int w, int h)
{
	int i,j,ii,jj,k;
	for (i=0; i<h; i++) for (j=0; j<w; j++)
	{
		k=0;
		if(i==0 || i==h-1 || j==0 || j==w-1)
		{
			output[i * w + j] = 0.0f;
			continue;
		}
		for (ii= -1; ii<=1; ii++)for (jj= -1; jj<=1; jj++)
			if (ii!=0 || jj!=0)	k += pImg[(i+ii)*w+(j+jj)];
		k = k - 8*(int)pImg[i*w+j];
		if (k<=0) output[i * w + j] = 0.0;
		else output[i * w + j] = (float)(k/8.0);
	}
}

int CBinarization::peaks_threshold(BYTE *pImg, int w, int h, int *hist, float *lap, int lval)
{
	int N, i,j,k;

	for (i=0; i<256; i++) hist[i] = 0;
	int t = -1;

/* Find the histogram */
	N = w * h;

	for (i=0; i<h; i++)for (j=0; j<w; j++)
	    if (lap[i*w+j] >= lval)
	      hist[pImg[i*w+j]] += 1;

/* Find the first peak */
	j = 0;
	for (i=0; i<256; i++)
	  if (hist[i] > hist[j]) j = i;

/* Find the second peak */
	k = 0;
	for (i=0; i<256; i++)
	  if (i>0 && hist[i-1]<=hist[i] && i<255 && hist[i+1]<=hist[i])
	    if ((k-j)*(k-j)*hist[k] < (i-j)*(i-j)*hist[i]) k = i;

	t = j;
	if (j<k)
	{
	  for (i=j; i<k; i++)
	    if (hist[i] < hist[t]) t = i;
	} else {
	  for (i=k; i<j; i++)
	    if (hist[i] < hist[t]) t = i;
	}
	return t;
}
BYTE* CBinarization::Binarization_Entropy_Joh(BYTE *pImg, int w, int h)
{
	double  th = GetThreshold_Entropy_Joh(pImg, w, h);
	BYTE*	pBinImg = Binarization_By_Th(pImg, w, h, th);
	return  pBinImg;
}
double CBinarization::GetThreshold_Entropy_Joh(BYTE *pImg, int w, int h)
{
	int i, t, start, end;
	float Sb, Sw, *Pt, *P_hist, *F, *Pq;
	int *hist;

	int N = w * h;
/* Histogram */
	hist = (int *)malloc(sizeof(int)*256);
	Pt = (float *)malloc(sizeof(float)*256);
	P_hist = (float *)malloc(sizeof(float)*256);
	F = (float *)malloc(sizeof(float)*256);
	Pq = (float *)malloc(sizeof(float)*256);

	CHistogram::GetHistogram(pImg, w, h, hist);
	for (i=0; i<256; i++) P_hist[i] = ((float)hist[i]) / (float)N;

/* Compute the factors */
	Pt[0] = P_hist[0];
	Pq[0] = 1.0f - Pt[0];
	for (i=1; i<256; i++)
	{
	  Pt[i] = Pt[i-1] + P_hist[i];
	  Pq[i] = 1.0f - Pt[i-1];
	}

	start = 0;
	while (P_hist[start++] <= 0.0f) ;
	end = 255;
	while (P_hist[end--] <= 0.0f) ;

/* Calculate the function to be minimized at all levels */
	t = -1;
	for (i=start; i<=end; i++)
	{
		if (P_hist[i] <= 0.0f) continue;
		Sb = flog(Pt[i]) + (1.0f/Pt[i])*
				(entropy(P_hist[i])+entropy(Pt[i-1]));
		Sw = flog (Pq[i]) + (1.0f/Pq[i])*
				(entropy(P_hist[i]) + entropy(Pq[i+1]));
		F[i] = Sb+Sw;
		if (t<0) t = i;
		else if (F[i] < F[t]) t = i;
	}
	free(hist);free(P_hist); free (Pt); free (F); free (Pq);
	return t;
}

float CBinarization::flog(float x)
{
	if (x > 0.0) return (float)log((double)x);
	else return 0.0;
}

float CBinarization::entropy(float *h, int a)
{
	if (h[a] > 0.0)
		return -(h[a] * (float)log((double)h[a]));
	return 0.0;
}

float CBinarization::entropy(float h)
{
	if (h > 0.0)
		return (-h * (float)log((double)(h)));
	else return 0.0;
}

float CBinarization::entropy(float *h, int a, float p)
{
	if (h[a] > 0.0 && p>0.0)
		return -(h[a]/p * (float)log((double)(h[a])/p));
	return 0.0;
}

double CBinarization::GetThreshold_Entropy_Kapur(BYTE *pImg, int w, int h)
{
	int i, j, t;
	float Hb, Hw, *Pt, *P_hist, *F;
	int *hist;
	int N = w * h;

	/* Histogram */
	hist = (int *)malloc(sizeof(int)*256);
	Pt = (float *)malloc(sizeof(float)*256);
	P_hist = (float *)malloc(sizeof(float)*256);  
	F = (float *)malloc(sizeof(float)*256);  
	
	CHistogram::GetHistogram (pImg, w, h, hist);
	for (i=0; i<256; i++) P_hist[i] = ((float)hist[i]) / (float)N;
	
/* Compute the factors */
	Pt[0] = P_hist[0];
	for (i=1; i<256; i++)
		Pt[i] = Pt[i-1] + P_hist[i];

/* Calculate the function to be maximized at all levels */
	t = 0;
	for (i=0; i<256; i++)
	{
		Hb = Hw = 0.0;
		for (j=0; j<256; j++)
			if (j<=i)
				Hb += entropy (P_hist, j, Pt[i]);
			else 
				Hw += entropy (P_hist, j, 1.0f-Pt[i]);

		F[i] = Hb+Hw;
		if (i>0 && F[i] > F[t]) t = i;
	}
	free(hist); free(P_hist); free(Pt); free(F);
	return t;
}
BYTE* CBinarization::Binarization_Entropy_Kapur(BYTE *pImg, int w, int h)
{
	double t = GetThreshold_Entropy_Kapur(pImg, w, h);
/* Threshold */
	BYTE*	pBinImg = Binarization_By_Th(pImg, w, h, t);
	return pBinImg;
}

double CBinarization::GetThreshold_Entropy_Pun(BYTE *pImg, int w, int h)
{
	int i, t;
	float *Ht, HT, *Pt, x, *F, y, z;
	float *P_hist, to, from;
	int *hist;

	int N = w * h;

/* Histogram */
	hist = (int *)malloc(sizeof(int)*256);
	Ht = (float *)malloc (sizeof(float)*256);
	Pt = (float *)malloc (sizeof(float)*256);        
	F  = (float *)malloc (sizeof(float)*256);        
	P_hist = (float *)malloc (sizeof(float)*256); 
	
	CHistogram::GetHistogram (pImg, w, h, hist);
	for (i=0; i<256; i++) P_hist[i] = ((float)hist[i]) / (float)N;

/* Compute the factors */
	HT = Ht[0] = entropy (P_hist, 0);
	Pt[0] = P_hist[0];
	for (i=1; i<256; i++)
	{
		Pt[i] = Pt[i-1] + P_hist[i];
		x = entropy(P_hist, i);
		Ht[i] = Ht[i-1] + x;
		HT += x;
	}

/* Calculate the function to be maximized at all levels */
	t = 0;
	for (i=0; i<256; i++)
	{
		to = (maxtot(P_hist,i));
		from = maxfromt(P_hist, i);
		if (to > 0.0 && from > 0.0)
		{
			x = (Ht[i]/HT)* flog(Pt[i])/flog(to);
			y = 1.0f - (Ht[i]/HT);
			z = flog(1 - Pt[i])/flog(from);
		}
		else x = y = z = 0.0f;
		F[i] = x + y*z;
		if (i>0 && F[i] > F[t]) t = i;
	}
	
	free(Ht); free(Pt); free(F);  free(hist);   free(P_hist); 
	return t;
}
BYTE* CBinarization::Binarization_Entropy_Pun(BYTE *pImg, int w, int h)
{
	double t = GetThreshold_Entropy_Pun(pImg,w,h);
/* Threshold */
	BYTE*	pBinImg = Binarization_By_Th(pImg, w, h, t);
	return pBinImg;
}


double CBinarization::GetThreshold_Fuzzy(BYTE *pImg, int w, int h, int method)
{
	double *S, *Sbar, *W, *Wbar;
	double *F, maxv=0.0, delta;
	int i,t,tbest= -1, u0, u1, sum, minsum;
	int start, end;

	int *hist;
	int N = w * h;
	
	S = (double *)malloc(sizeof(double)*256);
	Sbar = (double *)malloc(sizeof(double)*256);
	W = (double *)malloc(sizeof(double)*256);
	Wbar = (double *)malloc(sizeof(double)*256);
	hist = (int *)malloc(sizeof(int)*256);
	F = (double *)malloc(sizeof(double)*256);

/* Find the histogram */
	CHistogram::GetHistogram (pImg, w, h, hist);

/* Find cumulative histogram */
	S[0] = hist[0]; W[0] = 0;
	for (i=1; i<256; i++)
	{
		S[i] = S[i-1] + hist[i];
		W[i] = i*hist[i] + W[i-1];
	}

/* Cumulative reverse histogram */
	Sbar[255] = 0; Wbar[255] = 0;
	for (i=254; i>= 0; i--)
	{
		Sbar[i] = Sbar[i+1] + hist[i+1];
		Wbar[i] = Wbar[i+1] + (i+1)*hist[i+1];
	}

	for (t=1; t<255; t++)
	{
		if (hist[t] == 0.0) continue;
		if (S[t] == 0.0) continue;
		if (Sbar[t] == 0.0) continue;

/* Means */
		u0 = (int)(W[t]/S[t] + 0.5);
		u1 = (int)(Wbar[t]/Sbar[t] + 0.5);

/* Fuzziness measure */
		F[t] = fuzzy (hist, u0, u1, t, method)/N;

/* Keep the minimum fuzziness */
		if (F[t] > maxv) maxv = F[t];
		if (tbest < 0) tbest = t;
		else if (F[t] < F[tbest]) tbest = t;
	}

/* Find best out of a range of thresholds */
	delta = F[tbest] + (maxv-F[tbest])*0.05;        /* 5% */
	start = (int)(tbest - delta);
	if (start <= 0) start = 1;
	end   = (int)(tbest + delta);
	if (end>=255) end = 254;
	minsum = 1000000;

	for (i=start; i<=end; i++)
	{
		sum = hist[i-1] + hist[i] + hist[i+1];
		if (sum < minsum)
		{
			t = i;
			minsum = sum;
		}
	}

	free(S); free(Sbar);
	free(W); free(Wbar);
	free(hist); free(F);
	return t;
}
BYTE* CBinarization::Binarization_Fuzzy_Entropy(BYTE *pImg, int w, int h)
{
	double t = GetThreshold_Fuzzy(pImg, w, h, ENTROPY);
/* Threshold */
	BYTE*  pBinImg = Binarization_By_Th(pImg, w, h, t);
	return pBinImg;
}
BYTE* CBinarization::Binarization_Fuzzy_Yager(BYTE *pImg, int w, int h)
{
	double t = GetThreshold_Fuzzy(pImg, w, h, YAGER);
/* Threshold */
	BYTE*  pBinImg = Binarization_By_Th(pImg, w, h, t);
	return pBinImg;
}

double CBinarization::fuzzy(int *hist, int u0, int u1, int t, int method)
{
	int i;
	double E=0;

	if (method == ENTROPY)
	{
		for (i=0; i<255; i++)
		{
			E += Shannon (Ux(i,u0,u1, t))*hist[i];
		}
		return E;
	} 
	else 
	{
		return Yager (u0, u1, t);
	}
}

double CBinarization::Shannon(double x)
{
	if (x > 0.0 && x < 1.0)
		return (double)(-x*log((double)x) - (1.0-x)*log((double)(1.0-x)));
	else return 0.0;
}

double CBinarization::Ux(int g, int u0, int u1, int t)
{
	double ux, x;

	if (g <= t)
	{
		x = 1.0 + ((double)abs(g - u0))/255.0;
		ux = 1.0/x;
	} else {
		x = 1.0 + ((double)abs(g - u1))/255.0;
		ux = 1.0/x;
	}
	return ux;
}

double CBinarization::Yager(int u0, int u1, int t)
{
	int i;
	double x, sum=0.0;

	for (i=0; i<256; i++)
	{
		x = Ux(i, u0, u1, t);
		x = x*(1.0-x);
		sum += x*x;
	}
	x = (double)sqrt((double)sum);
	return x;
}

float CBinarization::maxtot(float *h, int i)
{
	float x;
	int j;

	x = h[0];
	for (j=1; j<=i; j++)
		if (x < h[j]) x = h[j];
	return x;
}

float CBinarization::maxfromt(float *h, int i)
{
	int j;
	float x;

	x = h[i+1];
	for (j=i+2; j<=255; j++)
		if (x < h[j]) x = h[j];
	return x;
}

double CBinarization::GetThreshold_IterativeSelect(BYTE *pImg, int w, int h)
{
	long i, j, told, tt, a, b, c, d;
	long N, *hist;

	hist = (long *) malloc(sizeof(long)*256);
	for (i=0; i<256; i++) hist[i] = 0;

/* Compute the mean and the histogram */
	N = (long)w * (long)h;
	tt = 0;
	for (i=0; i<h; i++)for (j=0; j<w; j++)
	{
		hist[pImg[i * w + j]] += 1;
		tt = tt + (pImg[i * w + j]);
	}
	tt = (long)(tt/(float)N);

	do
	{
		told = tt;
		a = 0; b = 0;
		for (i=0; i<=told; i++)
		{
			a += i*hist[i];
			b += hist[i];
		}
		b += b;

		c = 0; d = 0;
		for (i=told+1; i<256; i++)
		{
			c += i*hist[i];
			d += hist[i];
		}
		d += d;

		if (b==0) b = 1;
		if (d==0) d = 1;
		tt = a/b + c/d;
	} while (tt != told);
	free (hist);
	return tt;
}
BYTE* CBinarization::Binarization_IterativeSelect(BYTE *pImg, int w, int h)
{
	double  tt = GetThreshold_IterativeSelect(pImg, w, h);
/* Threshold */
	BYTE *pBinImg = Binarization_By_Th(pImg, w, h, tt);
	return pBinImg;
}

BYTE* CBinarization::Binarization_Tonggeguk(BYTE *pImg, int w, int h)
{
	if (!pImg) return NULL;
	int nHist[256];
	memset(nHist,0,256*sizeof(int));
	int  i, N;
	N = w * h;
	for (i=0; i<N; i++) nHist[pImg[i]]++;
	
	int t = 0;
	for(i=0;i<256;i++)
	{
		t+=nHist[i];
		if(t>w*h/4) 
			nHist[i] = 0;
	}
	double dist;
	double th = GetThreshold_Otsu_From_Histogram(nHist,dist);
	BYTE* pNewImg = Binarization_By_Th(pImg,w,h,th);
	return pNewImg;
}
int CBinarization::BinarizationBySubRectOfOtsu(BYTE *srcF,CSize totalSz,BYTE* destF,CRect SubRt,float &stad,float &ave)
{
	int Wx = totalSz.cx;
	int Wy = totalSz.cy; 
	int xs,xe,ys,ye;
	int i,j,k,tmin,tmax,n[256],t;
	int s;
	double m0,d0,w,m,beta,p0;
	xs=SubRt.left;ys=SubRt.top;xe= min(SubRt.right,Wx-1);ye= min(SubRt.bottom,Wy-1);
//1. Original histogram
	for(i=0;i<256;i++)n[i]=0; 
	for(i=ys;i<=ye;i++)for(j=xs;j<=xe;j++)
	{
		k=(int)destF[i*Wx+j];n[k]++;//gray histogram
	}
	
	t=0;tmin=0;
	for(i=0;i<256;i++)
	{	
		t+=n[i];
		if(t>(ye-ys)) {tmin=i;break;}// min gray level 
	}
	t=0;tmax=255;
	for(i=255;i>0;i--)
	{
		t+=n[i];
		if(t>(ye-ys)) {tmax=i;break;}// max gray level 
	}
	if((tmax-tmin)<=0) return 255;// no object
	
	//2. Binarization 
// total mean value of image
	
	s=0;m0=0;
	for(i=tmin;i<=tmax;i++){
		m0+=(double)i*(double)n[i];
		s+=n[i];
	}
	m0/=s;//toal mean gray level value 

	
// total deviation value of image		
	d0=0;
// 	for(i=tmin;i<=tmax;i++)
// 		d0+=(double)n[i]*pow(((double)i-m0),2);
// 	d0/=s;//total deviation value
	
// Optimal threshold value determination
	w=m=beta=d0=0;t=0;
	for(i=tmin;i<=tmax;i++)
	{
		if(n[i]==0) continue;
		p0=(double)n[i]/(double)s;
		w=w+p0;m=m+i*p0;
		//if(w==1) break;//2000.12.7
		if(w>=0.999999) break;//2000.12.7
		d0=pow((m0*w-m),2)/(w*(1-w));
		//To avoid difference between DEBUG and RELEASE
		if(beta<=d0) {
			beta=d0;t=i;
		}
	}
	if(ave > 5)
		if(t - tmin > 50) t = t - 20;//30;
	for(j=ys;j<=ye;j++)for(i=xs;i<=xe;i++)
	{	
		if(destF[j*Wx+i]<=t)	
			srcF[j*Wx+i] = 1;
	}	
	return t;

}
BYTE* CBinarization::Binarization_Otsu(BYTE *pImg, int w, int h)
{
	if (!pImg) return NULL;
	double th = GetThreshold_Otsu(pImg, w, h);
	BYTE *pNewImg = Binarization_By_Th(pImg, w, h, th);
	return pNewImg;
}

BYTE* CBinarization::Binarization_Otsu_SubRect(BYTE *pImg, int w, int h,CRect rect)
{
	if (!pImg) return NULL;
	double th = GetThreshold_Otsu(pImg, w, h, rect);
	BYTE *pNewImg = Binarization_By_Th(pImg, w, h, th);
	return pNewImg;
}
BYTE* CBinarization::Binarization_Camera(BYTE *pImg, int w, int h)
{
	BYTE* pMeanImg = CImageFilter::MeanFilter(pImg,w,h,50);
	if(pMeanImg==NULL) return NULL;
	int i,j,pos;
	for (i = 0; i < h; i++) {
		pos = i * w;
		for (j = 0; j < w; j++)
			if (pImg[pos + j] > pMeanImg[pos + j])
				pMeanImg[pos + j] = 255;
			else
				pMeanImg[pos + j] = 255 + pImg[pos + j] - pMeanImg[pos + j];
	}
		
	double th = GetThreshold_Otsu(pMeanImg, w, h);
	BYTE *pBinImg = Binarization_By_Th(pMeanImg, w, h, th);
	delete[] pMeanImg;
	return pBinImg;
}



#ifndef pi
	#define pi  3.141592
#endif
BYTE* CBinarization::Binarization_Maximum_Separability_Axis(BYTE *_24Dib)
{
	int Q, fai,i,k;
	if (!_24Dib) return NULL;
	int size = 0,w=0,h=0;
	RGBQUAD* pRgb = MakeRGBFrom24DIB(_24Dib,w,h);
	if(pRgb == NULL) return NULL;
	BYTE* pArray = new BYTE[w*h];
	BYTE* pMaxArray = new BYTE[w*h];

	double tanQ=0.0,tanfai=0.0;
	double MaxTh =0.0,MaxDist = 0.0;
	double axis[3]={0.0};

	for (Q=0 ; Q<180 ; Q++){//Q�� 0������ 180��Ĵ��
		tanQ = tan(Q*pi/180);
		for (fai=0 ; fai<180 ; fai++){//Fai�� 0������ 180��Ĵ�� �� ������ʿ �ٳ�.
			if (Q != 90 && fai !=90){
				tanfai = tan(fai*pi/180);
				axis[0] = 1.0;
				axis[1] = tanQ;
				axis[2] = tanfai/cos(Q*pi/180);
				for (i=0;i<w*h;i++)
					pArray[i] = (BYTE)ProjectRGBToAxis(pRgb[i].rgbRed,pRgb[i].rgbGreen,pRgb[i].rgbBlue,axis);
				double th=0.0,dist = 0.0;
				th = GetThreshold_Otsu(pArray,w,h,dist);
				if (dist>MaxDist){
					MaxTh = th;
					memcpy(pMaxArray,pArray,w*h);
				}
			}
		}
	}

	for (k=0; k<size ; k++)
		if (pMaxArray[k] < MaxTh)
			pMaxArray[k] = 0;
		else
			pMaxArray[k] = 255;

	delete [] pArray;pArray = NULL;
	delete [] pRgb; pRgb = NULL;

	return pMaxArray;
}


double CBinarization::GetThreshold_Otsu(BYTE *pImg, int w, int h)
{
	double dist;
	return GetThreshold_Otsu(pImg, w, h, dist, CRect(0,0,w,h));
}
double CBinarization::GetThreshold_Otsu(BYTE *pImg, int w, int h, CRect subrect)
{
	double dist;
	return GetThreshold_Otsu(pImg, w, h, dist, subrect);
}
double CBinarization::GetThreshold_Otsu(BYTE *pImg, int w, int h, double& dist)
{
	return GetThreshold_Otsu(pImg, w, h, dist, CRect(0,0,w,h));
}

double CBinarization::GetThreshold_Otsu(BYTE *pImg, int w, int h, double& dist, CRect subrect)
{
	if(pImg==NULL) return -1;
	if(subrect.left<0)    subrect.left = 0;
	if(subrect.top<0)     subrect.top = 0;
	if(subrect.right>=w)  subrect.right = w-1;
	if(subrect.bottom>=h) subrect.bottom = h-1;

	int xs,xe,ys,ye,pos;
	int i,j,k,n[256];

	xs=subrect.left;  ys=subrect.top;
	xe=subrect.right; ye=subrect.bottom;	
	
//1. Original histogram
	for(i=0;i<256;i++)n[i]=0; 
	for (i = ys; i <= ye; i++) {
		pos = i * w;
		for (j = xs; j <= xe; j++)
		{
			k = (int)pImg[pos + j]; n[k]++;//gray histogram
		}
	}

 	return GetThreshold_Otsu_From_Histogram(n,dist);
}

double CBinarization::GetThreshold_Otsu_From_Histogram(int* Hist, double& dist)
{
	int i,tmin,tmax,t;
	int s;
	float m0,d0,WW,m,beta,p0;
	
	t=0;
	for(i=0;i<256;i++)
		t+=Hist[i];
	int nIgnoe = (int)sqrt((double)t);

	t=0;tmin=0;
	for(i=0;i<256;i++)
	{
		t+=Hist[i];
		if(t > nIgnoe) {tmin=i;break;}// min gray level 
	}
	t=0;tmax=255;
	for(i=255;i>0;i--)
	{
		t+=Hist[i];
		if(t > nIgnoe) {tmax=i;break;}// max gray level 
	}
	if((tmax-tmin)<=0) return tmin;// no object
	
	//2. Binarization 
	// total mean value of image
	s=0;m0=0;
	for(i=tmin;i<=tmax;i++){
		m0+=(float)i*(float)Hist[i];
		s+=Hist[i];
	}
	m0/=s;//total mean gray level value 
	
	int s1=0;
	for(i=0;i<256;++i){
		if(Hist[i]>0) s1++;
	}
	if(s1<=2)	return (int)m0;
	
	// Optimal threshold value determination
	WW=m=beta=d0=0;t=0;
	for(i=tmin;i<tmax;i++)
	{
		if(Hist[i]==0) continue;
		p0=(float)Hist[i]/(float)s;
		WW=WW+p0; m=m+i*p0;
		if(WW>=0.999999) break;//2000.12.7
		d0=(m0*WW-m)*(m0*WW-m)/(WW*(1-WW));
		//To avoid difference between DEBUG and RELEASE
		if(beta<d0) {
			beta=d0;t=i;
		}
	}
	dist = beta;
 	return t;
}

double CBinarization::ProjectRGBToAxis(BYTE r, BYTE g, BYTE b, double *axis)
{
	double A[3];
	A[0]=(double)r;
	A[1]=(double)g;
	A[2]=(double)b;

	double* vlu = ProjectVector(A,axis,3);
	double len = sqrt(vlu[0]*vlu[0]+vlu[1]*vlu[1]+vlu[2]*vlu[2]);
	delete [] vlu;vlu = NULL;
	return len;
}

double* CBinarization::ProjectVector(double *A, double *B, int size)
{
	int i;
	double* ret = new double[size];
	double up = ScalarProduct(A,B,size);
	double down = ScalarProduct(B,B,size);
	up /= down;
	for (i=0; i<size ; i++)
		ret[i] = B[i]*up;

	return ret;
}

double CBinarization::ScalarProduct(double *V1, double *V2, int size)
{
	int i;
	if (!V1 || !V2) return 0.0;
	double ret=0.0;
	for (i=0; i<size ; i++)
		ret += V1[i]*V2[i];

	return ret;
}

RGBQUAD* CBinarization::MakeRGBFrom24DIB(BYTE *pDib, int& w,int& h)
{
	int i,j;
	if (pDib == NULL) return NULL;
	
	BITMAPINFOHEADER* pBIH = (BITMAPINFOHEADER*)(pDib+1);
	w = pBIH->biWidth;
	h = pBIH->biHeight;
	if (pBIH->biBitCount != 24) return NULL;
	BYTE* pBits = pDib+sizeof(BITMAPINFOHEADER);
	int ByteWid = (w*24+31)/32*4;
	RGBQUAD* pRgb = new RGBQUAD[w*h];
	for (i=0 ; i<h;i++)	for (j=0; j<w;j++)
	{
		pRgb[i*w+j].rgbBlue  = pBits[(h-1-i)*ByteWid+3*j];
		pRgb[i*w+j].rgbGreen = pBits[(h-1-i)*ByteWid+3*j+1];
		pRgb[i*w+j].rgbRed   = pBits[(h-1-i)*ByteWid+3*j+2];
	}
	return pRgb;
}

double CBinarization::GetThreshold_Minium_Error(BYTE *pImg, int w, int h)
{
	int i,j,t;
	float J[256], P1[256], P2[256], u1[256], u2[256], s1[256], s2[256];
	float a,b,c,d;

	int *hist;
/* Histogram */
	hist = (int *)malloc(sizeof(int)*256);

	CHistogram::GetHistogram (pImg, w, h, hist);

	int Num = 0, Sum = 0;
	for (i=0; i<256; i++)
	{
		Num += hist[i];
		Sum += hist[i]*i;
	}
	int sum1 = 0;
	int sum2 = 0;
	for (i=0; i<256; i++)
	{
		sum1 += hist[i];
		sum2 += hist[i]*i;
		P1[i] = (float)sum1;
		if(P1[i]>0){
			u1[i] = (float)sum2/P1[i];
			float s = 0.0f;
			for (j=0; j<=i; j++)
				s += (j-u1[i])*(j-u1[i])*hist[j];
			s1[i] = s/P1[i];		
		}
		else{
			u1[i] = 0.0f;
			s1[i] = 0.0f;
		}

		P2[i] = (float)(Num-sum1);
		if(P2[i]>0){
			u2[i] = (float)(Sum-sum2)/P2[i];
			float s = 0.0f;
			for (j=i+1; j<=255; j++)
				s += (j-u2[i])*(j-u2[i])*hist[j];
			s2[i] = s/P2[i];
		}
		else{
			u2[i] = 0.0f; 
			s2[i] = 0.0f;
		}

	}

	t = 0;
	a = P1[0]; b = s1[0];
	c = P2[0]; d = s2[0];
	J[0] = 1.0f + 2.0f*(a*flog(b) + c*flog(d)) - 2.0f*(a*flog(a) + c*flog(c));
	for (i=1; i<256; i++)
	{
		a = P1[i]; b = s1[i];
		c = P2[i]; d = s2[i];
		J[i] = 1.0f + 2.0f*(a*flog(b) + c*flog(d)) - 2.0f*(a*flog(a) + c*flog(c));
		if (J[i] < J[t]) t = i;
	}

	free(hist);
	return t;
}
BYTE* CBinarization::Binarization_Minium_Error(BYTE *pImg, int w, int h)
{
	double th = GetThreshold_Minium_Error(pImg, w, h);
	BYTE*	pBinImg = Binarization_By_Th(pImg, w, h, th);
	return pBinImg;
}


BYTE* CBinarization::Binarization_MovingAverages(BYTE *pImg, int w, int h)
{
	float pct = 15.0;       /* Make smaller to darken the image */
	float Navg = 5.0;       /* Fraction of a row in the average (ie 1/8) */

	int row, col, inc;
	float mean, s, sum;
	int p;
	long N, i;

	N = w * h;

	BYTE *pBinImg = (BYTE *)malloc(N);

	s = (float)(int)(w/Navg);
	sum = 127*s;

	row = col = 0;
	p = pImg[0];
	inc = 1;

	for (i=0; i<N-1; i++)
	{
	  if (col >= w)
	  {
	    col = w-1; row++;
	    p = pImg[row * w + col];
	    inc = -1;
	  } 
	  else if (col < 0)
	  {
	    col = 0;   row++;
	    p = pImg[row * w + col];
	    inc = 1;
	  }
	  else
	  {
	    p = pImg[row * w + col];
	  }

/* Estimate the mean of the last NC/8 pixels. */
	  sum = sum - sum/s + p;
	  mean = sum/s;
	  if (p < mean*(100-pct)/100.0) pBinImg[row * w +col] = LOW_LEVEL;
		else pBinImg[row * w +col] = HIGH_LEVEL;
	  col += inc;
	}
	return pBinImg;
}

/*
Name: Binarization_DynamicThereshold
Input
	pImg: image
	w,h:  width and height of image
	winX, winY:  size of window to calculate thresholds
	gridX,gridY: count of grids to calculate thresholds
	special_mode: 
Return
	Binary Image
Function:Binarization using dynamic thresholds 
Date 2007/10/05
*/
BYTE* CBinarization::Binarization_DynamicThreshold(BYTE* pImg,int w,int h,CSize WinSize,int special_mode/*=SMODE_NON*/)
{
	int nGridX = 2*w/WinSize.cx;
	int nGridY = 2*h/WinSize.cy;
	return Binarization_DynamicThreshold(pImg, w, h, WinSize.cx, WinSize.cy, nGridX, nGridY,special_mode);
}
BYTE* CBinarization::Binarization_DynamicThreshold(BYTE* pImg,int w,int h,int nGridX,int nGridY,int special_mode/*=SMODE_NON*/)
{
	int winX = 2*w/nGridX;
	int winY = 2*h/nGridY;
	return 	Binarization_DynamicThreshold(pImg, w, h, winX, winY, nGridX, nGridY,special_mode);
}
BYTE* CBinarization::Binarization_DynamicThreshold(BYTE* pImg,int w,int h,int winX, int winY,int nGridX,int nGridY,int special_mode/*=SMODE_NON*/)
{
	int i,j,pos,size;
	if(pImg==NULL) return NULL;
	if(winX<=0 || winY<=0) return NULL;
	if(winX>w || winY>h) return NULL;
	if(nGridX<=0 || nGridY<=0) return NULL;
	size = w * h;
	BYTE *pBinImg = new BYTE[size];
	if(pBinImg == NULL) return NULL;
	size = nGridX * nGridY;
	int    *Ths  = new int[size];
	double *Dist = new double[size];
	double SumDist = 0;
	int y_step = h/(nGridY);
	int x_step = w/(nGridX);
    
	double globalTh;
	if( special_mode==SMODE_GLOBAL_OTSU || special_mode==SMODE_SMALL_DIST_GLOBAL_OTSU)
		globalTh = GetThreshold_Otsu(pImg, w, h);

	for(i=0;i<nGridY;i++)for(j=0;j<nGridX;j++)
	{
		CRect rect;
		int y = y_step*i;
		int x = x_step*j;
		rect.top = y - winY /2;
		rect.bottom = y + winY /2;
		rect.left = x - winX /2;
		rect.right = x + winX /2;
		if(rect.top<0)
		{
			rect.bottom -= rect.top;
			rect.top = 0;
		}
		if(rect.left<0)
		{
			rect.right -= rect.left;
			rect.left = 0;
		}
		if(rect.bottom>=h)
		{
			rect.top -= (rect.bottom-h+1);
			rect.bottom = h-1;
		}
		if(rect.right>=w)
		{
			rect.left -= (rect.right-w+1);
			rect.right = w-1;
		}
		if(rect.left < h) {rect.right += (h - rect.left);rect.left = h ;}
		if(rect.right > w - h ) {rect.left -= (rect.right - (w-h));rect.right = w - h;}
		Ths[i*nGridX+j] = (int)GetThreshold_Otsu(pImg, w, h, Dist[i*nGridX+j], rect);
		SumDist += Dist[i*nGridX+j];
		if( special_mode==SMODE_GLOBAL_OTSU || special_mode==SMODE_SMALL_DIST_GLOBAL_OTSU)
			if(Ths[i*nGridX+j]>globalTh) Ths[i*nGridX+j] = (int)(globalTh+ (Ths[i*nGridX+j]-globalTh)*0.3);

	}
	if( special_mode==SMODE_SMALL_DIST || special_mode==SMODE_SMALL_DIST_GLOBAL_OTSU)
	{
		SumDist /= nGridY*nGridX;
		for(i=0;i<nGridY;i++)for(j=0;j<nGridX;j++)
			if(Dist[i*nGridX+j]<SumDist/10)  Ths[i*nGridX+j] = -1;
	}

	for (i = 0; i < h; i++) {
		pos = i * w;
		for (j = 0; j < w; j++)
		{
			int Th = 0;
			int ii = i / y_step;
			int jj = j / x_step;
			int di, dj;
			if (ii >= nGridY - 1) { ii = nGridY - 2; di = y_step; }
			else
				di = i - ii * y_step;

			if (jj >= nGridX - 1) { jj = nGridX - 2; dj = x_step; }
			else
				dj = j - jj * x_step;

			Th = (Ths[ii * nGridX + jj] * (y_step - di) * (x_step - dj) +
				Ths[(ii + 1) * nGridX + jj] * di * (x_step - dj) +
				Ths[ii * nGridX + jj + 1] * (y_step - di) * dj +
				Ths[(ii + 1) * nGridX + jj + 1] * di * dj) / y_step / x_step;

			if (pImg[pos + j] <= Th)
				pBinImg[pos + j] = LOW_LEVEL;
			else
				pBinImg[pos + j] = HIGH_LEVEL;
		}
	}
	delete[] Ths;
	delete[] Dist;
	return pBinImg;
}

BYTE* CBinarization::Binarization_Windows(BYTE* pImg,int w,int h,int nWinSize)
{
	if (!pImg || w<1 || h<1)
		return NULL;
	int nWindowSize = nWinSize;
	int i=0,j=0,i1,j1;
	int nSum = 0,nTemp=0;
	int divid = (2*nWindowSize+1)*(2*nWindowSize+1)-1;

	int ww = w+2*nWindowSize+1;
	int hh = h+2*nWindowSize;
	int size = ww * hh;
	BYTE* temp = new BYTE[size];
	memset(temp, 255, size);
	for(i = 0; i < h; i++) 
		memcpy(temp+(i+nWindowSize)*ww+nWindowSize+1 , pImg + i*w, w);

	size = w * h;
	int pos_x = 0;
	BYTE* pbImage = new BYTE[size];
	memset(pbImage, 0, size);
	for(i = nWindowSize; i < hh-nWindowSize; i++)
	{
		nSum = 0;
		int pos = (i - nWindowSize) * w;
		for (i1 = i - nWindowSize; i1 <= i + nWindowSize; i1++) {
			pos_x = i1 * ww;
			for (j1 = 0; j1 < 2 * nWindowSize + 1; j1++)
			{
				nSum += temp[pos_x + j1];
			}
		}
		for(j = nWindowSize+1; j < ww-nWindowSize; j++)
		{
			for(i1 = i-nWindowSize; i1 <= i+nWindowSize; i1++)
			{
				pos_x = i1 * ww;
				nSum -= temp[pos_x +j-nWindowSize-1];
				nSum += temp[pos_x +j+nWindowSize];
			}
			nTemp = pos + (j-nWindowSize-1);
			if(pImg[nTemp]+15 < (nSum-pImg[nTemp])/divid)
			//if (pImg[nTemp] + 30 < (nSum - pImg[nTemp]) / divid)
				pbImage[nTemp] = LOW_LEVEL;
			else
				pbImage[nTemp] = HIGH_LEVEL;
		}
	}
	delete[] temp;
	return pbImage;
}

//----------Discrete Convolution Filtering Technique-----------------
//HJI
BYTE* CBinarization::Binarization_HJI(BYTE *pImg, int w, int h)
{
	int i,j;
	int ii,jj;
	int meanV;
	int hh[5][5]={
		{-1,-1,-1,-1,-1},
		{-1,-2,-2,-2,-1},
		{-1,-2,35,-2,-1},
		{-1,-2,-2,-2,-1},
		{-1,-1,-1,-1,-1},
	};

	if (!pImg)
		return NULL;

	int N=w*h;
	
	BYTE* pImgT1 = new BYTE[N];
	memset(pImgT1,0,N);

	//Binarization  of image by BST method
    for(i=0 ;i <h ;i++ ){
		for(j=0; j<w ;j++){
			meanV=0;
			if(i<2 || i>h-3 || j<2 || j>w-3)
			{
				meanV=255;
			}
			else
			{
				for(ii=-2;ii<3;ii++){
					for(jj=-2;jj<3;jj++){
					meanV += pImg[(i+ii)*w+j+jj] * hh[ii+2][jj+2];
					}
				}
			}
			pImgT1[i*w+j]= meanV>128 ? HIGH_LEVEL: LOW_LEVEL;	
		}
	}
	return pImgT1;
}

