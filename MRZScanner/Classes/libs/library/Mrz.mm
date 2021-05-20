#include <stdio.h>
#include <iostream>
#include <string>
#include "Cardrec.h"
#include "StdAfx.h"
#include "FindRecogDigit.h"
#include "ImageBase.h"
#include "ImageFilter.h"
#include "Rotation.h"
#include "imgproc.h"
#include "Binarization.h"

#define _WIDTH		900 //860

BYTE* makeRotatedDib(BYTE* dib, int rot);
//void convPix2Byte(PIX* pix, BYTE* pbyImg, int &nC);
//BYTE* convPix2Dib(PIX* src_pix, int sw, int &w, int &h, int &c);
//PIX* convByte2Pix(BYTE* pbyImg, int nW, int nH, int nC);

BYTE* convRgb2Dib(char *img_rgb, int w, int h, int c, int w_new, int h_new, int c_new)
{
	int size = w_new * h_new * c_new;
	BYTE* pixels = new BYTE[size];
	im_Resize((BYTE*)img_rgb, w, h, c, pixels, w_new, h_new);

	BYTE* pTempDib = CImageBase::MakeDib(w_new, h_new, 24);
	BYTE* pBits = CImageBase::Get_lpBits(pTempDib);

	int wstep_d = (24 * w_new + 31) / 32 * 4;
	BYTE* srcData = pixels;
	BYTE* dstData = pBits + wstep_d * (h_new - 1);
	int wstep_s = w_new * c;
	for (int y = 0; y < h_new; y++)
	{
		memcpy(dstData, srcData, wstep_s);
		srcData += wstep_s;
		dstData -= wstep_d;
	}

	BYTE* byImg = makeRotatedDib(pTempDib, 90);
	delete[] pTempDib;
	delete[] pixels;

	return byImg;
}

void Cardrec::initMrz()
{
	_digitp = new CFindRecogDigit();
	_bRecognized = false;
	memset(_szResult, 0, 1024);
}

bool Cardrec::loadMrz(char* dic, int ndicLen, char* dic1, int ndicLen1)
{
	if (!_digitp) return false;

	bool ret = false;
	ret = _digitp->m_lineRecog.m_RecogBottomLine1Gray.LoadDicRes((BYTE*)dic, ndicLen);
	if (!ret) return ret;

	ret = _digitp->m_lineRecog.m_RecogBottomLine1.LoadDicRes((BYTE*)dic1, ndicLen1);
	if (!ret) return ret;

	return true;
}

