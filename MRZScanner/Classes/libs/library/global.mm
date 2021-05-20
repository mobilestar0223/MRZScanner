
#include "global.h"
#include "imgproc.h"
#include <time.h>

MainDataT* g_pdata_t = NULL;

bool glo_alloc_mem(int nW, int nH)
{
	int nSize = nW*nH;
	if (nSize <= 0)
		return false;

	if (!g_pdata_t)
		return false;

	g_pdata_t->g_nWidth = nW;
	g_pdata_t->g_nHeight = nH;
	g_pdata_t->g_pbyGray = new BYTE[nSize];
	g_pdata_t->g_pbySpec = new BYTE[nSize];
	g_pdata_t->g_pbyTemp0 = new BYTE[nSize];
	g_pdata_t->g_pbyTemp1 = new BYTE[nSize];
	g_pdata_t->g_pbyMono = new BYTE[nSize];

	g_pdata_t->g_pnTemp0 = new int[(nW+1)*(nH+1)];
	g_pdata_t->g_pnStroke = new int[nSize];

	if (!g_pdata_t->g_pbyGray || !g_pdata_t->g_pbyTemp0 || !g_pdata_t->g_pbyTemp1 || !g_pdata_t->g_pbyMono ||
		!g_pdata_t->g_pbySpec || !g_pdata_t->g_pnTemp0 || !g_pdata_t->g_pnStroke)
		return false;

	memset(g_pdata_t->g_pbyGray, 0x0, nSize);
	memset(g_pdata_t->g_pbyTemp0, 0x0, nSize);
	memset(g_pdata_t->g_pbyTemp1, 0x0, nSize);
	memset(g_pdata_t->g_pbyMono, 0x0, nSize);
	memset(g_pdata_t->g_pbySpec, 0x0, nSize);

	memset(g_pdata_t->g_pnTemp0, 0x0, sizeof(int)*nSize);
	memset(g_pdata_t->g_pnStroke, 0x0, sizeof(int)*nSize);

	return true;
}

void glo_free_mem()
{
	if (g_pdata_t->g_pbyGray) delete[] g_pdata_t->g_pbyGray; g_pdata_t->g_pbyGray = NULL;
	if (g_pdata_t->g_pbyMono) delete[] g_pdata_t->g_pbyMono; g_pdata_t->g_pbyMono = NULL;
	if (g_pdata_t->g_pbyTemp0) delete[] g_pdata_t->g_pbyTemp0; g_pdata_t->g_pbyTemp0 = NULL;
	if (g_pdata_t->g_pbyTemp1) delete[] g_pdata_t->g_pbyTemp1; g_pdata_t->g_pbyTemp1 = NULL;
	if (g_pdata_t->g_pbySpec) delete[] g_pdata_t->g_pbySpec; g_pdata_t->g_pbySpec = NULL;

	if (g_pdata_t->g_pnTemp0) delete[] g_pdata_t->g_pnTemp0; g_pdata_t->g_pnTemp0 = NULL;
	if (g_pdata_t->g_pnStroke) delete[] g_pdata_t->g_pnStroke; g_pdata_t->g_pnStroke = NULL;
}

RECT getRect(int x0, int y0, int x1, int y1)
{
	RECT ret;
	ret.left	= max(0, x0);
	ret.right	= max(ret.left, x1);
	ret.top		= max(0, y0);
	ret.bottom	= max(ret.top,  y1);
	return ret;
}

int getRectWidth(RECT x)
{
	return (x.right - x.left + 1) /*/ 2 * 2*/;
}
int getRectHeight(RECT x)
{
	return x.bottom - x.top + 1;
}

bool isIncludeRect(RECT x, RECT y, int nTh)
{
	bool bRet;
	if(x.left >= y.left && x.right <= y.right && x.top >= y.top && x.bottom <= y.bottom)
		bRet = true;
	else
		bRet = false;

	return bRet;
}

bool isIntersectRect(RECT x, RECT y)
{
	bool bRet = false;

	if (x.left < y.left && x.right > y.left && x.right < y.right && 
		x.top <= y.top && x.bottom > y.top && x.bottom <= y.bottom)
		bRet = true;

	if (x.left < y.left && x.right > y.left && x.right < y.right &&
		x.top >= y.top && x.top < y.bottom && x.bottom >= y.bottom)
		bRet = true;

	return bRet;
}

RECT boundRect(RECT rt, int nWidth, int nHeight)
{
	int t;
	RECT ret = rt;

	ret.left	= max(0, min(nWidth-1,	ret.left));
	ret.right	= max(0, min(nWidth-1,	ret.right));
	ret.top		= max(0, min(nHeight-1,	ret.top));
	ret.bottom	= max(0, min(nHeight-1,	ret.bottom));

	if(rt.left > rt.right)
	{
		t = rt.left;
		rt.left = rt.right;
		rt.right = t;
	}
	if(rt.top > rt.bottom)
	{
		t = rt.top;
		rt.top = rt.bottom;
		rt.bottom = t;
	}

	return ret;
}

//RECT glo_scale_rect(RECT rt, float fRate)
//{
//	RECT ret = rt;
//	ret.left *= fRate;
//	ret.top *= fRate;
//	ret.right *= fRate;
//	ret.bottom *= fRate;
//
//	return ret;
//}

