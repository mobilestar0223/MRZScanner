

#include "global.h"
#include "imgproc.h"

void im_blur(BYTE* pImg, BYTE* pOut, int nW, int nH, int nC)
{
	int x = 0, y = 0;
	int xx = 0;
	int ww = 0;
	int cc[3] = {0, 0, 0};

	memset(pOut, 0, nH*nW*nC);
	for(y = 1; y < nH-1; y++)
	{
		ww = nW*nC;
		for(x = 1; x < nW-1; x++)
		{
			xx = (y*nW + x)*nC;
			cc[0] = cc[1] = cc[2] = 0;
			for (int i = 0; i < nC; i++)
			{
				cc[i] = pImg[xx - ww - nC+i ] + pImg[xx - ww+i]*2 + pImg[xx - ww + nC+i ];
				cc[i] += pImg[xx - nC+i]*2 + pImg[xx+i]*4 + pImg[xx + nC+i ]*2;
				cc[i] += pImg[xx + ww - nC+i ] + pImg[xx + ww+i]*2 + pImg[xx + ww + nC+i ];

				pOut[xx+i] = cc[i]/16;
			}
		}
	}

	//edge 0, nH
	for (x = 0; x < nW; x++)
	{
		for (int i = 0; i < nC; i++)
		{
			pOut[x*nC + i]	 = pOut[(nW + x)*nC + i];
			pOut[((nH-1)*nW + x)*nC + i] = pOut[((nH-2)*nW + x)*nC + i];
		}
	}

	//edge 0, nH
	for (y = 0; y < nH; y++)
	{
		for (int i = 0; i < nC; i++)
		{
			pOut[y*nW*nC + i] = pOut[(y*nW+1)*nC + i];
			pOut[(y*nW+nW-1)*nC + i] = pOut[(y*nW+nW-2)*nC + i];
		}
	}
}

void im_binary(BYTE *pbGray, BYTE *pbOut, int nWidth, int nHeight, int nThres)
{
	int nX, nY, xx, yy;

	for( nY = 0; nY < nHeight; nY++ )
	{
		yy = nY*nWidth;
		for( nX = 0; nX < nWidth;  nX++ )
		{
			xx = yy+nX;
			if( pbGray[xx] > nThres )
				pbOut[xx] = 255;
			else
				pbOut[xx] = 0;
		}
	}
}

///////////////
void im_binary_windows(BYTE* pImg, BYTE* pOut, int w, int h, int nWinSize)
{
	if (!pImg || w<1 || h<1 || !pOut)
		return;

	int nWindowSize = nWinSize;
	int i = 0, j = 0, i1, j1;
	int nSum = 0, nTemp = 0;
	int divid = (2 * nWindowSize + 1)*(2 * nWindowSize + 1) - 1;

	int ww = w + 2 * nWindowSize + 1;
	int hh = h + 2 * nWindowSize;
	BYTE* temp = new BYTE[ww*hh];
	memset(temp, 255, ww*hh);
	for (i = 0; i < h; i++) memcpy(temp + (i + nWindowSize)*ww + nWindowSize + 1, pImg + i*w, w);


	memset(pOut, 0, w*h);
	for (i = nWindowSize; i < hh - nWindowSize; i++)
	{
		nSum = 0;
		for (i1 = i - nWindowSize; i1 <= i + nWindowSize; i1++)
			for (j1 = 0; j1 < 2 * nWindowSize + 1; j1++)
			{
				nSum += temp[i1*ww + j1];
			}
		for (j = nWindowSize + 1; j < ww - nWindowSize; j++)
		{
			for (i1 = i - nWindowSize; i1 <= i + nWindowSize; i1++)
			{
				nSum -= temp[i1*ww + j - nWindowSize - 1];
				nSum += temp[i1*ww + j + nWindowSize];
			}
			nTemp = (i - nWindowSize)*w + (j - nWindowSize - 1);
			if (pImg[nTemp] + 15 < (nSum - pImg[nTemp]) / divid)
				pOut[nTemp] = 0;
			else
				pOut[nTemp] = 255;
		}
	}
	delete[] temp;
}