int Find_BorderCard(BYTE* pImgRGB, int w, int h, CRect &rtCrop)
{
	int nRet = 0;
	int w_org = w;
	int h_org = h;

	int size = w * h;
	int w_new = 1024;
	float fRatio = (float)w_new / (float)w;
	int h_new = (int)(fRatio * h);
	BYTE *pReRGB = new BYTE[3 * w_new * h_new];
	im_Resize((BYTE*)pImgRGB, w, h, 3, pReRGB, w_new, h_new);
	w = w_new; h = h_new;
	BYTE *pGrayOrg = CImageBase::MakeGrayImgFrom24Img((BYTE*)pReRGB, w, h);
	BYTE *pBinOrg = CBinarization::Binarization_Windows(pGrayOrg, w, h, 5);

	CImageFilter::imDilate(pBinOrg, pGrayOrg, w, h, 6);
	CImageFilter::imErode(pGrayOrg, pBinOrg, w, h, 8);
//#ifdef LOG_VIEW
//	//IplImage *imgView = getIplImage((BYTE*)img_rgb, w, h, 3);
//	Mat imgView = getMatImage((BYTE*)pGrayOrg, w, h, 0);
//	DisplayMatImage(imgView, true);
//	imgView.release();
//
//	imgView = getMatImage((BYTE*)pBinOrg, w, h, 0);
//	DisplayMatImage(imgView, true);
//	imwrite("Crop.jpg", imgView);
//	imgView.release();
//#endif

	rtCrop.left = w;
	rtCrop.top = h;
	rtCrop.right = 0;
	rtCrop.bottom = 0;
	for (int i = 0; i < h; i++) {
		int pos = i * w;
		for (int j = 0; j < w; j++) {
			if (pBinOrg[pos + j] != 1)
				continue;
			if (rtCrop.left > j)
				rtCrop.left = j;
			if (rtCrop.right < j)
				rtCrop.right = j;
			if (rtCrop.top > i)
				rtCrop.top = i;
			if (rtCrop.bottom < i)
				rtCrop.bottom = i;
		}
	}

	if (rtCrop.left == w) rtCrop.left = 0;
	if (rtCrop.top == h) rtCrop.top = 0;
	if (rtCrop.right == 0) rtCrop.left = w;
	if (rtCrop.bottom == 0) rtCrop.left = h;

	if (3 * rtCrop.Width() < 2 * w)
		nRet = 1;
	if (3 * rtCrop.Height() < 2 * h)
		nRet = 1;

	if (nRet == 1)
	{
		rtCrop.left = (int)(rtCrop.left / fRatio);
		rtCrop.top = (int)(rtCrop.top / fRatio);
		rtCrop.right = (int)(rtCrop.right / fRatio);
		rtCrop.bottom = (int)(rtCrop.bottom / fRatio);

		rtCrop.left = max(0, rtCrop.left - 50);
		rtCrop.top = max(0, rtCrop.top - 50);
		rtCrop.right = min(w_org, rtCrop.right + 50);
		rtCrop.bottom = min(h_org, rtCrop.bottom + 50);
	}

	//CImageFilter::RemoveNoizeBinImg()

	delete[] pBinOrg; pBinOrg = nullptr;
	delete[] pGrayOrg; pGrayOrg = nullptr;

	return nRet;
}
int Cardrec::doRecognizeCrop(char* img_rgb, int w, int h, int x_crop, int y_crop, int w_crop, int h_crop)
{
	int res = -1;
	if (!_bLoaded) return res;
	if (!_digitp) return res;

	if (img_rgb == NULL || w == 0 || h == 0)
		return res;

	char chCodeBotLine1[] = _T("ABCDEFGHIJKLMNOPQRSTUVWXYZ<");
	WORD codebotLine1[30];
	int i;
	for (i = 0; i < 27; i++)
		codebotLine1[i] = chCodeBotLine1[i];

	_digitp->m_lineRecog.m_RecogBottomLine1.SetSelCodeIdTable(codebotLine1, 27);
	_digitp->m_lineRecog.m_RecogBottomLine1Gray.SetSelCodeIdTable(codebotLine1, 27);

	int size = w * h;	
	BYTE* gray = new BYTE[size];
	memset(gray, 0, size * sizeof(BYTE));

	if (w_crop == -1 || h_crop == -1) {
		//im_RGB2Gray((BYTE*)img_rgb, gray, w, h, 3);
		for (i = 0; i < size; i++)
		{
			int pos = i * 3;
			BYTE r = img_rgb[pos];
			BYTE g = img_rgb[pos + 1];
			BYTE b = img_rgb[pos + 2];
//			if (r > 120 && (r - b) > 30)
//				gray[i] = r;
//			else
			gray[i] = (((int)r * 117 + (int)g * 601 + (int)b * 306) >> 10);
		}
	}
	else {
		w_crop = min(w_crop, w - x_crop);
		h_crop = min(h_crop, h - h_crop);
		int wstep = w * 3;
		int wstep_crop = w_crop * 3;
		int top = y_crop * wstep;
		int left = x_crop * 3;
		for (int i = 0; i < h_crop; i++)
		{
			int pos = left + top + i * wstep;
			int pos_crop = i * w_crop;
			for (int j = 0; j < w_crop; j++)
			{
				BYTE r = (BYTE)img_rgb[pos + 3 * j];
				BYTE g = (BYTE)img_rgb[pos + 3 * j + 1];
				BYTE b = (BYTE)img_rgb[pos + 3 * j + 2];

				//if ((BYTE)b > 120 && (BYTE)(b-r) > 30)
				if (r > 120 && r - b > 30)
					gray[pos_crop + j] = 255;
				else
					gray[pos_crop + j] = (((int)r * 117 + (int)g * 601 + (int)b * 306) >> 10);
			}
		}

		w = w_crop;
		h = h_crop;
	}

#ifdef LOG_VIEW
	cv::Mat matView = getMatImage((BYTE*)gray, w, h, 1);
	DisplayMatImage(matView, true);
#endif //LOG_VIEW

	PassportData* pPtData = &_digitp->_passport;
	int ary_width[] = { 1200, _WIDTH };
	for (int cnt = 0; cnt < 2; cnt++)
	{
		//if (_digitp->m_tmpColorDib)
		//	delete[] _digitp->m_tmpColorDib;
		//_digitp->m_tmpColorDib = NULL;

		int sw = ary_width[cnt];
		float fscalex = (float)sw / (float)w;// src_pix->w);
		int sh = ((int)(h * fscalex * 8 + 31) / 32) * 4;
		//_digitp->m_tmpColorDib = convRgb2Dib(img_rgb, w, h, 3, sw, sh, 3);// ary_height[cnt], 3);

		int w_new = sw;
		int h_new = sh;// ary_height[cnt];
		size = w_new * h_new;
		BYTE* imgGray = new BYTE[size];
		im_Resize((BYTE*)gray, w, h, 1, imgGray, w_new, h_new);

		//BYTE* imgGray = CImageBase::MakeGrayImg(_digitp->m_tmpColorDib, w_new, h_new);
		CImageFilter::CorrectBrightForCameraImg(imgGray, w_new, h_new);
		CImageFilter::MeanFilter(imgGray, w_new, h_new);

		_digitp->UnKnownCard = true;
		memset(_szResult, 0, 1024);
		memset(pPtData, 0, sizeof(PassportData));

		res = _digitp->Find_RecogImg_Main(imgGray, w_new, h_new, false);
		if (res == -3)
		{
			delete[] imgGray; imgGray = NULL;
			break;
		}

		if (cnt > 0 && res < 0) //failed
		{//noise remove
			int size = w_new * h_new;
			BYTE* tmpBits = new BYTE[size];
			CImageFilter::imDilate(imgGray, tmpBits, w_new, h_new, 3);
			res = _digitp->Find_RecogImg_Main(tmpBits, w_new, h_new, false);
			delete[] tmpBits;
		}

		delete[] imgGray; imgGray = NULL;

		if (res >= 0)
			break;
	}

	delete[]gray; gray = NULL;

	if (res > 0)
		_bRecognized = true;

	return res;
}
//int Cardrec::doRecognize(char* img_rgb, int w, int h, bool bReadAddress)
//{
//	if (!_bLoaded) return -1;
//	if (!_digitp) return -1;
//	if (img_rgb == NULL || w == 0 || h == 0)
//		return -1;
//
//	_bRecognized = false;
//	_bReadAddress = bReadAddress;
//
//	char chCodeBotLine1[] = _T("ABCDEFGHIJKLMNOPQRSTUVWXYZ<");
//	WORD codebotLine1[30];
//	int i;
//	for (i = 0; i < 27; i++)
//		codebotLine1[i] = chCodeBotLine1[i];
//
//	_digitp->m_lineRecog.m_RecogBottomLine1.SetSelCodeIdTable(codebotLine1, 27);
//	_digitp->m_lineRecog.m_RecogBottomLine1Gray.SetSelCodeIdTable(codebotLine1, 27);
//
//
//	//CRect rtCrop;
//	//BYTE *pImgCrop = NULL;
//	//int bCrop = 0;
//	//if (w > 1200 || h > 1200)
//	//	bCrop = Find_BorderCard((BYTE*)img_rgb, w, h, rtCrop);
//
//	//if (bCrop > 0)
//	//{
//	//	int ww = rtCrop.Width();
//	//	int hh = rtCrop.Height();
//	//	int wstep = w * 3;
//	//	int wstep_crop = ww * 3;
//	//	int left = rtCrop.left * 3;
//	//	pImgCrop = new BYTE[wstep_crop * hh];
//	//	for (int i = rtCrop.top; i < rtCrop.bottom; i++)
//	//	{
//	//		int pos = left + i * wstep;
//	//		int pos_crop = (i - rtCrop.top) * wstep_crop;
//	//		memcpy(pImgCrop + pos_crop, img_rgb + pos, wstep_crop);
//	//	}
//
//	//	img_rgb = (char*)pImgCrop;
//	//	w = ww;
//	//	h = hh;
//	//}
//
//
//	int size = w * h;
//	BYTE* gray = new BYTE[size];
//	memset(gray, 0, size * sizeof(BYTE));
//	im_RGB2Gray((BYTE*)img_rgb, gray, w, h, 3);
//
//	int ary_width[] = { 1200, _WIDTH };
//	//int ary_width[] = { 300, 360 };
//	//int ary_height[] = { ary_width[0] * h / w, ary_width[1] * h / w };
//
//	//int w, h, c;
//	int c = 3;
//	int res = -1;
//	PassportData *pPtData = &_digitp->_passport;
//
//	for (int cnt = 0; cnt < 2; cnt++)
//	{
//		//if (_digitp->m_tmpColorDib)
//		//	delete[] _digitp->m_tmpColorDib;
//		//_digitp->m_tmpColorDib = NULL;
//
//		int sw = ary_width[cnt];
//		float fscalex = (float)sw / (float)w;// src_pix->w);
//		int sh = ((int)(h*fscalex * 8 + 31) / 32) * 4;
//		//_digitp->m_tmpColorDib = convRgb2Dib(img_rgb, w, h, 3, sw, sh, 3);// ary_height[cnt], 3);
//
//		int w_new = sw;
//		int h_new = sh;// ary_height[cnt];
//		size = w_new * h_new;
//		BYTE* imgGray = new BYTE[size];
//		im_Resize((BYTE*)gray, w, h, 1, imgGray, w_new, h_new);
//
//		//BYTE* imgGray = CImageBase::MakeGrayImg(_digitp->m_tmpColorDib, w_new, h_new);
//		CImageFilter::CorrectBrightForCameraImg(imgGray, w_new, h_new);
//		CImageFilter::MeanFilter(imgGray, w_new, h_new);
//
//		_digitp->UnKnownCard = true;
//		memset(_szResult, 0, 1024);
//		memset(pPtData, 0, sizeof(PassportData));
//
//		res = _digitp->Find_RecogImg_Main(imgGray, w_new, h_new, bReadAddress);
//		if (res == -3)
//		{
//			delete[] imgGray; imgGray = NULL;
//			break;
//		}
//
//		if (cnt > 0 && res < 0) //failed
//		{//noise remove
//			int size = w_new * h_new;
//			BYTE* tmpBits = new BYTE[size];
//			CImageFilter::imDilate(imgGray, tmpBits, w_new, h_new, 3);
//			res = _digitp->Find_RecogImg_Main(tmpBits, w_new, h_new, bReadAddress);
//			delete[] tmpBits;
//		}
//
//		delete[] imgGray; imgGray = NULL;
//
//		if (res >= 0)
//			break;
//	}
//
//	delete[]gray; gray = NULL;
//
//	//if (bCrop > 0)
//	//	delete[] pImgCrop;
//	//pImgCrop = NULL;
//
////	if (res == -3) {
////		int hh = h;
////		int ww = w / 2;
////		int wwstep = 3 * ww;
////		int wstep = 3 * w;
////		char* pbyCropImg = new char[wstep * hh];
////		for (int i = 0; i < h; i++)
////			memcpy(pbyCropImg + i * wwstep, img_rgb + i * wstep, wwstep);
////
////		w = ww;
////		for (int cnt = 0; cnt < 2; cnt++)
////		{
////			if (_digitp->m_tmpColorDib)
////				delete[] _digitp->m_tmpColorDib;
////			_digitp->m_tmpColorDib = NULL;
////
////			int sw = ary_width[cnt];
////			float fscalex = (float)sw / (float)w;// src_pix->w);
////			int sh = ((int)(h*fscalex * 8 + 31) / 32) * 4;
////			_digitp->m_tmpColorDib = convRgb2Dib(pbyCropImg, w, h, 3, sw, sh, 3);// ary_height[cnt], 3);
////			int w_new = sw;
////			int h_new = sh;// ary_height[cnt];
////			BYTE* imgGray = CImageBase::MakeGrayImg(_digitp->m_tmpColorDib, w_new, h_new);
////			CImageFilter::CorrectBrightForCameraImg(imgGray, w_new, h_new);
////			CImageFilter::MeanFilter(imgGray, w_new, h_new);
////
////
////			memset(_szResult, 0, 1024);
////			memset(pPtData, 0, sizeof(PassportData));
////
////			_digitp->UnKnownCard = true;
////			int facepick = 1;
////
////			res = _digitp->Find_RecogImg_Main(imgGray, w_new, h_new, facepick);
////			if (cnt > 0 && res <= 0) //failed
////			{//noise remove
////				BYTE* tmpBits = new BYTE[w_new*h_new];
////				CImageFilter::imDilate(imgGray, tmpBits, w_new, h_new, 3);
////				res = _digitp->Find_RecogImg_Main(tmpBits, w_new, h_new, facepick);
////				delete[] tmpBits;
////			}
////
////			delete[] imgGray; imgGray = NULL;
////
////			if (res > 0) break;
////		}
////
////		delete[] pbyCropImg; pbyCropImg = NULL;
////	}
//
//	if (res > 0)
//		_bRecognized = true;
//
//	return res;
//}