void glo_get_left_right(BYTE *pbIn, int nWidth, int nHeight, long &x0, long &x1, long y0, long y1)
{
	int nX, nY;
	for(nX = 0; nX < nWidth; nX++)
	{
		for(nY = y0; nY <= y1; nY++)
		{
			if( pbIn[nY*nWidth+nX] == 0 )
			{
				x0 = nX;
				nX = nWidth;
				break;
			}
		}
	}

	for(nX = nWidth-1; nX > 0; nX--)
	{
		for(nY = y0; nY <= y1; nY++)
		{
			if( pbIn[nY*nWidth+nX] == 0 )
			{
				x1 = nX;
				nX = 0;
				break;
			}
		}
	}

	if( x1 < x0 )
		x1 = x0;
}

int glo_detect_strokes(BYTE *pbIn, BYTE *pbOut, int *pnStroke, STROKE pStroke[], RECT rtRegion,
					   int nWidth, int nHeight, int nMaxNum, BYTE nBk,
					   int nSmallNum, int nSmallW, int nSmallH, bool bSmallRemove, int nMode)
{
	int		yy, yy1, xx;
	int		nX, nY, nX2, nY2, nX3, nY3, k;
	int		nStrokeNum, nPointNum, nStackTop;
	
	int		pnDirectX4[4] = {0, -1, 0, 1};
	int		pnDirectY4[4] = {-1, 0, 1,  0};
	int		pnDirectX8[8] = {-1,  0,  1, -1, 1, -1, 0, 1};
	int		pnDirectY8[8] = {-1, -1, -1,  0, 0,  1, 1, 1};
	int *pnDirectX = NULL, *pnDirectY = NULL;
	
	int*	pnStack = NULL;

	BYTE	nSeed;
	RECT	rtMinRect;

	nStrokeNum = 0;
	pnStack = g_pdata_t->g_pnTemp0;

	rtRegion = boundRect(rtRegion, nWidth, nHeight);

	memset(pnStack, 0, nWidth * nHeight * sizeof(int));
	for( nY = rtRegion.top;  nY <= rtRegion.bottom; nY++ )
	{
		yy = nY * nWidth;
		for( nX = rtRegion.left; nX <= rtRegion.right;  nX++ )
			pnStroke[yy+nX] = -1;
	}

	for( nY = rtRegion.top; nY <= rtRegion.bottom; nY++ )
		memcpy(g_pdata_t->g_pbyTemp0 + nY * nWidth + rtRegion.left, pbIn + nY * nWidth + rtRegion.left, getRectWidth(rtRegion));

	if (nMode == 8)
	{
		pnDirectX = (int*)pnDirectX8;
		pnDirectY = (int*)pnDirectY8;
	}
	else if (nMode == 4)
	{
		pnDirectX = (int*)pnDirectX4;
		pnDirectY = (int*)pnDirectY4;
	}

	for( nY = rtRegion.top; nY <= rtRegion.bottom; nY++ )
	{
		if( nStrokeNum >= nMaxNum )
			break;

		yy = nY * nWidth;
		for( nX = rtRegion.left; nX <= rtRegion.right; nX++ )
		{
			if( nStrokeNum >= nMaxNum )
				break;
			xx = yy + nX;
			nSeed = g_pdata_t->g_pbyTemp0[xx];
			if( nSeed == nBk )
				continue;

			g_pdata_t->g_pbyTemp0[xx] = nBk;
			nPointNum = 1;
			nStackTop = 0;
			pnStroke[xx] = -1;
			rtMinRect = getRect(nX, nY, nX, nY);

			nX3 = nX;
			nY3 = nY;
			while( 1 ) 
			{
				for( k = 0; k < nMode; k++ ) 
				{
					nX2 = nX3 + pnDirectX[k];
					nY2 = nY3 + pnDirectY[k];
					yy1 = nY2 * nWidth + nX2;
					if( nX2 < rtRegion.left || nX2 > rtRegion.right )
						continue;
					if( nY2 < rtRegion.top  || nY2 > rtRegion.bottom )
						continue;
					if (g_pdata_t->g_pbyTemp0[yy1] != nSeed)
						continue;

					rtMinRect.left		= min(nX2, rtMinRect.left);
					rtMinRect.right		= max(nX2, rtMinRect.right);
					rtMinRect.top		= min(nY2, rtMinRect.top);
					rtMinRect.bottom	= max(nY2, rtMinRect.bottom);

					g_pdata_t->g_pbyTemp0[yy1] = nBk;
					nPointNum++;
					pnStack[nStackTop] = yy1;
					nStackTop++;
				}

				nStackTop--;
				if( nStackTop < 0 )
					break;
				nX2 = pnStack[nStackTop] % nWidth;
				nY2 = pnStack[nStackTop] / nWidth;
				pnStroke[nY2*nWidth+nX2] = nY3 * nWidth + nX3;
				nY3 = nY2;
				nX3 = nX2;
			}
			pStroke[nStrokeNum].nFirst = nY3*nWidth+nX3;

			if( nPointNum < nSmallNum ||
				getRectWidth(rtMinRect) < nSmallW || getRectHeight(rtMinRect) < nSmallH )
			{
				if( bSmallRemove )
					glo_paint_stroke(pbOut, nWidth, pStroke[nStrokeNum].nFirst, pnStroke, nBk);
			}
			else
			{
				if( nStrokeNum > MAX_STROKE_NUM-1 )
					break;
				pStroke[nStrokeNum].nPointNum	 = nPointNum;
				pStroke[nStrokeNum].rtRegion	 = rtMinRect;
				pStroke[nStrokeNum].nCol		 = nSeed;
				nStrokeNum++;
			}
		}
	}

	return nStrokeNum;
}


