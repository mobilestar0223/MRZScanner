// FindRecogDigit.h: interface for the CFindRecogDigit class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_FINDRECOGDIGIT_H__DC78FAF4_0ED7_49D1_93EA_4702DB7CB782__INCLUDED_)
#define AFX_FINDRECOGDIGIT_H__DC78FAF4_0ED7_49D1_93EA_4702DB7CB782__INCLUDED_

#include "LineRecogPrint.h"
#include "MyEngineMRZWrapper.h"

typedef struct tagPassportData {
	char lines[100];
	char passportType[100];
	char country[100];
	char surName[100], givenName[100];
	char passportNumber[100], passportChecksum[100];
	char nationality[100];
	char birth[100], birthChecksum[100];
	char sex[100];
	char expirationDate[100], expirationChecksum[100];
	char personalNumber[100], personalChecksum[100];
	char secondrowChecksum[100];
	char issuedate[100];
	char departmentNumber[100];

	char correctPassportChecksum[10];
	char correctBirthChecksum[10];
	char correctExpirationChecksum[10];
	char correctPersonalChecksum[10];
	char correctSecondrowChecksum[10];

	char address[100];
	char town[100];
	char province[100];
}PassportData;

class CFindRecogDigit  
{
public:
	CFindRecogDigit();
	virtual ~CFindRecogDigit();

public:
	PassportData _passport;

	CLineRecogPrint	m_lineRecog;
	TCHAR _surname[100];
	TCHAR _givenname[100];
	
	int m_CharHeight,m_Linespace;
	//CRunRtAry mainrts;

	int		m_w, m_h;
	CRect	m_rtTotalMRZ;

	//BYTE*	m_tmpColorDib;
	//BYTE*	m_tmpResultDib;
	int		m_tmpW;
	int		m_tmpH;
	double	m_tmpfzoom;
	int		m_RotId;
	float   m_fAngle;
 	bool	UnKnownCard;
	bool	m_bFoundFace;
	bool	m_bFinalCheck;
	int		m_nCheckSum;
public:
	int Find_RecogImg_Main(BYTE* pGrayImg, int w, int h, bool bReadAddress);// , TCHAR* lines, TCHAR* passportType, TCHAR* country, TCHAR* surName, TCHAR* givenNames, TCHAR* passportNumber, TCHAR* passportChecksum, TCHAR* nationality, TCHAR* birth, TCHAR* birthChecksum, TCHAR* sex, TCHAR* expirationDate, TCHAR* expirationChecksum, TCHAR* issuedate, TCHAR* personalNumber, TCHAR* personalNumberChecksum, TCHAR* departmentNumber, TCHAR* secondRowChecksum);
	int Find_RecogImg(BYTE* pGrayImg, BYTE* pBinOrgImg, int w, int h, CRect &rtFirstMRZ, bool bRotate);// , TCHAR* lines, TCHAR* passportType, TCHAR* country, TCHAR* surName, TCHAR* givenNames, TCHAR* passportNumber, TCHAR* passportChecksum, TCHAR* nationality, TCHAR* birth, TCHAR* birthChecksum, TCHAR* sex, TCHAR* expirationDate, TCHAR* expirationChecksum, TCHAR* personalNumber, TCHAR* personalNumberChecksum, TCHAR* secondRowChecksum, int rotID = 0, bool bRotate = true);
	//int RecogImageAfterCrop(BYTE* pGrayImg, int w, int h, CRect& rtTotalMRZ);
	int Find_Address(BYTE* pGrayImg, BYTE* pBinOrgImg, int w, int h, CRect rtFirstMRZ, int nNumLineMRZ);

private:
	bool	m_bTotalcheck;

	void	DeleteNoneUseRects(CRunRtAry& RectAry);
	//float	GetAngleFromImg(BYTE* pImg,int w,int h);
	//float	GetAngleFromImg_1(BYTE* pImg,int w,int h);
	void	Recog_Filter(BYTE* pLineImg,BYTE* pGrayImg,int w,int h,TCHAR *str,double &dis,int mode,bool bgray=false);
	int		GetApproxRowHeight(CCharAry& rts,int w,int h,int& ls) ;
	inline float* GetGaussian(int wid);
	void	Merge_for_WordDetect(CRunRtAry& RunAry, int nDisBetweenChars);
	//void	Merge_for_Vertical();
	int		GetRealCharHeight(CRunRtAry& RunAry, int minTh, int defaltTh);
	int		Get_Distance_between_Rects(CRunRtAry& RunAry,int RtNo1,int RtNo2);
	int		GetCharHeightByHisto(CCharAry &ary,CRect rtBlk);
	void	RemoveRectsOutofSubRect(CRunRtAry& RectAry,CRect SubRt);
	int		DeleteLargeRects(CRunRtAry& RectAry,CSize Sz);
	int		CheckChecksum(TCHAR str[], int mode);
	bool	GetCheckChecksum(TCHAR str[], int mode);
	bool	ExtractionInformationFromFirstLine(TCHAR str[]);
	//bool	ReCheckName(BYTE* pBinImg,BYTE* pGrayImg,int w,int h,CRunRtAry& RunAry,TCHAR* strHanzi);
	int		MakeRoughLineAry(BYTE* pBinImg,int w,int h,CRunRtAry& LineAry,CRect subRect,int CharH);
	int		GetSecondrowChecksum(TCHAR str1[], TCHAR str2[], int mode);
};

#endif // !defined(AFX_FINDRECOGDIGIT_H__DC78FAF4_0ED7_49D1_93EA_4702DB7CB782__INCLUDED_)