char* Cardrec::getVersionSDK()
{
	std::string str = std::string(VERSION_CARDREC_SDK);
	memcpy(_szVersion, (char*)str.c_str(), str.length());
	return _szVersion;
}

char* Cardrec::getMrzResult(bool bDetail, int nMode)
{
	if (!_bRecognized)
		return NULL;

	std::string str_one = "\", \n";
	std::string str_two = "\", \n\n";

	PassportData *pPtData = &_digitp->_passport;
	std::string str;
	str.append("{\n");
	str.append("\"Lines\":");
	str.append("\"");
	str.append(pPtData->lines);
	if(bDetail == false){
		str.append(str_two);
		str.append("\"Status\":");
		if( nMode == 5)
			str.append("\"False\"\n}");
		else
			str.append("\"True\"\n}");

		memcpy(_szResult, (char*)str.c_str(), str.length());
		return _szResult;
	}

	str.append(str_two);

	str.append("\"DocType\":"); 
	str.append("\"");
	str.append(pPtData->passportType);
	str.append("\", ");

	str.append("\"Country\":");
	str.append("\"");
	str.append(pPtData->country);
	str.append(str_one);

	str.append("\"Surname\":");
	str.append("\"");
	str.append(pPtData->surName);
	str.append("\", ");

	str.append("\"Givename\":");
	str.append("\"");
	str.append(pPtData->givenName);
	str.append(str_one);

	str.append("\"Nationality\":"); 
	str.append("\"");
	str.append(pPtData->nationality);
	str.append("\", ");

	str.append("\"Sex\":"); 
	str.append("\"");
	str.append(pPtData->sex);
	str.append(str_one);

	str.append("\"IssueDate\":");
	str.append("\"");
	str.append(pPtData->issuedate);
	str.append("\", ");

	str.append("\"DepartmentNumber\":");
	str.append("\"");
	str.append(pPtData->departmentNumber);
	str.append(str_two);

	str.append("\"DocNumber\":");
	str.append("\"");
	str.append(pPtData->passportNumber);
	str.append(str_one);
	str.append("\"DocNumberCheckNumber\":");
	str.append("\"");
	str.append(pPtData->passportChecksum);
	str.append(str_one);
	str.append("\"CorrectDocNumberCheckNumber\":");
	str.append("\"");
	str.append(pPtData->correctPassportChecksum);
	str.append(str_two);

	str.append("\"Birth\":");
	str.append("\"");
	str.append(pPtData->birth);
	str.append(str_one);
	str.append("\"BirthCheckNumber\":");
	str.append("\"");
	str.append(pPtData->birthChecksum);
	str.append(str_one);
	str.append("\"CorrectBirthCheckNumber\":");
	str.append("\"");
	str.append(pPtData->correctBirthChecksum);
	str.append(str_two);

	str.append("\"ExpirationDate\":");
	str.append("\"");
	str.append(pPtData->expirationDate);
	str.append(str_one);
	str.append("\"ExpirationCheckNumber\":");
	str.append("\"");
	str.append(pPtData->expirationChecksum);
	str.append(str_one);
	str.append("\"CorrectExpirationCheckNumber\":");
	str.append("\"");
	str.append(pPtData->correctExpirationChecksum);
	str.append(str_two);

	str.append("\"PersonalNumber\":");
	str.append("\"");
	str.append(pPtData->personalNumber);
	str.append(str_one);
	str.append("\"PersonalCheckNumber\":");
	str.append("\"");
	str.append(pPtData->personalChecksum);
	str.append(str_one);
	str.append("\"CorrectPersonalCheckNumber\":");
	str.append("\"");
	str.append(pPtData->correctPersonalChecksum);
	str.append(str_two);

	str.append("\"SecondRowCheckNumber\":");
	str.append("\"");
	str.append(pPtData->secondrowChecksum);
	str.append(str_one);
	str.append("\"CorrectSecondRowCheckNumber\":");
	str.append("\"");
	str.append(pPtData->correctSecondrowChecksum);
//
//	if (_bReadAddress) {
//
//		str.append("\"Address\":");
//		str.append("\"");
//		str.append(pPtData->address);
//		str.append(str_one);
//		str.append("\"Town\":");
//		str.append("\"");
//		str.append(pPtData->town);
//		str.append(str_one);
//		str.append("\"Province\":");
//		str.append("\"");
//		str.append(pPtData->province);
//		str.append(str_one);
//	}

    str.append(str_two);
    str.append("\"Status\":");
    if( nMode == 5)
        str.append("\"False\"\n}");
    else
        str.append("\"True\"\n}");

    memcpy(_szResult, (char*)str.c_str(), str.length());
    return _szResult;
}