void glo_sub_binary(BYTE* pbyGray, int* pnSum, int* lpOut, int nWidth, int nHeight, int x0, int x1, int y0, int y1, int rw, int rh)
{
	int x, y, xx, yy;
	int sx0, sy0, sx1, sy1;
	int w1, n1, w3, n3;
	int nW = nWidth+1;

	for (y = y0; y <= y1; y++)
	{
		yy = y*nWidth;
		sy0 = y-rh;
		if(sy0 < 0)
			sy0 = 0;
		sy1 = y+rh;
		if(sy1 >= nHeight)
			sy1 = nHeight-1;
		for (x = x0; x <= x1; x++)
		{
			w1 = 0, n1 = 0;
			sx0 = x-rw;
			if(sx0 < 0)
				sx0=0;
			sx1 = x+rw;
			if(sx1 >= nWidth)
				sx1 = nWidth-1;
			n3 = (sx1-sx0+1)*(sy1-sy0+1);
			w3 = pnSum[(sy1+1)*nW+(sx1+1)] - pnSum[sy0*nW+(sx1+1)] - pnSum[(sy1+1)*nW+sx0] + pnSum[sy0*nW+sx0];

			xx = yy + x;
			if (x-1 >= 0)			n3--, w3 -= pbyGray[xx-1], n1++, w1 += pbyGray[xx-1];
			if (x+1 < nWidth)		n3--, w3 -= pbyGray[xx+1], n1++, w1 += pbyGray[xx+1];
			if (y-1 >= 0)			n3--, w3 -= pbyGray[xx-nWidth], n1++, w1 += pbyGray[xx-nWidth];
			if (y+1 < nHeight )		n3--, w3 -= pbyGray[xx+nWidth], n1++, w1 += pbyGray[xx+nWidth];

			n3--, w3 -= pbyGray[xx];
			n1++, w1 += pbyGray[xx];
			w1 /= n1;
			w3 /= n3;
			lpOut[xx] = w3-w1;
		}
	}
}

////////////////////////////////////////////////////////////////////////////
void glo_paint_stroke(BYTE* pbImg, int nW, int nFirst, int* pnStroke, BYTE nCol)
{
	int k, x, y;
	k = nFirst;
	do 
	{
		x = k % nW;
		y = k / nW;
		pbImg[y*nW+x] = nCol;
	} while( (k = pnStroke[k] ) != -1 );
}

void glo_sort_y_rects(RECT*pRt, int nNum)
{
	int i, j;
	RECT rtTemp;

	for(i = 0; i < nNum-1; i++)
	{
		for(j = i+1; j < nNum; j++)
		{
			if( pRt[i].top > pRt[j].top )
			{
				rtTemp = pRt[i];
				pRt[i] = pRt[j];
				pRt[j] = rtTemp;
			}
		}
	}
}

void glo_sort_x_rects(RECT*pRt, int nNum)
{
	int i, j;
	RECT rtTemp;

	for(i = 0; i < nNum-1; i++)
	{
		for(j = i+1; j < nNum; j++)
		{
			if( pRt[i].left > pRt[j].left )
			{
				rtTemp = pRt[i];
				pRt[i] = pRt[j];
				pRt[j] = rtTemp;
			}
		}
	}
}

void glo_sort_y_segs(SEGMENT *pSegs, int nNum)
{
	int i, j;
	SEGMENT sgTemp;

	for(i = 0; i < nNum-1; i++)
	{
		for(j = i+1; j < nNum; j++)
		{
			if( pSegs[i].rtRegion.top > pSegs[j].rtRegion.top )
			{
				sgTemp.rtRegion = pSegs[i].rtRegion;
				pSegs[i].rtRegion = pSegs[j].rtRegion;
				pSegs[j].rtRegion = sgTemp.rtRegion;
			}
		}
	}
}

void glo_sort_yx_segs(SEGMENT *pSegs, int nNum)
{
	int i, j;
	SEGMENT sgTemp;

	for (i = 0; i < nNum - 1; i++)
	{
		for (j = i + 1; j < nNum; j++)
		{
			if (pSegs[j].rtRegion.left < pSegs[i].rtRegion.left &&
				pSegs[j].rtRegion.top < pSegs[i].rtRegion.top + getRectHeight(pSegs[i].rtRegion)/2 &&
				pSegs[j].rtRegion.bottom >= pSegs[i].rtRegion.top)
			{
				memcpy(&sgTemp, &pSegs[i], sizeof(SEGMENT));
				memcpy(&pSegs[i], &pSegs[j], sizeof(SEGMENT));
				memcpy(&pSegs[j], &sgTemp, sizeof(SEGMENT));
				//sgTemp.rtRegion = pSegs[i].rtRegion;
				//pSegs[i].rtRegion = pSegs[j].rtRegion;
				//pSegs[j].rtRegion = sgTemp.rtRegion;
			}
		}
	}
}

void glo_sort_x_segs(SEGMENT *pSegs, int nNum)
{
	int i, j;
	SEGMENT sgTemp;

	for(i = 0; i < nNum-1; i++)
	{
		for(j = i+1; j < nNum; j++)
		{
			if( pSegs[i].rtRegion.left > pSegs[j].rtRegion.left )
			{
				sgTemp.rtRegion = pSegs[i].rtRegion;
				pSegs[i].rtRegion = pSegs[j].rtRegion;
				pSegs[j].rtRegion = sgTemp.rtRegion;
			}
		}
	}
}

