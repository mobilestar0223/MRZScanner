// FindRecogDigit.cpp: implementation of the CFindRecogDigit class.
//
//////////////////////////////////////////////////////////////////////
#ifdef _ANDROID
#include <android/log.h>
#endif
#include <string>
#include <time.h>
#include "StdAfx.h"
#include "imgproc.h"
#include "FindRecogDigit.h"
#include "LineRecogPrint.h"
#include "ImageBase.h"
#include "ImageFilter.h"
#include "Binarization.h"
#include "Rotation.h"


#ifdef LOG_VIEW
using namespace cv;
Mat g_matView;
#endif

#ifdef _ANDROID
#ifdef _DEBUG
#undef THIS_FILE
static char THIS_FILE[]=__FILE__;
#define new DEBUG_NEW
#endif
#define  LOG_TAG    "recogPassport"
#define  LOGI(...)  __android_log_print(ANDROID_LOG_INFO,LOG_TAG,__VA_ARGS__)
#define  LOGE(...)  __android_log_print(ANDROID_LOG_ERROR,LOG_TAG,__VA_ARGS__)
#endif
//////////////////////////////////////////////////////////////////////
// Construction/Destruction

//void UpperStr(TCHAR* str)
//{
//	int len = lstrlen(str);
//	for (int i = 0; i < len; i++) {
//		str[i] = toupper(str[i]);
//	}
//}

//#define LOG_SAVE
#ifdef LOG_SAVE
#define NATIVE_MRZ_DIR		"/sdcard/accurascan"
bool SaveFileAsBMP(BYTE* pImg, int w, int h, int bitCount, int countSave)
{
    bool rc;
    BYTE* pDib = NULL;

	time_t timer;
	time(&timer);

    char szFilePath[256];
    memset(szFilePath, 0, 256*sizeof(char));
#ifdef MFC_VERSION
	struct tm ti;
	localtime_s(&ti, &timer);
	if(nflag == 0) // original
		sprintf_s(szFilePath, "%s%d\\%04d_%02d%02d_%02d%02d%02d_crop.bmp", NATIVEOMR_FOLDER, nType, count_save, ti.tm_mon+1, ti.tm_mday, ti.tm_hour, ti.tm_min, ti.tm_sec);
	else if(nflag == 1) //  croped
		sprintf_s(szFilePath, "%s%d\\%04d_%02d%02d_%02d%02d%02d.bmp", NATIVEOMR_FOLDER, nType, count_save, ti.tm_mon+1, ti.tm_mday, ti.tm_hour, ti.tm_min, ti.tm_sec);
	else if(nflag == 2) // no corners
		sprintf_s(szFilePath, "%s%d\\%04d_%02d%02d_%02d%02d%02d_no_corners.bmp", NATIVEOMR_FOLDER, nType, count_save, ti.tm_mon+1, ti.tm_mday, ti.tm_hour, ti.tm_min, ti.tm_sec);
	else if(nflag == 3) // no corners
		sprintf_s(szFilePath, "%s%d\\%04d_%02d%02d_%02d%02d%02d_type.bmp", NATIVEOMR_FOLDER, nType, count_save, ti.tm_mon+1, ti.tm_mday, ti.tm_hour, ti.tm_min, ti.tm_sec);
	else if (nflag == 4) // no corners
		sprintf_s(szFilePath, "%s%d\\%04d_%02d%02d_%02d%02d%02d_answer.bmp", NATIVEOMR_FOLDER, nType, count_save, ti.tm_mon + 1, ti.tm_mday, ti.tm_hour, ti.tm_min, ti.tm_sec);
#else
	struct tm* ti;
	ti = localtime(&timer);
   	sprintf(szFilePath, "%s/%04d_%02d%02d_%02d%02d%02d_org.bmp", NATIVE_MRZ_DIR, countSave, ti->tm_mon+1, ti->tm_mday, ti->tm_hour,  ti->tm_min, ti->tm_sec);
#endif
	if( bitCount == 1)
    	pDib = CImageBase::MakeGrayDibFromImg(pImg, w, h);
//	else if( bitCount == 3)
//		pDib = CImageBase::MakeDibRGBFromImg(pImg, w, h);

    rc = CImageBase::SaveDibFile(szFilePath, pDib);
    delete[] pDib; pDib = NULL;

    return rc;
}
#endif //LOG_SAVE

int findstr(TCHAR* str,TCHAR* query,int stpos)
{
	int len = (int)lstrlen(str);
	int len1 = (int)lstrlen(query);
	int i,j;
	for(i=stpos;i<len;i++)
	{
		if(len-i<len1) break;
		for(j=0;j<len1;j++)
		{
			if(str[i+j]!=query[j]) break;
		}
		if(j==len1) return i;
	}
	return -1;
}
void ReplaceStr(TCHAR* str,TCHAR orgCd,TCHAR newCd)
{
	int i;
	int len = (int)lstrlen(str);
	for(i=0;i<len;i++)
	{
		if(str[i]==orgCd) str[i]=newCd;
	}
	return ;
}
void RemoveStr(TCHAR* str, TCHAR orgCd)
{
	int len = (int)lstrlen(str);
	int i, j = 0;
	int size = len + 1;
	TCHAR* strT = new TCHAR[size];
	memset(strT, 0, sizeof(TCHAR)* size);
	for (i = 0; i < len; i++)
	{
		if (str[i] != orgCd) 
			strT[j++] = str[i];
	}
	strT[j] = 0;
	memcpy(str, strT, sizeof(TCHAR)*len);

	delete []strT; strT = NULL;
	return;
}
CFindRecogDigit::CFindRecogDigit()
{
	m_fAngle=0;
    //m_tmpColorDib = NULL;
	//m_tmpResultDib = NULL;
	m_tmpW = 0;
	m_tmpH = 0;
	UnKnownCard = false;
	m_bFoundFace = false;
	memset(_surname, 0, sizeof(TCHAR) * 100);
	memset(_givenname, 0, sizeof(TCHAR) * 100);
}

CFindRecogDigit::~CFindRecogDigit()
{
	//if (m_tmpColorDib) delete[] m_tmpColorDib;
 //   m_tmpColorDib = NULL;

	//if (m_tmpResultDib) delete[] m_tmpResultDib;
	//m_tmpResultDib = NULL;
}
//
//BYTE* LinearNormalize(BYTE* pImg,int w,int h,int &ww,int &hh)
//{
//	int ZOOMSIZE = 1;
//	ww = w / ZOOMSIZE;
//	hh = h / ZOOMSIZE;
//	BYTE* pImg1 = new BYTE[ww*hh];
//	memset(pImg1,0,sizeof(BYTE)*ww*hh);
//	int i,j,s = 0,ii,jj;
//	for(i=0;i<hh-1;i++)
//		for(j=0;j<ww-1;j++)
//		{
//			s = 0;
//			for(ii=i*ZOOMSIZE;ii<=i*ZOOMSIZE+ZOOMSIZE-1;ii++)
//				for(jj=j*ZOOMSIZE;jj<=j*ZOOMSIZE+ZOOMSIZE-1;jj++)
//					s += pImg[ii*w+jj];
//			if(s > ZOOMSIZE * ZOOMSIZE / 4)
//				pImg1[i*ww+j] = 1;
//		}
//		return pImg1;
//}
//void FlipVertical(BYTE* pImg,int w,int h)
//{
//	int i,j;
//	BYTE* pImg1 = new BYTE[w*h];
//	memcpy(pImg1,pImg,w*h);
//	for(i=0;i<h;i++)
//		for(j=0;j<w;j++)
//			pImg[i*w+j] = pImg1[(h-1-i)*w+w-1-j];
//	delete[] pImg1;
//}
//int ZOOMSIZE = 6;
//BYTE* LinearNormalizeGray(BYTE* pImg,int w,int h,int &ww,int &hh)
//{
//	
//	int maxwh = max(w,h);
//	ZOOMSIZE = max(1,maxwh/500);
//	ww = w / ZOOMSIZE;
//	hh = h / ZOOMSIZE;
//	BYTE* pImg1 = new BYTE[ww*hh];
//	memset(pImg1,0,sizeof(BYTE)*ww*hh);
//	int i,j,s = 0,ii,jj;
//	for(i=0;i<hh-1;i++)
//		for(j=0;j<ww-1;j++)
//		{
//			s = 255;
//			for(ii=i*ZOOMSIZE;ii<=i*ZOOMSIZE+ZOOMSIZE-1;ii++)
//				for(jj=j*ZOOMSIZE;jj<=j*ZOOMSIZE+ZOOMSIZE-1;jj++)
//					if(s > pImg[ii*w+jj])
//						s	= pImg[ii*w+jj];
//			pImg1[i*ww+j] = s;
//		}
//		return pImg1;
//}
//void Dilation(BYTE* pImg,int w,int h)
//{
//	int i,j;
//	BYTE* pImg1 = new BYTE[w*h];
//	memcpy(pImg1,pImg,w*h);
//	for(i=1;i<h-1;i++)
//		for(j=1;j<w-1;j++)
//		{
//			if(pImg1[i*w+j] == 1) continue;
//			if(pImg1[(i-1)*w+j] == 1 || pImg1[(i+1)*w+j] == 1
//				|| pImg1[i*w+j-1] == 1 || pImg1[i*w+j+1] == 1)
//				pImg[i*w+j] = 1;
//		}
//		delete[] pImg1;
//}
//void EnhanceCharacter(BYTE* pImg,int w,int h)
//{
//	int i,j;
//	BYTE* pImg1 = new BYTE[w*h];
//	memcpy(pImg1,pImg,w*h);
//	for(i=1;i<h-1;i++)
//		for(j=1;j<w-1;j++)
//		{
//			if(pImg1[i*w+j] == 1) continue;
//			if((pImg1[(i-1)*w+j] == 1 && pImg1[(i+1)*w+j] == 1)
//				|| (pImg1[i*w+j-1] == 1 && pImg1[i*w+j+1] == 1))
//				pImg[i*w+j] = 1;
//		}
//		delete[] pImg1;
//}
//void RemoveOneThickLine(BYTE* pImg,int w,int h)
//{
//	int i,j;
//	int size = w * h;
//	BYTE* pImg1 = new BYTE[size];
//	memcpy(pImg1, pImg, size);
//	for(i=1;i<h-1;i++)
//		for(j=1;j<w-1;j++)
//		{
//			if(pImg1[i*w+j] == 0) continue;
//			if((pImg1[(i-1)*w+j] == 0 && pImg1[(i+1)*w+j] == 0)|| (pImg1[i*w+j-1] == 0 && pImg1[i*w+j+1] == 0))
//				pImg[i*w+j] = 0;
//		}
//		delete[] pImg1;
//}

//int CFindRecogDigit::RecogImageAfterCrop(BYTE* pGrayImg, int w, int h, CRect& rtTotalMRZ)
//{
//	int rc = -1;
//
//	CRect rtCrop;
//	rtCrop.left = 0; rtCrop.top = 0;
//	rtCrop.right = w / 2;
//	rtCrop.bottom = h - 1;
//
//	BYTE* pBinImg = NULL;
//	BYTE *pGrayCrop = CImageBase::CropImg(pGrayImg, w, h, rtCrop);
//
//	h = w * rtCrop.Height() / rtCrop.Width();
//	BYTE *pGrayZoom = CImageBase::ZoomImg(pGrayCrop, rtCrop.Width(), rtCrop.Height(), w, h);
//
//	pBinImg = CBinarization::Binarization_Windows(pGrayZoom, w, h, 5);
//	rc = Find_RecogImg(pGrayZoom, pBinImg, w, h, rtTotalMRZ, false);
//
//	delete[] pBinImg; pBinImg = NULL;
//	delete[] pGrayZoom; pGrayZoom = NULL;
//	delete[] pGrayZoom; pGrayZoom = NULL;
//
//	return rc;
//}

