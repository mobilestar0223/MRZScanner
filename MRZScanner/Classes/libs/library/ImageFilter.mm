// ImageFilter.cpp: implementation of the CImageFilter class.
//
//////////////////////////////////////////////////////////////////////

#include "StdAfx.h"
#include "ImageFilter.h"
#include "ImageBase.h"
//#include "IntImage.h"
#include "TRunProc.h"
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

CImageFilter::CImageFilter()
{

}

CImageFilter::~CImageFilter()
{

}

BOOL CImageFilter::RemoveNoizeDib(BYTE *pDib,CSize ThSz,int ThAs)
{
	if (!pDib) return FALSE;
	int nBitCount = CImageBase::GetBitCount(pDib);
	if(nBitCount==24)
		return FALSE;
	else if(nBitCount==8)
		return FALSE;
	else if(nBitCount==1)
		return RemoveNoizeBinDib(pDib,ThSz,ThAs);
	return FALSE;
}

void CImageFilter::RemoveNoisebyMedian(BYTE* pImg,int w,int h,int mode,CRect rt)
{
	int size = w * h;
	BYTE* pNewImg=new BYTE[size];
	int i,j,k,l,a[10],temp;
	memcpy(pNewImg,pImg, size);
	for(i=max(1,rt.top);i<=min(h-2,rt.bottom);i++)
		for(j=max(1,rt.left);j<=min(w-2,rt.right);j++)
		{
			a[1]=pImg[(i-1)*w+j];a[4]=pImg[i*w+j];
			a[2]=pImg[(i+1)*w+j];a[3]=pImg[i*w+j-1];a[0]=pImg[i*w+j+1];
			for(k=0;k<4;k++)
				for(l=k+1;l<5;l++)
					if(a[k]>a[l])
					{
						temp=a[k];a[k]=a[l];a[l]=temp;
					}
					if(mode==1)
						pNewImg[i*w+j]=(BYTE)a[3];
					else if(mode==2)
						pNewImg[i*w+j]=(BYTE)a[1];
					else if(mode==0)
						pNewImg[i*w+j]=(BYTE)a[2];
		}
		memcpy(pImg,pNewImg,w*h);
		delete []pNewImg;
}
float CImageFilter::GetPixelWidth(BYTE* pImg,int w,CRect rt)
{
	int i,j;
	int n,n2;
	n=n2=0;
	for(i=rt.top;i<rt.bottom-1;i++)
		for(j=rt.left;j<rt.right-1;j++)
		{
			n+=pImg[i*w+j];
			if(i!=rt.bottom && j!=rt.right && pImg[i*w+j]==1 && pImg[i*w+j+1]==1 &&
				pImg[(i+1)*w+j]==1 && pImg[(i+1)*w+j+1]==1)
				n2++;
		}
		return n/float(n-n2);
}
BOOL CImageFilter::RemoveNoizeBinImg(BYTE *pImg, int w, int h, CSize ThSz, int ThAs)
{
	if(pImg == NULL) return FALSE;
	
	CRunProc pRunProc;
	BYTE* pNewImg = pRunProc.GetRemoveNoizeImg(pImg,w,h,ThSz,ThAs);
	memcpy(pImg,pNewImg,w*h);
	delete[]pNewImg;
	return TRUE;
}


BOOL CImageFilter::RemoveNoizeBinDib(BYTE *pDib,CSize ThSz,int ThAs)
{
	if(pDib == NULL) return FALSE;

	int nBitCount = CImageBase::GetBitCount(pDib);
	if(nBitCount != 1) return FALSE;
	int w,h;
	CImageBase::GetWidthHeight(pDib,w,h);
	BYTE* pBits = CImageBase::Get_lpBits(pDib);

	CRunProc pRunProc;
	BYTE* pNewBits = pRunProc.GetRemoveNoizeBits(pBits,w,h,ThSz,ThAs);
	int bw = (w+31)/32*4;
	memcpy(pBits,pNewBits,bw*h);
	delete[]pNewBits;
	return TRUE;
}

BOOL CImageFilter::MorphoErosionDib(BYTE *pDib)
{
	if (!pDib) return FALSE;
	int nBitCount = CImageBase::GetBitCount(pDib);
	if(nBitCount==24)
		return MorphoErosion24Dib(pDib);
	else if(nBitCount==8)
		return MorphoErosionGrayDib(pDib);
	else if(nBitCount==1)
		return MorphoErosionBinDib(pDib);
	
	return FALSE;
}

BOOL CImageFilter::MorphoDilationDib(BYTE *pDib)
{
	if (!pDib) return FALSE;
	int nBitCount = CImageBase::GetBitCount(pDib);
	if(nBitCount==24)
		return MorphoDilation24Dib(pDib);
	else if(nBitCount==8)
		return MorphoDilationGrayDib(pDib);
	else if(nBitCount==1)
		return MorphoDilationBinDib(pDib);

	return FALSE;
}

BOOL CImageFilter::MorphoErosion24Dib(BYTE *pDib)
{
	if (!pDib) return FALSE;
	
	int w,h;
	int nBitCount = CImageBase::GetBitCount(pDib);
	if(nBitCount!=24) return FALSE;
	CImageBase::GetWidthHeight(pDib,w,h);
	int bw = (w*nBitCount+31)/32*4;
	
	BYTE* pBits = CImageBase::Get_lpBits(pDib);
	BYTE* pTempBits = new BYTE[bw*h];
	memcpy(pTempBits,pBits,h*bw);

	int i,j;
	BYTE bBlack;
	
	for (i=1 ; i< h-1; i++)
	{
		for (j=1 ; j<w-1 ; j++)
		{
			bBlack = max(pTempBits[i*bw+3*(j-1)],pTempBits[i*bw+3*(j+1)]);
			bBlack = max(bBlack,pTempBits[(i-1)*bw+3*j]);
			bBlack = max(bBlack,pTempBits[i*bw+3*j]);
			bBlack = max(bBlack,pTempBits[(i+1)*bw+3*j]);
			pBits[i*bw+3*j] = bBlack;
			bBlack = max(pTempBits[i*bw+3*(j-1)+1],pTempBits[i*bw+3*(j+1)+1]);
			bBlack = max(bBlack,pTempBits[(i-1)*bw+3*j+1]);
			bBlack = max(bBlack,pTempBits[i*bw+3*j+1]);
			bBlack = max(bBlack,pTempBits[(i+1)*bw+3*j+1]);
			pBits[i*bw+3*j+1] = bBlack;
			bBlack = max(pTempBits[i*bw+3*(j-1)+2],pTempBits[i*bw+3*(j+1)+2]);
			bBlack = max(bBlack,pTempBits[(i-1)*bw+3*j+2]);
			bBlack = max(bBlack,pTempBits[i*bw+3*j+2]);
			bBlack = max(bBlack,pTempBits[(i+1)*bw+3*j+2]);
			pBits[i*bw+3*j+2] = bBlack;
		}
	}
	delete []pTempBits;
	return TRUE;
}
BOOL CImageFilter::MorphoDilation24Dib(BYTE *pDib)
{
	if (!pDib) return FALSE;
	
	int w,h;
	int nBitCount = CImageBase::GetBitCount(pDib);
	if(nBitCount!=24) return FALSE;
	CImageBase::GetWidthHeight(pDib,w,h);
	int bw = (w*nBitCount+31)/32*4;
	
	BYTE* pBits = CImageBase::Get_lpBits(pDib);
	BYTE* pTempBits = new BYTE[bw*h];
	memcpy(pTempBits,pBits,h*bw);
	
	int i,j;
	BYTE bBlack;
	
	for (i=1 ; i< h-1; i++)
	{
		for (j=1 ; j<w-1 ; j++)
		{
			bBlack = min(pTempBits[i*bw+3*(j-1)],pTempBits[i*bw+3*(j+1)]);
			bBlack = min(bBlack,pTempBits[(i-1)*bw+3*j]);
			bBlack = min(bBlack,pTempBits[i*bw+3*j]);
			bBlack = min(bBlack,pTempBits[(i+1)*bw+3*j]);
			pBits[i*bw+3*j] = bBlack;
			bBlack = min(pTempBits[i*bw+3*(j-1)+1],pTempBits[i*bw+3*(j+1)+1]);
			bBlack = min(bBlack,pTempBits[(i-1)*bw+3*j+1]);
			bBlack = min(bBlack,pTempBits[i*bw+3*j+1]);
			bBlack = min(bBlack,pTempBits[(i+1)*bw+3*j+1]);
			pBits[i*bw+3*j+1] = bBlack;
			bBlack = min(pTempBits[i*bw+3*(j-1)+2],pTempBits[i*bw+3*(j+1)+2]);
			bBlack = min(bBlack,pTempBits[(i-1)*bw+3*j+2]);
			bBlack = min(bBlack,pTempBits[i*bw+3*j+2]);
			bBlack = min(bBlack,pTempBits[(i+1)*bw+3*j+2]);
			pBits[i*bw+3*j+2] = bBlack;
		}
	}
	delete []pTempBits;
	return TRUE;
}
BOOL CImageFilter::MorphoErosionGrayDib(BYTE *pDib)
{
	if (!pDib) return FALSE;
	
	int w,h;
	int nBitCount = CImageBase::GetBitCount(pDib);
	if(nBitCount!=8) return FALSE;
	CImageBase::GetWidthHeight(pDib,w,h);
	int bw = (w*8+31)/32*4;
	
	BYTE* pBits = CImageBase::Get_lpBits(pDib);
	BYTE* pTempBits = new BYTE[bw*h];
	
	int i,j;
	memcpy(pTempBits,pBits,h*bw);
	BYTE bBlack;
	for (i=1 ; i< h-1; i++)
	{
		for (j=1 ; j<w-1 ; j++)
		{
			bBlack = max(pTempBits[i*bw+j-1],pTempBits[i*bw+j+1]);
			bBlack = max(bBlack,pTempBits[(i-1)*bw+j]);
			bBlack = max(bBlack,pTempBits[i*bw+j]);
			bBlack = max(bBlack,pTempBits[(i+1)*bw+j]);
			pBits[i*bw+j] = bBlack;
		}
	}
	delete []pTempBits;
	return TRUE;
}