int glo_segment_by_hist(BYTE* pbyImg, int nW, int nH, int nLetterW, int nLetterH, SEGMENT* &pSegAry)
{
	int nSegNum = 0;
	int *pnHist = NULL;
	int nX, nY, n, m, i, j;
	RECT*pRtTemp;
	int  nLong, nShort;
	int  *pnLongStart, *pnLongEnd;
	int  *pnShortStart, *pnShortEnd;
	int point_pos;
	int nMin, nMax;

	pnHist = new int[nW];
	pnLongStart = new int[nW];
	pnLongEnd = new int[nW];
	pnShortStart = new int[nW];
	pnShortEnd = new int[nW];

	pRtTemp = new RECT[nW];

	memset(pnHist, 0, nW*sizeof(int));
	for(nY = 0; nY < nH; nY++)
	{
		point_pos = nY*nW;
		for(nX = 0; nX < nW;  nX++)
		{
			if( pbyImg[point_pos+nX] != 255 )
				pnHist[nX]++;
		}
	}

	nLong	 = 1;
	pnLongStart[0]	= 0;
	pnLongEnd[0]	= nW-1;

	nMin = 0/*nLetterH/6*/;//0
	nMax = 4;//nLetterH/4;//5, //3
	for(n = nMin; n < nMax; n++)
	{
		nShort = 0;
		for(m = 0; m < nLong; m++)
		{
			j = pnLongStart[m];
			if( pnHist[j] > n )
				pnShortStart[nShort] = j;

			for(j = pnLongStart[m]+1; j <= pnLongEnd[m]; j++)
			{
				if( pnHist[j-1] <= n && pnHist[j] >  n )
					pnShortStart[nShort] = j;
				if( pnHist[j-1] >  n && pnHist[j] <= n )
					pnShortEnd[nShort++] = j-1;
			}
			j = pnLongEnd[m];
			if( pnHist[j] > n )
				pnShortEnd[nShort++] = j;
		}

		nLong = 0;
		for(i = 0; i < nShort; i++)
		{
			if( pnShortEnd[i] - pnShortStart[i] + 1 < nLetterW + 3 )
			{
				pRtTemp[nSegNum].left = pnShortStart[i];
				pRtTemp[nSegNum].right = pnShortEnd[i];
				nSegNum++;
			}
			else
			{
				pnLongStart[nLong] = pnShortStart[i];
				pnLongEnd[nLong] = pnShortEnd[i];
				nLong++;
			}
		}
	}

	memset(pnHist, 0, nW*sizeof(int));
	for(i = 0; i < nLong; i++)
	{
		long h0, h1;
		glo_get_top_bottom(pbyImg, nW, nH, pnLongStart[i], pnLongEnd[i], h0, h1);
		if( h0 > h1-5 )
			continue;
		if( h0+2 >= nH || h1-2 < 0 )
			continue;

		for(nY = h0+1; nY <= h1-2; nY++)
		{
			point_pos = nY*nW;
			for(nX = pnLongStart[i]; nX <= pnLongEnd[i];  nX++)
			{
				if( pbyImg[point_pos+nX] != 255 )
					pnHist[nX]++;
			}
		}
		nShort	= 0;
		j = pnLongStart[i];
		if( pnHist[j] > 0 )
			pnShortStart[nShort] = j;
		for(j = pnLongStart[i]+1; j <= pnLongEnd[i]; j++)
		{
			if( pnHist[j-1] <= 0 && pnHist[j] >  0 )
				pnShortStart[nShort] = j;
			if( pnHist[j-1] >  0 && pnHist[j] <= 0 )
				pnShortEnd[nShort++] = j-1;
		}
		j = pnLongEnd[i];
		if(pnHist[j] > 0) pnShortEnd[nShort++] = j;

		if (!nShort)
		{
			pRtTemp[nSegNum].left = pnLongStart[j];
			pRtTemp[nSegNum].right = pnLongEnd[j];
			nSegNum++;		
		}

		for(j = 0; j < nShort; j++)
		{
			pRtTemp[nSegNum].left = pnShortStart[j];
			pRtTemp[nSegNum].right = pnShortEnd[j];

			nSegNum++;
		}
	}

	if (!pSegAry)
		pSegAry = new SEGMENT[nSegNum];

	for(i = 0; i < nSegNum; i++)
	{
		long t = pRtTemp[i].top;
		long b = pRtTemp[i].bottom;
		glo_get_top_bottom(pbyImg, nW, nH, pRtTemp[i].left, pRtTemp[i].right, t,b);
		pRtTemp[i].top = t;
		pRtTemp[i].bottom = b;

		pSegAry[i].rtRegion = pRtTemp[i];
	}

	delete[] pnHist;
	delete[] pnLongStart;
	delete[] pnLongEnd;
	delete[] pnShortStart;
	delete[] pnShortEnd;

	return nSegNum;
}

void glo_get_top_bottom(BYTE *pbyImg, int nW, int nH, long x0, long x1, long &y0, long &y1)
{
	int nX, nY;
	int point_pos;
	for(nY = 0; nY < nH; nY++)
	{
		point_pos = nY*nW;
		for(nX = x0; nX <= x1; nX++)
		{
			if( pbyImg[point_pos+nX] != 255 )
			{
				y0 = nY;
				nY = nH;
				break;
			}
		}
	}
	for(nY = nH-1; nY > 0; nY--)
	{
		point_pos = nY*nW;
		for(nX = x0; nX <= x1; nX++)
		{
			if( pbyImg[point_pos+nX] != 255 )
			{
				y1 = nY;
				nY = 0;
				break;
			}
		}
	}

	if( y1 < y0 )
		y1 = y0;
}