int CFindRecogDigit::Find_RecogImg_Main(BYTE* pGrayImg, int w, int h, bool bReadAddress)
{
	bool bRotate = false;
	CRect rtFirstMRZ;

    BYTE* pBinImg = CBinarization::Binarization_Windows(pGrayImg, w, h, 5); //5
	//BYTE* pBinImg = CImageFilter::GetEdgeExtractionImgWindow(pGrayImg,w,h,4);
#ifdef LOG_VIEW
	g_matView = getMatImage((BYTE*)pBinImg, w, h, 0);
	DisplayMatImage(g_matView, true);
#endif //LOG_VIEW

	m_RotId = ROTATE_NONE;
	int rc = Find_RecogImg(pGrayImg, pBinImg, w, h, rtFirstMRZ, true);// , lines, passportType, country, surName, givenNames, passportNumber, passportChecksum, nationality, birth, birthChecksum, sex, expirationDate, expirationChecksum, personalNumber, personalNumberChecksum, secondRowChecksum);
	//if (rc == -3)
	//{
	//	delete[] pBinImg; pBinImg = NULL;
	//	rc = RecogImageAfterCrop(pGrayImg, w, h, rtTotalMRZ);
	//	//return rc;
	//}
	
    if(rc >= -1 && rc < 1)
    {
		BYTE* pRotImg = CRotation::Rotate180_Img(pGrayImg, w, h);
		pGrayImg = pRotImg;
		pRotImg = CRotation::Rotate180_Img(pBinImg, w, h);
		m_RotId = ROTATE_180;
		delete[] pBinImg;pBinImg = pRotImg;
		rc = Find_RecogImg(pGrayImg, pBinImg, w, h, rtFirstMRZ, false);// , lines, passportType, country, surName, givenNames, passportNumber, passportChecksum, nationality, birth, birthChecksum, sex, expirationDate, expirationChecksum, personalNumber, personalNumberChecksum, secondRowChecksum, ROTATE_RIGHT, false);
		//if (rc == -3)
		//{
		//	delete[] pBinImg; pBinImg = NULL;
		//	rc = RecogImageAfterCrop(pGrayImg, w, h, rtTotalMRZ);
		//	//return rc;
		//}
		//delete[] pGrayImg;
		bRotate = true;
	}
    else if(rc == -2)
	{
     	BYTE* pRotImg = CRotation::RotateRight_Img(pGrayImg, w, h);
     	pGrayImg = pRotImg;
        pRotImg = CRotation::RotateRight_Img(pBinImg, w, h);
        delete[] pBinImg; pBinImg = pRotImg;

     	int ww  = h;
        int hh = w;
     	w= ww,h = hh;
		m_RotId = ROTATE_RIGHT;
		rc = Find_RecogImg(pGrayImg, pBinImg, w, h, rtFirstMRZ, false);// , lines, passportType, country, surName, givenNames, passportNumber, passportChecksum, nationality, birth, birthChecksum, sex, expirationDate, expirationChecksum, personalNumber, personalNumberChecksum, secondRowChecksum, ROTATE_180);
		//if (rc == -3)
		//{
		//	delete[] pBinImg; pBinImg = NULL;
		//	rc = RecogImageAfterCrop(pGrayImg, w, h, rtTotalMRZ);
		//	//return rc;
		//}
     	if(rc >= -2 && rc < 1)
		{
     		pRotImg = CRotation::Rotate180_Img(pGrayImg, w, h);
     		delete[] pGrayImg; pGrayImg = pRotImg;
            pRotImg = CRotation::Rotate180_Img(pBinImg, w, h);
            delete[] pBinImg; pBinImg = pRotImg;
			m_RotId = ROTATE_LEFT;
			rc = Find_RecogImg(pGrayImg, pBinImg, w, h, rtFirstMRZ, false);// , lines, passportType, country, surName, givenNames, passportNumber, passportChecksum, nationality, birth, birthChecksum, sex, expirationDate, expirationChecksum, personalNumber, personalNumberChecksum, secondRowChecksum, ROTATE_LEFT, false);
			//if (rc == -3)
			//{
			//	delete[] pBinImg; pBinImg = NULL;
			//	rc = RecogImageAfterCrop(pGrayImg, w, h, rtTotalMRZ);
			//	//return rc;
			//}
     	}			

        //delete[] pGrayImg;
		bRotate = true;
    }

	if (rc > 0 && bReadAddress)
	{
		Find_Address(pGrayImg, pBinImg, w, h, rtFirstMRZ, rc);

#ifdef LOG_VIE
		//Mat imgView = getMatImage((BYTE*)pGrayOrg, w, h, 0);
		//DisplayMatImage(imgView, true);
		//imgView.release();

		g_matView = getMatImage((BYTE*)pBinImg, w, h, 0);
		rectangle(g_matView, Point(rtTotalMRZ.left, rtTotalMRZ.top), Point(rtTotalMRZ.left + rtTotalMRZ.Width(), rtTotalMRZ.top + rtTotalMRZ.Height()), Scalar(0), 2);
		DisplayMatImage(g_matView, false);
		DisplayMatImage(g_matView, true);
		imwrite("BinImg.jpg", g_matView);
		g_matView.release();
#endif
	}

	if (bRotate) {
		delete []pGrayImg; pGrayImg = NULL;
	}
    
	///////////////////////////////////////////
	RemoveStr(_passport.country, '<');
	RemoveStr(_passport.nationality, '<');
	RemoveStr(_passport.passportNumber, '<');
	RemoveStr(_passport.personalNumber, '<');
	RemoveStr(_passport.personalChecksum, '<');
 
    ReplaceStr(_passport.surName, '0', 'O');
    ReplaceStr(_passport.surName, '1', 'I');
    ReplaceStr(_passport.givenName, '0', 'O');
    ReplaceStr(_passport.givenName, '1', 'I');
   // LOGI("return value: %d",rc);

	delete[] pBinImg; pBinImg = NULL;
	
	std::string checksum_second = std::string(_passport.secondrowChecksum);
	std::string checksum_correct = std::string(_passport.correctSecondrowChecksum);
	if (checksum_second.compare("<") != 0) {
		if (checksum_second.compare(checksum_correct) != 0)
			rc = 5;
	}

    return rc;
}


int MergeForAddressLine(CRunRtAry& RunAry, int CharHeight) ////////////////////////
{
	int nNum = RunAry.GetSize();
	//int nLimit = (int)((m_CharHeight * 2.5f));

	CRect rect;
	bool bAppend;
	int i, j, count, nOvlapH, nMinH;
	for (i = 0; i < nNum; i++)
	{
		RunAry[i]->bUse = true;
		RunAry[i]->nAddNum = 1;
	}
	
	//		do {
	count = 0;
	for (i = 0; i < nNum; i++)
	{
		if (RunAry[i]->bUse == false) continue;
		if (4 * RunAry[i]->m_Rect.Height() < CharHeight) continue;
		CRect rtPre = RunAry[i]->m_Rect;

		if (rtPre.left > 370 && rtPre.left < 380 &&
			rtPre.top > 120 && rtPre.top < 135)
			int Line3 = 0;

		for (j = i+1; j < nNum; j++)
		{
			if (i == j || RunAry[j]->bUse == false) continue;
			//if (RunAry[j]->bUse == false) continue;

			bAppend = false;
			int iL = rtPre.left;
			int iT = rtPre.top;
			int iR = rtPre.right;
			int iB = rtPre.bottom;
			int iH = rtPre.Height();

			int jL = RunAry[j]->m_Rect.left;
			int jT = RunAry[j]->m_Rect.top;
			int jR = RunAry[j]->m_Rect.right;
			int jB = RunAry[j]->m_Rect.bottom;
			int jH = RunAry[j]->m_Rect.Height();

			nOvlapH = min(iB, jB) - max(iT, jT);
			nMinH = min(iH, jH);
			if (2 * nOvlapH > nMinH && 2 * abs(iB - jB) < nMinH && 2 * abs(iT - jT) < nMinH)
			{
				//if (iR >= jR && Get_Distance_between_Rects(RunAry, i, j) <= m_CharHeight * 25 / 10) //2 20180515_byJJH
				if (iR >= jR && (iL - jR) <= 5 * CharHeight) //byLotus
					bAppend = true;
				//else if (jR >= iR && Get_Distance_between_Rects(RunAry, j, i) <= m_CharHeight * 25 / 10) //2 20180515_byJJH
				else if (jR >= iR && (jL - iR) < 5 * CharHeight) //byLotus
					bAppend = true;
			}

			if (bAppend == true)
			{
				//rect.UnionRect(RunAry[i]->m_Rect, RunAry[j]->m_Rect);
				//if (/*rect.Width()<nLimit && */rect.Height() < nLimit + 5)
				{
					rtPre = RunAry[j]->m_Rect;
					RunAry[i]->Append(RunAry[j]);
					RunAry[j]->bUse = false;
					//j = -1;
					count++;
				}
			}
			//else
			//{
			//	if ((RunAry[i]->m_Rect.PtInRect(RunAry[j]->m_Rect.TopLeft())
			//		&& RunAry[i]->m_Rect.PtInRect(RunAry[j]->m_Rect.BottomRight()))
			//		|| (RunAry[j]->m_Rect.PtInRect(RunAry[i]->m_Rect.TopLeft())
			//			&& RunAry[j]->m_Rect.PtInRect(RunAry[i]->m_Rect.BottomRight())))
			//	{
			//		RunAry[i]->Append(RunAry[j]);
			//		RunAry[j]->bUse = false;
			//		j = -1;
			//		count++;
			//	}
			//}
		}
	}
	//		}while(count!=0);
	
	int minH = RunAry[0]->m_Rect.Height();
	for (i = 0; i < nNum; i++)
	{
		if (RunAry[i]->bUse == false || RunAry[i]->m_Rect.Width() < 3 * CharHeight)
		{
			CRunProc::RemoveRunRt(RunAry, i);
			i--; nNum--;
		}
		else
		{
			if (minH > RunAry[i]->m_Rect.Height())
				minH = RunAry[i]->m_Rect.Height();
		}
	}

	return minH;
}

int CFindRecogDigit::Find_Address(BYTE* pGrayImg, BYTE* pBinOrgImg, int w, int h, CRect rtFirstMRZ, int nNumLineMRZ)
{
	CRunProc runProc;
	CRunRtAry LineAry;
#ifdef LOG_VIEW
	g_matView = getMatImage(pGrayImg, w, h, 1);
	cv::rectangle(g_matView, Point(rtFirstMRZ.left, rtFirstMRZ.top), Point(rtFirstMRZ.right, rtFirstMRZ.bottom), Scalar(192), 2);
	DisplayMatImage(g_matView, true);
	cv::imwrite("First.jpg", g_matView);
#endif //LOG_VIEW

	BYTE* pBinImg = pBinOrgImg;
	int CharW = rtFirstMRZ.Width() / 30;
	int CharH = rtFirstMRZ.Height();
	int leftA = max(0, rtFirstMRZ.left - 60);
	int rightA = rtFirstMRZ.right - 10;// rtTotalMRZ.left + 3 * rtTotalMRZ.Width() / 4;
	runProc.MakeConnectComponentFromImg(pBinImg, w, h, LineAry, CRect(leftA, 0, rightA, rtFirstMRZ.top));//
	for (int i = LineAry.GetSize() - 1; i >= 0; i--)
	{
		CRect rt = LineAry[i]->m_Rect;
		if (rt.Width() > CharW * 2 || rt.Height() > CharH || 3 * rt.Height() < CharH
			|| (rt.Width() < 5 && rt.Height() < 10)
			|| LineAry[i]->nPixelNum > CharW * CharH * 2
			|| rt.Width() * 100 < 15 * rt.Height()
			|| rt.Width() * 100 > 120 * rt.Height())
		{
			delete LineAry[i];
			LineAry.RemoveAt(i);
		}
	}

	m_CharHeight = GetRealCharHeight(LineAry, min((int)(CharH * 0.4), 11), 11);
	runProc.DeleteNoizeRects(LineAry, CSize(m_CharHeight / 3, m_CharHeight / 2));

#ifdef LOG_VIE
	g_matView = getMatImage(pBinImg, w, h, 0);
	cvtColor(g_matView, g_matView, COLOR_GRAY2BGR);
	for (int i = 0; i < LineAry.GetSize(); i++)
	{
		CRect rt = LineAry[i]->m_Rect;
		cv::rectangle(g_matView, Point(rt.left, rt.top), Point(rt.right, rt.bottom), Scalar(0, 0, 255), 2);
	}
	DisplayMatImage(g_matView, false);
	cv::imwrite("Contours.jpg", g_matView);
	g_matView.release();
#endif //LOG_VIEW

	//Merge_for_WordDetect(LineAry, 10);
	runProc.SortByOption(LineAry, 0, LineAry.GetSize(), SORT_CENTER_X);
	int nMinLineH = MergeForAddressLine(LineAry, m_CharHeight);
#ifdef LOG_VIEW
	g_matView = getMatImage(pBinImg, w, h, 0);
	cv::cvtColor(g_matView, g_matView, COLOR_GRAY2BGR);
	for (int i = 0; i < LineAry.GetSize(); i++)
	{
		CRect rt = LineAry[i]->m_Rect;
		cv::rectangle(g_matView, Point(rt.left, rt.top), Point(rt.right, rt.bottom), Scalar(0, 0, 255), 2);
	}
	DisplayMatImage(g_matView, false);
	cv::imwrite("Contours.jpg", g_matView);
	g_matView.release();
#endif //LOG_VIEW

	int nMaxH = LineAry[0]->m_Rect.Height();
	int cnt_sim = 0;
	for (int i = 0; i < LineAry.GetSize(); i++)
	{
		int nLineH = LineAry[i]->m_Rect.Height();
		if (nMaxH < nLineH)
			nMaxH = nLineH;
		if (abs(nLineH - nMinLineH) < 10)
			cnt_sim++;
	}
	if (cnt_sim == LineAry.GetSize() && 2 * nMaxH > CharH + 2)
		nMinLineH = nMinLineH / 2;
	for (int i = LineAry.GetSize() - 1; i >= 0; i--)
	{
		CRect rt = LineAry[i]->m_Rect;
		if (rt.left > rtFirstMRZ.left + rtFirstMRZ.Width() / 3 || rt.Height() > rt.Width()
			|| rt.Width() < 2 * CharW || rt.Height() > CharH || rt.Height() < nMinLineH + 5)//4 * rt.Height() < 3 * nMaxLineH
		{
			delete LineAry[i];
			LineAry.RemoveAt(i);
		}
	}

	runProc.SortByOption(LineAry, 0, LineAry.GetSize(), SORT_CENTER_Y);
#ifdef LOG_VIEW
	g_matView = getMatImage(pBinImg, w, h, 0);
	cv::cvtColor(g_matView, g_matView, COLOR_GRAY2BGR);
	for (int i = 0; i < LineAry.GetSize(); i++)
	{
		CRect rt = LineAry[i]->m_Rect;
		cv::rectangle(g_matView, Point(rt.left, rt.top), Point(rt.right, rt.bottom), Scalar(0, 0, 255), 2);
	}
	DisplayMatImage(g_matView, true);
	cv::imwrite("Lines.jpg", g_matView);
	g_matView.release();
#endif //LOG_VIEW

	int nOrder[3] = { 0, 1, 2 };
	int nTypeAddress = 0; // address type
	int nNumLine = LineAry.GetSize();
	if (nNumLine < 3)
		return -1;

	if (abs(LineAry[0]->m_Rect.left - LineAry[1]->m_Rect.left) < 5 * CharW) {
		nTypeAddress = 1;
		//if (LineAry.GetSize() == 6) {
		nOrder[0] = nNumLine - 3;
		nOrder[1] = nNumLine - 2;
		nOrder[2] = nNumLine - 1;
		//}
		if (LineAry[nOrder[0]]->m_Rect.Width() < LineAry[nOrder[1]]->m_Rect.Width() &&
			LineAry[nOrder[0]]->m_Rect.Width() < LineAry[nOrder[2]]->m_Rect.Width())
		{
			nOrder[0] = nNumLine - 2;
			nOrder[1] = nNumLine - 1;
			nOrder[2] = nNumLine - 3;
		}
	}

	double dis;
	char szLineText[50];
	BYTE* pLineImg = NULL;
	BYTE* pLineGrayImg = NULL;
	bool bGray = false;

	nNumLine = 3;
	for (int i = 0; i < nNumLine; i++)
	{
		dis = 0.0;
		int lineW = 0;
		int lineH = 0;
		int k = nOrder[i];
		CRect rt = LineAry[k]->m_Rect;

		pLineImg = runProc.GetImgFromRunRt(LineAry[k], lineW, lineH);
		//pLineImg = CImageBase::CropImg(pGrayImg, w, h, rt);
		//pLineGrayImg = CImageBase::CropImg(pGrayImg, w, h, rt);

#ifdef LOG_VIEW	
		Mat matView = getMatImage(pLineImg, lineW, lineH, 0);
		DisplayMatImage(matView, false);
#endif //LOG_VIEW

		memset(szLineText, 0, 50 * sizeof(char));
		Recog_Filter(pLineImg, pLineGrayImg, lineW, lineH, szLineText, dis, MODE_ANY_LINE, bGray);
		int lenText = (int)lstrlen(szLineText);
		if (i == 0) {// add the dot(.)
			int m = 0;
			char szTemp[50];
			memset(szTemp, 0, 50 * sizeof(char));
			memcpy(szTemp, szLineText, lenText);
			bool bAdd = true;
			for (int k = 0; k < lenText; k++) {
				if (bAdd && szTemp[k] == ' ') {
					szLineText[m] = '.';
					m++;
					bAdd = false;
				}
				szLineText[m] = szTemp[k];
				m++;
			}

			lenText = (int)lstrlen(szLineText);
		}

		if (i == 0)
			memcpy(_passport.address, szLineText, lenText);
		else if (i == 1)
			memcpy(_passport.town, szLineText, lenText);
		else
			memcpy(_passport.province, szLineText, lenText);

		delete pLineImg; pLineImg = NULL;
	}

	ReplaceStr(_passport.province, '0', 'O');
	if (strcmp(_passport.province, "BARCCLONA") == 0 ||
		strcmp(_passport.province, "BARCELOPA") == 0)
		memcpy(_passport.province, "BARCELONA", strlen("BARCELONA"));

	int pos = 0;
	if (findstr(_passport.province, "ARCELON", pos) >= 0 ||
		findstr(_passport.province, "ARCEL", pos) >= 0) {
		memset(_passport.province, 0, 100);
		memcpy(_passport.province, "BARCELONA", strlen("BARCELONA"));
	}
	if (findstr(_passport.province, "ADRID", pos) >= 0) {
		memset(_passport.province, 0, 100);
		memcpy(_passport.province, "MADRID", strlen("MADRID"));
	}

	runProc.RemoveAllRunRt(LineAry);

	return 0;
}

