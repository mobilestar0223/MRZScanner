// Rotation.cpp: implementation of the CRotation class.
//
//////////////////////////////////////////////////////////////////////

#include "StdAfx.h"
#include "TRunProc.h"
#include "ImageBase.h"
#include "Rotation.h"
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

CRotation::CRotation()
{

}

CRotation::~CRotation()
{

}

BYTE* CRotation::RotateDib(BYTE *pDib, double fAng,int nBackGround/*=BACKGROUND_WHITE*/,int bKeepSize/*=TRUE*/)
{
	if(pDib==NULL) return NULL;
	BYTE* pNewDib = NULL;
	LPBITMAPINFOHEADER pBIH = (LPBITMAPINFOHEADER)pDib;
	if(pBIH->biBitCount == 24)
	{
		RGBQUAD clrBack;
		if(nBackGround == BACKGROUND_BLACK)
			clrBack.rgbBlue = clrBack.rgbGreen = clrBack.rgbRed = clrBack.rgbReserved = 0;
		else if(nBackGround == BACKGROUND_CALC)
		{
			int w,h;
			CImageBase::GetWidthHeight(pDib,w,h);
			clrBack = CImageBase::GetBkClrInRect24Dib(pDib,CRect(0,0,w,h));
		}
		else
		{
			clrBack.rgbBlue = clrBack.rgbGreen = clrBack.rgbRed = 255;
			clrBack.rgbReserved = 0;
		}
		pNewDib = Rotate_24Dib(pDib,fAng,&clrBack,bKeepSize);
	}
	else if(pBIH->biBitCount == 8)
	{
		BYTE grayBack;
		if(nBackGround == BACKGROUND_BLACK)
			grayBack = 0;
		else if(nBackGround == BACKGROUND_CALC)
		{
			int w,h;
			CImageBase::GetWidthHeight(pDib,w,h);
			grayBack = CImageBase::GetBkClrInRectGrayDib(pDib,CRect(0,0,w,h));
		}
		else
			grayBack = 255;
		pNewDib = Rotate_GrayDib(pDib,fAng, grayBack, bKeepSize);
	}
	else if(pBIH->biBitCount == 1)
	{
		pNewDib = Rotate_BinDib(pDib, fAng, nBackGround, bKeepSize);
	}
	else
		return NULL;

	return pNewDib;
}
BYTE* CRotation::Rotate_24Dib(BYTE *pDib, double fAng,RGBQUAD* ColorBackGround/* = NULL*/,int bKeepSize/*=TRUE*/)
{
	if(pDib==NULL) return NULL;
	LPBITMAPINFOHEADER pBIH = (LPBITMAPINFOHEADER)pDib;
	if(pBIH->biBitCount != 24) return NULL;
	int headsize = sizeof(BITMAPINFOHEADER);
	BYTE* pBits = pDib + headsize;
	int w = pBIH->biWidth;
	int h = pBIH->biHeight;
	int i;
	BYTE *pNewDib,*pNewBits;
	
	int dwEffWidth = ((((24 * w) + 31) / 32) * 4); 
	if (fabs(fAng)<0.05)
	{
		pNewDib = new BYTE[headsize+dwEffWidth*h];
		memcpy(pNewDib,pDib,headsize+dwEffWidth*h);
		return pNewDib;
	}
	RGBQUAD ClrBack;
	if(ColorBackGround==NULL)
	{
		ClrBack.rgbBlue     = 255;
		ClrBack.rgbGreen    = 255;
		ClrBack.rgbRed      = 255;
		ClrBack.rgbReserved = 0;
	}
	else
	{
		ClrBack.rgbBlue     = ColorBackGround->rgbBlue;
		ClrBack.rgbGreen    = ColorBackGround->rgbGreen;
		ClrBack.rgbRed      = ColorBackGround->rgbRed;
		ClrBack.rgbReserved = ColorBackGround->rgbReserved;
	}
	
	double ang = -fAng*acos(0.0f)/90.0f;		//convert angle to radians and invert (positive angle performs clockwise rotation)
	float cos_angle = (float) cos(ang);			//these two are needed later (to rotate)
	float sin_angle = (float) sin(ang);
	
	double pX[4]={-0.5f,w-0.5f,-0.5f,w-0.5f};
	double pY[4]={-0.5f,-0.5f,h-0.5f,h-0.5f};
	
	double newpX[4]={0};
	double newpY[4]={0};
	if (bKeepSize){
		for (i=0; i<4; i++) {
			newpX[i] = pX[i];
			newpY[i] = pY[i];
		}
	} 
	else{
		for (i=0; i<4; i++) {
				newpX[i] = (pX[i]*cos_angle - pY[i]*sin_angle);
				newpY[i] = (pY[i]*cos_angle + pX[i]*sin_angle);
		}
	}

    //(read new dimensions from location of corners)
	float minx = (float) min(min(newpX[0],newpX[1]),min(newpX[2],newpX[3]));
	float miny = (float) min(min(newpY[0],newpY[1]),min(newpY[2],newpY[3]));
	float maxx = (float) max(max(newpX[0],newpX[1]),max(newpX[2],newpX[3]));
	float maxy = (float) max(max(newpY[0],newpY[1]),max(newpY[2],newpY[3]));
	
	int newWidth = (int) floor(maxx-minx+0.5f);
	int newHeight= (int) floor(maxy-miny+0.5f);
	int newEffWidth = ((((24 * newWidth) + 31) / 32) * 4); 

	float ssx=((maxx+minx)- ((float) newWidth-1))/2.0f;   //start for x
	float ssy=((maxy+miny)- ((float) newHeight-1))/2.0f;  //start for y

	float newxcenteroffset = 0.5f * newWidth;
	float newycenteroffset = 0.5f * newHeight;
	if (bKeepSize){
		ssx -= 0.5f * w;
		ssy -= 0.5f * h;
	}

	pNewDib = new BYTE[headsize+newEffWidth*newHeight];
	pNewBits = pNewDib+headsize;
	memcpy(pNewDib,pDib,headsize);
	LPBITMAPINFOHEADER pNewBIH = (LPBITMAPINFOHEADER) pNewDib;
	pNewBIH->biHeight = newHeight;
	pNewBIH->biWidth = newWidth;
	memset(pNewBits,0,newEffWidth*newHeight);

	float x,y;              //destination location (float, with proper offset)
	float origx, origy;
	int nearx,neary;        //origin location
	int destx, desty;       //destination location
	double t1,t2,a,b,c,d;
	
	y=ssy;         
    
	for (desty=0; desty<newHeight; desty++) {
		x=ssx;
		for (destx=0; destx<newWidth; destx++) {

			origx=(cos_angle*x+sin_angle*y);
			origy=(cos_angle*y-sin_angle*x);

			if (bKeepSize){
				origx += newxcenteroffset;
				origy += newycenteroffset;
			}

			nearx = (int)origx; if (nearx<0) nearx--;
			neary = (int)origy; if (neary<0) neary--;

			t1 = origx - nearx;
			t2 = origy - neary;
			
			d= t1*t2;
			b=t1-d;
			c=t2-d;
			a=1-t1-c;

			if (nearx>0 && nearx<=w-1 && neary>0 && neary<=h-1)
			{
				BYTE *a1,*b1,*c1,*d1;
				if (nearx == w-1){
					if (neary == h-1)
						a1 = b1= c1= d1 = pBits+neary*dwEffWidth+3*nearx;
					else{
						a1 = b1 = pBits+neary*dwEffWidth+3*nearx;
						c1 = d1 = pBits+(neary+1)*dwEffWidth+3*nearx;
					}
				}
				else if (neary == h-1){
					if (nearx == w-1)
						a1 = b1= c1= d1 = pBits+neary*dwEffWidth+3*nearx;
					else{
						a1 = c1 = pBits+neary*dwEffWidth+3*nearx;
						b1 = d1 = pBits+neary*dwEffWidth+3*(nearx+1);
					}
				}
				else{
				 a1 = pBits+neary*dwEffWidth+3*nearx;
				 b1 = pBits+neary*dwEffWidth+3*(nearx+1);
				 c1 = pBits+(neary+1)*dwEffWidth+3*nearx;
				 d1 = pBits+(neary+1)*dwEffWidth+3*(nearx+1);
				}
				pNewBits[desty*newEffWidth+3*destx]   = max(0,min(255,(int)(a*a1[0]+b*b1[0]+c*c1[0]+d*d1[0]+0.5))); 
				pNewBits[desty*newEffWidth+3*destx+1] = max(0,min(255,(int)(a*a1[1]+b*b1[1]+c*c1[1]+d*d1[1]+0.5))); 
				pNewBits[desty*newEffWidth+3*destx+2] = max(0,min(255,(int)(a*a1[2]+b*b1[2]+c*c1[2]+d*d1[2]+0.5))); 
			}
			else
			{
				pNewBits[desty*newEffWidth+3*destx] = ClrBack.rgbBlue;
				pNewBits[desty*newEffWidth+3*destx+1] = ClrBack.rgbGreen;
				pNewBits[desty*newEffWidth+3*destx+2] = ClrBack.rgbRed;
			}
			x++;
		}
		y++;
	}
    return pNewDib;
}
BYTE* CRotation::Rotate_GrayDib(BYTE *pDib, double fAng,BYTE GrayBackGround/*=255*/ ,int bKeepSize/*=TRUE*/)
{
	if(pDib==NULL) return NULL;
	LPBITMAPINFOHEADER pBIH = (LPBITMAPINFOHEADER)pDib;
	if(pBIH->biBitCount != 8) return NULL;
	int headsize = sizeof(BITMAPINFOHEADER)+256*sizeof(RGBQUAD);
	BYTE* pBits = pDib + headsize;
	int w = pBIH->biWidth;
	int h = pBIH->biHeight;
	int i;
	BYTE *pNewDib,*pNewBits;

	int dwEffWidth = ((((8 * w) + 31) / 32) * 4); 
	if (!pBits) return NULL;
	if (fabs(fAng)<0.05)
	{
		BYTE* pNewDib = new BYTE[headsize+dwEffWidth*h];
		memcpy(pNewDib,pDib,headsize+dwEffWidth*h);
		return pNewDib;
	}

	double ang = -fAng*acos(0.0f)/90.0f;		//convert angle to radians and invert (positive angle performs clockwise rotation)
	float cos_angle = (float) cos(ang);			//these two are needed later (to rotate)
	float sin_angle = (float) sin(ang);

	double pX[4]={-0.5f,w-0.5f,-0.5f,w-0.5f};
	double pY[4]={-0.5f,-0.5f,h-0.5f,h-0.5f};

	double newpX[4]={0};
	double newpY[4]={0};

	if (bKeepSize){
		for (i=0; i<4; i++) {
			newpX[i] = pX[i];
			newpY[i] = pY[i];
		}
	} 
	else{
		for (i=0; i<4; i++) {
			newpX[i] = (pX[i]*cos_angle - pY[i]*sin_angle);
			newpY[i] = (pY[i]*cos_angle + pX[i]*sin_angle);
		}
	}

	//(read new dimensions from location of corners)
	float minx = (float) min(min(newpX[0],newpX[1]),min(newpX[2],newpX[3]));
	float miny = (float) min(min(newpY[0],newpY[1]),min(newpY[2],newpY[3]));
	float maxx = (float) max(max(newpX[0],newpX[1]),max(newpX[2],newpX[3]));
	float maxy = (float) max(max(newpY[0],newpY[1]),max(newpY[2],newpY[3]));

	int newWidth = (int) floor(maxx-minx+0.5f);
	int newHeight= (int) floor(maxy-miny+0.5f);
	int newEffWidth = ((((8 * newWidth) + 31) / 32) * 4); 

	float ssx=((maxx+minx)- ((float) newWidth-1))/2.0f;   //start for x
	float ssy=((maxy+miny)- ((float) newHeight-1))/2.0f;  //start for y

	float newxcenteroffset = 0.5f * newWidth;
	float newycenteroffset = 0.5f * newHeight;
	if (bKeepSize){
		ssx -= 0.5f * w;
		ssy -= 0.5f * h;
	}

	pNewDib = new BYTE[headsize+newEffWidth*newHeight];
	pNewBits = pNewDib+headsize;
	memcpy(pNewDib,pDib,headsize);
	LPBITMAPINFOHEADER pNewBIH = (LPBITMAPINFOHEADER) pNewDib;
	pNewBIH->biHeight = newHeight;
	pNewBIH->biWidth = newWidth;
	memset(pNewBits,0,newEffWidth*newHeight);

	float x,y;              //destination location (float, with proper offset)
	float origx, origy;
	int nearx,neary;        //origin location
	int destx, desty;       //destination location
	double t1,t2,a,b,c,d;

	y=ssy;         

	for (desty=0; desty<newHeight; desty++) {
		x=ssx;
		for (destx=0; destx<newWidth; destx++) {

			origx=(cos_angle*x+sin_angle*y);
			origy=(cos_angle*y-sin_angle*x);

			if (bKeepSize){
				origx += newxcenteroffset;
				origy += newycenteroffset;
			}

			nearx = (int)origx; if (nearx<0) nearx--;
			neary = (int)origy; if (neary<0) neary--;

			t1 = origx - nearx;
			t2 = origy - neary;

			d= t1*t2;
			b=t1-d;
			c=t2-d;
			a=1-t1-c;

			if (nearx>0 && nearx<=w-1 && neary>0 && neary<=h-1)
			{
				BYTE a1,b1,c1,d1;
				if (nearx == w-1){
					if (neary == h-1)
						a1 = b1= c1= d1 = pBits[nearx+neary*dwEffWidth];
					else{
						a1 = pBits[nearx+neary*dwEffWidth];
						b1 = pBits[nearx+neary*dwEffWidth];
						c1 = pBits[nearx+(neary+1)*dwEffWidth];
						d1 = pBits[nearx+(neary+1)*dwEffWidth];
					}
				}
				else if (neary == h-1){
					if (nearx == w-1)
						a1 = b1= c1= d1 = pBits[nearx+neary*dwEffWidth];
					else{
						a1 = pBits[nearx+neary*dwEffWidth];
						b1 = pBits[nearx+1+neary*dwEffWidth];
						c1 = pBits[nearx+neary*dwEffWidth];
						d1 = pBits[nearx+1+neary*dwEffWidth];
					}
				}
				else{
					a1 = pBits[nearx+neary*dwEffWidth];
					b1 = pBits[nearx+1+neary*dwEffWidth];
					c1 = pBits[nearx+(neary+1)*dwEffWidth];
					d1 = pBits[nearx+1+(neary+1)*dwEffWidth];
				}
				pNewBits[desty*newEffWidth+destx] = max(0,min(255,(int)(a*a1+b*b1+c*c1+d*d1+0.5))); 
			}
			else				
				pNewBits[desty*newEffWidth+destx] = GrayBackGround;
			x++;
		}
		y++;
	}

	return pNewDib;
}
BYTE* CRotation::Rotate_GrayImg(BYTE *pImg, int &w, int &h,double fAng,BYTE GrayBackGround,int bKeepSize/*=TRUE*/)
{
	BYTE	*pNewImg;
	int w0 = w;
	int h0 = h;
	int i;
	if (!pImg) return FALSE;

	if (fabs(fAng)<0.05)
	{
		BYTE* pNewImg = new BYTE[w0*h0];
		memcpy(pNewImg,pImg,w0*h0);
		return pNewImg;
	}

	double ang = fAng*acos(0.0f)/90.0f;		//convert angle to radians and invert (positive angle performs clockwise rotation)
	float cos_angle = (float) cos(ang);			//these two are needed later (to rotate)
	float sin_angle = (float) sin(ang);

	double pX[4]={-0.5f,w0-0.5f,-0.5f,w0-0.5f};
	double pY[4]={-0.5f,-0.5f,h0-0.5f,h0-0.5f};

	double newpX[4]={0};
	double newpY[4]={0};

	if (bKeepSize){
		for (i=0; i<4; i++) {
			newpX[i] = pX[i];
			newpY[i] = pY[i];
		}
	} 
	else{
		for (i=0; i<4; i++) {
			newpX[i] = (pX[i]*cos_angle - pY[i]*sin_angle);
			newpY[i] = (pY[i]*cos_angle + pX[i]*sin_angle);
		}
	}

	//(read new dimensions from location of corners)
	float minx = (float) min(min(newpX[0],newpX[1]),min(newpX[2],newpX[3]));
	float miny = (float) min(min(newpY[0],newpY[1]),min(newpY[2],newpY[3]));
	float maxx = (float) max(max(newpX[0],newpX[1]),max(newpX[2],newpX[3]));
	float maxy = (float) max(max(newpY[0],newpY[1]),max(newpY[2],newpY[3]));

	int newWidth = (int) floor(maxx-minx+0.5f);
	int newHeight= (int) floor(maxy-miny+0.5f);

	w = newWidth;
	h = newHeight;

	float ssx=((maxx+minx)- ((float) newWidth-1))/2.0f;   //start for x
	float ssy=((maxy+miny)- ((float) newHeight-1))/2.0f;  //start for y

	float newxcenteroffset = 0.5f * newWidth;
	float newycenteroffset = 0.5f * newHeight;
	if (bKeepSize){
		ssx -= 0.5f * w0;
		ssy -= 0.5f * h0;
	}
	int size = w * h;
	pNewImg = new BYTE[size];
	memset(pNewImg, 0, size);


	int x,y,pos;              //destination location (float, with proper offset)
	int origx, origy;
	int nearx,neary;        //origin location
	int destx, desty,tempG;       //destination location
	int t1,t2,a,b,c,d;

	y=(int)(ssy+0.5f);
	int icos_angle = (int)(cos_angle*1024);
	int isin_angle = (int)(sin_angle*1024);
	int inewxcenteroffset = (int)(newxcenteroffset*1024);
	int inewycenteroffset = (int)(newycenteroffset*1024);
	int T = (1<<20),hT1 = (1<<19);

	for (desty = 0; desty < h; desty++) {
		x = (int)(ssx+0.5f);
		pos = desty * w;
		for (destx = 0; destx < w; destx++) {

			origx=(icos_angle*x+isin_angle*y);
			origy=(icos_angle*y-isin_angle*x);

			if (bKeepSize){
				origx += inewxcenteroffset;
				origy += inewycenteroffset;
			}

			nearx = (int)(origx>>10); if (nearx<0) nearx--;
			neary = (int)(origy>>10); if (neary<0) neary--;

			t1 = origx - (nearx<<10);
			t2 = origy - (neary<<10);


			d= t1*t2;
			b=(t1<<10)-d;
			c=(t2<<10)-d;
			a=T-(t1<<10)-c;

			if (nearx>0 && nearx<=w0-1 && neary>0 && neary<=h0-1)
			{
				BYTE a1,b1,c1,d1;
				if (nearx == w0-1){
					if (neary == h0-1)
						a1 = b1= c1= d1 = pImg[nearx+neary*w0];
					else{
						a1 = pImg[nearx+neary*w0];
						b1 = pImg[nearx+neary*w0];
						c1 = pImg[nearx+(neary+1)*w0];
						d1 = pImg[nearx+(neary+1)*w0];
					}
				}
				else if (neary == h0-1){
					if (nearx == w0-1)
						a1 = b1= c1= d1 = pImg[nearx+neary*w0];
					else{
						a1 = pImg[nearx+neary*w0];
						b1 = pImg[nearx+1+neary*w0];
						c1 = pImg[nearx+neary*w0];
						d1 = pImg[nearx+1+neary*w0];
					}
				}
				else{
					a1 = pImg[nearx+neary*w0];
					b1 = pImg[nearx+1+neary*w0];
					c1 = pImg[nearx+(neary+1)*w0];
					d1 = pImg[nearx+1+(neary+1)*w0];
				}
				tempG = (a*a1+b*b1+c*c1+d*d1+hT1)>>20; 
				pNewImg[pos + destx] = max(0,min(255,tempG));
 			}
			else				
				pNewImg[pos + destx] = GrayBackGround;
			x++;
		}
		y++;
	}

	return pNewImg;
}
BYTE* CRotation::Rotate_BinDib(BYTE *pDib, double fAng,int nBackGround/*=BACKGROUND_WHITE*/,int bKeepSize/*=TRUE*/)
{
	if(pDib==NULL) return NULL;
	LPBITMAPINFOHEADER pBIH = (LPBITMAPINFOHEADER)pDib;
	if(pBIH->biBitCount != 1)return NULL;
	int w,h;
	BYTE* pImg = CImageBase::MakeImgFromBinDib(pDib,w,h);
	BYTE* pNewImg = Rotate_BinImg(pImg,w,h,fAng,nBackGround,bKeepSize);
	BYTE* pNewDib = CImageBase::MakeBinDibFromImg(pNewImg,w,h);
	delete[]pImg;
	delete[]pNewImg;
	return pNewDib;
}