//
//PIX* glo_Byte2Pix(BYTE* pbyImg, int nW, int nH, int nC)
//{
//	int i = 0;
//	PIX* pixs = pixCreate(nW, nH, 32);
//	BYTE cc[3];
//
//	for (int y = 0; y < nH; y++) {
//		int pos = y * nW;
//		for (int x = 0; x < nW; x++) {
//
//			for (i = 0; i < nC; i++)
//				cc[i] = pbyImg[pos*nC + x*nC + i];
//
//			if (nC == 1){
//				cc[1] = cc[0];
//				cc[2] = cc[0];
//			}
//
//			l_uint32 v = (cc[2] << 24) + (cc[1] << 16) + (cc[0] << 8) + 0;
//			pixs->data[pos + x] = v;
//		}
//	}
//
//	return pixs;
//}
//
//void glo_Pix2Byte(PIX* pix, BYTE* pbyImg, int nC)
//{
//	if (!pix)
//		return;
//	
//	BYTE cc[3];
//	for (int y = 0; y < (int)pix->h; y++)
//	{
//		int pos = y*pix->w;
//		for (int x = 0; x < (int)pix->w; x++)
//		{
//			cc[0] = (BYTE)(pix->data[pos + x] >> 24);
//			cc[1] = (BYTE)(pix->data[pos + x] >> 16);
//			cc[2] = (BYTE)(pix->data[pos + x] >> 8);
//		
//
//			for (int i = 0; i < nC; i++)
//				pbyImg[pos*nC + x*nC + i] = cc[nC - (i + 1)];
//		}
//	}
//}

void glo_Resize(BYTE *pSrc, int nSrcW, int nSrcH, int nC, BYTE *pDst, int nDstW, int nDstH)
{
	//PIX *pix = glo_Byte2Pix(pSrc, nSrcW, nSrcH, nC);

	//float fscalex = (float)((nDstW) / (float)nSrcW);
	//float fscaley = (float)((nDstH) / (float)nSrcH);

	////PIX *spix = pixScaleSmooth(pix, fscalex, fscaley);
	//PIX *spix = pixScale(pix, fscalex, fscaley);

	//glo_Pix2Byte(spix, pDst, nC);

	//pixDestroy(&pix);
	//pixDestroy(&spix);
	im_Resize(pSrc, nSrcW, nSrcH, nC, pDst, nDstW, nDstH);
}


/////////////
//get angle
////////////