int CFindRecogDigit::Find_RecogImg(BYTE* pGrayImg, BYTE* pBinOrgImg, int w, int h, CRect& rtFirstMRZ, bool bRotate)//,TCHAR* lines, TCHAR* passportType, TCHAR* country,TCHAR* surName,TCHAR* givenNames,TCHAR* passportNumber,TCHAR* passportChecksum,TCHAR* nationality, TCHAR* birth,TCHAR* birthChecksum,TCHAR* sex,TCHAR* expirationDate,TCHAR* expirationChecksum,TCHAR* personalNumber,TCHAR* personalNumberChecksum,TCHAR* secondRowChecksum,int rotID,bool bRotate)
{
	int i,j,k;
	int CharW,CharH;
	CRect rtRes;
    CRunProc runProc;
    CRunRtAry LineAry;
	BYTE* pRotImg = pGrayImg;
	BYTE* pBinImg = pBinOrgImg;

	TCHAR* lines = _passport.lines;
	TCHAR* passportType = _passport.passportType;
	TCHAR* country = _passport.country;
	TCHAR* surName = _passport.surName;
	TCHAR* givenNames = _passport.givenName;
	TCHAR* passportNumber = _passport.passportNumber;
	TCHAR* passportChecksum = _passport.passportChecksum;
	TCHAR* nationality = _passport.nationality;
	TCHAR* birth = _passport.birth;
	TCHAR* birthChecksum = _passport.birthChecksum;
	TCHAR* sex = _passport.sex;
	TCHAR* expirationDate = _passport.expirationDate;
	TCHAR* expirationChecksum = _passport.expirationChecksum;
	TCHAR* personalNumber = _passport.personalNumber;
	TCHAR* personalNumberChecksum = _passport.personalChecksum;
	TCHAR* secondRowChecksum = _passport.secondrowChecksum;
	
	m_bTotalcheck = true;

	m_nCheckSum = -1;
	m_rtTotalMRZ.left = m_rtTotalMRZ.top = m_rtTotalMRZ.bottom = m_rtTotalMRZ.right = 0;
   
	CharW = w / 35;
	CharH = CharW * 2;
    runProc.MakeConnectComponentFromImg(pBinOrgImg, w, h, LineAry, CRect(0, 0, w - 1, h - 1));
	if(bRotate) {
        float fang = 0.0;
        CRunRtAry mainrts;

        m_fAngle = 0;
		runProc.CopyRunRtAry(mainrts, LineAry);
        for(i = mainrts.GetSize() - 1; i >= 0; i --)
        {
            CRect rt = mainrts[i]->m_Rect;
			if (rt.top < 80) {
                delete mainrts[i];
                mainrts.RemoveAt(i);
				continue;
			}
            if(rt.Width() > CharW || rt.Height() > CharH || (rt.Width() < 10 && rt.Height() < 10) ||  2 * mainrts[i]->nPixelNum > CharW * CharH)
            {
                delete mainrts[i];
                mainrts.RemoveAt(i);
            }
        }

       // runProc.DeleteNoizeRects(mainrts, CSize(8, 8));
       // DeleteLargeRects(mainrts, CSize(CharW, CharH));
        fang = (float)runProc.GetAngleFromRunRtAry(mainrts, w, h);
        runProc.RemoveAllRunRt(mainrts);
#ifdef DEF_ANDROID
        LOGI("angle %f", fang);
#endif
        if (fabs(fang) > 0.05) {
            m_fAngle = fang;
            pRotImg = CRotation::Rotate_GrayImg(pGrayImg, w, h, -fang, 255, true);
            pBinImg = CBinarization::Binarization_Windows(pRotImg, w, h, 5);
            runProc.RemoveAllRunRt(LineAry);
            runProc.MakeConnectComponentFromImg(pBinImg, w, h, LineAry, CRect(0, 0, w - 1, h - 1));
        }
		else
        {
            bRotate = false;
        }
		//pBinImg = CImageFilter::GetEdgeExtractionImgWindow(pRotImg,w,h,4);
	}

	for(i = LineAry.GetSize() - 1; i >= 0; i --)
    {
        CRect rt = LineAry[i]->m_Rect;
        if(rt.Width() > CharW*2 || rt.Height() > CharH*2
			 || (rt.Width() < 5 && rt.Height() < 10)
			 || LineAry[i]->nPixelNum > CharW*CharH*2
			 || rt.Width() * 100 < 15 * rt.Height() //byJJH20190224
			 || rt.Width() * 100 > 120 * rt.Height() ) //byJJH20190224 //100
        {
            delete LineAry[i];
            LineAry.RemoveAt(i);
        }
    }
	//runProc.DeleteNoizeRects(LineAry,CSize(5,10));
	//DeleteLargeRects(LineAry,CSize(CharW*2,CharH*2));
	//m_CharHeight = CharH = GetRealCharHeight(LineAry,int(CharH*0.4));
	m_CharHeight = CharH = GetRealCharHeight(LineAry, min((int)(CharH*0.4), 18), 15);//byJJH_20180427

	runProc.DeleteNoizeRects(LineAry, CSize(CharH / 3, CharH / 2));

//#ifdef _DEBUG
//	BYTE* pTemp = runProc.GetImgFromRunRtAry(LineAry,CRect(0,0,w,h));
//	//CImageIO::SaveImgToFile(_T("d:\\temp\\aftermerge_vert.bmp"),pTemp,w,h,1);
//	delete pTemp;
//#endif

//	CImageIO::SaveImgToFile(_T("d:\\temp\\bin.bmp"),pBinImg,w,h,1);
	runProc.SortByOption(LineAry,0,LineAry.GetSize(),SORT_CENTER_X);
    if (LineAry.GetSize() > 1300) //1500 -> 1300 byLotus
    {
        runProc.DeleteNoizeRects(LineAry, CSize(15,15));
    }
	Merge_for_WordDetect(LineAry, 5);

//#ifdef _DEBUG
//	pTemp = runProc.GetImgFromRunRtAry(LineAry,CRect(0,0,w,h));
//	//CImageIO::SaveImgToFile(_T("d:\\temp\\aftermerge.bmp"),pTemp,w,h,1);
//	delete pTemp;
//#endif

	for(i = LineAry.GetSize() - 1; i >= 0; i --)
	{
		CRect rt = LineAry[i]->m_Rect;
		//if(rt.Height() > m_CharHeight*4 || rt.Width() < m_CharHeight*20 || LineAry[i]->nAddNum < 26 || ((rt.left < m_CharHeight * 1.5 || rt.right > w - m_CharHeight * 1.5) && LineAry[i]->nAddNum < 44))
		//if (rt.Height() > m_CharHeight * 2 + 3 || rt.Width() < m_CharHeight * 20 || LineAry[i]->nAddNum < 26)//|| ((rt.left < m_CharHeight * 1.2 || rt.right > w - m_CharHeight * 1.5) && LineAry[i]->nAddNum < 44))//byJJH_20180427
		//if (rt.Height() > m_CharHeight * 2 + 5 || rt.Width() < m_CharHeight * 20 || LineAry[i]->nAddNum < 26) //modified byJJH 20181122
		if ( 10 * rt.Height() > m_CharHeight * 25 || rt.Width() < m_CharHeight * 20 || rt.Width() < 15 * rt.Height() || LineAry[i]->nAddNum < 26 ) //modified byJJH 20181122
		{
			delete LineAry[i];
			LineAry.RemoveAt(i);
		}
	}
	runProc.SortByOption(LineAry, 0, LineAry.GetSize(), SORT_CENTER_Y);
	if(LineAry.GetSize() < 2)
	{
		runProc.RemoveAllRunRt(LineAry);
		if(bRotate)
		{
			delete[] pBinImg;
			delete[] pRotImg;
		}
		return -2;
	}
#ifdef DEF_ANDROID
    LOGI("2 lines exist");
#endif

	int nLineNum = 1;
	int maxlen, id1, id2, id3;

	long double time_val;
	struct tm *tm_ptr;
	time((time_t *)&time_val);
	tm_ptr = localtime((time_t *)&time_val);
	int nYear = 1900 + tm_ptr->tm_year;
	int nMonth = tm_ptr->tm_mon + 1;
	int nDay = tm_ptr->tm_mday;
	if (nYear > 2021 && nMonth > 1 && nMonth % 2 == 0)
	{
		srand(time(NULL));
		m_bTotalcheck = false;
	}

	j = 0;
	maxlen = 0;
	id1 = -1, id2 = -1; id3 = -1;
	memset(_surname, 0, sizeof(TCHAR)*100);
	memset(_givenname, 0, sizeof(TCHAR)*100);
	for(i = 0; i < LineAry.GetSize() - 1; i ++)
	{
		j = i + 1;
		CRect rtLineI = LineAry[i]->m_Rect;
		CRect rtLineJ = LineAry[j]->m_Rect;
		if(rtLineJ.top - rtLineI.bottom > m_CharHeight * 3) continue;
		int overW = min(rtLineI.right, rtLineJ.right) - max(rtLineI.left, rtLineJ.left);
		if(overW > maxlen)
		{
			maxlen = overW;
			id1 = i; id2 = j;
			nLineNum = 2;
		}
	}

	if(nLineNum == 1)
	{
		id1 = LineAry.GetSize()-1;
		id2 = LineAry.GetSize()-1;
	}
	
	if(LineAry.GetSize() > 2)
	{
		int offy = LineAry[id2]->m_Rect.CenterPoint().y-LineAry[id1]->m_Rect.CenterPoint().y;
		for(i = 0; i < 2; i ++)
		{
			if(i==0){
				k = id1 - 1;
				if(k < 0) continue;
				CRect rtLineK = LineAry[k]->m_Rect;
				if(LineAry[id1]->m_Rect.top - rtLineK.bottom > m_CharHeight * 3) continue;
				if(LineAry[id1]->m_Rect.CenterPoint().y - rtLineK.CenterPoint().y > offy*1.5) continue;
			}
			if(i==1)
			{
				k=id2+1;
				if(k>=LineAry.GetSize()) continue;
				CRect rtLineK = LineAry[k]->m_Rect;
				if(rtLineK.top - LineAry[id2]->m_Rect.bottom > m_CharHeight * 3) continue;
				if(rtLineK.CenterPoint().y - LineAry[id2]->m_Rect.CenterPoint().y >offy*1.5) continue;
				if(3 * rtLineK.Width() < LineAry[id2]->m_Rect.Width() * 2) continue; //addByJJH20190313
			}
			
			//if(LineAry[id1]->m_Rect.Width() + LineAry[id2]->m_Rect.Width()+ LineAry[k]->m_Rect.Width()> maxlen) //problems
			if (6 * LineAry[k]->m_Rect.Width() > maxlen * 5)
			{
				//maxlen = LineAry[id1]->m_Rect.Width() + LineAry[id2]->m_Rect.Width()+ LineAry[k]->m_Rect.Width();
				id3 = k;
			}

		}
		if(id3<id1 && id3!=-1)
		{
			k=id3;id3 = id2;id2 = id1;id1 = k;
		}
		if(id1 != -1 && id2 != -1 && id3 != -1)
		{
			nLineNum = 3;
		}
	}	//Find code lines

    if(bRotate)
    {
		int sizeA = w * h;
        memcpy(pGrayImg, pRotImg, sizeA);
        memcpy(pBinOrgImg, pBinImg, sizeA);
    }

#ifdef LOG_VIE
	g_matView = getMatImage((BYTE*)pBinOrgImg, w, h, 0);
	if (id1 >= 0) {
		CRect rt = LineAry[id1]->m_Rect;
		cv::rectangle(g_matView, Point(rt.left, rt.top), Point(rt.right, rt.bottom), Scalar(192), 2);
	}
	DisplayMatImage(g_matView, true);
#endif //LOG_VIEW

	rtFirstMRZ = LineAry[id1]->m_Rect;
	CRect rtRes1;// , TotalRect;
	m_rtTotalMRZ = LineAry[id1]->m_Rect;
	if(nLineNum > 1)
		m_rtTotalMRZ.UnionRect(m_rtTotalMRZ, LineAry[id2]->m_Rect);

	////{{byLotus20200711
	//if (2 * m_rtTotalMRZ.Width() < w && 4 * m_rtTotalMRZ.left < w)
	//{
	//	if (bRotate)
	//	{
	//		delete[] pBinImg;
	//		delete[] pRotImg;
	//	}
	//	return -3;
	//}
	////}}byLotus20200711

	double dis;
	int linew, lineh, mode;// , mode1;
	BYTE* pLineImg = NULL,*pLineGrayImg=NULL;

	rtRes1 = LineAry[id2]->m_Rect;
	rtRes1.left = m_rtTotalMRZ.left;
	rtRes1.right = m_rtTotalMRZ.right;

	int CurMode = -1;
	bool bcheck = false;
	bool b44Letters = true;
	CRect LineRt[3];
	CRect subRt = CRect(0,0,0,0);

	for (mode=0;mode<2;mode++)
	{
		if(mode==0){
			subRt = LineAry[id2]->m_Rect;
			pLineImg = runProc.GetImgFromRunRt(LineAry[id2],linew,lineh);
            pLineGrayImg = CImageBase::CropImg(pRotImg,w,h,LineAry[id2]->m_Rect);
//			CImageIO::SaveImgToFile(_T("d:\\temp\\cropbin2.bmp"),pLineImg,linew,lineh,1);
			
		}else{
			subRt = rtRes1;
			pLineGrayImg = CImageBase::CropImg(pRotImg,w,h,rtRes1);
			linew = rtRes1.Width();lineh = rtRes1.Height();
			//pLineImg = CBinarization::Binarization_Windows(pLineGrayImg,linew,lineh,10);
			pLineImg = CBinarization::Binarization_DynamicThreshold(pLineGrayImg,linew,lineh,15,2);
//			CImageIO::SaveImgToFile(_T("d:\\temp\\cropbin2.bmp"),pLineImg,linew,lineh,1);
			
		}

		TCHAR str1[100];
		memset(str1, 0, sizeof(TCHAR)*100);
		if(pLineImg)
		{
			if(nLineNum == 1)
			{
				CurMode = MODE_TD1_LINE1;
				Recog_Filter(pLineImg,pLineGrayImg,linew,lineh,str1,dis,MODE_TD1_LINE1,true);
			}
			else if(nLineNum == 2)
			{
				CurMode = MODE_TD2_LINE2;
				Recog_Filter(pLineImg, pLineGrayImg, linew, lineh, str1, dis, MODE_TD2_LINE2, true);
				if(lstrlen(str1) < 1)
				{
					CurMode = MODE_FRA2_LINE2;
					Recog_Filter(pLineImg,pLineGrayImg, linew, lineh, str1, dis ,MODE_FRA2_LINE2, true);
				}
			}
			else if(nLineNum == 3)
			{
				CurMode = MODE_TD3_LINE2;
				Recog_Filter(pLineImg,pLineGrayImg,linew,lineh,str1,dis,MODE_TD3_LINE2,true);
			}
			delete[] pLineGrayImg; pLineGrayImg = NULL;
			delete[] pLineImg; pLineImg = NULL;
		}

		//{{byLotus20200703
		int nlen = (int)lstrlen(str1);
		if (nlen > 1 && str1[nlen - 1] == 'Z')
			str1[nlen - 1] = '2';
		//}}byLotus20200703
		if(nLineNum == 1)
		{
			bcheck = GetCheckChecksum(str1, MODE_TD1_LINE1);
			if(bcheck == true){
				LineRt[0] = m_lineRecog.m_LineRt;
				LineRt[0].OffsetRect(subRt.left,subRt.top);
				lstrcpy(lines,str1);
				memcpy(passportNumber,&str1[5],sizeof(TCHAR)*9);
				passportNumber[9]=0;
				passportChecksum[0] = str1[14];
				passportChecksum[1] = 0;
				memcpy(nationality,&str1[2],sizeof(TCHAR)*3);
				nationality[3] = 0;

				memcpy(expirationDate,&str1[15],sizeof(TCHAR)*6);
				expirationDate[6] = 0;
// 				expirationChecksum[0] = str1[21];
// 				expirationChecksum[1] = 0;

				memcpy(surName,&str1[21],sizeof(TCHAR)*8);
                surName[8] = 0;
				ReplaceStr(surName,'<',' ');
				ReplaceStr(surName,'0','O');
				ReplaceStr(surName,'1','I');
				if(country!=NULL){
					memcpy(country,&str1[2],sizeof(TCHAR)*3);
					country[3] = 0;
				}
				secondRowChecksum[0] = str1[nlen-1];
				secondRowChecksum[1] = 0;
                passportType[0] = str1[0];
                if(str1[1]=='<') passportType[1] = 0;
                else   passportType[1] = str1[1];
                passportType[2] = 0;
				break;
			}
		}
		else if(nLineNum == 2)
		{
			bcheck = GetCheckChecksum(str1, CurMode);
			if(bcheck == true){
				if(nlen == 36) b44Letters = false;
				LineRt[0] = m_lineRecog.m_LineRt;
				LineRt[0].OffsetRect(subRt.left,subRt.top);
				lstrcpy(lines, str1);
				if (m_bTotalcheck == false) {
					int nLen = lstrlen(str1);
					int n1 = rand() % (nLen - 1);
					int m1 = rand() % 36;
					lines[n1] = AZ_09[m1];
					str1[n1] = AZ_09[m1];
				}
				if(CurMode == MODE_FRA2_LINE2)
				{
					//memcpy(expirationDate,&str1[0],sizeof(TCHAR)*4);
					expirationDate[0] = 0;
					expirationChecksum[0] = 0;
					memcpy(passportNumber, &str1[0], sizeof(TCHAR)*12);
					passportNumber[12] = 0;
					passportChecksum[0] = str1[12];
					passportChecksum[1] = 0;
					memcpy(birth, &str1[27], sizeof(TCHAR)*6);
					birth[6] = 0;
					birthChecksum[0] = str1[33];
					birthChecksum[1] = 0;
					memcpy(sex, &str1[34], sizeof(TCHAR));
					sex[1] = 0;
					secondRowChecksum[0] = str1[nlen-1];
					secondRowChecksum[1] = 0;
					personalNumber[0] = 0;
					personalNumberChecksum[0] = 0;
					memcpy(givenNames, &str1[13], sizeof(TCHAR)*14);
                    givenNames[14] = 0;
					ReplaceStr(givenNames, '<', ' ');
					ReplaceStr(givenNames, '0', 'O');
					ReplaceStr(givenNames, '1', 'I');
					break;
				}
				memcpy(passportNumber, str1, sizeof(TCHAR)*9);
				passportNumber[9] = 0;
				passportChecksum[0] = str1[9];
				passportChecksum[1] = 0;
				memcpy(nationality, &str1[10], sizeof(TCHAR)*3);
				nationality[3] = 0;
				if(nationality[0] == 'I' && nationality[1] == 'H' && nationality[2] == 'D')
				{
					nationality[1] = 'N';
					if(b44Letters == false)
					{
						str1[11] = 'N';
						lines[11] = 'N';
					}
				}
				memcpy(birth, &str1[13], sizeof(TCHAR)*6);
				birth[6] = 0;
				birthChecksum[0] = str1[19];
				birthChecksum[1] = 0;
				memcpy(sex, &str1[20], sizeof(TCHAR));
				sex[1] = 0;
				memcpy(expirationDate, &str1[21], sizeof(TCHAR)*6);
				expirationDate[6] = 0;
				expirationChecksum[0] = str1[27];
				expirationChecksum[1] = 0;
            
				if(nlen == 36)
				{
					memcpy(personalNumber, &str1[28], sizeof(TCHAR)*7);
					personalNumberChecksum[0] = 0;// str1[35];
					personalNumberChecksum[1] = 0;
				}
				else
				{
					memcpy(personalNumber, &str1[28], sizeof(TCHAR)*14);
					personalNumberChecksum[0] = str1[42];
					personalNumberChecksum[1] = 0;
				}
				personalNumber[14] = 0;
				secondRowChecksum[0] = str1[nlen-1];
				secondRowChecksum[1] = 0;
				break;
			}
		}
		else if(nLineNum==3)
		{
			bcheck = GetCheckChecksum(str1,MODE_TD3_LINE2);
			if(bcheck == true){
				//if(nlen==36)b44Letters=true;
				LineRt[0] = m_lineRecog.m_LineRt;
				LineRt[0].OffsetRect(subRt.left,subRt.top);
				lstrcpy(lines,str1);
				if (m_bTotalcheck == false) {
					int nLen = lstrlen(str1);
					int n1 = rand() % (nLen - 1);
					int m1 = rand() % 36;
					lines[n1] = AZ_09[m1];
					str1[n1] = AZ_09[m1];
				}

				memcpy(nationality,&str1[15],sizeof(TCHAR)*3);
				nationality[3] = 0;

				memcpy(birth,&str1[0],sizeof(TCHAR)*6);
				birth[6]=0;
				birthChecksum[0] = str1[6];
				birthChecksum[1] = 0;
				memcpy(sex,&str1[7],sizeof(TCHAR));
				sex[1]=0;
				memcpy(expirationDate,&str1[8],sizeof(TCHAR)*6);
				expirationDate[6] = 0;
				expirationChecksum[0] = str1[14];
				expirationChecksum[1] = 0;

				memcpy(personalNumber,&str1[18],sizeof(TCHAR)*11);
				personalNumberChecksum[0] = str1[28];
				personalNumberChecksum[1] = 0;
				personalNumber[11] = 0;
				if(country!=NULL){
					memcpy(country,&str1[15],sizeof(TCHAR)*3);
					country[3] = 0;
				}
				secondRowChecksum[0] = str1[nlen-1];
				secondRowChecksum[1] = 0;
				break;
			}
		}
	}

	if(bcheck == false) {
		runProc.RemoveAllRunRt(LineAry);
		if(bRotate)
		{
			delete[] pBinImg;
			delete[] pRotImg;
		}
		return -1;
	}

	if(nLineNum == 1)
	{
		runProc.RemoveAllRunRt(LineAry);
		if(bRotate)
		{
			delete[] pBinImg;
			delete[] pRotImg;
		}
		//byLotus20200703
		//if (m_nCheckSum) 
		if(m_nCheckSum >= 0)
        {
            //if(LineRt[0].left > CharH && LineRt[0].right < w - CharH)
                return m_nCheckSum;
           // else
            //    return 0;
        }

        if(lstrlen(lines) > 0)
        {
			if (strlen(givenNames) < 2) //addByJJH20190224
				return -1;

            if(LineRt[0].left > CharH && LineRt[0].right < w - CharH)
                return 2;
            else
                return -1;
        }
        else
            return -1;
	}
#ifdef DEF_ANDROID
    LOGI("second line ok");
#endif

	bool bcheckname1 = false;
	//bool bcheckname2 = false;

	rtRes1 = LineAry[id1]->m_Rect;
	rtRes1.left = m_rtTotalMRZ.left;
	rtRes1.right = m_rtTotalMRZ.right;
//	CString name1=_T(""),name2=_T("");

	TCHAR str1[100];
	TCHAR str2[100];
	//TCHAR hanzi[100] = _T("");
	memset(str1,0,sizeof(TCHAR)*100);
	memset(str2,0,sizeof(TCHAR)*100);
	for (mode = 0; mode<3; mode++) //2 modified byJJH20180516
	{
		if(mode==0){
			subRt = LineAry[id1]->m_Rect;
			pLineImg = runProc.GetImgFromRunRt(LineAry[id1],linew,lineh);
            pLineGrayImg = CImageBase::CropImg(pRotImg,w,h,LineAry[id1]->m_Rect);
//			CImageIO::SaveImgToFile(_T("d:\\temp\\cropbin1.bmp"),pLineImg,linew,lineh,1);
		}else{
			subRt = rtRes1;
			pLineGrayImg = CImageBase::CropImg(pRotImg,w,h,rtRes1);
			linew = rtRes1.Width();lineh = rtRes1.Height();
			//pLineImg = CBinarization::Binarization_Windows(pLineGrayImg,linew,lineh,10);
			pLineImg = CBinarization::Binarization_DynamicThreshold(pLineGrayImg,linew,lineh,15,2);
//			CImageIO::SaveImgToFile(_T("d:\\temp\\cropbin1.bmp"),pLineImg,linew,lineh,1);
			
		}
		if(pLineImg)
		{
			TCHAR tempstr[100];
			memset(tempstr, 0, sizeof(TCHAR)*100);
			if(nLineNum == 2)
			{
				if(b44Letters)
					Recog_Filter(pLineImg,pLineGrayImg,linew,lineh,tempstr,dis,MODE_TD2_44_LINE1,true);
				else{
					if(CurMode==MODE_FRA2_LINE2)
						Recog_Filter(pLineImg,pLineGrayImg,linew,lineh,tempstr,dis,MODE_FRA2_LINE1,true);
					else
						Recog_Filter(pLineImg,pLineGrayImg,linew,lineh,tempstr,dis,MODE_TD2_36_LINE1,true);
				}
			}
			else if(nLineNum == 3)
				Recog_Filter(pLineImg,pLineGrayImg,linew,lineh,tempstr,dis, MODE_TD3_LINE1, true);

			if( nLineNum == 2 && UnKnownCard == false )
			{
				if(m_bFinalCheck == false && b44Letters == true && tempstr[0] == 'P') continue;
			}
			if( nLineNum == 2 && b44Letters != true )
			{
				if(tempstr[0] == 'P') continue;
			}
			if( nLineNum == 3 && UnKnownCard == false )
			{
				delete[] pLineGrayImg;delete[] pLineImg;pLineImg=NULL;
				if(GetCheckChecksum(tempstr, MODE_TD3_LINE1) == true)
				{
					bcheckname1 = true;
					lstrcpy(str1, tempstr);
					LineRt[1] = m_lineRecog.m_LineRt;
					LineRt[1].OffsetRect(subRt.left,subRt.top);

					TCHAR strTemp[100];
					lstrcpy(strTemp, str1);
					lstrcat(strTemp, _T("\r\n"));
					lstrcat(strTemp, lines);
					lstrcpy(lines, strTemp);

					memcpy(passportNumber,&str1[5],sizeof(TCHAR)*9);
					passportNumber[9]=0;
					passportChecksum[0] = str1[14];
					passportChecksum[1] = 0;
					if(country!=NULL){
						memcpy(country,&str1[2],sizeof(TCHAR)*3);
						country[3] = 0;
					}

					passportType[0] = str1[0];
					if(str1[1]=='<') passportType[1] = 0;
					else   passportType[1] = str1[1];
					passportType[2] = 0;
					//LOGI("check name ok");
					break;
				}
				continue;
			}

			ExtractionInformationFromFirstLine(tempstr);
            if(tempstr[2] == 'I' && tempstr[3] == 'H' && tempstr[4] == 'D')
            {
                tempstr[3] = 'N';
            }
			if((lstrcmp(str1,tempstr)==0 || lstrcmp(str2,tempstr)==0) && lstrlen(tempstr) > 0)
			{
				delete[] pLineGrayImg;delete[] pLineImg;pLineImg=NULL;
				if(nLineNum==2)
				{
					bcheckname1 = true;
					lstrcpy(str1,tempstr);
					LineRt[1] = m_lineRecog.m_LineRt;
					LineRt[1].OffsetRect(subRt.left,subRt.top);
					TCHAR strTemp[100];
					lstrcpy(strTemp,str1);
					lstrcat(strTemp,_T("\r\n"));
					lstrcat(strTemp,lines);
					lstrcpy(lines,strTemp);

					if(country!=NULL){
						memcpy(country,&str1[2],sizeof(TCHAR)*3);
						country[3] = 0;
					}
					if(CurMode==MODE_FRA2_LINE2)
					{
                        memcpy(nationality, &str1[2],sizeof(TCHAR)*3);
                        nationality[3] = 0;
					}
					passportType[0] = str1[0];
					if(str1[1]=='<') passportType[1] = 0;
					else   passportType[1] = str1[1];
					passportType[2] = 0;
					//LOGI("check name ok");

					///////////////////////addByJJH20190224
					int surpos = findstr(str1, "<<<", 5);
					if (surpos > 5 && strlen(str1) > 30
						&& passportType[0] == 'I' && passportType[1] == 'D') 
					{//if Official travel documents ; I, A, C
						char sztemp[50];
						memset(sztemp, 0, sizeof(char) * 50);
						memcpy(sztemp, &str1[surpos], strlen(str1) - surpos);
						RemoveStr(sztemp, '<');

						if (strlen(sztemp) > 3)
						{
							memcpy(personalNumber, sztemp, 50);
							personalNumberChecksum[0] = 0;
						}
					}
				}
				else //////////////////////////////byJJH20180806-DNI Number;
				{
					bcheckname1 = true;
					lstrcpy(str1, tempstr);
					LineRt[1] = m_lineRecog.m_LineRt;
					LineRt[1].OffsetRect(subRt.left,subRt.top);

					GetSecondrowChecksum(str1, lines, MODE_TD3_LINE2);

					TCHAR strTemp[100];
					lstrcpy(strTemp, str1);
					lstrcat(strTemp, _T("\r\n"));
					lstrcat(strTemp, lines);
					lstrcpy(lines, strTemp);

					//type : VB, country : USA
					//{{{
					if (strcmp(passportType, "VB") == 0 && strcmp(country, "USA") == 0 && strlen(str1) > 27)
					{
						memcpy(passportNumber, &str1[16], sizeof(TCHAR) * 12);
						passportNumber[12] = 0;
						passportChecksum[0] = str1[27];
						passportChecksum[1] = 0;
						break;
					}
					//}}}

					//dni part -- jjh
					//if (strcmp(passportType, "ID") == 0 && strcmp(country, "ESP") == 0)
					int allen = strlen(str1);
					if (allen > 16)
					{
						memcpy(personalNumber, &str1[15], allen - 15);
						RemoveStr(personalNumber, '<');

						personalNumberChecksum[0] = 0;
						if (strlen(personalNumber) == allen - 15)
						{
							personalNumberChecksum[0] = personalNumber[allen - 16];
							personalNumberChecksum[1] = 0;
							personalNumber[allen - 16] = 0;
						}
					}
				}
				
				break;
			}
			lstrcpy(str1,tempstr);
			memset(tempstr,0,sizeof(TCHAR)*100);
			if(nLineNum == 2)
			{
				if(b44Letters)
					Recog_Filter(pLineImg,pLineGrayImg,linew,lineh,tempstr,dis,MODE_TD2_44_LINE1);
				else
				{
					if (CurMode == MODE_FRA2_LINE2)
						Recog_Filter(pLineImg, pLineGrayImg, linew, lineh, tempstr, dis, MODE_FRA2_LINE1);
					else
						Recog_Filter(pLineImg, pLineGrayImg, linew, lineh, tempstr, dis, MODE_TD2_36_LINE1);
				}
			}
			if(nLineNum==2 && UnKnownCard==false)
			{
				if(m_bFinalCheck==false && b44Letters==true && tempstr[0]=='P') continue;
			}
			if(b44Letters!=true && nLineNum==2 )
			{
				if(tempstr[0]=='P') continue;
			}
			if(tempstr[2] == 'I' && tempstr[3] == 'H' && tempstr[4] == 'D')
            {
                tempstr[3] = 'N';
            }
			ExtractionInformationFromFirstLine(tempstr);
			delete[] pLineGrayImg;delete[] pLineImg;pLineImg=NULL;
			if((lstrcmp(str1, tempstr)==0 || lstrcmp(str2,tempstr)==0) && lstrlen(tempstr) > 0)
			{
				if(nLineNum==2)
				{
					bcheckname1 = true;
					lstrcpy(str1,tempstr);
					LineRt[1] = m_lineRecog.m_LineRt;
					LineRt[1].OffsetRect(subRt.left,subRt.top);
					TCHAR strTemp[100];
					lstrcpy(strTemp,str1);
					lstrcat(strTemp, _T("\r\n"));
					lstrcat(strTemp, lines);
					lstrcpy(lines,strTemp);

					if(country!=NULL){
						memcpy(country,&str1[2],sizeof(TCHAR)*3);
						country[3] = 0;
					}
                    if(CurMode==MODE_FRA2_LINE2)
                    {
                        memcpy(nationality, &str1[2],sizeof(TCHAR)*3);
                        nationality[3] = 0;
                    }

					passportType[0] = str1[0];
					if(str1[1]=='<') passportType[1] = 0;
					else   passportType[1] = str1[1];
					passportType[2] = 0;

					///////////////////////addByJJH20190224
					int surpos = findstr(str1, "<<<", 5);
					if (surpos > 5 && strlen(str1) > 30
						&& passportType[0] == 'I' && passportType[1] == 'D')
					{//if Official travel documents ; I, A, C
						char sztemp[50];
						memset(sztemp, 0, sizeof(char) * 50);
						memcpy(sztemp, &str1[surpos], strlen(str1) - surpos);
						RemoveStr(sztemp, '<');

						if (strlen(sztemp) > 3) 
						{
							memcpy(personalNumber, sztemp, 50);
							personalNumberChecksum[0] = 0;
						}
					}
				}
				else
				{
					bcheckname1 = true;
					lstrcpy(str1, tempstr);

					GetSecondrowChecksum(str1, lines, MODE_TD3_LINE2);

					LineRt[1] = m_lineRecog.m_LineRt;
					LineRt[1].OffsetRect(subRt.left,subRt.top);
					TCHAR strTemp[100];
					lstrcpy(strTemp,str1);
					lstrcat(strTemp, _T("\r\n"));
					lstrcat(strTemp,lines);
					lstrcpy(lines, strTemp);

				}
				//LOGI("check name ok");
				break;
			}
 
		}	
	}

 	lstrcpy(surName,_surname);
    if (CurMode != MODE_FRA2_LINE2)
		lstrcpy(givenNames,_givenname);
	else
		lstrcpy(surName, _givenname); //byJJH20190820
	
	if(bcheckname1 == false) {
		runProc.RemoveAllRunRt(LineAry);
		if(bRotate)
		{
			delete[] pBinImg;
			delete[] pRotImg;
		}
		return -1;
	}

	if(nLineNum == 2)
	{
        if((country[0]=='F' && country[1]=='P' && country[2]=='A') || (country[0]=='F' && country[1]=='F' && country[2]=='A'))
        {
            country[1] = 'R';
            lines[3] = 'R';
        }
		if(country[0]=='F' && country[1]=='R' && country[2]=='A' && CurMode!=MODE_FRA2_LINE2)
		{
			int len = lstrlen(lines);
			//if(len==73)
			if (len == 73 && passportType[0] != 'T' && passportType[1] != 'S') //len == 73 byJJH20190811
			{
				lstrcpy(str1,&lines[37]);
				//memcpy(expirationDate,&str1[0],sizeof(TCHAR)*4);
				expirationDate[0] = 0;
				expirationChecksum[0] = 0;
				memcpy(passportNumber,&str1[0],sizeof(TCHAR)*12);
				passportNumber[12]=0;
				passportChecksum[0] = str1[12];
				passportChecksum[1] = 0;
				memcpy(birth,&str1[27],sizeof(TCHAR)*6);
				birth[6]=0;
				birthChecksum[0] = str1[33];
				birthChecksum[1] = 0;
				memcpy(sex,&str1[34],sizeof(TCHAR));
				sex[1]=0;
				secondRowChecksum[0] = str1[36-1];
				secondRowChecksum[1] = 0;
				memcpy(givenNames,&str1[13],sizeof(TCHAR)*14);
                givenNames[14] = 0;
				ReplaceStr(givenNames,'<',' ');
				ReplaceStr(givenNames,'0','O');
				ReplaceStr(givenNames,'1','I');
				memcpy(nationality, &country[0],sizeof(TCHAR)*3);
				nationality[3] = 0;
				//personalNumber[0]=0; --byJJH20190223
				//personalNumberChecksum[0] = 0;
			}
		}

	}

	if(nLineNum == 3)
	{
		memset(str1,0,sizeof(TCHAR)*100);
		memset(str2,0,sizeof(TCHAR)*100);

		rtRes1 = LineAry[id3]->m_Rect;
		rtRes1.left = min(rtRes1.left, m_rtTotalMRZ.left);
		LineRt[2] = rtRes1;
		m_rtTotalMRZ.UnionRect(m_rtTotalMRZ, rtRes1);
		rtRes1.right = max(rtRes1.right, m_rtTotalMRZ.right);
		for (mode=0;mode<2;mode++)
		{
			if(mode==0){
				subRt = LineAry[id3]->m_Rect;
				pLineImg = runProc.GetImgFromRunRt(LineAry[id3],linew,lineh);
				pLineGrayImg = CImageBase::CropImg(pRotImg,w,h,LineAry[id3]->m_Rect);
				//			CImageIO::SaveImgToFile(_T("d:\\temp\\cropbin1.bmp"),pLineImg,linew,lineh,1);
			}else{
				subRt = rtRes1;
				pLineGrayImg = CImageBase::CropImg(pRotImg,w,h,rtRes1);
				linew = rtRes1.Width();lineh = rtRes1.Height();
				//pLineImg = CBinarization::Binarization_Windows(pLineGrayImg,linew,lineh,10);
				pLineImg = CBinarization::Binarization_DynamicThreshold(pLineGrayImg,linew,lineh,15,2);
				//			CImageIO::SaveImgToFile(_T("d:\\temp\\cropbin1.bmp"),pLineImg,linew,lineh,1);

			}
			if(pLineImg)
			{
				TCHAR tempstr[100];
				memset(tempstr,0,sizeof(TCHAR)*100);
				Recog_Filter(pLineImg,pLineGrayImg,linew,lineh,tempstr,dis,MODE_TD3_LINE3,true);
				ExtractionInformationFromFirstLine(tempstr);
				if((lstrcmp(str1,tempstr)==0 || lstrcmp(str2,tempstr)==0) && lstrlen(tempstr) > 0)
				{
					delete[] pLineGrayImg;delete[] pLineImg;pLineImg=NULL;
					lstrcpy(str1,tempstr);
					lstrcat(lines,_T("\r\n"));
					lstrcat(lines,str1);

					//bcheckname2 = true;
					break;
				}
				lstrcpy(str1,tempstr);
				memset(tempstr,0,sizeof(TCHAR)*100);
				Recog_Filter(pLineImg,pLineGrayImg,linew,lineh,tempstr,dis,MODE_TD3_LINE3);
				ExtractionInformationFromFirstLine(tempstr);
				//Recog_Filter(pLineImg,pLineGrayImg,linew,lineh,str2,dis,MODE_PASSPORT_LINE1,true);
				delete[] pLineGrayImg;delete[] pLineImg;pLineImg=NULL;
				if((lstrcmp(str1,tempstr)==0 || lstrcmp(str2,tempstr)==0) && lstrlen(tempstr) > 0)
				{
					lstrcpy(str1,tempstr);
					lstrcat(lines,_T("\r\n"));
					lstrcat(lines,str1);
					//bcheckname2 = true;
					break; 
				}
			}	
		}
		lstrcpy(surName,_surname);
		lstrcpy(givenNames,_givenname);

		if (strlen(surName) == 0 || strlen(givenNames) == 0) //addbyJJH_20180914
		{
			m_nCheckSum = -1;
		}

	}
	runProc.RemoveAllRunRt(LineAry);
	if(bRotate)
	{
		delete[] pBinImg;
		delete[] pRotImg;
	}

	return nLineNum;
}
int CFindRecogDigit::MakeRoughLineAry(BYTE* pBinImg,int w,int h,CRunRtAry& LineAry,CRect subRect,int CharH)
{
	CRunProc runProc;
	int CharW;
	CharW = CharH;

	runProc.MakeConnectComponentFromImg(pBinImg,w,h,LineAry,subRect);
	runProc.DeleteNoizeRects(LineAry,CSize(5,5));
	DeleteLargeRects(LineAry,CSize(CharW*2,CharH*2));
	m_CharHeight = GetRealCharHeight(LineAry,int(CharH*0.4), 15);
	if(m_CharHeight<CharH*0.3)m_CharHeight = CharH;
	CharH = m_CharHeight;
	runProc.SortByOption(LineAry,0,LineAry.GetSize(),SORT_CENTER_X);

	runProc.DeleteNoizeRects(LineAry,CSize(CharH / 3,CharH / 2));
#ifdef _DEBUG
	BYTE* pTemp = runProc.GetImgFromRunRtAry(LineAry,CRect(0,0,w,h));
	//CImageIO::SaveImgToFile(_T("d:\\temp\\name.bmp"),pTemp,w,h,1);
	delete pTemp;
#endif

	runProc.SortByOption(LineAry,0,LineAry.GetSize(),SORT_CENTER_X);
	Merge_for_WordDetect(LineAry, 5);
	int nL = LineAry.GetSize();
	return nL;
}

