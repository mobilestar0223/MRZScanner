// Rotation.h: interface for the CRotation class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(_ROTATION_H__)
#define _ROTATION_H__



#define ROTATE_NONE     0
#define ROTATE_LEFT     1
#define ROTATE_RIGHT    2
#define ROTATE_180      3

#define BACKGROUND_BLACK  0
#define BACKGROUND_WHITE  1
#define BACKGROUND_CALC   2

class CRotation  
{
public:
	CRotation();
	virtual ~CRotation();
	static	BYTE*	RotateDib(BYTE *pDib, double fAng,int nBackGround=BACKGROUND_WHITE,int bKeepSize=TRUE);
	static	BYTE*	RotateRegularDib(BYTE *pDib,int nRegularRotateMode=ROTATE_LEFT);
	static	BYTE*	RotateRegularImg(BYTE *pImg,int w,int h,int nRegularRotateMode=ROTATE_LEFT);

	static	BYTE*	Rotate_24Dib(BYTE *pDib, double fAng, RGBQUAD *ColorBackGround=NULL,int bKeepSize=TRUE);

	static	BYTE*	RotateLeft_24Dib(BYTE *pDib);
	static	BYTE*	RotateRight_24Dib(BYTE *pDib);
	static	BYTE*	Rotate180_24Dib(BYTE *pDib);

	static	BYTE*	Rotate_GrayDib(BYTE *pDib, double fAng,BYTE GrayBackGround=255,int bKeepSize=TRUE);
	static	BYTE*	RotateLeft_GrayDib(BYTE *pDib);
	static	BYTE*	RotateRight_GrayDib(BYTE *pDib);
	static	BYTE*	Rotate180_GrayDib(BYTE *pDib);

	static	BYTE*	Rotate_BinDib_ByRun(BYTE *pDib, double fAng,int bKeepSize=TRUE);
	static	BYTE*	Rotate_BinDib(BYTE *pDib, double fAng,int nBackGround=BACKGROUND_WHITE,int bKeepSize=TRUE);
	static	BYTE*	RotateLeft_BinDib(BYTE *pDib);
	static	BYTE*	RotateRight_BinDib(BYTE *pDib);
	static	BYTE*	Rotate180_BinDib(BYTE *pDib);

	static	BYTE*	Rotate_GrayImg(BYTE *pImg, int &w, int &h,double fAng,BYTE GrayBackGround,int bKeepSize=TRUE);
	static	BYTE*	Rotate_BinImg(BYTE *pImg, int &w, int &h,double fAng,int nBackGround=BACKGROUND_WHITE,int bKeepSize=TRUE);
	static	BYTE*	Rotate_BinImg_ByRun(BYTE *pImg, int &w, int &h,double fAng,int bKeepSize=TRUE);
	
	static	BYTE*	RotateLeft_Img(BYTE *pImg, int w, int h);
	static	BYTE*	RotateRight_Img(BYTE *pImg, int w, int h);
	static	BYTE*	Rotate180_Img(BYTE *pImg, int w, int h);

	static	void	RotateDibRegion(BYTE *pDib, double fAng, CRect Region,BOOL bKeepSize=TRUE);
};

#endif // !defined(_ROTATION_H__)