//double glo_get_angle_image(BYTE* pbyImg, int w, int h)
//{
//	double fAng = 0.0;
//	int i, j, k, hh, *pHighHis, nNum, nId, nMaxH, ww;
//
//	//im_AdaptiveThreshold(pbyImg, g_pdata_t->g_pbySpec, w,  h, w / 16, 0.16f);
//	im_binary_windows(pbyImg, g_pdata_t->g_pbySpec, w, h, 5);
//
//#ifdef _LOG_VIEW
//	if (img) cvReleaseImage(&img);
//	img = getIplImage(g_pdata_t->g_pbySpec, w, h, 1);
//	//showIplImage(img);
//	cvReleaseImage(&img);
//#endif
//
//	STROKE* pStroke = new STROKE[MAX_STROKE_NUM];
//	bool* bOver = new bool[MAX_STROKE_NUM];
//	int nSegs = 0;
//	RECT rtRegion;
//	rtRegion.left = rtRegion.top = 0;
//	rtRegion.right = w - 1;
//	rtRegion.bottom = h - 1;
//	int nStroke = glo_detect_strokes(g_pdata_t->g_pbySpec, g_pdata_t->g_pbySpec, g_pdata_t->g_pnStroke, pStroke, rtRegion, w, h, MAX_STROKE_NUM, 255, 5, 5, 5, false);
//
//	int CharW = max(w, h) / 35;
//	int CharH = CharW * 2;
//	int nSW, nSH;// , nSW1, nSH1;
//
//	int nMinW = 5; //10 //byJJH20180601
//	int nMinH = 5; //10 //byJJH20180601
//
//	j = 0;
//	for (i = 0; i < nStroke; i++)
//	{
//		nSW = getRectWidth(pStroke[i].rtRegion);
//		nSH = getRectHeight(pStroke[i].rtRegion);
//
//		//if (nSW > CharW || nSH > CharH || (nSW < 10 && nSH < 10) || pStroke[i].nPointNum > CharW*CharH / 2)
//		if (nSW > CharW*2 || nSH > CharH*2 || (nSW < nMinW && nSH < nMinH) || pStroke[i].nPointNum > CharW*CharH / 2) //byJJH20180601
//			continue;
//		
//		pStroke[j++] = pStroke[i];
//	}
//	nStroke = j;
//
//	pHighHis = new int[h + 1];
//	memset(pHighHis, 0, h * sizeof(int));
//
//	if (nStroke < 20)
//	{
//		delete[]pHighHis;
//		if (pStroke) delete[] pStroke;
//		if (bOver) delete[] bOver;
//		return 0.0;
//	}
//
//#ifdef _LOG_VIEW
//	if (img) cvReleaseImage(&img);
//	img = getIplImage(g_pdata_t->g_pbySpec, w, h, 1);
//	for (i = 0; i < nStroke; i++)
//	{
//		cvDrawRect(img, cvPoint(pStroke[i].rtRegion.left, pStroke[i].rtRegion.top),
//			cvPoint(pStroke[i].rtRegion.right, pStroke[i].rtRegion.bottom), cvScalarAll(64), 1);
//	}
//
//	//showIplImage(img);
//	cvReleaseImage(&img);
//#endif
//
//	for (i = 0; i<nStroke; i++) {
//		//pRsn->bUse = 1;
//		bOver[i] = false;
//		nSW = getRectWidth(pStroke[i].rtRegion);
//		nSH = getRectHeight(pStroke[i].rtRegion);
//		if (nSH < nSW) continue;
//		if (nSH<nMinH && nSW<nMinW)continue; //nMinH : 10 //byJJH20180601
//		pHighHis[nSH]++;
//	}
//	nId = -1; nMaxH = 0;
//	for (i = 0; i<h; i++) {
//		if (pHighHis[i]>nMaxH) {
//			nMaxH = pHighHis[i];
//			nId = i;
//		}
//	}
//	if (nId<10 || nMaxH<10)
//	{
//		delete[]pHighHis;
//		if (pStroke) delete[] pStroke;
//		if (bOver) delete[] bOver;
//		return 0.0;
//	}
//
//	if (nId == -1) {
//		delete[] pHighHis; pHighHis = NULL;
//		if (pStroke) delete[] pStroke;
//		if (bOver) delete[] bOver;
//		return fAng;//FALSE;
//	}
//
//	int nTmin, nTmax;
//
//	////// ²ÚËËÌ© ¾×´Ý,¾×ºÏ °éÂ×±¨ ///////
//	nTmin = (int)((double)nId*0.5);
//	nTmax = (int)((double)nId*1.5);
//
//	for (i = 0; i<nStroke; i++) {
//		nSW = getRectWidth(pStroke[i].rtRegion);
//		nSH = getRectHeight(pStroke[i].rtRegion);
//	
//		if (nSH<nSW) {
//			//pRsn->bUse = 0;
//			bOver[i] = true;
//			continue;
//		}
//
//		if (nSH<nTmin || nSH>nTmax) {
//			//pRsn->bUse = 0;
//			bOver[i] = true;
//			continue;
//		}
//	}
//
//	j = 0;
//	for (i = 0; i<nStroke; i++) {
//		if (bOver[i]) continue;
//		pStroke[j++] = pStroke[i];
//	}
//	nStroke = j;
//
//	delete[] pHighHis; pHighHis = NULL;
//
//
//	//// ¹¦µá¿Í²ÚËËÌ® ¹¦µá¿Í±¶ºã °éÂ×±¨ //////
//	int nSubBlockH, nBlockNum;
//
//	nSubBlockH = nId * 20;
//
//	nBlockNum = (int)(h / nSubBlockH);
//	if (nBlockNum == 0)nBlockNum = 1;
//	RECT cSubAllRt[50];
//
//	for (i = 0; i<nBlockNum; i++) {
//		cSubAllRt[i].left = 0;
//		cSubAllRt[i].right = w;
//		cSubAllRt[i].top = i*nSubBlockH;
//		if (i == (nBlockNum - 1))
//			cSubAllRt[i].bottom = h;
//		else
//			cSubAllRt[i].bottom = (i + 1)*nSubBlockH;
//	}
//
//
//	////// °¢´ª ÃÅº÷ÀË°ûµ½ °éÂ×±¨ ///////
//
//	int AngleHis[50][2][90], nBlkId1, nBlkId2;
//	for (i = 0; i<50; i++) {
//		for (j = 0; j<2; j++) {
//			for (k = 0; k<90; k++) {
//				AngleHis[i][j][k] = 0;
//			}
//		}
//	}
//
//	for (i = 0; i<nStroke; i++) {
//		nBlkId1 = GetBlkId(pStroke[i].rtRegion, cSubAllRt, nBlockNum);
//		if (nBlkId1 == -1)continue;
//		for (j = 0; j<nStroke; j++) {
//			if (i == j)continue;
//			nBlkId2 = GetBlkId(pStroke[j].rtRegion, cSubAllRt, nBlockNum);
//			if (nBlkId2 == -1)continue;
//			if (nBlkId1 != nBlkId2)continue;
//			double ang1, ang2;
//			GetLUAngle(pStroke[i].rtRegion, pStroke[j].rtRegion, ang1, ang2);
//			int a1 = (int)ang1, a2 = (int)ang2;
//			if (abs(a1)<45)
//				AngleHis[nBlkId1][0][45 + a1]++;
//			if (abs(a2)<45)
//				AngleHis[nBlkId1][1][45 + a2]++;
//
//		}
//	}
//	//// °º¾¹ °¢´ª °éÂ×±¨ ////////////
//	int n1, n2, n3, nMax;
//	nMax = 0;
//	for (i = 0; i<nBlockNum; i++) {
//		for (j = 0; j<2; j++) {
//			for (k = 0; k<90; k++) {
//				if (AngleHis[i][j][k]>nMax) {
//					nMax = AngleHis[i][j][k];
//					n1 = i; n2 = j; n3 = k;
//				}
//			}
//		}
//	}
//	n3 = n3 - 45;
//
//	///// °¢´ª n3Ë¾ ¾¡¾¥Â×²÷´ç ¶®Ë¦´ô 4°¢Âô ÊÐ±¨ /////
//	int		nSubRtNum = 0;
//	double ang1;
//	ang1 = n3;
//
//	typedef struct tagCouple {
//		RECT cRt1;
//		RECT cRt2;
//		BYTE	op;
//		double	ang;
//	}Couple;
//
//	Couple *pCouple = new Couple[nStroke*nStroke];
//
//	for (i = 0; i<nStroke; i++) {
//		nBlkId1 = GetBlkId(pStroke[i].rtRegion, cSubAllRt, nBlockNum);
//		if (nBlkId1 == -1)continue;
//		for (j = 0; j<nStroke; j++) {
//			if (i == j)continue;
//			nBlkId2 = GetBlkId(pStroke[j].rtRegion, cSubAllRt, nBlockNum);
//			if (nBlkId2 == -1)continue;
//			if (nBlkId1 != nBlkId2)continue;
//			double ang1, ang2;
//			GetLUAngle(pStroke[i].rtRegion, pStroke[j].rtRegion, ang1, ang2);
//			int a1 = (int)ang1, a2 = (int)ang2;
//			if (n2 == 0 && abs(a1)<45) {
//				if (n3 == a1) {
//					pCouple[nSubRtNum].cRt1 = pStroke[i].rtRegion;
//					pCouple[nSubRtNum].cRt2 = pStroke[j].rtRegion;
//					pCouple[nSubRtNum].ang = ang1;
//					nSubRtNum++;
//				}
//			}
//			else if (n2 == 1 && abs(a1)<45) {
//				if (n3 == a2) {
//					pCouple[nSubRtNum].cRt1 = pStroke[i].rtRegion;
//					pCouple[nSubRtNum].cRt2 = pStroke[j].rtRegion;
//					pCouple[nSubRtNum].ang = ang2;
//					nSubRtNum++;
//				}
//			}
//		}
//	}
//
//	if (nSubRtNum == 0) {
//		fAng = ang1;
//		delete[] pCouple; pCouple = NULL;
//		if (fabs(fAng) > 5) fAng = 0;
//
//		if (pStroke) delete[] pStroke;
//		if (bOver) delete[] bOver;
//
//		return fAng;
//	}
//
//
//	double ag;
//	int newId;
//	int newAng[200];
//	memset(newAng, 0, 200 * sizeof(int));
//	for (i = 0; i<nSubRtNum; i++) {
//		if (pCouple[i].ang>n3 - 0.99 && pCouple[i].ang<n3 + 0.99) {
//			ag = pCouple[i].ang;
//			newId = (int)(100.0*(ag - n3));
//			if (newId == 0)continue;
//			newAng[100 + newId]++;
//		}
//	}
//	//int max1,max2,max3;
//	int maxValue = 0;
//	newId = 0;
//	for (i = 0; i<200; i++) {
//		if (newAng[i]>maxValue) {
//			maxValue = newAng[i];
//			newId = i;
//		}
//	}
//	fAng = n3 - (100 - newId)*0.01;
//
//	if (fabs(fAng) > 45) fAng = 0;
//
//	delete[] pCouple; pCouple = NULL;
//	if (pStroke) delete[] pStroke;
//	if (bOver) delete[] bOver;
//
//	return fAng;
//}