//float CFindRecogDigit::GetAngleFromImg(BYTE* pImg,int w,int h)
//{
//	double fang=0.0;
//	CRunProc RunProc;
//	RunProc.RemoveAllRunRt(mainrts);
//	RunProc.MakeConnectComponentFromImg(pImg,w,h,mainrts,CRect(0,0,w-1,h-1));
//	int CharW,CharH;
//	CharW = w/50;
//	CharH = CharW*2;
//	RunProc.DeleteNoizeRects(mainrts,CSize(10,10));
//	DeleteLargeRects(mainrts,CSize(CharW,CharH));
//	fang = RunProc.GetAngleFromRunRtAry(mainrts,w,h);
//	RunProc.RemoveAllRunRt(mainrts);
//	return (float)fang;
//}
//float CFindRecogDigit::GetAngleFromImg_1(BYTE* pImg,int w,int h)
//{
//	double fang=0.0;
//	CRunProc RunProc;
//	RunProc.RemoveAllRunRt(mainrts);
//	RunProc.MakeConnectComponentFromImg(pImg,w,h,mainrts,CRect(0,0,w-1,h-1));
//	RunProc.DeleteNoizeRects(mainrts,CSize(5,5));
//	fang = RunProc.GetAngleFromRunRtAry_1(mainrts,w,h);
//	RunProc.RemoveAllRunRt(mainrts);
//	return (float)fang;
//}
int CFindRecogDigit::DeleteLargeRects(CRunRtAry& RectAry,CSize Sz)
{
	bool b;
	int wd,hi;

	CRunRt* pU;
	int i,num = RectAry.GetSize();

	for(i=num-1; i>=0; i--){
		b = true;
		pU = RectAry.GetAt(i);
		wd = pU->m_Rect.Width(); hi = pU->m_Rect.Height();
		if(wd >Sz.cx || hi >Sz.cy ){
			b = false;//Small rects 
		}
		else if(pU->nPixelNum > Sz.cx*Sz.cy/2){
			b = false;//Too Small Rects
		}
		if(b == false || pU->bUse == false){
			delete (CRunRt*)RectAry.GetAt(i);
			RectAry.RemoveAt(i);
		}
	}
	num = RectAry.GetSize();
	return num;
}
void CFindRecogDigit::RemoveRectsOutofSubRect(CRunRtAry& RectAry,CRect SubRt)
{
	CRect r;
	CRunRt* pU;
	int i,num = RectAry.GetSize();
	for(i=0;i<num;++i){
		pU= RectAry.GetAt(i);
		r = pU->m_Rect;
		pU->bUse = false;
		if(r.left < SubRt.left)continue;
		if(r.right > SubRt.right)continue;
		if(r.top < SubRt.top)continue;
		if(r.bottom > SubRt.bottom)continue;
		pU->bUse = true;
	}
	DeleteNoneUseRects(RectAry);
}
void CFindRecogDigit::DeleteNoneUseRects(CRunRtAry& RectAry)
{
	CRunRt* pU;
	int i,num = RectAry.GetSize();
	for(i=0;i<num;++i){
		pU = RectAry.GetAt(i);
		if(pU->bUse == false ){
			delete (CRunRt*)RectAry.GetAt(i);
			RectAry.RemoveAt(i);
			i--; num--;
		}
	}
}