void im_RGB2Gray(BYTE *pbRGB, BYTE *pbGray, int nWidth, int nHeight, int nChannel)
{
	int i, nSize = nWidth * nHeight;
	//for( i = 0; i < nSize; i++ )
	//	pbGray[i] = ( ( (int)pbRGB[i*3] * 117 + (int)pbRGB[i*3+1] * 601 + (int)pbRGB[i*3+2] * 306 ) >> 10 ) & pbMask[i];

	for(i = 0; i < nSize; i++)
		pbGray[i] = (((int)pbRGB[i*nChannel]*117+(int)pbRGB[i*nChannel+1]*601+(int)pbRGB[i*nChannel+2]*306) >> 10);
}

void im_RGB2HSL(BYTE nR, BYTE nG, BYTE nB, BYTE& nH, BYTE& nS, BYTE& nL) 
{
#define  HSLMAX   255
#define  RGBMAX   255
#define  UNDEFINED ( HSLMAX * 2 / 3 )

	BYTE cMax,cMin;
	WORD Rdelta,Gdelta,Bdelta;

	cMax = max( max( nR, nG ), nB );
	cMin = min( min( nR, nG ), nB );
	nL = (BYTE)( ( ( ( cMax + cMin ) * HSLMAX ) + RGBMAX ) / ( 2 * RGBMAX ) );

	if ( cMax == cMin ) 
	{
		nS = 0;
		nH = UNDEFINED;
	}
	else 
	{
		if ( nL <= ( HSLMAX / 2 ) )
			nS = (BYTE)( ( ( ( cMax - cMin ) * HSLMAX ) + ( ( cMax + cMin ) / 2 ) ) / ( cMax + cMin ) );
		else
			nS = (BYTE)( ( ( ( cMax - cMin ) * HSLMAX ) + ( ( 2 * RGBMAX - cMax - cMin ) / 2 ) ) / ( 2 * RGBMAX - cMax - cMin ) );
		/* hue */
		Rdelta = (WORD)((((cMax - nR) * (HSLMAX / 6)) + ((cMax - cMin) / 2) ) / (cMax - cMin));
		Gdelta = (WORD)((((cMax - nG) * (HSLMAX / 6)) + ((cMax - cMin) / 2) ) / (cMax - cMin));
		Bdelta = (WORD)((((cMax - nB) * (HSLMAX / 6)) + ((cMax - cMin) / 2) ) / (cMax - cMin));

		if ( nR == cMax )
			nH = (BYTE)( Bdelta - Gdelta );
		else if ( nG == cMax )
			nH = (BYTE)(( HSLMAX / 3) + Rdelta - Bdelta);
		else
			nH = (BYTE)(((2 * HSLMAX) / 3) + Gdelta - Rdelta);

		if ( nH < 0 ) 
			nH += HSLMAX;
		if ( nH > HSLMAX ) 
			nH -= HSLMAX;
	}
}

void im_EnhanceImage(BYTE *pbImg, int nW, int nH, int nC)
{
	int hist[3][256];
	int nMax = 255, nMin = 0, nTotal = 0;
	int nMax1 = 240, nMin1 = 10;
	int point_pos = 0;

	int i = 0, j = 0;
	BYTE** ppbyTemp;
	ppbyTemp = new BYTE*[nC];
	for (i = 0; i < nC; i++)
	{
		ppbyTemp[i] = new BYTE[nW*nH];
		for (j = 0; j < nW*nH; j++)
			ppbyTemp[i][j] = pbImg[j*nC+i];
	}

	for (i = 0; i < nC; i++)
	{
		im_Histogram(ppbyTemp[i], nW, nH, hist[i]);
		im_MaxMin(hist[i], 256, NULL, NULL, &nTotal);

		int nTemp;
		nTemp = 0;
		while( nTemp < nTotal*5/100 )
			nTemp += hist[i][nMax--];
		nTemp = 0;
		while( nTemp < nTotal*5/100 )
			nTemp += hist[i][nMin++];

		float temp = (float)(nMax1 - nMin1)/(float)(nMax - nMin);
		float res;

		for (int y = 0; y < nH; y++)
		{
			point_pos = y*nW;
			for (int x = 0; x < nW; x++)
			{
				res = nMin1 + (ppbyTemp[i][x+point_pos] - nMin)*temp;
				if (res < 0)
					res = 0;
				else if(res > 255)
					res = 255;
				pbImg[(x+point_pos)*nC+i] = (BYTE)res;
			}
		}
	}

	for (i = 0; i < nC; i++)
		delete[] ppbyTemp[i];
	delete[] ppbyTemp;
}