BOOL CImageFilter::MorphoDilationGrayDib(BYTE *pDib)
{
	if (!pDib) return FALSE;
	
	int w,h;
	int nBitCount = CImageBase::GetBitCount(pDib);
	if(nBitCount!=8) return FALSE;
	CImageBase::GetWidthHeight(pDib,w,h);
	int bw = (w*8+31)/32*4;
	
	BYTE* pBits = CImageBase::Get_lpBits(pDib);
	BYTE* pTempBits = new BYTE[bw*h];
	
	int i,j;
 	memcpy(pTempBits,pBits,h*bw);
	BYTE bBlack;
	
	for (i=1 ; i< h-1; i++)
	{
		for (j=1 ; j<w-1 ; j++)
		{
			bBlack = min(pTempBits[i*bw+j-1],pTempBits[i*bw+j+1]);
			bBlack = min(bBlack,pTempBits[(i-1)*bw+j]);
			bBlack = min(bBlack,pTempBits[i*bw+j]);
			bBlack = min(bBlack,pTempBits[(i+1)*bw+j]);
			pBits[i*bw+j] = bBlack;
		}
	}
	delete []pTempBits;
	return TRUE;
}

BOOL CImageFilter::MorphoDilationBinDib(BYTE *pDib)
{
	if (!pDib) return FALSE;
	
	int w,h;
	int nBitCount = CImageBase::GetBitCount(pDib);
	if(nBitCount!=1) return FALSE;
	
	BYTE* pImg = CImageBase::MakeImgFromBinDib(pDib,w,h);
	BYTE* pImg1 = new BYTE[w*h];
	memcpy(pImg1, pImg,h*w);
	
	int i,j;
	for (i=1 ; i< h-1; i++)
	{
		for (j=1 ; j<w-1 ; j++)
		{
			if(pImg1[i*w+j]==1) continue;
			if(pImg1[i*w+j-1]==1 || pImg1[i*w+j+1]==1 || 
				pImg1[(i+1)*w+j]==1 || pImg1[(i-1)*w+j]==1)
				pImg[i*w+j] = 1;
		}
	}
	BYTE* pBits = CImageBase::Get_lpBits(pDib);
	BYTE* pNewBits = CImageBase::MakeBinBitsFromImg(pImg,w,h);
	int bw = (w+31)/32*4;
	memcpy(pBits, pNewBits, bw*h);
	delete[] pImg;
	delete[] pImg1;
	delete[] pNewBits;
	
	return TRUE;
}
BYTE*   CImageFilter::MorphoErosion(BYTE *pImg,int w,int h)
{
	BYTE* pRet = new BYTE[w*h];
	memcpy(pRet,pImg,w*h);
	int i,j;
	int b;
	for(i = 1; i < h - 1; i ++)
		for(j = 1; j < w - 1; j ++)
		{
			b = max(pImg[i*w+j-1],pImg[i*w+j+1]);
			b = max(b,pImg[(i-1)*w+j]);
			b = max(b,pImg[i*w+j]);
			b = max(b,pImg[(i+1)*w+j]);
			pRet[i*w+j] = b;
		}
	return pRet;

}
BOOL CImageFilter::MorphoErosionBinDib(BYTE *pDib)
{
	if (!pDib) return FALSE;
	
	int w,h;
	int nBitCount = CImageBase::GetBitCount(pDib);
	if(nBitCount!=1) return FALSE;
	
	BYTE* pImg = CImageBase::MakeImgFromBinDib(pDib,w,h);
	BYTE* pImg1 = new BYTE[w*h];
	memcpy(pImg1, pImg,h*w);
	
	int i,j;
	for (i=1 ; i< h-1; i++)
	{
		for (j=1 ; j<w-1 ; j++)
		{
			if(pImg1[i*w+j]==0) continue;
			if(pImg1[i*w+j-1]==0 || pImg1[i*w+j+1]==0 || 
				pImg1[(i+1)*w+j]==0 || pImg1[(i-1)*w+j]==0)
				pImg[i*w+j] = 0;
		}
	}
	BYTE* pBits = CImageBase::Get_lpBits(pDib);
	BYTE* pNewBits = CImageBase::MakeBinBitsFromImg(pImg,w,h);
	int bw = (w+31)/32*4;
	memcpy(pBits, pNewBits, bw*h);
	delete[] pImg;
	delete[] pImg1;
	delete[] pNewBits;
	
	return TRUE;
}

//�ٳ������� ������ ���� 2�������� ������  �����嶮�� �����ײ� �ܺ�
//�ٳ������� ��˧ ����ʯ̩ ���ɰ�˩�纷 ���� ��˼ ��˺�� �����ٳ�
//2�������� ��˧ ����ʯ�� �̲� ���˵��� 0�˵��� 0˺�� �����ٳ�
//                ����ʯ̩ ���� ���� 1���� 1�� �����ٳ�
//groupSize�� ������ ��̡ �� «��Ĵ�� ��������  �� 3��������  1�˰�(���� ����Ͳ� 9��̺�ϰ� �輬����ʿ �ٳ�) 
//            ������ ��̡ �� «��Ĵ�� ��������  2�˳�.
//���»�:Daydreamer
//���²���:2007�� 8̻  16��

BYTE* CImageFilter::MorphoErosion(BYTE *pImg, int w, int h,int groupSize,int* Mask)
{
	if (!pImg)
		return NULL;

	if (groupSize <1)
		return NULL;

	BYTE* pNew = new BYTE[w*h];

	int off = groupSize;
	int i,j,m;
	for (i = 0 ; i<off ; i++)
	{
		for (m =0; m<w ; m++){
			pNew[i*w + m] = pImg[i*w+m];
			pNew[(h-i-1)*w+m] = pImg[(h-i-1)*w+m];
		}

		for (m =0; m<h ; m++)
		{
			pNew[m*w+i] = pImg[m*w+i];
			pNew[m*w+w-i-1] = pImg[m*w+w-i-1];
			
		}	
	}

	int k,l;
	int index=0;

	for (i=off ; i< h-off; i++)
	{
		for (j=off ; j<w-off ; j++)
		{
			BYTE bBlack = 255;
			index  = 0 ;
			for (k=-off ; k<off+1; k++)
				for (l=-off ;l<off+1;l++)
				{
			        if  ((Mask[index] == 1) && pImg[(i+k)*w+j+l] < bBlack)
						bBlack = pImg[(i+k)*w+j+l];
					index++;
				}
			pNew[i*w+j] = bBlack;
		}
	}

	return pNew;
}

//�ٳ������� ������ ���� 2�������� ������  ¹�۽嶮�� �����ײ� �ܺ�
//�ٳ������� ��˧ ����ʯ̩ ���ɰ�˩�纷 ���� �� ��˺�� �����ٳ�
//2�������� ��˧ ����ʯ�� �̲� ���˵��� 1�˵��� 1�� �����ٳ�
//                ����ʯ̩ ���� ���� 0���� 0˺�� �����ٳ�
//groupSize�� ������ ��̡ �� «��Ĵ�� ��������  �� 3��������  1�˰� 
//            ������ ��̡ �� «��Ĵ�� ��������  2�˳�.
//���»�:Daydreamer
//���²���:2007�� 8̻  16��

BYTE* CImageFilter::MorphoDilation(BYTE *pImg, int w, int h, int groupSize,int* Mask)
{
	if (!pImg)
		return NULL;

	if (groupSize <1)
		return NULL;

	BYTE* pNew = new BYTE[w*h];

	int off = groupSize;
	int i,j,m;
	for (i = 0 ; i<off ; i++)
	{
		for (m =0; m<w ; m++){
			pNew[i*w + m] = pImg[i*w+m];
			pNew[(h-i-1)*w+m] = pImg[(h-i-1)*w+m];
		}

		for (m =0; m<h ; m++)
		{
			pNew[m*w+i] = pImg[m*w+i];
			pNew[m*w+w-i-1] = pImg[m*w+w-i-1];
		}	
	}

	int k,l;
	int index = 0 ;

	for (i=off ; i< h-off; i++)
	{
		for (j=off ; j<w-off ; j++)
		{
			index =0;
			BYTE bBlack = 0;
			for (k=-off ; k<off+1; k++)
				for (l=-off ;l<off+1;l++)
				{
			        if  ( Mask[index] == 1 && pImg[(i+k)*w+j+l] > bBlack)
						bBlack = pImg[(i+k)*w+j+l];
					index++;
				}
			pNew[i*w+j] = bBlack;
		}
	}
	return pNew;
}

//�ٳ������� ������ ���� 2�������� ������  Opening�嶮�� �����ײ� �ܺ�
//groupSize�� ������ ��̡ �� «��Ĵ�� ��������  �� 3��������  1�˰� 
//            ������ ��̡ �� «��Ĵ�� ��������  2�˳�.
//���»�:Daydreamer
//���²���:2007�� 8̻  16��

BYTE* CImageFilter::MorphoOpening(BYTE *pImg, int w, int h, int groupSize,int* Mask)
{
	BYTE* pNewImg = MorphoErosion(pImg,w,h,groupSize,Mask);
	BYTE* pRetImg = MorphoDilation(pNewImg,w,h,groupSize,Mask);
	delete [] pNewImg;pNewImg = NULL;
	return pRetImg;
}