int GetBlkId(RECT cRt, RECT cSubAllRt[50], int nNum)
{
	int i, nId = -1;
	RECT Rt;
	for (i = 0; i<nNum; i++) {
		Rt = cSubAllRt[i];
		if (cRt.left >= Rt.left && cRt.right <= Rt.right &&
			cRt.top >= Rt.top && cRt.bottom <= Rt.bottom) {
			nId = i; break;
		}
	}
	return nId;
}

void GetLUAngle(RECT cRt1, RECT cRt2, double& ang1, double& ang2)
{
	IPOINT tPtL, tPtR;
	IPOINT bPtL, bPtR;
	int	tw, th, bw, bh;

	double a1, a2;


	tPtL.x = (cRt1.left + cRt1.right) / 2;	tPtL.y = cRt1.top;
	tPtR.x = (cRt2.left + cRt2.right) / 2; tPtR.y = cRt2.top;

	bPtL.x = (cRt1.left + cRt1.right) / 2; bPtL.y = cRt1.bottom;
	bPtR.x = (cRt2.left + cRt2.right) / 2; bPtR.y = cRt2.bottom;

	th = tPtR.y - tPtL.y; tw = tPtR.x - tPtL.x;
	bh = bPtR.y - bPtL.y; bw = bPtR.x - bPtL.x;

	a1 = atan2((double)th, tw);
	a2 = atan2((double)bh, (double)bw);

	a1 *= 57.2957;
	a2 *= 57.2957;

	if (tw == 0)a1 = 90.0;
	if (bw == 0)a2 = 90.0;

	ang1 = a1; ang2 = a2;
	if (ang1>90)ang1 = -1 * (180 - ang1);
	else if (ang1<-90)ang1 = 180 + ang1;
	if (ang2>90)ang2 = -1 * (180 - ang2);
	else if (ang2<-90)ang2 = 180 + ang2;
}