void im_NegativeImage(BYTE* pbImg, int nW, int nH, RECT* pRt, int nCol)
{
	int k = 0, i, j;
	int x0 = 0, y0 = 0;
	int x1 = nW, y1 = nH;
	int point_pos = 0;

	if (pRt)
	{
		x0 = pRt->left;
		y0 = pRt->top;
		x1 = pRt->right + 1;
		y1 = pRt->bottom + 1;
	}

	if (nCol == 255)
	{
		for(j = y0; j < y1; j++)
		{
			point_pos = j*nW;
			for (i = x0; i < x1; i++)
			{
				pbImg[point_pos + i] = 255 - pbImg[point_pos + i];
			}
		}
	}
}

void im_dilate(BYTE* pbImg, BYTE* pbOut, int nW, int nH, int Ksize)
{
	if (!pbImg || !pbOut) return;

	int k2 = Ksize/2;
	int kmax= Ksize-k2;
	BYTE byMax;

	for(int y=0; y<nH; y++)
	{
		for(int x=0; x<nW; x++)
		{
			byMax = 0;
			for(int j=-k2; j<kmax; j++)
			{
				for(int k=-k2; k<kmax; k++){
					if (0<=y+k && y+k<nH && 0<=x+j && x+j<nW)
					{
						if (pbImg[(y+k)*nW + (x + j)] > byMax)
							byMax = pbImg[(y+k)*nW + (x + j)];
					}
				}
			}
			pbOut[y*nW + x] = byMax;
		}
	}
}

void im_erode(BYTE* pbImg, BYTE* pbOut, int nW, int nH, int Ksize)
{
	if (!pbImg || !pbOut) return;

	int k2 = Ksize/2;
	int kmax= Ksize-k2;
	BYTE byMin;

	for(int y=0; y<nH; y++)
	{
		for(int x=0; x<nW; x++)
		{
			byMin = 255;
			for(int j=-k2; j<kmax; j++)
			{
				for(int k=-k2; k<kmax; k++){
					if (0<=y+k && y+k<nH && 0<=x+j && x+j<nW)
					{
						if (pbImg[(y+k)*nW + (x + j)] < byMin)
							byMin = pbImg[(y+k)*nW + (x + j)];
					}
				}
			}
			pbOut[y*nW + x] = byMin;
		}
	}
}

void im_edge(BYTE* pbImg, BYTE* pbOut, int nW, int nH, int Ksize)
{
	if (!pbImg || !pbOut) return;

	int k2 = Ksize/2;
	int kmax= Ksize-k2;
	BYTE byMin, byMax;

	for(int y=0; y<nH; y++)
	{
		for(int x=0; x<nW; x++)
		{
			{
				byMax=0;
				byMin=255;
				for(int j=-k2;j<kmax;j++)
				{
					for(int k=-k2;k<kmax;k++)
					{
						if (0<=y+k && y+k<nH && 0<=x+j && x+j<nW)
						{
							if (pbImg[(y+k)*nW + (x + j)] > byMax)
								byMax = pbImg[(y+k)*nW + (x + j)];
							if (pbImg[(y+k)*nW + (x + j)] < byMin)
								byMin = pbImg[(y+k)*nW + (x + j)];
						}
					}
				}
				pbOut[y*nW + x] = (BYTE)(255-abs(byMax - byMin));
			}
		}
	}
}