//�ٳ������� ������ ���� 2�������� ������  Closing�嶮�� �����ײ� �ܺ�
//groupSize�� ������ ��̡ �� «��Ĵ�� ��������  �� 3��������  1�˰� 
//            ������ ��̡ �� «��Ĵ�� ��������  2�˳�.
//���»�:Daydreamer
//���²���:2007�� 8̻  16��
BYTE* CImageFilter::MorphoClosing(BYTE *pImg, int w, int h, int groupSize,int* Mask)
{
	BYTE* pNewImg = MorphoDilation(pImg,w,h,groupSize,Mask);
	BYTE* pRetImg = MorphoErosion(pNewImg,w,h,groupSize,Mask);
	delete [] pNewImg;pNewImg = NULL;
	return pRetImg;
}
unsigned int* CImageFilter::MakeIntegralImg(BYTE* pImg,int w,int h)
{
	int i,j;
	unsigned int partialsum;
	unsigned int* IntegralImage = new unsigned int[w*h];
	memset(IntegralImage,0,sizeof(unsigned int)*w*h);

	partialsum =  0;
	for(j=0;j<w;j++)
	{
		partialsum += pImg[j];
		IntegralImage[j] = partialsum;
	}
	for(i=1;i<h;i++)
	{
		partialsum =  0;
		for(j=0;j<w;j++)
		{
			partialsum += pImg[i*w+j];
			IntegralImage[i*w+j] = IntegralImage[(i-1)*w+j] + partialsum;
		}
	}
	return IntegralImage;
}
BYTE* CImageFilter::MeanFilter(BYTE* pImg, int w, int h, int nWinSize)
{
	if (pImg == NULL || w < 1 || h < 1)
		return NULL;
	if(nWinSize >= w - 1 || nWinSize >= h - 1)
		nWinSize = min(w, h) - 1;
	int i, j;
	int ww = w+1,hh=h+1;
	int size = ww * hh;
	int *IntImg = new int[size];
	memset(IntImg, 0, sizeof(int)* size);
	size = w * h;
	BYTE *NewImg = new BYTE[size];
	memset(NewImg, 0, size);
	int partialsum, pos, pos1, pos2;
	for(i = 0; i < h; i++)
	{
		partialsum  = 0;
		pos = i * ww;
		pos1 = i * w;
		IntImg[(i+1)*ww] = 0;
		for(j = 1; j <= w; j++)
		{
			partialsum += pImg[pos1 +j-1];
			IntImg[pos + ww + j] = IntImg[pos + j] + partialsum;
		}
	}

	int rw=nWinSize,rh=nWinSize,sum;
	int rnum = (rw*2)*(rh*2);
	for(i=rh;i<h-rh;i++)
	{
		pos = i * w;
		pos1 = (i - rh) * ww;
		pos2 = (i + rh) * ww;
		for(j=rw;j<w-rw;j++)
		{
			sum = IntImg[pos1 + j-rw] + IntImg[pos2 +j+rw] - IntImg[pos1 +j+rw] - IntImg[pos2 +j-rw];
			NewImg[pos+j] = sum>>12;
		}
	}
	int sty,edy,stx,edx,num=0;
	sty=0;
	for(i=0;i<rh;i++)
	{
		edy = min(h,(i+rh+1));
		pos = i * w;
		pos1 = edy * ww;
		for(j=0;j<w;j++)
		{
			stx = max(0,j-rw);
			edx = min(w,j+rw+1);
			sum = IntImg[stx] + IntImg[pos1 + edx] - IntImg[edx] - IntImg[pos1 + stx];
			sum = (sum )/((edy-sty)*(edx-stx));
			NewImg[pos +j] = sum;
		}
	}
	for(i=h-rh;i<h;i++)
	{
		sty=max(0,i-rh);
		edy = min(h,(i+rh+1));
		pos = i * w;
		pos1 = edy * ww;
		pos2 = sty * ww;
		for(j=0;j<w;j++)
		{
			stx = max(0,j-rw);
			edx = min(w,j+rw+1);
			sum = IntImg[pos2 +stx] + IntImg[pos1 +edx] - IntImg[pos2 +edx] - IntImg[pos1 +stx];

			sum = (sum)/((edy-sty)*(edx-stx));
			NewImg[pos +j] = sum;
		}
	}
	for(i=rh;i<h-rh;i++)
	{
		sty=max(0,i-rh);
		edy = min(h,(i+rh+1));
		pos = i * w;
		pos1 = edy * ww;
		pos2 = sty * ww;
		for(j=0;j<rw;j++)
		{
			stx = max(0,j-rw);
			edx = min(w,j+rw+1);
			sum = IntImg[pos2 +stx] + IntImg[pos1 +edx] - IntImg[pos2 +edx] - IntImg[pos1 +stx];

			sum = (sum)/((edy-sty)*(edx-stx));
			NewImg[pos +j] = sum;
		}
	}
	for(i=rh;i<h-rh;i++)
	{
		sty=max(0,i-rh);
		edy = min(h,(i+rh+1));
		pos = i * w;
		pos1 = edy * ww;
		pos2 = sty * ww;
		for(j=w-rw;j<w;j++)
		{
			stx = max(0,j-rw);
			edx = min(w,j+rw+1);
			sum = IntImg[pos2 +stx] + IntImg[pos1 +edx] - IntImg[pos2 +edx] - IntImg[pos1 +stx];

			sum = (sum)/((edy-sty)*(edx-stx));
			NewImg[pos+j] = sum;
		}
	}

	delete[] IntImg; IntImg = NULL;
	return NewImg;
}
void CImageFilter::MeanFilter(BYTE* pImg,int w,int h)
{
	int i,j,size;
	size = w * h;
	int* NewImg = new int[size];
	int p,pix = size;
	for(i=1;i<pix-1;i++){
		NewImg[i] = pImg[i-1] + pImg[i] + pImg[i+1];
	}
	for (i = 1; i < h - 1; i++) {
		int pos = i * w;
		for (j = 1; j < w - 1; j++)
		{
			p = pos + j;
			pImg[p] = BYTE((NewImg[p - w] + NewImg[p] + NewImg[p + w]) / 9);
		}
	}
	delete[] NewImg;
}
void CImageFilter::MedianFilter(BYTE* pImg,int w,int h)
{
	int i,j,ii,jj;
	BYTE c[9],buf;
	BYTE* NewImg = new BYTE[w*h];
	memcpy(NewImg,pImg,w*h);
	for(i=1;i<h-1;++i)for(j=1;j<w-1;j++){
		c[0] = NewImg[(i-1)*w+j-1];
		c[1] = NewImg[(i-1)*w+j];
		c[2] = NewImg[(i-1)*w+j+1];
		c[3] = NewImg[i*w+j-1];
		c[4] = NewImg[i*w+j];
		c[5] = NewImg[i*w+j+1];
		c[6] = NewImg[(i+1)*w+j-1];
		c[7] = NewImg[(i+1)*w+j];
		c[8] = NewImg[(i+1)*w+j+1];

		for(ii=0;ii<8;ii++){
			for(jj=ii+1;jj<9;jj++){
				if(c[ii] > c[jj]){
					buf = c[ii];c[ii] = c[jj];c[jj]=buf;
				}
			}
		}
		pImg[i*w+j] = c[4];
	}
	delete[] NewImg;
}
BYTE* CImageFilter::FilteringImage(BYTE *pImg, int w, int h, int groupSize,double* Filter)
{
	if (!pImg)
		return NULL;

	if (groupSize <1)
		return NULL;

	BYTE* pNew = new BYTE[w*h];
	
	int off = groupSize;
	int i,j,ii,jj,i1,j1;
	double s;
	for (i = 0 ; i<h ; i++)	for (j = 0 ; j<w ; j++)
	{
		s = 0.0;
		for (ii = -off ; ii<=off ; ii++)
		{
			i1 = i+ii;
			i1=min(h-1,max(0,i1));
			for (jj = -off ; jj<=off ; jj++)
			{
				j1 = j+jj;
				j1=min(w-1,max(0,j1));
				s += pImg[i1*w+j1]*Filter[(ii+off)*(2*off+1)+(jj+off)];
			}
		}
		pNew[i*w+j] =(BYTE) min(255,max(0,s));
	}
	return pNew;
}

BYTE* CImageFilter::FilteringImage(BYTE *pImg, int w, int h, double* Filter, int f_w, int f_h)
{
	if (!pImg)
		return NULL;
	
	if (w<1 || h<1 || f_w <1 || f_h<1)
		return NULL;
	
	BYTE* pNew = new BYTE[w*h];
	
	int off_x = f_w>>1;
	int off_y = f_h>>1;
	
	int i,j,ii,jj,i1,j1;
	double s;
	for (i = 0 ; i<h ; i++)	for (j = 0 ; j<w ; j++)
	{
		s = 0.0;
		for (ii = -off_y ; ii<f_h-off_y ; ii++)
		{
			i1 = i+ii;
			i1=min(h-1,max(0,i1));
			for (jj = -off_x ; jj<f_w-off_x ; jj++)
			{
				j1 = j+jj;
				j1=min(w-1,max(0,j1));
				s += pImg[i1*w+j1]*Filter[(ii+off_y)*f_w+(jj+off_x)];
			}
		}
		pNew[i*w+j] = 255 - (BYTE) min(255,max(0,s));
		//		if(pNew[i*w+j] > 50) pNew[i*w+j] = 255;
	}
	return pNew;
}