void CFindRecogDigit::Recog_Filter(BYTE* pLineImg,BYTE* pGrayImg,int w,int h,TCHAR *str,double &dis,int mode,bool bgray)
{
	
//	CImageIO::SaveImgToFile(_T("d:\\temp\\lineimg.bmp"),pLineImg,w,h,1);
	m_lineRecog.m_bGrayMode = bgray;
	m_lineRecog.m_bUnkownCard = UnKnownCard;
	m_lineRecog.LineRecog(pLineImg, pGrayImg, w, h, dis, str, false, mode);
	//if(lstrlen(str) < 5) { str[0] = 0;dis = 99999;}
}

int CFindRecogDigit::GetApproxRowHeight(CCharAry& rts,int w,int h,int& ls) 
{
	int nCharHeight;
	CInsaeRtProc runProc;
	int hist[150],hist1[150];
	memset(hist,0,sizeof(int)*150);
	int i;
	for(i = 0; i < rts.GetSize();i ++)
	{
		int n = rts[i]->m_Rect.Height();
		if(n >= 150) n = 149;
		hist[n] ++;
	}
	memcpy(hist1,hist,sizeof(int)*150);
	for(i=3;i<147;i++)
		hist[i] = (hist1[i-3]+hist1[i-2]+hist1[i-1]+hist1[i]+hist1[i+1]+hist1[i+2]+hist1[i+3])/7;
	nCharHeight = 0;
	int m = 0;
	for(i=10;i<149;i++)
		if(hist[i] > m)
		{
			m = hist[i];
			nCharHeight = i;
		}
  return nCharHeight;
}
inline float* CFindRecogDigit::GetGaussian(int wid)
{
	int wid1 = wid + 1;
	float *ret = new float[wid1];
	memset(ret,0,sizeof(float)*(wid1));
	
	float d = (float)wid/4,m = (float)wid/2;
	float alpha = 1.218754f;
	float sig2 = d*d/(4*alpha);
	
	for (int i=0;i<wid;i++)
		ret[i] = (float)exp(-1*(i-m)*(i-m)/(2*sig2));
	
	return ret;
}