void im_filter(BYTE* pbImg, BYTE* pbOut, int nW, int nH, int* pnT, int nSize, int nFactor, int nOffset)
{
	if (!pbImg || !pbOut) return;

	int k2 = nSize/2;
	int kmax= nSize-k2;
	int b, i;
	int ksumcur,ksumtot;

	ksumtot = 0;
	for(int j=-k2;j<kmax;j++){
		for(int k=-k2;k<kmax;k++){
			ksumtot += pnT[(j+k2)+nSize*(k+k2)];
		}
	}

	int iCount;
	int iY, iY2, iY1;
	for(int y=0; y<nH; y++)
	{
		iY1 = y*nW;
		for(int x=0; x<nW; x++, iY1++)
		{
			{
				b=ksumcur=0;
				iCount = 0;
				iY2 = ((y-k2)*nW);
				for(int j=-k2;j<kmax;j++, iY2+=nW)
				{
					if (0>(y+j) || (y+j)>=nH) continue;
					iY = iY2+x;
					for(long k=-k2;k<kmax;k++, iCount++)
					{
						if (0>(x+k) || (x+k)>=nW) continue;
						i=pnT[iCount];
						b += pbImg[iY+k] * i;
						ksumcur += i;
					}
				}
				if (nFactor==0 || ksumcur==0){
					pbOut[iY1] = (BYTE)min(255, max(0,(int)(b + nOffset)));
				} else if (ksumtot == ksumcur) {
					pbOut[iY1] = (BYTE)min(255, max(0,(int)(b/nFactor + nOffset)));
				} else {
					pbOut[iY1] = (BYTE)min(255, max(0,(int)((b*ksumtot)/(ksumcur*nFactor) + nOffset)));
				}
			}
		}
	}
}

int get_optical_threshold(BYTE *pbImg, int nW, int nH)
{
	if (!pbImg)
		return -1;

	double p[256];
	memset(p,  0, 256*sizeof(double));
	//build histogram
	for (long y = 0; y < nH; y++){
		BYTE* pGray = (pbImg+y*nW);
		for (long x = 0; x<nW; x++){
			BYTE n = *pGray++;
			p[n]++;
		}
	}

	//find histogram limits
	int gray_min = 0;
	while (gray_min<255 && p[gray_min]==0) gray_min++;
	int gray_max = 255;
	while (gray_max>0 && p[gray_max]==0) gray_max--;
	if (gray_min > gray_max)
		return -1;
	if (gray_min == gray_max){
		if (gray_min == 0)
			return 0;
		else
			return gray_max-1;
	}

	//compute total moments 0th,1st,2nd order
	int i,k;
	double w_tot = 0;
	double m_tot = 0;
	double q_tot = 0;
	for (i = gray_min; i <= gray_max; i++){
		w_tot += p[i];
		m_tot += i*p[i];
		q_tot += i*i*p[i];
	}

	double L, L1max, L2max, L3max, L4max; //objective functions
	int th1,th2,th3,th4; //optimal thresholds
	L1max = L2max = L3max = L4max = 0;
	th1 = th2 = th3 = th4 = -1;

	double w1, w2, m1, m2, q1, q2, s1, s2;
	w1 = m1 = q1 = 0;
	for (i = gray_min; i < gray_max; i++){
		w1 += p[i];
		w2 = w_tot - w1;
		m1 += i*p[i];
		m2 = m_tot - m1;
		q1 += i*i*p[i];
		q2 = q_tot - q1;
		s1 = q1/w1-m1*m1/w1/w1; //s1 = q1/w1-pow(m1/w1,2);
		s2 = q2/w2-m2*m2/w2/w2; //s2 = q2/w2-pow(m2/w2,2);

		//Otsu
		L = -(s1*w1 + s2*w2); //implemented as definition
		//L = w1 * w2 * (m2/w2 - m1/w1)*(m2/w2 - m1/w1); //implementation that doesn't need s1 & s2
		if (L1max < L || th1<0){
			L1max = L;
			th1 = i;
		}

		//Kittler and Illingworth
		if (s1>0 && s2>0){
			L = w1*log(w1/sqrt(s1))+w2*log(w2/sqrt(s2));
			//L = w1*log(w1*w1/s1)+w2*log(w2*w2/s2);
			if (L2max < L || th2<0){
				L2max = L;
				th2 = i;
			}
		}

		//max entropy
		L = 0;
		for (k=gray_min;k<=i;k++) if (p[k] > 0)	L -= p[k]*log(p[k]/w1)/w1;
		for (k;k<=gray_max;k++) if (p[k] > 0)	L -= p[k]*log(p[k]/w2)/w2;
		if (L3max < L || th3<0){
			L3max = L;
			th3 = i;
		}

		//potential difference (based on Electrostatic Binarization method by J. Acharya & G. Sreechakra)
		// L=-fabs(vdiff/vsum); ?molto selettivo, sembra che L=-fabs(vdiff) o L=-(vsum)
		// abbiano lo stesso valore di soglia... il che semplificherebbe molto la routine
		double vdiff = 0;
		for (k=gray_min;k<=i;k++)
			vdiff += p[k]*(i-k)*(i-k);
		double vsum = vdiff;
		for (k;k<=gray_max;k++){
			double dv = p[k]*(k-i)*(k-i);
			vdiff -= dv;
			vsum += dv;
		}
		if (vsum>0) L = -fabs(vdiff/vsum); else L = 0;
		if (L4max < L || th4<0){
			L4max = L;
			th4 = i;
		}
	}

	int threshold = 0;
	int nt = 0;
	if (th1>=0) { threshold += th1; nt++;}
	if (th2>=0) { threshold += th2; nt++;}
	if (th3>=0) { threshold += th3; nt++;}
	if (th4>=0) { threshold += th4; nt++;}
	if (nt)
		threshold /= nt;
	else
		threshold = (gray_min+gray_max)/2;

	if (threshold <= gray_min || threshold >= gray_max)
		threshold = (gray_min+gray_max)/2;

	return threshold;
}