int glo_get_image_quality(BYTE* pbyImg, int nW, int nH, RECT rtRoi, RECT rtFace, RECT rtQR)
{
	RECT rtMain = rtRoi;
	rtMain.left = rtMain.left + getRectWidth(rtFace) / 2;
	rtMain.top = rtFace.top + 20;
	rtMain.bottom = rtFace.bottom + 20;

	int nSW = getRectWidth(rtMain);
	int nSH = getRectHeight(rtMain);
	im_Crop(pbyImg, nW, nH, g_pdata_t->g_pbySpec, rtMain.left, rtMain.top, nSW, nSH);
	//im_AdaptiveThreshold(pbyImg, g_pdata_t->g_pbySpec, w,  h, w / 16, 0.16f);
	im_binary_windows(g_pdata_t->g_pbySpec, g_pdata_t->g_pbyTemp0, nSW, nSH, 8);
	memcpy(g_pdata_t->g_pbySpec, g_pdata_t->g_pbyTemp0, nSW*nSH);

	RECT rtRegion;
	rtRegion.left = rtRegion.top = 0;
	rtRegion.right = nSW - 1;
	rtRegion.bottom = nSH - 1;

	STROKE* pStroke = new STROKE[MAX_STROKE_NUM];
	bool* bOver = new bool[MAX_STROKE_NUM];
	int nSegs = 0, i = 0;
	int nStroke = glo_detect_strokes(g_pdata_t->g_pbySpec, g_pdata_t->g_pbySpec, g_pdata_t->g_pnStroke, pStroke, rtRegion, nSW, nSH, MAX_STROKE_NUM, 255, 2, 5, 5, false);

	int* pnHist1 = new int[nSH];
	int* pnHist2 = new int[nSH];
	memset(pnHist1, 0, nSH * sizeof(int));
	memset(pnHist2, 0, nSH * sizeof(int));

	int nTotal = 0;
	for (i = 0; i < nStroke; i++)
	{
		int nCW = getRectWidth(pStroke[i].rtRegion);
		int nCH = getRectHeight(pStroke[i].rtRegion);
		if (isIncludeRect(pStroke[i].rtRegion, rtFace) || isIncludeRect(pStroke[i].rtRegion, rtQR))
			continue;
		if (nCW > nSW / 4 || nCH > nSH / 4) continue;


		nTotal++;
		if (nCH >= 150) nCH = 149;
		if (nCW > nCH) continue;
		pnHist1[nCH]++;
	}

	int minTh = 5;
	memcpy(pnHist2, pnHist1, sizeof(int) * nSH);
	memset(pnHist1, 0, sizeof(int)*nSH);
	for (i = minTh; i < nSH - minTh; i++)
		pnHist1[i] = (pnHist2[i - 3] + pnHist2[i - 2] + pnHist2[i - 1] + pnHist2[i] + pnHist2[i + 1] + pnHist2[i + 2] + pnHist2[i + 3]);

	int nCharHeight = 0;
	int m = 0;
	for (i = minTh; i < nSH - minTh; i++)
	{
		if (pnHist1[i] > m)
		{
			m = pnHist1[i];
			nCharHeight = i;
		}
	}

	int nRet = m * 100 / nTotal;

	if (pStroke) delete[] pStroke;
	if (bOver) delete[] bOver;
	if (pnHist1) delete[] pnHist1;
	if (pnHist2) delete[] pnHist2;

	return nRet;
}

int glo_get_image_similarity(BYTE* pbyPre, int npW, int npH, BYTE* pbyCur, int ncW, int ncH)
{
	int nRet = 0;
	if (npW != ncW || npH != ncH)
		return 0;

	int nStep = 5, i = 0;
	int *pnT = new int[nStep*nStep];
	for (i = 0; i < nStep*nStep; i++)
		pnT[i] = 1;

	BYTE* pbyTemp0 = new BYTE[npW*npH];
	BYTE* pbyTemp1 = new BYTE[npW*npH];

	if (pbyTemp0 == NULL || pbyTemp1 == NULL)
		return 0;

	im_filter(pbyPre, pbyTemp0, npW, npH, pnT, nStep, nStep*nStep, 0);
	im_filter(pbyCur, pbyTemp1, npW, npH, pnT, nStep, nStep*nStep, 0);

	int nMatch = 0;
	int nCount = 0;
	for (i = nStep/2; i < npW*npH; i+=nStep)
	{
		nCount++;
		if (abs(pbyTemp0[i] - pbyTemp1[i]) < 10)
			nMatch++;
	}

	delete[] pbyTemp0;
	delete[] pbyTemp1;

	nRet = nMatch * 100 / nCount;
	return nRet;
}

/////////////////////////////////////
long getCurTime()
{
	clock_t start = clock();
	return (long)start;
}

double getElaspedTime(long start)
{
	double duration;
	clock_t finish = clock();
	duration = (double)(finish - start) / CLOCKS_PER_SEC;
	return duration;
}


///////////////////////////////////////
//rotation
///////////////////////////
void glo_RotateRight_Img(BYTE *pImg, BYTE* pOut, int w, int h, int c)
{
	int i, j, k;
	if (pImg == NULL) return;
	for (i = 0; i<h; i++) 
		for (j = 0; j<w; j++)
			for (k = 0; k < c; k++)
			{
				pOut[c*h*j + c*(h - 1 - i) + k] = pImg[c*w*i + c*j + k];
			}
}

void glo_RotateLeft_Img(BYTE *pImg, BYTE* pOut, int w, int h, int c)
{
	int i, j, k;
	if (pImg == NULL) return;
	for (i = 0; i<h; i++)
		for (j = 0; j<w; j++)
			for (k = 0; k < c; k++)
				pOut[c*(h*(w - 1 - j) + i) + k] = pImg[c*(w*i + j) + k];
}

void glo_Rotate180_Img(BYTE *pImg, BYTE* pOut, int w, int h, int c)
{
	int i, j, k;
	if (pImg == NULL) return;
	for (i = 0; i<h; i++)
		for (j = 0; j<w; j++)
			for (k = 0; k < c; k++)
				pOut[c*(w*(h - 1 - i) + (w - 1 - j)) + k] = pImg[c*(w*i + j) + k];
}

int glo_get_char_height(SEGMENT* pSegs, int nSegs, int minTh)
{
	minTh = max(15, minTh);
	float hist[150], hist1[150];
	memset(hist, 0, sizeof(float) * 150);
	int i;
	for (i = 0; i < nSegs; i++)
	{
		int n = getRectHeight(pSegs[i].rtRegion);
		int ww = getRectWidth(pSegs[i].rtRegion);
		if (n >= 150) n = 149;
		//if (ww > n) continue;
		hist[n] ++;
	}
	memcpy(hist1, hist, sizeof(int) * 150);
	for (i = minTh; i<147; i++)
		hist[i] = (hist1[i - 3] + hist1[i - 2] + hist1[i - 1] + hist1[i] + hist1[i + 1] + hist1[i + 2] + hist1[i + 3]) / 7;
	int nCharHeight = 0;
	float m = 0;
	for (i = minTh; i<149; i++)
		if (hist[i] > m)
		{
			m = hist[i];
			nCharHeight = i;
		}
	return nCharHeight;
}