BOOL CImageFilter::CorrectBrightForCameraImg(BYTE* pImg,int w,int h)
{
	BYTE* pMeanImg = MeanFilter(pImg, w, h, 32);//13);//
	if(pMeanImg == NULL)
		return FALSE;
	int i;
	int minval = 255;
	int maxval = 0;
	int s=0;
	int wh=w*h;
	for(i=0;i<wh;i++)
	{
		if(pImg[i]>250)s++;
	}
	if(s/float(wh)>0.6f) 
	{
		delete []pMeanImg;
		return FALSE;
	}
	for(i=0;i<wh;i++)
	{
		if(pImg[i]>pMeanImg[i])
			pImg[i] = 255;
		else
		{
			pImg[i] = 255 + pImg[i] - pMeanImg[i];
			minval = min(pImg[i],minval);
		}
		maxval = max(pImg[i], maxval);
	}
	if(maxval>minval)
	{
		minval = min(maxval-1,minval+(maxval-minval)/3);
		for(i=0;i<wh;i++)
		{
			
			pImg[i] = BYTE(min(255,max(0,(pImg[i]-minval)*255/(maxval-minval))));
		}
	}
	delete[] pMeanImg;
	return TRUE;
}
// BOOL CImageFilter::CorrectBrightForCameraImg(BYTE* pImg,int w,int h)
// {
// 	BYTE* pMeanImg = MeanFilter(pImg,w,h,50);
// 	int i,j;
// 	int minval = 255;
// 	int maxval = 0;
// 	int Hist[256];
// 	memset(Hist,0,256*sizeof(int));
// 
// 	for(i=0;i<h;i++) for(j=0;j<w;j++)
// 	{
// 		int pos = i*w+j;
// 		if(pImg[pos]>pMeanImg[pos])
// 			pImg[pos] = 255;
// 		else
// 		{
// 			pImg[pos] = 255 + pImg[pos] - pMeanImg[pos];
// 		}
// 		minval = min(pImg[pos],minval);
// 		maxval = max(pImg[pos], maxval);
// 		Hist[pImg[pos]]++;
// 	}
// 	int sum=0;
// 	i=0;
// 	while(sum< w*h/200 && i<256)
// 	{
// 		sum+=Hist[i];
// 		i++;
// 	}
// 	minval = max(0, i-1);
// 	sum=0;
// 	i=255;
// 	while(sum< w*h/200 && i>=0)
// 	{
// 		sum+=Hist[i];
// 		i--;
// 	}
// 	maxval = min(255,i+1);
//
// 	if(maxval>minval)
// 	{
// 		for(i=0;i<h;i++) for(j=0;j<w;j++)
// 		{
// 			int pos = i*w+j;
// 			int val = (pImg[pos]-minval)*255/(maxval-minval);
// 			pImg[pos] = max(0,min(255,val));
// 		}
// 	}
// 
// 	delete[] pMeanImg;
// 	return TRUE;
// }
BYTE* CImageFilter::CorrectBrightForCameraDib(BYTE* pDib)
{
	if(pDib == NULL) return NULL;
	BYTE* pNewDib;
	int nBitCount = CImageBase::GetBitCount(pDib);
	if(nBitCount==1)
	{
		pNewDib = CImageBase::CopyDib(pDib);
	}
	else
	{
		int w,h;
		BYTE* pImg;
		if(nBitCount == 24)
			pImg = CImageBase::MakeGrayImgFrom24Dib(pDib,w,h);
		else if(nBitCount == 8)
			pImg = CImageBase::MakeImgFromGrayDib(pDib,w,h);
        else
            return NULL;
		
		BOOL bRet=CorrectBrightForCameraImg(pImg,w,h);
		MeanFilter(pImg,w,h);

		if(bRet==FALSE)
			pNewDib = CImageBase::CopyDib(pDib);
		else
			pNewDib = CImageBase::MakeGrayDibFromImg(pImg,w,h);

		delete[]pImg;
	}
	return pNewDib;
}


BOOL CImageFilter::GetEdgeExtractionImg_V_Sobel(BYTE* pImg,int w,int h,int* Edge,int Pecent)
{
	int nHist[2050];
	memset(nHist,0,sizeof(int)*2050);
	memset(Edge,0,sizeof(int)*w*h);
	int i,j,c,cc,Th;
	int totalPixCount = (w-2)*(h-2);
	if(totalPixCount<4) return FALSE;
	int removePixCount = totalPixCount*Pecent/100;
	float Sumc=0;
	int* pEdgeData;
	for(i=1;i<h-1;++i){
		pEdgeData = Edge+i*w;
		for(j=1;j<w-1;++j){
			cc = -pImg[(i-1)*w+j-1]-2*pImg[i*w+j-1]-pImg[(i+1)*w+j-1];
			cc += pImg[(i-1)*w+j+1]+2*pImg[i*w+j+1]+pImg[(i+1)*w+j+1];
			c = abs(cc);
			Sumc+=(float)c;
			pEdgeData[j] = c;
			nHist[c]++;
		}
	}
	if(Pecent<1) Th = (int)((4*Sumc)/totalPixCount);
	else{
		int sumCount=0;
		for(i=0;i<2050;++i){
			sumCount+=nHist[i];
			if(sumCount>=removePixCount) break;
		}
		if(i==1000) Th = 999;
		else if(sumCount-removePixCount > removePixCount - sumCount+nHist[i])
			Th = i-1;
		else Th = i;

	}
	BYTE* pImgData;
	for(i=0;i<h;++i){
		pEdgeData = Edge+i*w;
		pImgData = pImg+i*w;
		for(j=1;j<w-1;++j){
			c = pEdgeData[j];
			if(c > Th && c>=pEdgeData[j-1] && c>=pEdgeData[j+1])
				pImgData[j] = 255;//(BYTE)c;
			else
				pImgData[j] = 0;//(BYTE)c;
		}
	}
	for(i=0;i<h;++i){
		pImg[i*w] = 0;
		pImg[i*w+w-1] = 0;
	}
	return TRUE;
}

void CImageFilter::RemoveLongAndShortLine_speed(BYTE *pImg, int w, int h,int Th_short,int Th_long)
{
	int i,j,value,temp;
	BYTE* pImgData;
/////////////////////////////////////////////////
	int* M = new int[w*h];
	memset(M,0,sizeof(int)*w*h);
	for(i=2;i<h-2;++i){
		pImgData = pImg+i*w;
		for(j=2;j<w-2;++j){
			if(pImgData[j]==0)continue;
			if(pImg[(i-1)*w+j-1]+pImg[(i-1)*w+j]
				+pImg[(i-1)*w+j+1]+pImg[(i)*w+j-1] > 0 )
			{
				value = M[(i-1)*w+j-1];
				temp = M[(i-1)*w+j];
				value = max(value,temp);
				temp = M[(i-1)*w+j+1];
				value = max(value,temp);
				temp = M[(i)*w+j-1];
				value = max(value,temp);
				M[(i)*w+j] = value+1;
			}else{
				value = M[(i-2)*w+j-1];
				temp = M[(i-2)*w+j];
				value = max(value,temp);
				temp = M[(i-2)*w+j+1];
				value = max(value,temp);
				temp = M[(i-1)*w+j-2];
				value = max(value,temp);
				temp = M[(i-1)*w+j+2];
				value = max(value,temp);
				temp = M[(i)*w+j-2];
				value = max(value,temp);
				M[(i)*w+j] = value+1;
			}
		}
	}
//////////////////////////////////////////////////
	int* NN = new int[w*h];
	memset(NN,0,sizeof(int)*w*h);
	for(i=h-3;i>1;i--){
		pImgData = pImg+i*w;
		for(j=w-3;j>1;j--){
			if(pImgData[j]==0)continue;
			if(pImg[(i+1)*w+j-1]+pImg[(i+1)*w+j]
				+pImg[(i+1)*w+j+1]+pImg[(i)*w+j+1] > 0 )
			{
				value = NN[(i+1)*w+j-1];
				temp = NN[(i+1)*w+j];
				value = max(value,temp);
				temp = NN[(i+1)*w+j+1];
				value = max(value,temp);
				temp = NN[(i)*w+j+1];
				value = max(value,temp);
				NN[(i)*w+j] = value+1;
			}else{
				value = NN[(i+2)*w+j-1];
				temp = NN[(i+2)*w+j];
				value = max(value,temp);
				temp = NN[(i+2)*w+j+1];
				value = max(value,temp);
				temp = NN[(i+1)*w+j-2];
				value = max(value,temp);
				temp = NN[(i+1)*w+j+2];
				value = max(value,temp);
				temp = NN[(i)*w+j+2];
				value = max(value,temp);
				NN[i*w+j] = value+1;
			}
		}
	}
/////////////////////////////////////////////
	int *pM,*pNN;

	for(i=0;i<h;++i){
		pImgData = pImg+i*w;
		pM = M+i*w;
		pNN = NN+i*w;
		for(j=0;j<w;++j){
			if(pImgData[j]==0) continue;
			value = pM[j]+pNN[j];
			if(value>Th_long || value<Th_short)
				pImgData[j]=0;
		}
	}
	delete[] M;M=NULL;
	delete[] NN;NN=NULL;
}