int get_mean_threshold(BYTE *pbImg, int nW, int nH)
{
	if (!pbImg) return -1;

	float sum=0;
	for(long y=0; y<nH; y++){
		for(long x=0; x<nW; x++){
			sum+=pbImg[y*nW+x];
		}
	}
	return (int)sum/nW/nH;
}

void im_Histogram(BYTE* src, int width, int height, int* hist)
{
	int total = 0;
	int x, y, yy;

	memset(hist, 0, sizeof(int)*256);
	for(y = 0; y < height; y++)
	{
		yy = y*width;
		for(x = 0; x < width; x++)
		{
			total++;
			hist[src[x+yy]]++;
		}
	}
	return;
}

//nBin : the width of histogram, nVal : the color value to be calculated, nFlag : direction
void im_CoHistogram(BYTE* bySrc, int nW, int nH, int nBin, BYTE byVal, int* pnHist, int nFlag)
{
	int x, y, i;

	if (nFlag == HORI)
	{
		//horizontal
		memset(pnHist, 0, sizeof(int)*nW);
		for(x = 0; x < nW; x++)
		{
			for(y = 0; y < nH; y++)
			{
				for (i = x - nBin/2; i<= x+nBin/2; i++)
				{
					if (i < 0) continue;
					if (i >= nW) break;

					if (bySrc[y*nW+i] == byVal)
						pnHist[x]++;
				}
			}
		}
	}
	else if (nFlag == VERT)
	{
		//vertical
		memset(pnHist, 0, sizeof(int)*nH);
		for(y = 0; y < nH; y++)
		{
			for(x = 0; x < nW; x++)
			{
				for (i = y - nBin/2; i<= y+nBin/2; i++)
				{
					if (i < 0) continue;
					if (i >= nH) break;

					if (bySrc[i*nW+x] == byVal)
						pnHist[y]++;
				}
			}
		}
	}
}