//char* Cardrec::getMrzImage(int &nImageSize)
char* Cardrec::getMrzImage(int &w, int &h, int &c)
{
	//if (!_bRecognized)
		return NULL;

	//if (!_digitp->m_tmpResultDib || _digitp->m_tmpW == 0 || _digitp->m_tmpH == 0)
	//	return NULL;

	//LPBITMAPINFOHEADER lpBIH = (LPBITMAPINFOHEADER)_digitp->m_tmpResultDib;
	//BYTE* pbyImg = CImageBase::Get_lpBits(_digitp->m_tmpResultDib);
	////PIX* pixImg = convByte2Pix(pbyImg, _digitp->m_tmpW, _digitp->m_tmpH, 3);

	////l_uint8 *imgcard = NULL;
	////size_t nimgcard = 0;
	////pixWriteMem(&imgcard, &nimgcard, pixImg, IFF_JFIF_JPEG);
	////pixDestroy(&pixImg);

	////delete[] _digitp->m_tmpResultDib;
	////_digitp->m_tmpResultDib = NULL;

	////nImageSize = nimgcard;

	//w = _digitp->m_tmpW;
	//h = _digitp->m_tmpH;
	//c = lpBIH->biBitCount / 8;

	//int wstep = (lpBIH->biBitCount*w + 31) / 32 * 4;
	//int wstep0 = w * c;
	//int img_size = wstep0 * h;
	//char *imgcard = new char[img_size];
	//BYTE *srcData = pbyImg + (h - 1) * wstep;
	//for (int y = 0; y < h; y++)
	//{
	//	//memcpy(imgcard + wstep0, pbyImg, wstep0);
	//	memcpy(imgcard + y * wstep0, srcData, wstep0);
	//	//imgcard += w*c;
	//	srcData -= wstep;
	//}

	//delete[] _digitp->m_tmpResultDib;
	//_digitp->m_tmpResultDib = NULL;

	//return (char*)imgcard;
}

void Cardrec::freeMrz()
{
	if (_digitp)
	{
		//if (_digitp->m_tmpColorDib)
		//	delete[] _digitp->m_tmpColorDib;
		//_digitp->m_tmpColorDib = NULL;

		//if (_digitp->m_tmpResultDib)
		//	delete[] _digitp->m_tmpResultDib;
		//_digitp->m_tmpResultDib = NULL;

		delete _digitp;
		_digitp = NULL;
	}
}

BYTE* makeRotatedDib(BYTE* dib, int rot)
{
	if (rot == 90)
	{
		return CImageBase::CopyDib(dib);
	}
	else if (rot == 0)
	{
		return CRotation::RotateRight_24Dib(dib);
	}
	else if (rot == 270)
	{
		return CRotation::Rotate180_24Dib(dib);
	}
	return CRotation::RotateLeft_24Dib(dib);
}