BYTE* CRotation::Rotate_BinImg(BYTE *pImg, int &w, int &h,double fAng,int nBackGround/*=BACKGROUND_WHITE*/,int bKeepSize/*=TRUE*/)
{
	BYTE GrayBackGround = (nBackGround == BACKGROUND_BLACK)? 1: 0;
	return Rotate_GrayImg(pImg, w, h, fAng, GrayBackGround, bKeepSize);
}
//Speed Gray Image Rotate:Bilinear Method
BYTE* CRotation::Rotate_BinDib_ByRun(BYTE *pDib, double fAng,int bKeepSize/*=TRUE*/)
{
	if(pDib==NULL) return NULL;
	LPBITMAPINFOHEADER pBIH = (LPBITMAPINFOHEADER)pDib;
	if(pBIH->biBitCount != 1) return NULL;
	int headsize = sizeof(BITMAPINFOHEADER)+2*sizeof(RGBQUAD);
	BYTE* pBits = pDib + headsize;
	int w = pBIH->biWidth;
	int h = pBIH->biHeight;

	BYTE *pNewDib;
	int dwEffWidth;
	if (fabs(fAng)<0.05)
	{
		dwEffWidth = (((w + 31) / 32) * 4); 
		pNewDib = new BYTE[headsize+dwEffWidth*h];
		memcpy(pNewDib,pDib,headsize+dwEffWidth*h);
		return pNewDib;
	}
	CRunProc  runProc;
	BYTE* pNewBits = runProc.Rotate_BinBits(pBits,w, h, fAng, bKeepSize);
	pNewDib = CImageBase::MakeBinDibFromBits(pNewBits,w,h);
	delete[] pNewBits;
	return pNewDib;

}
BYTE* CRotation::Rotate_BinImg_ByRun(BYTE *pImg, int &w, int &h,double fAng,int bKeepSize/*=TRUE*/)
{
	if(pImg==NULL) return NULL;
	BYTE *pNewImg;
	if (fabs(fAng)<0.05)
	{
		pNewImg = new BYTE[w*h];
		memcpy(pNewImg,pImg,w*h);
		return pNewImg;
	}
	CRunProc  runProc;
	return runProc.Rotate_BinImg(pImg,w, h, fAng, bKeepSize);
}
BYTE* CRotation::RotateRegularDib(BYTE *pDib,int nRegularRotateMode/*=ROTATE_LEFT*/)
{
	if(pDib==NULL) return NULL;
	BYTE* pRotDib=NULL;
	LPBITMAPINFOHEADER pBIH = (LPBITMAPINFOHEADER)pDib;
	if(pBIH->biBitCount == 24)
	{
		if(nRegularRotateMode == ROTATE_LEFT)
			pRotDib = RotateLeft_24Dib(pDib);
		else if(nRegularRotateMode == ROTATE_RIGHT)
			pRotDib = RotateRight_24Dib(pDib);
		else if(nRegularRotateMode == ROTATE_180)
			pRotDib = Rotate180_24Dib(pDib);
		else
			pRotDib = RotateLeft_24Dib(pDib);
	}
	else if(pBIH->biBitCount == 8)
	{
		if(nRegularRotateMode == ROTATE_LEFT)
			pRotDib = RotateLeft_GrayDib(pDib);
		else if(nRegularRotateMode == ROTATE_RIGHT)
			pRotDib = RotateRight_GrayDib(pDib);
		else if(nRegularRotateMode == ROTATE_180)
			pRotDib = Rotate180_GrayDib(pDib);
		else
			pRotDib = RotateLeft_GrayDib(pDib);
	}
	else if(pBIH->biBitCount == 1)
	{
		if(nRegularRotateMode == ROTATE_LEFT)
			pRotDib = RotateLeft_BinDib(pDib);
		else if(nRegularRotateMode == ROTATE_RIGHT)
			pRotDib = RotateRight_BinDib(pDib);
		else if(nRegularRotateMode == ROTATE_180)
			pRotDib = Rotate180_BinDib(pDib);
		else
			pRotDib = RotateLeft_BinDib(pDib);
	}
	else 
		return NULL;
	return pRotDib;
}
BYTE* CRotation::RotateLeft_24Dib(BYTE *pDib)
{
	if(pDib==NULL) return NULL;
	LPBITMAPINFOHEADER pBIH = (LPBITMAPINFOHEADER)pDib;
	if(pBIH->biBitCount != 24) return NULL;
	int headsize = sizeof(BITMAPINFOHEADER);
	BYTE* pBits = pDib + headsize;
	int w = pBIH->biWidth;
	int h = pBIH->biHeight;
	int dwEffWidth = ((((24 * w) + 31) / 32) * 4);

	BYTE *pNewDib,*pNewBits;
	int dwNewEffWidth = ((((24 * h) + 31) / 32) * 4);
	pNewDib = new BYTE[headsize+dwNewEffWidth*w];
	memcpy(pNewDib,pDib,headsize);
	LPBITMAPINFOHEADER pNewBIH = (LPBITMAPINFOHEADER)pNewDib;
	pNewBIH->biSizeImage = dwNewEffWidth*w;
	pNewBIH->biWidth = h;
	pNewBIH->biHeight = w;
	pNewBits = pNewDib + headsize;
	int i,j;
	for(i=0;i<h;i++)for(j=0;j<w;j++)
	{
		pNewBits[dwNewEffWidth*j+3*(h-1-i)] = pBits[dwEffWidth*i+3*j];
		pNewBits[dwNewEffWidth*j+3*(h-1-i)+1] = pBits[dwEffWidth*i+3*j+1];
		pNewBits[dwNewEffWidth*j+3*(h-1-i)+2] = pBits[dwEffWidth*i+3*j+2];
	}
	return pNewDib;
}
BYTE* CRotation::RotateRight_24Dib(BYTE *pDib)
{
	if(pDib==NULL) return NULL;
	LPBITMAPINFOHEADER pBIH = (LPBITMAPINFOHEADER)pDib;
	if(pBIH->biBitCount != 24) return NULL;
	int headsize = sizeof(BITMAPINFOHEADER);
	BYTE* pBits = pDib + headsize;
	int w = pBIH->biWidth;
	int h = pBIH->biHeight;
	int dwEffWidth = ((((24 * w) + 31) / 32) * 4);

	BYTE *pNewDib,*pNewBits;
	int dwNewEffWidth = ((((24 * h) + 31) / 32) * 4);
	pNewDib = new BYTE[headsize+dwNewEffWidth*w];
	memcpy(pNewDib,pDib,headsize);
	LPBITMAPINFOHEADER pNewBIH = (LPBITMAPINFOHEADER)pNewDib;
	pNewBIH->biSizeImage = dwNewEffWidth*w;
	pNewBIH->biWidth = h;
	pNewBIH->biHeight = w;
	pNewBits = pNewDib + headsize;
	int i,j;
	for(i=0;i<h;i++)for(j=0;j<w;j++)
	{
		pNewBits[dwNewEffWidth*(w-1-j)+3*i] = pBits[dwEffWidth*i+3*j];
		pNewBits[dwNewEffWidth*(w-1-j)+3*i+1] = pBits[dwEffWidth*i+3*j+1];
		pNewBits[dwNewEffWidth*(w-1-j)+3*i+2] = pBits[dwEffWidth*i+3*j+2];
	}
	return pNewDib;
}
BYTE* CRotation::Rotate180_24Dib(BYTE *pDib)
{
	if(pDib==NULL) return NULL;
	LPBITMAPINFOHEADER pBIH = (LPBITMAPINFOHEADER)pDib;
	if(pBIH->biBitCount != 24) return NULL;
	int headsize = sizeof(BITMAPINFOHEADER);
	BYTE* pBits = pDib + headsize;
	int w = pBIH->biWidth;
	int h = pBIH->biHeight;
	int dwEffWidth = ((((24 * w) + 31) / 32) * 4);

	BYTE *pNewDib,*pNewBits;
	pNewDib = new BYTE[headsize+dwEffWidth*h];
	memcpy(pNewDib,pDib,headsize);
	pNewBits = pNewDib + headsize;
	int i,j;
	for(i=0;i<h;i++)for(j=0;j<w;j++)
	{
		pNewBits[dwEffWidth*(h-1-i)+3*(w-1-j)] = pBits[dwEffWidth*i+3*j];
		pNewBits[dwEffWidth*(h-1-i)+3*(w-1-j)+1] = pBits[dwEffWidth*i+3*j+1];
		pNewBits[dwEffWidth*(h-1-i)+3*(w-1-j)+2] = pBits[dwEffWidth*i+3*j+2];
	}
	return pNewDib;
}
BYTE* CRotation::RotateLeft_GrayDib(BYTE *pDib)
{
	if(pDib==NULL) return NULL;
	LPBITMAPINFOHEADER pBIH = (LPBITMAPINFOHEADER)pDib;
	if(pBIH->biBitCount != 8) return NULL;
	int headsize = sizeof(BITMAPINFOHEADER)+256*sizeof(RGBQUAD);
	BYTE* pBits = pDib + headsize;
	int w = pBIH->biWidth;
	int h = pBIH->biHeight;
	int dwEffWidth = ((((8 * w) + 31) / 32) * 4);

	BYTE *pNewDib,*pNewBits;
	int dwNewEffWidth = ((((8 * h) + 31) / 32) * 4);
	pNewDib = new BYTE[headsize+dwNewEffWidth*w];
	memcpy(pNewDib,pDib,headsize);
	LPBITMAPINFOHEADER pNewBIH = (LPBITMAPINFOHEADER)pNewDib;
	pNewBIH->biSizeImage = dwNewEffWidth*w;
	pNewBIH->biWidth = h;
	pNewBIH->biHeight = w;
	pNewBits = pNewDib + headsize;
	int i,j;
	for(i=0;i<h;i++)for(j=0;j<w;j++)
		pNewBits[dwNewEffWidth*j+(h-1-i)] = pBits[dwEffWidth*i+j];
	return pNewDib;
}
BYTE* CRotation::RotateRight_GrayDib(BYTE *pDib)
{
	if(pDib==NULL) return NULL;
	LPBITMAPINFOHEADER pBIH = (LPBITMAPINFOHEADER)pDib;
	if(pBIH->biBitCount != 8) return NULL;
	int headsize = sizeof(BITMAPINFOHEADER)+256*sizeof(RGBQUAD);
	BYTE* pBits = pDib + headsize;
	int w = pBIH->biWidth;
	int h = pBIH->biHeight;
	int dwEffWidth = ((((8 * w) + 31) / 32) * 4);

	BYTE *pNewDib,*pNewBits;
	int dwNewEffWidth = ((((8 * h) + 31) / 32) * 4);
	pNewDib = new BYTE[headsize+dwNewEffWidth*w];
	memcpy(pNewDib,pDib,headsize);
	LPBITMAPINFOHEADER pNewBIH = (LPBITMAPINFOHEADER)pNewDib;
	pNewBIH->biSizeImage = dwNewEffWidth*w;
	pNewBIH->biWidth = h;
	pNewBIH->biHeight = w;
	pNewBits = pNewDib + headsize;
	int i,j;
	for(i=0;i<h;i++)for(j=0;j<w;j++)
		pNewBits[dwNewEffWidth*(w-1-j)+i] = pBits[dwEffWidth*i+j];
	return pNewDib;
}
BYTE* CRotation::Rotate180_GrayDib(BYTE *pDib)
{
	if(pDib==NULL) return NULL;
	LPBITMAPINFOHEADER pBIH = (LPBITMAPINFOHEADER)pDib;
	if(pBIH->biBitCount != 8) return NULL;
	int headsize = sizeof(BITMAPINFOHEADER)+256*sizeof(RGBQUAD);
	BYTE* pBits = pDib + headsize;
	int w = pBIH->biWidth;
	int h = pBIH->biHeight;
	int dwEffWidth = ((((8 * w) + 31) / 32) * 4);

	BYTE *pNewDib,*pNewBits;
	pNewDib = new BYTE[headsize+dwEffWidth*h];
	memcpy(pNewDib,pDib,headsize);
	pNewBits = pNewDib + headsize;
	int i,j;
	for(i=0;i<h;i++)for(j=0;j<w;j++)
		pNewBits[dwEffWidth*(h-1-i)+(w-1-j)] = pBits[dwEffWidth*i+j];
	return pNewDib;
}
BYTE* CRotation::RotateLeft_BinDib(BYTE *pDib)
{
	if(pDib==NULL) return NULL;
	LPBITMAPINFOHEADER pBIH = (LPBITMAPINFOHEADER)pDib;
	if(pBIH->biBitCount != 1) return NULL;
	int w,h;
	BYTE* pBits = CImageBase::Get_lpBits(pDib);
	CImageBase::GetWidthHeight(pDib,w,h);
	int ByteW = (w+31)/32*4;
	int ByteW1 = (h+31)/32*4;
	
	BYTE* pRotDib = CImageBase::MakeDib(h,w,1);
	BYTE* pRotBits = CImageBase::Get_lpBits(pRotDib);
	int i,j;
	for(i=0;i<h;i++)for(j=0;j<w;j++)
	{
		BYTE val = CImageBase::GetPx(pBits,ByteW, j, i);
		CImageBase::SetPx(pRotBits,ByteW1, h-1-i, j, val);
	}
	return pRotDib;
}
BYTE* CRotation::RotateRight_BinDib(BYTE *pDib)
{
	if(pDib==NULL) return NULL;
	LPBITMAPINFOHEADER pBIH = (LPBITMAPINFOHEADER)pDib;
	if(pBIH->biBitCount != 1) return NULL;
	int w,h;
	BYTE* pBits = CImageBase::Get_lpBits(pDib);
	CImageBase::GetWidthHeight(pDib,w,h);
	int ByteW = (w+31)/32*4;
	int ByteW1 = (h+31)/32*4;

	BYTE* pRotDib = CImageBase::MakeDib(h,w,1);
	BYTE* pRotBits = CImageBase::Get_lpBits(pRotDib);
	int i,j;
	for(i=0;i<h;i++)for(j=0;j<w;j++)
	{
		BYTE val = CImageBase::GetPx(pBits,ByteW, j, i);
		CImageBase::SetPx(pRotBits,ByteW1, i, w-1-j, val);
	}
	return pRotDib;
}
BYTE* CRotation::Rotate180_BinDib(BYTE *pDib)
{
	if(pDib==NULL) return NULL;
	LPBITMAPINFOHEADER pBIH = (LPBITMAPINFOHEADER)pDib;
	if(pBIH->biBitCount != 1) return NULL;
	int w,h,ByteW;
	BYTE* pBits = CImageBase::Get_lpBits(pDib);
	CImageBase::GetWidthHeight(pDib,w,h);
	ByteW = (w+31)/32*4;
	BYTE* pRotDib = CImageBase::MakeDib(w,h,1);
	BYTE* pRotBits = CImageBase::Get_lpBits(pRotDib);
	int i,j;
	for(i=0;i<h;i++)for(j=0;j<w;j++)
	{
		BYTE val = CImageBase::GetPx(pBits,ByteW, j, i);
		CImageBase::SetPx(pRotBits,ByteW, w-1-j, h-1-i, val);
	}
	return pRotDib;
}
BYTE* CRotation::RotateRegularImg(BYTE *pImg,int w,int h,int nRegularRotateMode/*=ROTATE_LEFT*/)
{
	if(pImg==NULL)return NULL;
	BYTE *pRotImg = NULL;
	if(nRegularRotateMode == ROTATE_LEFT)
		pRotImg = RotateLeft_Img(pImg, w, h);
	else if(nRegularRotateMode == ROTATE_RIGHT)
		pRotImg = RotateRight_Img(pImg, w, h);
	else if(nRegularRotateMode == ROTATE_180)
		pRotImg = Rotate180_Img(pImg, w, h);
	else
		pRotImg = RotateLeft_Img(pImg, w, h);
	return pRotImg;
}