void im_MaxMin(int* src, int len, int* max, int* min, int* total)
{
	int i;
	int max1 = 0, min1 = 10000, total1 = 0;
	for (i = 0; i < len; i++)
	{
		if( src[i] == 0 )
			continue;
		total1 += src[i];
		if( src[i] > max1 ) max1 = src[i];
		if( src[i] < min1 ) min1 = src[i];
	}

	if( max != NULL ) *max = max1;
	if( min != NULL ) *min = min1;
	if( total != NULL ) *total = total1;

	return;
}

void im_Resize(BYTE *pSrc, int nSrcW, int nSrcH, int nC, BYTE *pDst, int nDstW, int nDstH)
{
	float ratio_x = 1.0f*nSrcW/nDstW;
	float ratio_y = 1.0f*nSrcH/nDstH;
	int i, j, k;
	int x1, y1, point_pos, point_pos1;
	int step = nC;

	for(j = 0; j < nDstH; j++)
	{
		y1 = (int)(j*ratio_y);
		point_pos = j*nDstW*step;
		point_pos1 = y1*nSrcW*step;
		for (i = 0; i < nDstW; i ++)
		{
			x1 = (int)(i*ratio_x);
			for(k = 0; k < step; k++)
				pDst[point_pos+step*i+k] = pSrc[point_pos1+step*x1+k];
		}
	}
}

void im_Crop(BYTE* pSrc, int nSrcW, int nSrcH, BYTE* pDst, int cx, int cy, int cw, int ch, int nc)
{
	int x, y;
	int pos_x = (cy*nSrcW + cx)*nc;
	for (y = 0; y < ch; y++)
	{
		x = pos_x + y*nSrcW*nc;
		memcpy(pDst + y*cw*nc, pSrc + x, cw*nc);
	}
}

void im_Rotate(BYTE* pSrc, int nSrcW, int nSrcH, BYTE* pdst, int nW, int nH, IPOINT center, float rotateang, int nc)
{
	int i, j, k;
	float x, y;
	float cosAlpa = (float)cos(rotateang);// / 180.0f*PI);
	float sinAlpa = (float)sin(rotateang);// / 180.0f*PI);

	Point2D32f pos;
	SizeInfo tmp_size = getSizeInfo(nSrcW, nSrcH);
	memset(pdst, 0, nW*nH);

	for (j = 0; j < nH; j++)
	{
		for (i = 0; i < nW; i++)
		{
			x = cosAlpa*(i - center.x) + sinAlpa*(j - center.y) + center.x;
			y = -sinAlpa*(i - center.x) + cosAlpa*(j - center.y) + center.y;
			x = min(nW - 1, x);
			x = max(0, x);
			y = min(nH - 1, y);
			y = max(0, y);
			pos.x = x;
			pos.y = y;
			
			for (k = 0; k < nc; k++)
				get_pixelvalue_by_cubic(pSrc, tmp_size, pos, &pdst[nc*j*nW + nc*i + k], nc, k);
			//get_pixelvalue_by_linear(pSrc, tmp_size, pos, &pdst[j*nW+i]);
		}
	}
}