void CImageFilter::GetSortValueOrder(float* fValue,int* Ord,int n,int Direct/*=0*/)
{
	int i,j,tm;
	float d;
	for(i=0;i<n;i++)	Ord[i]=i;	//distance  number
	if(Direct == 0){
		for(i=0;i<n;i++)
		{
			d=fValue[Ord[i]];
			for (j = i+1; j <n; j++)
			{
				if ( d> fValue[Ord[j]] )
				{ 
					tm =  Ord[j] ;  Ord[j] = Ord[i] ; Ord[i] = tm;    
					d=fValue[Ord[i]]; 
				} 
			}	
		}
	}
	else{
		for(i=0;i<n;i++)
		{
			d=fValue[Ord[i]];
			for (j = i+1; j <n; j++)
			{
				if ( d< fValue[Ord[j]] )
				{ 
					tm =  Ord[j] ;  Ord[j] = Ord[i] ; Ord[i] = tm;    
					d=fValue[Ord[i]]; 
				} 
			}	
		}
	}
}

void CImageFilter::My_pre_process(BYTE *buffer, int width, int height)
{
	int h;
	int wh = height*width;
	double mean=0;
	
	// get mean of image luminance
	for (h = 0; h < wh; h++)
		mean += buffer[h] ;
	mean /= ((double) wh );
	
	// move mean of image to value 30;
	for (h = 0; h <  wh; h++)
	{
		double buf =  (double)buffer[h] - mean + 30;
		if (buf < 0) buf = 0;
		if (buf > 255) buf = 255;
		buf =  buf + mean - 30;
		if (buf < 0) buf = 0;
		if (buf > 255) buf = 255;
		buffer[h] = (BYTE)buf;
	}
}
static int ki[8]={-1,-1,0,1,1,1,0,-1};
static int kj[8]={0,1,1,1,0,-1,-1,-1};