BYTE* CRotation::RotateRight_Img(BYTE *pImg, int w, int h)
{
	int i,j;
	if(pImg==NULL) return NULL;
	BYTE *pNewImg = new BYTE[h*w];
	for(i=0;i<h;i++)for(j=0;j<w;j++)
		pNewImg[h*j+(h-1-i)] = pImg[w*i+j];
	return pNewImg;
}
BYTE* CRotation::RotateLeft_Img(BYTE *pImg, int w, int h)
{
	int i,j;
	if(pImg==NULL) return NULL;
	BYTE *pNewImg = new BYTE[h*w];
	for(i=0;i<h;i++)for(j=0;j<w;j++)
		pNewImg[h*(w-1-j)+i] = pImg[w*i+j];
	return pNewImg;
}
BYTE* CRotation::Rotate180_Img(BYTE *pImg, int w, int h)
{
	int i,j;
	if(pImg==NULL) return NULL;
	BYTE *pNewImg = new BYTE[h*w];
	for(i=0;i<h;i++)for(j=0;j<w;j++)
		pNewImg[w*(h-1-i)+(w-1-j)] = pImg[w*i+j];
	return pNewImg;
}


void CRotation::RotateDibRegion(BYTE *pDib, double fAng, CRect Region, BOOL bKeepSize)
{
	BYTE* pSubDib = CImageBase::CropDib(pDib,Region);
	BYTE* pRotDib = CRotation::RotateDib(pSubDib,fAng,BACKGROUND_CALC, bKeepSize);

	CPoint pos;
	if(bKeepSize==FALSE)
	{
		int w,h,dx,dy;
		CImageBase::GetWidthHeight(pRotDib,w,h);
		dx = (w-Region.Width())/2;
		dy = (h-Region.Height())/2;
		pos = CPoint(Region.left-dx, Region.top-dy);
	}
	else
		pos = CPoint(Region.left,Region.top);

	CImageBase::MergeCopyDibB2A(pDib, pRotDib, pos);
	delete[] pSubDib;
	delete[] pRotDib;
}