//void im_Skew(BYTE* lpIn, int nInW, int nInH, int x0, int y0, BYTE* lpOut, int nWidth, int nHeight, float fAngX, float fAngY, BYTE nSpaceCol)
//{
//	int i, j, m, n;
//	float x, y, p, q;
//	float cx, sx, cy, sy, cyy, syy;
//	int d, p1, p2, p3, p4;
//	int point_pos;
//
//	cx = cos(fAngX);
//	sx = sin(fAngX);
//
//	cy = cos(fAngY);
//	sy = sin(fAngY);
//
//	int ndx, ndy;
//	y = (nWidth/2)*sx + cy * (nHeight/2);
//	x = (nWidth/2)*cx - sy * (nHeight/2);
//	if(y > 0)	ndy = (int)y;
//	else		ndy = (int)y-1;
//	if(x > 0)	ndx = (int)x;
//	else		ndx = (int)x-1;
//
//	ndy = (ndy - nHeight/2);
//	ndx = (ndx - nWidth/2);
//
//	x0 = x0 - ndx;
//	y0 = y0 - ndy;
//	for(i = 0; i < nHeight + 2*abs(ndy); i++)
//	{
//		cyy = i*cy;
//		syy = i*sy;
//		point_pos = i*(nWidth + 2*abs(ndx));
//		for(j = 0; j < nWidth + 2*abs(ndx); j++)
//		{
//			y = (j*sx + cyy);
//			x = (j*cx - syy);
//			if(y > 0)	m = (int)y;
//			else		m = (int)y-1;
//			if(x > 0)	n = (int)x;
//			else		n = (int)x -1;
//
//			q = y - m;
//			p = x - n;
//
//			p1 = (m+  y0)*nInW+n+  x0;
//			p2 = (m+  y0)*nInW+n+1+x0;
//			p3 = (m+1+y0)*nInW+n+  x0;
//			p4 = (m+1+y0)*nInW+n+1+x0;
//
//			if( (m+y0 >= 0) && (m+y0 < nInH-1) && (n+x0 >= 0) && (n+x0 < nInW-1) )
//				d =(int) (((1-q)*((1-p)*lpIn[p1] + p*lpIn[p2]) + q*((1-p)*lpIn[p3] + p*lpIn[p4])));
//			else
//				d = nSpaceCol;
//			if (i* nWidth+ j < nWidth*nHeight)
//				lpOut[i* nWidth+ j] = max(0, min(255, d));
//		}
//	}
//}
//}}byJJH_20140311

void im_IntImage(BYTE* pbyGray, int *pnSum, int nWidth, int nHeight)
{
	int x, y, yy;
	int partialsum;
	int* pnSumBuff = NULL;
	BYTE* pbGraybuff = NULL;
	int nW = nWidth+1, nH = nHeight+1;

	memset(pnSum, 0, nW*sizeof(int));

	for (y = 1; y < nH; y++)
	{
		yy = y*nW;
		pnSum[yy] = 0;
		partialsum = 0;
		pbGraybuff = &pbyGray[(y-1)*nWidth];
		pnSumBuff = &pnSum[yy-nW];
		for (x = 1; x < nW; x++)
		{
			partialsum += (int)pbGraybuff[(x-1)];
			pnSum[yy+x] = pnSumBuff[x] + partialsum;
		}
	}
}

void im_AdaptiveThreshold(BYTE* pbyGray, BYTE* pbyOut, int nW, int nH, int S, float T)
{
	//int S = nW/16; //nW/16
	//float T = 0.15f; //0.15f

	unsigned long* integralImg = 0;
	int i, j;
	long sum=0;
	int count=0;
	int index;
	int x1, y1, x2, y2;
	int s2 = S/2;

	// create the integral image
	integralImg = (unsigned long*)malloc(nW*nH*sizeof(unsigned long*));

	for (i=0; i<nW; i++)
	{
		// reset this column sum
		sum = 0;

		for (j=0; j<nH; j++)
		{
			index = j*nW+i;

			sum += pbyGray[index];
			if (i==0)
				integralImg[index] = sum;
			else
				integralImg[index] = integralImg[index-1] + sum;
		}
	}

	// perform thresholding
	for (i=0; i<nW; i++)
	{
		for (j=0; j<nH; j++)
		{
			index = j*nW+i;

			// set the SxS region
			x1=i-s2; x2=i+s2;
			y1=j-s2; y2=j+s2;

			// check the border
			if (x1 < 0) x1 = 0;
			if (x2 >= nW) x2 = nW-1;
			if (y1 < 0) y1 = 0;
			if (y2 >= nH) y2 = nH-1;

			count = (x2-x1)*(y2-y1);

			// I(x,y)=s(x2,y2)-s(x1,y2)-s(x2,y1)+s(x1,x1)
			sum = integralImg[y2*nW+x2] -
				integralImg[y1*nW+x2] -
				integralImg[y2*nW+x1] +
				integralImg[y1*nW+x1];

			if ((long)(pbyGray[index]*count) < (long)(sum*(1.0-T)))
				pbyOut[index] = 0;
			else
				pbyOut[index] = 255;
		}
	}

	free (integralImg);
}