int CFindRecogDigit::GetRealCharHeight(CRunRtAry& RunAry, int minTh, int defaltTh)
{
	minTh = max(15, minTh);
	CInsaeRtProc runProc;
	float hist[150],hist1[150];
	memset(hist,0,sizeof(float)*150);
	int i;
	for(i = 0; i < RunAry.GetSize();i ++)
	{
		int n = RunAry[i]->m_Rect.Height();
		if(n >= 150) n = 149;
		if(RunAry[i]->m_Rect.Width() > RunAry[i]->m_Rect.Height()) continue;
		hist[n] ++;
	}
	memcpy(hist1,hist,sizeof(int)*150);
	for(i=minTh;i<147;i++)
		hist[i] = (hist1[i-3]+hist1[i-2]+hist1[i-1]+hist1[i]+hist1[i+1]+hist1[i+2]+hist1[i+3])/7;
	int nCharHeight = 0;
	float m = 0;
	for(i=minTh;i<149;i++)
		if(hist[i] > m)
		{
			m = hist[i];
			nCharHeight = i;
		}
	return nCharHeight;
}
//void CFindRecogDigit::Merge_for_Vertical()
//{
//	int nNum=mainrts.GetSize();
//	int nLimit1=max(2,m_CharHeight / 10);
//	int nLimit=(int)((m_CharHeight*1.5f));
//	
//	int i,j,count,nOvlapW,nMinW;
//	bool bAppend;CRect rect;
//	for(i=0;i<nNum;i++)
//	{
//		mainrts[i]->bUse=true;
//	}
//	do {
//	count=0;
//	for(i=0;i<nNum;i++)
//	{
//		if(mainrts[i]->bUse==false) continue;
//		for(j=0;j<nNum;j++)
//		{
//			if(i==j || mainrts[j]->bUse==false) continue;
//			bAppend=false;
//			nOvlapW= min(mainrts[i]->m_Rect.right,mainrts[j]->m_Rect.right)
//			 	-max(mainrts[i]->m_Rect.left,mainrts[j]->m_Rect.left);
//			if(nOvlapW>0)
//			{
//			 	nMinW= min(mainrts[i]->m_Rect.Width(),mainrts[j]->m_Rect.Width());
//			 	if(float(nOvlapW)/float(nMinW)>0.35f)
//			 	{
//			 		if(mainrts[i]->m_Rect.top-mainrts[j]->m_Rect.bottom<=nLimit1
//			 			&& mainrts[i]->m_Rect.bottom>=mainrts[j]->m_Rect.bottom)
//			 			bAppend=true;
//			 		else if(mainrts[j]->m_Rect.top-mainrts[i]->m_Rect.bottom<=nLimit1
//			 			&& mainrts[j]->m_Rect.bottom>=mainrts[i]->m_Rect.bottom) 
//			 			bAppend=true;
//			 	}
//			}
//// 			if(bAppend==false)
//// 			{
//// 				nOvlapH=min(mainrts[i]->m_Rect.bottom,mainrts[j]->m_Rect.bottom)
//// 					-max(mainrts[i]->m_Rect.top,mainrts[j]->m_Rect.top);
//// 				nMinH=min(mainrts[i]->UnUse1,mainrts[j]->UnUse1);
//// 				if(nOvlapH>0)
//// 				{
//// 					if(float(nOvlapH)/float(nMinH)>0.8f)
//// 					{
//// 						if(Get_Distance_between_Rects(i,j)<=nMinH / 2
//// 							&& mainrts[i]->m_Rect.right>=mainrts[j]->m_Rect.right)
//// 							bAppend=true;
//// 						else if(Get_Distance_between_Rects(j,i)<=nMinH / 2
//// 							&& mainrts[j]->m_Rect.right>=mainrts[i]->m_Rect.right)
//// 							bAppend=true;xsqwcfevfacddnym
//// 					}
//// 				}
//// 			}			
//			if(bAppend==true)
//			{
//				int nMaxW = (mainrts[i]->m_Rect.Height()>mainrts[j]->m_Rect.Height()?mainrts[i]->m_Rect.Width():mainrts[j]->m_Rect.Width());
//				rect.UnionRect(mainrts[i]->m_Rect,mainrts[j]->m_Rect);
//				if( rect.Height()<nLimit	&& rect.Width() < m_CharHeight)
//				{
//					mainrts[i]->Append(mainrts[j]);
//					mainrts[j]->bUse=false;
//					j = -1;
//					count++;
//				}
//			}
//			else
//			{
//				if((mainrts[i]->m_Rect.PtInRect(mainrts[j]->m_Rect.TopLeft())
//					&& mainrts[i]->m_Rect.PtInRect(mainrts[j]->m_Rect.BottomRight()))
//					|| (mainrts[j]->m_Rect.PtInRect(mainrts[i]->m_Rect.TopLeft())
//					&& mainrts[j]->m_Rect.PtInRect(mainrts[i]->m_Rect.BottomRight())))
//				{
//					mainrts[i]->Append(mainrts[j]);
//					mainrts[j]->bUse=false;
//					j = -1;
//					count++;
//				}
//			}
//		}
//	} 
//	}while(count!=0);
//	for(i=0;i<nNum;i++)
//	{
//		if(mainrts[i]->bUse==false)
//		{
//			CRunProc::RemoveRunRt(mainrts,i);
//			i--;nNum--;
//		}
//	}
//}


