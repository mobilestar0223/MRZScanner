
#include "Cardrec.h"
#include <string.h>
#ifdef LICENSE_DEFINE
#include "License.h"
#endif

Cardrec::Cardrec()
{
	_digitp = NULL;
	_bRecognized = false;
	_bLoaded = false;
#ifdef HAVE_CARDS
	_hCard = NULL;
	_rgb = NULL;
	_width = _height = _channel = 0;
#endif

	memset(_szErr, 0, 256);
}

void Cardrec::init(int nCardType)
{
	_nCardType = nCardType;

	if (_nCardType == CARD_TYPE_MRZ)
		initMrz();
}

int Cardrec::loadDB(char* dic, int ndicLen, char* dic1, int ndicLen1, char* tdata, int tLen, char* szLicense, int nLicense)
{
	int nRet = 0;
#ifdef LICENSE_DEFINE
	nRet = checkLicense(szLicense, nLicense, _szErr);
#endif
	_bLoaded = false;
	if (nRet < 0)
		return nRet; //license error

	bool ret;
	if (_nCardType == CARD_TYPE_MRZ){
		ret = loadMrz(dic, ndicLen, dic1, ndicLen1);
		if (!ret) {
			strcpy(_szErr, "Failed to Load Database!");
			return -1; //failed to load
		}
	}
	else {
#ifdef HAVE_CARDS
		ret = loadCards(tdata, tLen);
		if (!ret) {
			strcpy(_szErr, "Failed to Load Database!");
			return -1; //failed to load
		}
#endif
	}

	_bLoaded = true;
	return 0;
}
//int Cardrec::doRecognize(char* img_rgb, int w, int h, bool bReadAddress)
////int Cardrec::doRecognize(char* szImage, int nLen)
//{
//	int nRet = 0;
//	if (!_bLoaded) return -1;
//
//	_bReadAddress = bReadAddress;
//	if (_nCardType == CARD_TYPE_MRZ)
//		return doRecMrzRGB(img_rgb, w, h, bReadAddress);// doRecMrz(szImage, nLen);
//
//#ifdef HAVE_CARDS	
//	bool bRet = doRecCards(szImage, nLen);
//	nRet = (bRet == true) ? 1 : 0;
//#endif
//
//	return nRet;
//}

char* Cardrec::getResult(bool bDetail, int mode)
{
	if (!_bLoaded)
		return 0;

	if (_nCardType == CARD_TYPE_MRZ)
		return getMrzResult(bDetail, mode);

#ifdef HAVE_CARDS	
	return getCardsResult();
#endif

	return 0;
}

char* Cardrec::getCardImage()// int &nImageSize)
{
	if (!_bLoaded)
		return 0;

	int c = 0;
	if (_nCardType == CARD_TYPE_MRZ)
		return getMrzImage(_nCardW, _nCardH, c);// (nImageSize);

#ifdef HAVE_CARDS	
	return getCardsImage(nImageSize);
#endif

	return 0;
}

char* Cardrec::getErrorMsg()
{
	return (char*)_szErr;
}

char* Cardrec::getDevInfo()
{
	//char szBios[256];
	char szHDD[256];
	char szDomain[256];

	//memset(szBios, 0, 256);
	memset(szHDD, 0, 256);
	memset(szDomain, 0, 256);
#ifdef LICENSE_DEFINE
	//get_bios_sn(szBios);
	get_hdd_sn(szHDD);
	get_domain_name(szDomain);

	//sprintf(_szResult, "{\"BIOS\":\"%s\", \"HDD\":\"%s\", \"Domain\":\"%s\"}", szBios, szHDD, szDomain);
	sprintf(_szResult, "{\"HDD\":\"%s\", \"Domain\":\"%s\"}", szHDD, szDomain);
#endif

	return (char*)_szResult;
}

void Cardrec::release()
{
	if (_nCardType == CARD_TYPE_MRZ)
		freeMrz();

#ifdef HAVE_CARDS	
	if (_nCardType != CARD_TYPE_MRZ &&
		_nCardType != CARD_TYPE_FACE)
		freeCards();
#endif
}


Cardrec::~Cardrec()
{
	release();
}