void im_Extend(BYTE* pbImg, BYTE* pbOut, int &nW, int &nH, int nExt, int nBK)
{
	memset(pbOut, nBK, (nW + 2*nExt)*(nH + 2*nExt));
	for (int y = 0; y < nH; y++)
		memcpy(pbOut + (y + nExt)*(nW + 2 * nExt) + nExt, pbImg + y*nW, nW);

	nW += 2 * nExt;
	nH += 2 * nExt;
}

bool im_isBlurredImage(BYTE* pbImg, int nW, int nH)
{
	int x, y;
	int val = 0;

	BYTE* pbOut = new BYTE[nW*nH];
	int pnT[] = {0, 1, 0, 1, -4, 1, 0, 1, 0};
	im_filter(pbImg, pbOut, nW, nH, pnT, 3, 1, 0);

	for (y = 0; y < nH; y++)
	{
		for (x = 0; x < nW - 1; x++)
		{
			val += pbOut[y*nW + x];
		}
	}

	val /= (nW*nH);
	val *= val;

	delete[] pbOut;

	if (val <= 16) return false;

	return true;
}

int get_otsu_threshold(BYTE* pImg, int w, int h)
{
	int xs, xe, ys, ye;
	int i, j, k, n[256];

	xs = 0;  ys = 0;
	xe = w - 1; ye = h - 1;

	//1. Original histogram
	for (i = 0; i<256; i++)n[i] = 0;
	for (i = ys; i <= ye; i++)for (j = xs; j <= xe; j++)
	{
		k = (int)pImg[i*w + j]; n[k]++;//gray histogram
	}

	double dist;
	int tmin, tmax, t;
	int s;
	float m0, d0, WW, m, beta, p0;

	t = 0;
	for (i = 0; i<256; i++)
		t += n[i];
	int nIgnoe = (int)sqrt((double)t);

	t = 0; tmin = 0;
	for (i = 0; i<256; i++)
	{
		t += n[i];
		if (t > nIgnoe) { tmin = i; break; }// min gray level 
	}
	t = 0; tmax = 255;
	for (i = 255; i>0; i--)
	{
		t += n[i];
		if (t > nIgnoe) { tmax = i; break; }// max gray level 
	}
	if ((tmax - tmin) <= 0) return tmin;// no object

										//2. Binarization 
										// total mean value of image
	s = 0; m0 = 0;
	for (i = tmin; i <= tmax; i++) {
		m0 += (float)i*(float)n[i];
		s += n[i];
	}
	m0 /= s;//total mean gray level value 

	int s1 = 0;
	for (i = 0; i<256; ++i) {
		if (n[i]>0) s1++;
	}
	if (s1 <= 2)	return (int)m0;

	// Optimal threshold value determination
	WW = m = beta = d0 = 0; t = 0;
	for (i = tmin; i<tmax; i++)
	{
		if (n[i] == 0) continue;
		p0 = (float)n[i] / (float)s;
		WW = WW + p0; m = m + i*p0;
		if (WW >= 0.999999) break;//2000.12.7
		d0 = (m0*WW - m)*(m0*WW - m) / (WW*(1 - WW));
		//To avoid difference between DEBUG and RELEASE
		if (beta<d0) {
			beta = d0; t = i;
		}
	}
	dist = beta;
	return t;
}

void im_binary_otsu(BYTE *pImg, BYTE* pOut, int w, int h)
{
	if (!pImg) return;
	int th = get_otsu_threshold(pImg, w, h);
	
	int i, j;
	for (i = 0; i<h; i++) for (j = 0; j<w; j++)
		if (pImg[i*w + j] <= th)
			pOut[i*w + j] = 0;
		else
			pOut[i*w + j] = 255;
}