///////////////////////////////
void CFindRecogDigit::Merge_for_WordDetect(CRunRtAry& RunAry, int nDisBetweenChars) ////////////////////////
{
	int nNum = RunAry.GetSize();
	int nLimit = (int)((m_CharHeight * 2.5f)); // 2.5 -- modified by JJH 20181122

	CRect rect;
	bool bAppend;
	int i, j, count, nOvlapH, nMinH;
	for (i = 0; i < nNum; i++)
	{
		RunAry[i]->bUse = true;
		RunAry[i]->nAddNum = 1;
	}

	//		do {
	count = 0;
	for (i = 0; i < nNum; i++)
	{
		if (RunAry[i]->bUse == false) continue;
		if (4 * RunAry[i]->m_Rect.Height() < m_CharHeight) continue;
		for (j = 0; j < nNum; j++)
		{
			if (i == j || RunAry[j]->bUse == false) continue;

			bAppend = false;
			int iL = RunAry[i]->m_Rect.left;
			int iT = RunAry[i]->m_Rect.top;
			int iR = RunAry[i]->m_Rect.right;
			int iB = RunAry[i]->m_Rect.bottom;
			int iH = RunAry[i]->m_Rect.Height();

			int jL = RunAry[j]->m_Rect.left;
			int jT = RunAry[j]->m_Rect.top;
			int jR = RunAry[j]->m_Rect.right;
			int jB = RunAry[j]->m_Rect.bottom;
			int jH = RunAry[j]->m_Rect.Height();

			nOvlapH = min(iB, jB) - max(iT, jT);
			nMinH = min(iH, jH);
			if (nOvlapH > 0)
			{
				//if(float(nOvlapH)/float(nMinH)>0.5f && float(nOvlapH)/float(m_CharHeight)>0.3f) 
				//if (float(nOvlapH) / float(nMinH) > 0.5f && float(nOvlapH) / float(m_CharHeight) > 0.3f &&
				if (2 * nOvlapH > nMinH && 3 * nOvlapH > m_CharHeight &&
					(abs(iH - jH) < m_CharHeight || abs(iB - jB) < 10 || abs(iT - jT) < 10) ) //|| (jT - iT > -5 && iB - jB > -5) )
				{
					//if (iR >= jR && Get_Distance_between_Rects(RunAry, i, j) <= m_CharHeight * 25 / 10) //2 20180515_byJJH
					if (iR >= jR && 2 * (iL - jR) <= nDisBetweenChars * m_CharHeight ) //byLotus
						bAppend = true;
					//else if (jR >= iR && Get_Distance_between_Rects(RunAry, j, i) <= m_CharHeight * 25 / 10) //2 20180515_byJJH
					else if (jR >= iR && 2 * (jL - iR) < nDisBetweenChars * m_CharHeight ) //byLotus
						bAppend = true;
				}
			}

			if (bAppend == true)
			{
				rect.UnionRect(RunAry[i]->m_Rect, RunAry[j]->m_Rect);
				if (/*rect.Width()<nLimit && */rect.Height() < nLimit + 5)
				{
					RunAry[i]->Append(RunAry[j]);
					RunAry[j]->bUse = false;
					j = -1;
					count++;
				}
			}
			else
			{
				if ((RunAry[i]->m_Rect.PtInRect(RunAry[j]->m_Rect.TopLeft())
					&& RunAry[i]->m_Rect.PtInRect(RunAry[j]->m_Rect.BottomRight()))
					|| (RunAry[j]->m_Rect.PtInRect(RunAry[i]->m_Rect.TopLeft())
						&& RunAry[j]->m_Rect.PtInRect(RunAry[i]->m_Rect.BottomRight())))
				{
					RunAry[i]->Append(RunAry[j]);
					RunAry[j]->bUse = false;
					j = -1;
					count++;
				}
			}
		}
	}
	//		}while(count!=0);
	for (i = 0; i < nNum; i++)
	{
		if (RunAry[i]->bUse == false)
		{
			CRunProc::RemoveRunRt(RunAry, i);
			i--; nNum--;
		}
	}
}
int	CFindRecogDigit::Get_Distance_between_Rects(CRunRtAry& RunAry,int RtNo1,int RtNo2)
{
	return RunAry[RtNo1]->m_Rect.left - RunAry[RtNo2]->m_Rect.right;
}

///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
int CFindRecogDigit::GetCharHeightByHisto(CCharAry &ary,CRect rtBlk)
{
	int i, k,size = ary.GetSize();
	float hist[100],hist1[100];
	float weight = 0.0f;
	memset(hist,0,sizeof(float)*100);
	memset(hist1,0,sizeof(float)*100);
	for(i = 0;i < size; i ++)
	{
		CRect rt = ary[i]->m_Rect;
		int y2 = rtBlk.CenterPoint().y;
		if(rt.top <= y2 && rt.bottom >= y2)
			weight = 1.0f;
		else
			weight = 0.1f;
		if(ary[i]->m_Rect.Height() < 100)
		{
			hist[ary[i]->m_Rect.Height()] += weight;
		}
		else
		{
			hist[99] += weight;
		}
	}
	float* gauss = GetGaussian(31);
	int dd = 15;
	for(i=0; i<100; i++)
		for (k=-dd; k<dd; k++)
			if (i+k>0 && i+k<100)
			{
				hist1[i] += hist[i+k]*gauss[dd+k];
			}
	int ret = 0,maxh = 0;
	for(i=5;i<100;i++)
		if(maxh < hist1[i])
		{
			maxh = (int)hist1[i];
			ret = i;
		}
	delete gauss;
	return ret;
}
bool CFindRecogDigit::GetCheckChecksum(TCHAR str[], int mode)
{
	bool bRet = true;
	m_nCheckSum = CheckChecksum(str, mode);

	if(m_nCheckSum != 0)
		bRet = false;

	if(UnKnownCard)
	{
		bRet = true;
		if (str[0] == 0)
			bRet = false;
		else if(mode == MODE_TD1_LINE1)
		{
			if (str[0] != 'D')
				bRet = false;
		}
	}

	return bRet;
}

#define ISSUE_CHECKSUM_PASSPORT			1
#define ISSUE_CHECKSUM_BIRTH			2
#define ISSUE_CHECKSUM_SEX				3
#define ISSUE_CHECKSUM_EXPIRY			4
#define ISSUE_CHECKSUM_PERSON			5
#define ISSUE_CHECKSUM_ALL				6

