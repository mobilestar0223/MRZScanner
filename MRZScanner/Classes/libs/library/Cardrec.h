#ifndef CARDREC_H
#define CARDREC_H

#pragma once

class CFindRecogDigit;

#define VERSION_CARDREC_SDK			"1.2.7.15"

//#define CARD_TYPE_PAN		0
//#define CARD_TYPE_AADHAR	1
#define CARD_TYPE_MRZ		2
#define CARD_TYPE_FACE		100

//#define HAVE_CARDS

class Cardrec
{
private:
	int _nCardType;
	//MRZ
	CFindRecogDigit* _digitp;
	//PassportData _passport;
	bool _bRecognized;
	bool _bLoaded;
	char _szResult[1024];
	char _szErr[256];
	char _szVersion[256];

	int _nCardW;
	int _nCardH;

#ifdef HAVE_CARDS
	//PAN, AADHAR
	void* _hCard;
	void* _rgb;
	int _width, _height, _channel;
#endif

public:
	Cardrec();

	static Cardrec *getInstance() {
		static Cardrec *instance = nullptr;
		if (instance == nullptr) {
			instance = new Cardrec();
		}
		return instance;
	}

	int loadDB(char* dic, int ndicLen, char* dic1, int ndicLen1, char* tdata, int tLen, char* szLicense = 0, int nLicense = 0);
	//int doRecognize(char* szImage, int nLen);
	//char* doFaceDetect(char* szImage, int nLen, int &nResult);
	//int doRecognize(char* img_rgb, int w, int h, bool bReadAddress);
	int doRecognizeCrop(char* img_rgb, int w, int h, int x_crop, int y_crop, int w_crop, int h_crop);
	char* getResult(bool bDetail, int mode);
	char* getCardImage();
	char* getVersionSDK();

	int getCardWidth() { return _nCardW; }
	int	getCardHeight() { return _nCardH; }

	char* getDevInfo();
	char* getErrorMsg();

	void init(int nCardType);
	void release();

	~Cardrec();

private:
	void initMrz();
	bool loadMrz(char* dic, int ndicLen, char* dic1, int ndicLen1);
	//int doRecMrz(char* szImage, int nLen);
	char* getMrzResult(bool bDetail, int nMode);
	//char* getMrzImage(int &nImageSize);
	char* getMrzImage(int &w, int &h, int &c);
	void freeMrz();

#ifdef HAVE_CARDS
	void initCards();
	bool loadCards(char* tdata, int tLen);
	bool doRecCards(char* szImage, int nLen);
	char* getCardsResult();
	char* getCardsFaceImage(int &nImageSize);
	char* getCardsImage(int &nImageSize);
	void freeCards();
#endif

};

#endif