BOOL CImageFilter::GetEdgeExtractionImg(BYTE* pImg,int w,int h,int Th,CRect SubRt,int* Edge)
{
	int x0=SubRt.left,x1=SubRt.right,y0=SubRt.top,y1=SubRt.bottom;
	int i,j,k,r,max,min,g,m,nHist[256];
	int ki1[2]={-1,1};
	int kj1[2]={0,0};
	int Edge_th[256];
	int tmin,tmax,med,zi,zj;
	{
		int	wid = x1-x0,high = y1-y0 ;
		memset(nHist,0,sizeof(int)*256);
		for(i=y0;i<y1;i++)for(j=x0;j<x1;j++)	nHist[pImg[i*w+j]]++;
		for(k=0,i=0;i<256;i++){
			k+=nHist[i];
			if(k>(wid)) {tmin=i;break;}// min gray level 
		}
		for(k=0,i=255;i>=0;i--){
			k+=nHist[i];
			if(k>(wid)) {tmax=i;break;}// max gray level
		}
		for(k=0,j=0,i=tmin;i<=tmax;i++){	k+=(nHist[i]*i);j+=nHist[i];}
		med=k/j;//Average Brightness
	}

	if((tmax-tmin)<=0){
		//		AfxMessageBox("Can not Extract Edge!");
		return FALSE;
	}

	BYTE* pImg1 = new BYTE[w*h];
	memset(pImg1,0,w*h);
	memset(Edge,0,sizeof(int)*w*h);
	Edge_th[0]=(int)((tmax-tmin)/(float)Th+0.5);//40;//10;//20;

	for(j=y0;j<y1;j++)for(i=x0;i<x1;i++)
	{
		min=256;max=0;
		for(k=0;k<8;k++)
		{
			zj = j+kj[k]; zi = i+ki[k];
			if(zj<y0 || zj>=y1 || zi<x0 || zi>=x1) continue;
			max = max(max,pImg[zj*w+zi]);
			min = min(min,pImg[zj*w+zi]);
		}
		g=pImg[j*w+i];
		if((min==256)&&(max==0)) max=min=g;
		//if(fabs(s-(double)g)<Edge_th[0]/8)max=min=g;
		k=g-min;m=g-max;
		if(abs(k)<abs(m)) k=m;
		r=abs(k);			
		if(r<Edge_th[0]) pImg1[j*w+i]=100;//no_edge point
		else
		{
			Edge[j*w+i]=k;
			if(k<0)	pImg1[j*w+i]=0;
			else	pImg1[j*w+i]=255;
		}
	}
	//return EdgeSum;
	//Contour noise deletion
	int* Edge1 = new int[w*h];
	memcpy(Edge1,Edge,sizeof(int)*w*h);
	memcpy(pImg,pImg1,w*h);
	for(j=y0;j<y1;j++)for(i=x0;i<x1;i++)
	{
		if(pImg1[j*w+i]==100) continue;
		min=max=Edge1[j*w+i];
		m = 0;
		for(k=0;k<8;k++)
		{
			zj = j+kj[k]; zi = i+ki[k];
			if(zj<y0 || zj>=y1 || zi<x0 || zi>=x1) continue;
			if(pImg1[j*w+i] != pImg1[zj*w+zi]) m++;
			if(pImg1[zj*w+zi]==100) continue;
			if(abs(max)<abs(Edge1[zj*w+zi])) max=Edge1[zj*w+zi];
		}
		g=abs(Edge1[j*w+i]);
		k=abs(max)/2;
		if(g<=k || m==8){
			pImg[j*w+i] = 100;//no_edge point
			Edge[j*w+i] = 0;
		}
	}
	delete[] pImg1;pImg1=NULL;
	delete[] Edge1;Edge1=NULL;
	return TRUE;
}
BYTE* CImageFilter::GetEdgeExtractionImgWindow(BYTE* pImg,int w,int h,int Th)
{
	int i,j;
	int ww = w+1,hh=h+1;
	BYTE* pNewImg = new BYTE[w*h];
	memset(pNewImg,0,w*h);
	int *IntImg = new int[ww*hh];
	int* Edge = new int[w*h];
	for(i=0;i<=w+1;i++) IntImg[i]=0;
	int partialsum;
	int* pIntBuff,*preIntBuff;
	BYTE* pImgBuff;
	for(i=1;i<=h;i++)
	{
		partialsum  = 0;
		pIntBuff = &IntImg[i*ww];
		preIntBuff = pIntBuff-ww;
		pImgBuff = &pImg[(i-1)*w];
		*pIntBuff = 0;
		preIntBuff++;pIntBuff++;
		for(j=1;j<=w;j++)
		{
			partialsum += *pImgBuff;pImgBuff++;
			*(pIntBuff) = *(preIntBuff) + partialsum;
			preIntBuff++;pIntBuff++;
		}
	}
	int rw=3,rh=3,sum;
	memset(Edge,0,w*h);
	for(i=rh;i<h-rh;i++)
	{
		preIntBuff = &IntImg[(i-rh)*ww];
		pIntBuff = &IntImg[(i+rh+1)*ww];
		pImgBuff = &pImg[i*w];
		for(j=rw;j<w-rw;j++)
		{
			sum = preIntBuff[j-rw] + pIntBuff[j+rw+1] - preIntBuff[j+rw+1] - pIntBuff[j-rw];
			partialsum = pImgBuff[j]+ pImgBuff[j-1] + pImgBuff[j+1] + *(pImgBuff-w+j) + *(pImgBuff+w+j);
			sum = (sum - partialsum)/44;
			partialsum = partialsum/5;
			Edge[i*w+j] = sum-partialsum;
		}
	}
	int sty,edy,stx,edx,num=0;
	sty=0;
	for(i=0;i<rh;i++)
	{
		preIntBuff = IntImg;
		edy = min(h,(i+rh+1));
		pIntBuff = &IntImg[edy*ww];
		pImgBuff = &pImg[i*w];
		for(j=0;j<w;j++)
		{
			stx = max(0,j-rw);
			edx = min(w,j+rw+1);
			sum = preIntBuff[stx] + pIntBuff[edx] - preIntBuff[edx] - pIntBuff[stx];
			partialsum = pImgBuff[j] + *(pImgBuff+w+j);
			num=2;
			if(i>0) {partialsum += *(pImgBuff-w+j);num++;}
			if(j>0) {partialsum += pImgBuff[j-1] ;num++;}
			if(j<w-1) {partialsum += pImgBuff[j+1]  ;num++;}
			
			sum = (sum - partialsum)/((edy-sty)*(edx-stx)-num);
			partialsum = partialsum/num;
			Edge[i*w+j] = sum-partialsum;
		}
	}
	for(i=h-rh;i<h;i++)
	{
		sty=max(0,i-rh);
		preIntBuff = &IntImg[sty*ww];
		edy = min(h,(i+rh+1));
		pIntBuff = &IntImg[edy*ww];
		pImgBuff = &pImg[i*w];
		for(j=0;j<w;j++)
		{
			stx = max(0,j-rw);
			edx = min(w,j+rw+1);
			sum = preIntBuff[stx] + pIntBuff[edx] - preIntBuff[edx] - pIntBuff[stx];
			partialsum = pImgBuff[j] + *(pImgBuff-w+j);
			num=2;
			if(i<h-1) {partialsum += *(pImgBuff+w+j);num++;}
			if(j>0) {partialsum += pImgBuff[j-1] ;num++;}
			if(j<w-1) {partialsum += pImgBuff[j+1]  ;num++;}
			
			sum = (sum - partialsum)/((edy-sty)*(edx-stx)-num);
			partialsum = partialsum/num;
			Edge[i*w+j] = sum-partialsum;
		}
	}
	for(i=rh;i<h-rh;i++)
	{
		sty=max(0,i-rh);
		preIntBuff = &IntImg[sty*ww];
		edy = min(h,(i+rh+1));
		pIntBuff = &IntImg[edy*ww];
		pImgBuff = &pImg[i*w];
		for(j=0;j<rw;j++)
		{
			stx = max(0,j-rw);
			edx = min(w,j+rw+1);
			sum = preIntBuff[stx] + pIntBuff[edx] - preIntBuff[edx] - pIntBuff[stx];
			partialsum = pImgBuff[j] + *(pImgBuff-w+j);
			num=2;
			if(i<h-1) {partialsum += *(pImgBuff+w+j);num++;}
			if(j>0) {partialsum += pImgBuff[j-1] ;num++;}
			if(j<w-1) {partialsum += pImgBuff[j+1]  ;num++;}
			
			sum = (sum - partialsum)/((edy-sty)*(edx-stx)-num);
			partialsum = partialsum/num;
			Edge[i*w+j] = sum-partialsum;
		}
	}
	for(i=rh;i<h-rh;i++)
	{
		sty=max(0,i-rh);
		preIntBuff = &IntImg[sty*ww];
		edy = min(h,(i+rh+1));
		pIntBuff = &IntImg[edy*ww];
		pImgBuff = &pImg[i*w];
		for(j=w-rw;j<w;j++)
		{
			stx = max(0,j-rw);
			edx = min(w,j+rw+1);
			sum = preIntBuff[stx] + pIntBuff[edx] - preIntBuff[edx] - pIntBuff[stx];
			partialsum = pImgBuff[j] + *(pImgBuff-w+j);
			num=2;
			if(i<h-1) {partialsum += *(pImgBuff+w+j);num++;}
			if(j>0) {partialsum += pImgBuff[j-1] ;num++;}
			if(j<w-1) {partialsum += pImgBuff[j+1]  ;num++;}
			
			sum = (sum - partialsum)/((edy-sty)*(edx-stx)-num);
			partialsum = partialsum/num;
			Edge[i*w+j] = sum-partialsum;
		}
	}
	delete[] IntImg;
	for(i=0;i<h*w;i++)
	{
		if(Edge[i]>Th) {pNewImg[i] = 1;continue;}
		//if(Edge[i]<-Th) {Edge[i] = 255;continue;}
		//pImg[i] = 0;
	}
	delete[] Edge;
	return pNewImg;
}
void CImageFilter::EnhanceVertLine(BYTE *pImg, int w, int h)
{
	int i,j,c,cc,mx,mn;
	int* Temp = new int[w*h];
	memset(Temp,0,w*h*sizeof(int));
	mn = 1000; mx = 0;
	for(i=2;i<h-2;++i)for(j=3;j<w-3;++j)
	{
		cc = c = 0;
		cc = -pImg[(i-2)*w+j-1]-pImg[(i-1)*w+j-1]-2*pImg[i*w+j-1]-pImg[(i+1)*w+j-1]-pImg[(i+2)*w+j-1];
		cc += pImg[(i-2)*w+j+1]+pImg[(i-1)*w+j+1]+2*pImg[i*w+j+1]+pImg[(i+1)*w+j+1]+pImg[(i+2)*w+j+1];
		c = abs(cc);	
		if(cc<0){
			Temp[i*w+j+2]+=c;
			Temp[i*w+j+3]+=c/2;
		}
		if(cc>0){
			Temp[i*w+j-2]+=c;
			Temp[i*w+j-3]+=c/2;
		}
		mx = max(mx,c);
		mn = min(mn,c);
	}
	float rat = 100.0f/(mx-mn+0.01f);
	
	for(i=0;i<w*h;++i)
	{
		cc = Temp[i];
		cc  = (int)((cc-mn)*rat);
		cc = max(0,cc);
		cc = min(50,cc);
		cc = pImg[i] - cc;
		cc = max(0,cc);cc = min(255,cc);
		pImg[i] = (BYTE)cc;
	}

	delete[] Temp;
}
BOOL CImageFilter::GetSharpnessQuantity(BYTE* pImg,int w,int h)
{
	int nHist[1050];
	memset(nHist,0,sizeof(int)*1050);
	int* Edge = new int[w*h];
	memset(Edge,0,sizeof(int)*w*h);
	int i,j,k,c,cc,Th;
	int totalPixCount = (w-2)*(h-2);
	if(totalPixCount<4) return FALSE;
	int removePixCount = totalPixCount*95/100;
	float Sumc=0;
	int* pEdgeData;
	for(i=1;i<h-1;++i){
		pEdgeData = Edge+i*w;
		for(j=1;j<w-1;++j){
			cc = -pImg[(i-1)*w+j-1]-2*pImg[i*w+j-1]-pImg[(i+1)*w+j-1];
			cc += pImg[(i-1)*w+j+1]+2*pImg[i*w+j+1]+pImg[(i+1)*w+j+1];
			c = abs(cc);
			Sumc+=(float)c;
			pEdgeData[j] = c;
			nHist[c]++;
		}
	}
	int sumCount=0;
	for(i=0;i<1050;++i){
		sumCount+=nHist[i];
		if(sumCount>=removePixCount) break;
	}
	if(i>=1000) Th = 999;
	else if(sumCount-removePixCount > removePixCount - sumCount+nHist[i])
		Th = i-1;
	else Th = i;
		
	BYTE* pImgData;
	int DoM,II;
	float Sx,ThSx=1.8f,sumSx=0;
	int Edgenum=0,SharpNum = 0;
	for(i=0;i<h;++i){
		pEdgeData = Edge+i*w;
		pImgData = pImg+i*w;
		for(j=7;j<w-7;++j){
			c = pEdgeData[j];
			if(c > Th /*&& c>=pEdgeData[j-1] && c>=pEdgeData[j+1]*/)
			{
				Edgenum++;
				DoM=0;II=0;
				for(k=j-2;k<=j+2;k++)
				{
					cc= abs(pImgData[k+2]-pImgData[k])-abs(pImgData[k]-pImgData[k-2]);
					DoM += abs(cc);
					c = pImgData[k] - pImgData[k-1];
					II += abs(c);
				}
				if(II==0)Sx=0.0f;
				else Sx = (float)DoM/(float)II;
				if(Sx>ThSx) SharpNum++;
				sumSx += Sx;
			}
		}
	}


	delete[] Edge; Edge = NULL;
	if(Edgenum<=10) return FALSE;
	sumSx = sumSx/(float)Edgenum;
	Sx = (float)SharpNum/(float)Edgenum;

	if(Sx<0.2f) return FALSE;
	return TRUE;
}
BOOL CImageFilter::Contrast_Enhancement(BYTE* Img,int w,int h)
{
	CRect subRt = CRect(0,0,w,h);
	return Contrast_EnhancementInSubRt(Img,w,h,subRt);
}
BOOL CImageFilter::Contrast_EnhancementInSubRt(BYTE* Img,int w,int h,CRect subRt,BOOL bAllArea/*=TRUE*/,BOOL bForce/*=TRUE*/)
{	
	int tmin,tmax;
	return Contrast_EnhancementInSubRt(Img,w,h,subRt,tmin,tmax,bAllArea,bForce);
}
BOOL CImageFilter::Contrast_EnhancementInSubRt(BYTE* Img,int w,int h,CRect subRt,int& tmin,int& tmax,BOOL bAllArea/*=TRUE*/,BOOL bForce/*=TRUE*/)
{	
	int x0,x1,y0,y1;
	int i,j,k=0,c,med;
	int n[256];
	tmin=0;tmax=0;
	CHistogram::GetHistogram(Img,w,h,subRt,n,tmin,tmax);
	if((tmax-tmin)<=0) return FALSE;
	if(bForce == FALSE && tmax-tmin>70) return FALSE;
	k=0;j=0;
	for(i=tmin;i<=tmax;i++) { k+=(n[i]*i);j+=n[i];}
	med=k/j;//Average Brightness

	if(bAllArea == TRUE)	{ x0 = 0; y0 = 0; x1 = w; y1 = h; }
	else					{ x0 = subRt.left,x1=subRt.right,y0=subRt.top,y1=subRt.bottom;
	}

	//Brightness Correction
	med=128-med;
	for(i=y0;i<y1;i++)for(j=x0;j<x1;j++)
	{
		k=Img[i*w+j]+med;
		if(k<0) k=0;
		if(k>255) k=255;
		Img[i*w+j]=(BYTE)k;
	}
	tmin=tmin+med;
	if(tmin<0) tmin=0;if(tmin>255) tmin=255;
	tmax=tmax+med;
	if(tmax<0) tmax=0;if(tmax>255) tmax=255;
	if( tmax-tmin <= 5) return FALSE;

	//Contrast Enhancement
	for(i=y0;i<y1;i++)for(j=x0;j<x1;j++)
	{
		k=Img[i*w+j];
		c=(255*(k-tmin))/(tmax-tmin);
		if(c<0) c=0;
		if(c>255)c=255;
		Img[i*w+j]=(BYTE)c;
	}
	return TRUE;
}
BOOL CImageFilter::Shade_Enhancement(BYTE* Img,int w,int h,CRect subRt)
{	
	int tmin,tmax;
	BOOL bAllArea = TRUE;
	int x0,x1,y0,y1;
	int i,j,k=0,c,med;
	int n[256];
	tmin=0;tmax=0;
	CHistogram::GetHistogram(Img,w,h,subRt,n,tmin,tmax);
	if((tmax-tmin)<=0) return FALSE;
	k=0;j=0;
	for(i=tmin;i<=tmax;i++) { k+=(n[i]*i);j+=n[i];}
	med=k/j;//Average Brightness

	if(bAllArea == TRUE)	{ x0 = 0; y0 = 0; x1 = w; y1 = h; }
	else					{ x0 = subRt.left,x1=subRt.right,y0=subRt.top,y1=subRt.bottom;
	}

	//Brightness Correction
	med=250-med;
	for(i=y0;i<y1;i++)for(j=x0;j<x1;j++)
	{
		k=Img[i*w+j]+med;
		if(k<0) k=0;
		if(k>255) k=255;
		Img[i*w+j]=(BYTE)k;
	}
	tmin=tmin+med;
	if(tmin<0) tmin=0;if(tmin>255) tmin=255;
	tmax=tmax+med;
	if(tmax<0) tmax=0;if(tmax>255) tmax=255;
	if( tmax-tmin <= 5) return FALSE;

	//Contrast Enhancement
	for(i=y0;i<y1;i++)for(j=x0;j<x1;j++)
	{
		k=Img[i*w+j];
		c=(255*(k-tmin))/(tmax-tmin);
		if(c<0) c=0;
		if(c>255)c=255;
		Img[i*w+j]=(BYTE)c;
	}
	return TRUE;
}
void CImageFilter::BoldImg(BYTE *Img1,int w,int h)
{
	int i,j,i0,j0,i1,j1;
	BYTE *Img2 = new BYTE[w*h];
	memcpy(Img2,Img1,w*h);
	for (i=0;i<h;i++) for (j=0;j<w;j++){
		if (Img2[i*w+j]==1){
			for (i0=-1;i0<2;i0++) for (j0=-1;j0<2;j0++){
				i1=i+i0;j1=j+j0;
				if(i1<0 || i1>h-1) continue;
				if(j1<0 || j1>w-1) continue;
				Img1[i1*w+j1]=1;
			}
		}
	}
	delete[] Img2;Img2 = NULL;
}
///////////////////////////////
void CImageFilter::imDilate(BYTE* pbImg, BYTE* pbOut, int nW, int nH, int Ksize)
{
	if (!pbImg || !pbOut) return;

	int k2 = Ksize / 2;
	int kmax = Ksize - k2;
	BYTE byMax;

	for (int y = 0; y<nH; y++)
	{
		for (int x = 0; x<nW; x++)
		{
			byMax = 0;
			for (int j = -k2; j<kmax; j++)
			{
				for (int k = -k2; k<kmax; k++) {
					if (0 <= y + k && y + k<nH && 0 <= x + j && x + j<nW)
					{
						if (pbImg[(y + k)*nW + (x + j)] > byMax)
							byMax = pbImg[(y + k)*nW + (x + j)];
					}
				}
			}
			pbOut[y*nW + x] = byMax;
		}
	}
}

void CImageFilter::imErode(BYTE* pbImg, BYTE* pbOut, int nW, int nH, int Ksize)
{
	if (!pbImg || !pbOut) return;

	int k2 = Ksize / 2;
	int kmax = Ksize - k2;
	BYTE byMin;

	for (int y = 0; y<nH; y++)
	{
		for (int x = 0; x<nW; x++)
		{
			byMin = 255;
			for (int j = -k2; j<kmax; j++)
			{
				for (int k = -k2; k<kmax; k++) {
					if (0 <= y + k && y + k<nH && 0 <= x + j && x + j<nW)
					{
						if (pbImg[(y + k)*nW + (x + j)] < byMin)
							byMin = pbImg[(y + k)*nW + (x + j)];
					}
				}
			}
			pbOut[y*nW + x] = byMin;
		}
	}
}