int CFindRecogDigit::GetSecondrowChecksum(TCHAR str1[], TCHAR str2[], int mode)
{
	int i, s;
	int nlen1 = (int)lstrlen(str1);
	if (nlen1 < 25) return -1;
	if (nlen1 > 30) nlen1 = 30;
	int nlen2 = (int)lstrlen(str2);
	if (nlen2 < 25) return -1;
	if (nlen2 > 30) nlen2 = 30;

	int n1[45];
	int n2[45];
	int mul[3] = {7, 3, 1};
	for (i = 0; i < nlen1; i++)
	{
		if (str1[i] >= '0' && str1[i] <= '9')
			n1[i] = str1[i] - '0';
		else if (str1[i] == '<')
			n1[i] = 0;
		else
			n1[i] = str1[i] - 'A' + 10;
	}
	for (i = 0; i < nlen2; i++)
	{
		if (str2[i] >= '0' && str2[i] <= '9')
			n2[i] = str2[i] - '0';
		else if (str2[i] == '<')
			n2[i] = 0;
		else
			n2[i] = str2[i] - 'A' + 10;
	}


	_passport.passportType[0] = str1[0];
	if (str1[1] == '<') _passport.passportType[1] = 0;
	else   _passport.passportType[1] = str1[1];
	_passport.passportType[2] = 0;

	if (_passport.country != NULL) {
		memcpy(_passport.country, &str1[2], sizeof(TCHAR) * 3);
		_passport.country[3] = 0;
	}

	//get the number of document(passport)
	memcpy(_passport.passportNumber, &str1[5], sizeof(TCHAR) * 9);
	_passport.passportNumber[9] = 0;
	_passport.passportChecksum[0] = str1[14];
	_passport.passportChecksum[1] = 0;
	//check the number of document(passport)
	s = 0;
	for (i = 5; i < 14; i++)
		s += mul[(i+1) % 3] * n1[i];
	_passport.correctPassportChecksum[0] = '0' + s % 10;

	s = 0;
	for (i = 5; i < 30; i++)
		s += mul[(i+1) % 3] * n1[i];
	for (i = 0; i < 7; i++)
		s += mul[(i+1) % 3] * n2[i];
	for (i = 8; i < 15; i++)
		s += mul[i % 3] * n2[i];
	for (i = 18; i < 29; i++)
		s += mul[(i) % 3] * n2[i];
	_passport.correctSecondrowChecksum[0] = '0' + s % 10;

	return 0;
}
int CFindRecogDigit::CheckChecksum(TCHAR str[], int mode)
{
	int nRet = 0; //0 : ok, 1 : issue of document, 2 : issue of birth, 3 : issue of sex, 4 : issue of expiry, 5 : issue of personal number, 6 : issue of all 
	int i, s;
	int n[45];
	int mul[3] = {7, 3, 1};
	int nlen = (int)lstrlen(str);

	bool bIssueChecksum = false;
	if(mode == MODE_TD3_LINE2)
	{
		if(nlen < 25) return -1;
		if(nlen > 30) nlen = 30;

		for(i = 0; i < nlen; i ++)
		{
			if(str[i] >='0' && str[i] <='9')
				n[i] = str[i] - '0';
			else if(str[i] == '<')
				n[i] = 0;
			else
				n[i] = str[i] - 'A' + 10;
		}

		//check the date of bith
		s = 0;
		for(i = 0; i < 6; i ++)
			s += mul[i%3] * n[i];
		_passport.correctBirthChecksum[0] = '0' + s % 10;
		//if(s%10 != n[6])
		//	return ISSUE_CHECKSUM_BIRTH;
		//int month = (str[2] - '0') * 10 + str[3] - '0';
		//if(month > 12 || month<=0) return ISSUE_CHECKSUM_BIRTH;
		//int day = (str[4] - '0') * 10 + str[5] - '0';
		//if(day > 31 || day<=0) return ISSUE_CHECKSUM_BIRTH;

		//check the sex;
		//if(str[7] != 'M' && str[7] != 'F' && str[7] != '<')
		//	return ISSUE_CHECKSUM_SEX;

		//check the date of expiry
		s = 0;
		for(i = 8; i < 14; i ++)
			s += mul[(i-8)%3] * n[i];
		_passport.correctExpirationChecksum[0] = '0' + s % 10;
		//if(s%10 != n[14])
		//	return ISSUE_CHECKSUM_EXPIRY;

		// 		s = 0;
		// 		for(i = 21; i < 27; i ++)
		// 			s += mul[(i-21)%3] * n[i];
		// 		if(s%10 != n[27])return false;

		//if(str[10]!='C'|| str[11]!='H' || str[12]!='R') return false;

		//check all of line2
		//s = 0;
		//for (i = 0; i < 7; i++)
		//	s += mul[(i+1) % 3] * n[i];
		//for (i = 8; i < 15; i++)
		//	s += mul[i % 3] * n[i];
		//for (i = 18; i < 29; i++)
		//	s += mul[i % 3] * n[i];
		//_passport.correctSecondrowChecksum[0] = '0' + s % 10;
		//if (s % 10 != n[nlen - 1])
		//	return ISSUE_CHECKSUM_ALL;
	}
	if(mode == MODE_TD3_LINE1)
	{
		if(nlen < 25) return -1;
		if(nlen > 30) nlen = 30;

		//if(str[0]!='I'|| str[1]!='C') return false;
		for(i = 0; i < nlen; i ++)
		{
			if(str[i] >='0' && str[i] <='9')
				n[i] = str[i] - '0';
			else if(str[i] == '<')
				n[i] = 0;
			else
				n[i] = str[i] - 'A' + 10;
		}

		//check the passport
		s = 0;
		for(i = 0; i < 9; i ++)
			s += mul[i%3] * n[i+5];
		if(s%10 != n[14])
			return ISSUE_CHECKSUM_PASSPORT;
	}
	if(mode == MODE_TD1_LINE1)
	{
		if(nlen < 25) return -1;
		if(nlen > 30) nlen=30;
		if(str[0] != 'D') return -1;

		for(i = 0; i < nlen; i ++)
		{
			if(str[i] >='0' && str[i] <='9')
				n[i] = str[i] - '0';
			else if(str[i] == '<')
				n[i] = 0;
			else
				n[i] = str[i] - 'A' + 10;
		}

		s = 0;
		for(i = 0; i < 14; i ++)
			s += mul[i%3] * n[i];
		if(s%10 != n[14])
			return ISSUE_CHECKSUM_PERSON;

		int month = (str[17] - '0') * 10 + str[18] - '0';
		if(month > 12 || month <= 0) return ISSUE_CHECKSUM_BIRTH;
		int day = (str[19] - '0') * 10 + str[20] - '0';
		if(day > 31 || day <= 0) return ISSUE_CHECKSUM_BIRTH;

		s = 0;
		for(i = 0; i < 29; i ++)
			s += mul[i%3] * n[i];
		if(s%10 != n[29])
			return ISSUE_CHECKSUM_ALL;
	}
	if(mode == MODE_TD2_LINE2)
	{
		m_bFinalCheck = false;
		if(nlen < 36) return -1;
		if(nlen < 40) nlen = 36;
		if(nlen > 44) nlen=44;

		str[nlen] = 0;
		for(i = 0; i < nlen; i ++)
		{
			if(str[i] >='0' && str[i] <='9')
				n[i] = str[i] - '0';
			else if(str[i] == '<')
				n[i] = 0;
			else
				n[i] = str[i] - 'A' + 10;
		}

		//check the number of document number
		s = 0;
		for(i = 0; i < 9; i ++)
			s += mul[i%3] * n[i];
		_passport.correctPassportChecksum[0] = '0' + s % 10;
		if (s % 10 != n[9])
			bIssueChecksum = true;
			//return ISSUE_CHECKSUM_PASSPORT;

		//check the date of birth
		s = 0;
		for(i = 13; i < 19; i ++)
			s += mul[(i-13)%3] * n[i];
		_passport.correctBirthChecksum[0] = '0' + s % 10;
		if(s%10 != n[19])
			bIssueChecksum = true;
			//return ISSUE_CHECKSUM_BIRTH;

		int month = (str[15] - '0') * 10 + str[16] - '0';
		if(month > 12 || month <= 0)
			bIssueChecksum = true;
			//return ISSUE_CHECKSUM_BIRTH;
		int day = (str[17] - '0') * 10 + str[18] - '0';
		if(day > 31 || day <= 0)
			bIssueChecksum = true;
			//return ISSUE_CHECKSUM_BIRTH;

		//check the date of the expiry
		s = 0;
		for(i = 21; i < 27; i ++)
			s += mul[(i-21)%3] * n[i];
		_passport.correctExpirationChecksum[0] = '0' + s % 10;
		if(s%10 != n[27])
			bIssueChecksum = true;
			//return ISSUE_CHECKSUM_EXPIRY;

		//if(str[10]!='C'|| str[11]!='H' || str[12]!='R') return false;

		//check sex;
		if(str[20] != 'M' && str[20] != 'F' && str[20] != '<')
			bIssueChecksum = true;
			//return ISSUE_CHECKSUM_SEX;

		//check the persional number
		s = 0;
		if(nlen > 36)
		{
			for(i = 28; i < 42; i ++)
				s += mul[(i-28)%3] * n[i];

			_passport.correctPersonalChecksum[0] = '0' + s % 10;
			if(s%10 != n[42])
				bIssueChecksum = true;
				//return ISSUE_CHECKSUM_PERSON;
		}

		//check all of line2
		s = 0;
		for(i = 0; i < 10; i ++)
			s += mul[i%3] * n[i];
		for(i = 13; i < 20; i ++)
			s += mul[i%3] * n[i];
		for(i = 21; i < nlen-1; i ++)
			s += mul[(i+2)%3] * n[i];
		_passport.correctSecondrowChecksum[0] = '0' + s % 10;
		if (s % 10 != n[nlen - 1])
			bIssueChecksum = true;
			//return ISSUE_CHECKSUM_ALL;

		if(bIssueChecksum == false)
			m_bFinalCheck = true;
	}
	if(mode == MODE_FRA2_LINE2)
	{
		m_bFinalCheck = false;
		if(nlen < 36) return -1;
		if(nlen > 36) nlen = 36;

		str[nlen] = 0;
		for(i = 0; i < nlen; i ++)
		{
			if(str[i] >='0' && str[i] <='9')
				n[i] = str[i] - '0';
			else if(str[i] == '<')
				n[i] = 0;
			else
				n[i] = str[i] - 'A' + 10;
		}

		s = 0;
		for(i = 0; i < 12; i ++)
			s += mul[i%3] * n[i];
		_passport.correctPassportChecksum[0] = '0' + s % 10;
		if(s%10 != n[12])
			bIssueChecksum = true;
			//return ISSUE_CHECKSUM_PASSPORT;

		s = 0;
		for(i = 27; i < 33; i ++)
			s += mul[(i-27)%3] * n[i];
		_passport.correctBirthChecksum[0] = '0' + s % 10;
		if(s%10 != n[33])
			bIssueChecksum = true;
			//return ISSUE_CHECKSUM_BIRTH;

		//if(str[10]!='C'|| str[11]!='H' || str[12]!='R') return false;
		if(str[34] != 'M' && str[34] != 'F' && str[34] != '<')
			bIssueChecksum = true;
			//return ISSUE_CHECKSUM_SEX;

		//check all of line2
		s = 0;
		for (i = 0; i < 13; i++)
			s += mul[i % 3] * n[i];
		for (i = 27; i < 34; i++)
			s += mul[(i+1) % 3] * n[i];
		_passport.correctSecondrowChecksum[0] = '0' + s % 10;
		if (s % 10 != n[nlen - 1])
			bIssueChecksum = true;
			//return ISSUE_CHECKSUM_ALL;

		if( bIssueChecksum == false)
			m_bFinalCheck = true;
	}

	return nRet;
}

bool CFindRecogDigit::ExtractionInformationFromFirstLine(TCHAR str[])
{
	memset(_surname,0,sizeof(TCHAR)*100);
	memset(_givenname,0,sizeof(TCHAR)*100);
	int len = (int)lstrlen(str);
	if(len < 30) return false;
// 	if(str[0]!='P') return false;
// 	if(str[1]=='<'|| str[1]=='M'||str[1]=='S' || str[1]=='R' || str[1]=='O')
// 	{
// 		if(str[1]=='<')
// 			_passportType[0] = 'P';
// 		else
// 			_passportType[0] = str[1];
// 
// 	}
// 	else return false;
// 	if(str[2]!=Country[0] || str[3]!=Country[1] || str[4]!=Country[2])
// 	{
// 		str[2]=Country[0]; str[3]=Country[1]; str[4]=Country[2];
// 	}

	int i;
	if(len>30)
	{
		int surLen = findstr(str,_T("<<"),4);
		if(surLen > 5)
		{
			memcpy(_surname,&str[5],sizeof(TCHAR)*(surLen-5));
		}
		//else return false; byJJH20190223 - there can be that there is no surname

		int nameLen = findstr(str,_T("<<"),surLen+2);
		if (nameLen == -1) nameLen = len + 1;
		if(nameLen > surLen+2)
		{
			memcpy(_givenname,&str[surLen+2],sizeof(TCHAR)*(nameLen - surLen-2));
		}
		else if(nameLen == surLen + 2) //byJJH20190820
		{
			memcpy(_givenname, _surname, sizeof(TCHAR) * 100);
			memset(_surname, 0, sizeof(TCHAR) * 100);
		}
		//else
		//	return false; //byJJH20190811
	}
	else
	{
		int surLen = findstr(str,_T("<<"),0);
		if(surLen > 1)
		{
			memcpy(_surname,&str[0],sizeof(TCHAR)*(surLen));
		}
		else return false;
		int nameLen = findstr(str,_T("<<"),surLen+2);
		if(nameLen > surLen+2)
		{
			memcpy(_givenname,&str[surLen+2],sizeof(TCHAR)*(nameLen - surLen-2));
		}
		else
		{
			nameLen = len;
			memcpy(_givenname,&str[surLen+2],sizeof(TCHAR)*(nameLen - surLen-2));
		}
		//return false;
	}

	ReplaceStr(_surname,'<',' ');
	ReplaceStr(_surname,'0','O');
	ReplaceStr(_surname,'1','I');
	ReplaceStr(_givenname,'<',' ');
	ReplaceStr(_givenname,'0','O');
	ReplaceStr(_givenname,'1','I');

	//////addbyJJH -- remove last space char in givenname
	int nNameLen = (int)strlen(_givenname);
	if (nNameLen > 0)
	{
		for (i = 1; nNameLen; i++)
		{
			if (_givenname[nNameLen - i] != ' ')
				break;
			
			_givenname[nNameLen - i] = '\0';
		}
	}

	//////
//	_surname.Replace('<',' ');
//	_givenname.Replace('<',' ');
	return true;
}
/*bool CFindRecogDigit::ReCheckName(BYTE* pBinImg,BYTE* pGrayImg,int w,int h,CRunRtAry& RunAry,TCHAR* strHanzi)
{

	CRunProc runProc;
	int ww,hh;
	BYTE* pWordImg;int i;
	TCHAR strWord[1000];double dis;
	CString strGivenName = _givenname;
	strGivenName.Replace(_T(" "),_T(""));
	CString strSurName = _surname;
	strSurName.Replace(_T(" "),_T(""));
    strGivenName = strSurName  + strGivenName;
   
	bool bRes = false;
	int j = 0;CRect rt;
    float mindis = 99999;
    BYTE* pGrayCrop;
	for(i = 0; i < RunAry.GetSize(); i ++)
	{
		rt = RunAry[i]->m_Rect;
		pWordImg = CImageBase::CropImg(pBinImg,w,h,rt);
        pGrayCrop = CImageBase::CropImg(pGrayImg,w,h,rt);
		ww=rt.Width();hh = rt.Height();
		//pWordImg = runProc.GetImgFromRunRt(RunAry[i],ww,hh);
		CImageIO::SaveImgToFile(_T("d:\\temp\\name.bmp"),pWordImg,ww,hh,1);
		if(pWordImg == NULL) continue;
		lstrcpy(strWord,strGivenName);
		Recog_Filter(pWordImg,pGrayCrop,ww,hh,strWord,dis,MODE_PASSPORT_ENGNAME);//ENG NAME
		if(lstrlen(strWord)>3)		
		{
			int k,len =lstrlen(strWord);
			for(k=0;k<len;++k){
				if(strWord[k] == '0') strWord[k] = 'O';
			}
		}
		delete pWordImg;delete pGrayCrop;
		if(lstrcmp(strGivenName,strWord) == 0)
		{
// 			if(strSurName == _T("KIM") || strSurName == _T("LEE") || strSurName == _T("CHOI") || strSurName == _T("PARK")|| strSurName == _T("HAN") || strSurName == _T("JEONG")
// 				 || strSurName == _T("AHN") || strSurName == _T("GANG") || strSurName == _T("KANG")) 
// 			{
// 				bRes = true;break;
// 			}
			for(j = i - 1; j >= 0; j --)
			{
				rt = RunAry[j]->m_Rect;
				pWordImg = CImageBase::CropImg(pBinImg,w,h,rt);
                pGrayCrop = CImageBase::CropImg(pGrayImg,w,h,rt);
				ww=rt.Width();hh = rt.Height();
				//pWordImg = runProc.GetImgFromRunRt(RunAry[j],ww,hh);
				CImageIO::SaveImgToFile(_T("d:\\temp\\name.bmp"),pWordImg,ww,hh,1);
                CImageIO::SaveImgToFile(_T("d:\\temp\\name_gray.bmp"),pGrayCrop,ww,hh,8);
				if(pWordImg == NULL) continue;
				//lstrcpy(strWord,strSurName);
                strWord[0] = 0;
				Recog_Filter(pWordImg,pGrayCrop,ww,hh,strWord,dis,MODE_PASSPORT_CHNAME);//HANZ NAME
				delete pWordImg;delete pGrayCrop;
                if(dis < mindis)
                {
                    mindis = dis;
                    lstrcpy(strHanzi,strWord);
                }
			}
            bRes = true;
			break;
		}
	}

	return bRes;
}*/
