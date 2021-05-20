// LineRecogPrint.h: interface for the CLineRecogPrint class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_LINERECOGPRINT_H__FB3CA690_0B98_409A_AB92_4F0F1797F895__INCLUDED_)
#define AFX_LINERECOGPRINT_H__FB3CA690_0B98_409A_AB92_4F0F1797F895__INCLUDED_

#include "TRunProc.h"
#include "Recog.h"

#define NHUBO			10 //Ã¨¸óºã

#define LineFeed		0x0a0d
#define SpaceOne		0x20
#define DEL_KEY			0x2e
#define BS_KEY			0x08

#define NONJUSTIFY		0//cch
#define JUSTIFY			1//cch


//#define IMAGESIZE		2000000
#define COMIMAGESIZE	500000


#define DOWNWARD_LEFT   65535
#define DOWNWARD		65536
#define UPWARD_LEFT     65537
#define UPWARD		    65536

#define MODE_TD1_LINE1		1
#define MODE_TD2_44_LINE1	2
#define MODE_TD2_36_LINE1	3
#define MODE_TD2_LINE2		4	//line = 2, the num of line : 44

#define MODE_TD3_LINE1		5
#define MODE_TD3_LINE2		6
#define MODE_TD3_LINE3		7


#define MODE_FRA2_LINE1		8
#define MODE_FRA2_LINE2		9

#define MODE_ANY_LINE			15
#define MODE_PASSPORT_ENGNAME	20




//// RECOG SETTING/////////////
#define	KOREAN			0 //	¼¿ººÊÌ
#define	ENGLISH			1 //	ÊéÊÌ
#define	ALL_LANGUAGE	2 //	¼­¾Ë
#define	PICK_KOREA		3 //	¼¿ººÊÌ¶í
#define	PICK_SYMBOL		4 //	±¨Âö
#define PICK_DIGIT		5 //	ºã»ô¶í
//#define		HANZA			1 //	ÂÙ»ô

#define     DOT_TYPE		0	//
#define     UNDER_LINE_TYPE	1
#define     I_TYPE			2
#define     RECT_TYPE		3	//¼³¸ÒÂô±¡»ô
#define		SUPERSCRIPT		0x04
#define		SUBSCRIPT		0x02
#define		MIDDLESCRIPT	0x01
#define		NONESCRIPT		0x0



typedef struct tagHUBO{
	WORD	Code[NHUBO];		//Candidate codes
	int     Index[NHUBO];	//Candidate Indexes
	double	Dis[NHUBO];		
	int		Font[NHUBO];
	double	Conf[NHUBO];//Candidate Confidences
	int		nCandNum;		//number of Candiates
	int		nRej;			//REJECT or ACCEPT
	int		ntf;			//=0:Confirm,=1:not Confirm,=2:MisSegmentation
	int		nRHuboId;
	int		nSpLn;
	int		nModifyRst;	//°ä¼³¼Çµù¶¦ ±ýÀ°³­²÷ ±¨¸Ë
	int		nMustModify;//0: °ä¼³ÂÚºã ÊÖËÁ , 1: °ä¼³ÂÚºã ËØËÁ
	int		nCharNum;
}HUBO;

class  CInsaeRt:public CRunRt
{
public:
	BYTE	nReserved1; //it is used to indicate whether it is segmented
	BYTE	nRecogFlag; //2:it is recognized successfully, 1: it is recognized, but omitted by next char, 0:it isn't recognized.
	BYTE	nAddNum;
	BYTE	nRecogType;//DOT_TYPE, I_TYPE, RECT_TYPE
	BYTE	nScriptType;//SUPERSCRIPT,SUBSCRIPT,MIDDLESCRIPT,NONESCRIPT
	int		UnUse1;
	HUBO	Hubo;
	CInsaeRt() {
		nRecogFlag = nScriptType = nReserved1 = 0;nAddNum = 0; memset(&Hubo,0,sizeof(HUBO));nReserved1=0;
		nRecogType = RECT_TYPE; 
		UnUse1 = 0;}
	virtual ~CInsaeRt() {};
};
typedef TRunProc<CInsaeRt> CInsaeRtProc;
typedef CInsaeRt CCharRt;
typedef CTypedPtrArray <CPtrArray, CCharRt*> CCharAry;

class CLineRecogPrint  
{
public:
	CLineRecogPrint();
	virtual ~CLineRecogPrint();

public:
	CRecog	m_RecogBottomLine1;
	CRecog	m_RecogBottomLine1Gray;
	//CRecog	m_RecogBottomLine2;
	//CRecog	m_RecogEnglish;

	CCharAry m_CharAry;
	int		m_CharSize;	//ÃÔËæº·Ì© Áâ°÷·Í»ô¿Í±¨
	int		m_LineOrientation;//ÃÔÌ© ¸ÒÂá(0:°¡µá,1:»½µá)
	int     m_w,m_h;
    BYTE    *m_pGrayImg;
	bool	m_bGrayMode;
	bool	m_bUnkownCard;
	CRect	m_LineRt;	//ÃÔÌ© Ë÷¼±4°¢Âô
	int		m_SpaceTh;
	BOOL	m_Mode;
	BOOL    m_bNoise;

	void	LineRecog(BYTE* pImg, BYTE* pGrayImg, int w, int h, double &dis, TCHAR* str, BOOL bNoise = FALSE, int mode = 0);
	void	CharRecogInLine(CCharAry& RunRtAry);	//char recog by chch
	void	InseaGeneralPickInLine(CCharAry& RunRtAry,int  nStep=1);	//General char pick by chch
	int		GetRealCharHeight();
	int		RemoveNoneUseRects(CCharAry& RunRtAry);
	void	RemoveBeforAfterDot(CCharAry& RunRtAry);  //2010.1.29

private:
	BYTE*	m_OrgImg;
	int		m_OrgW,m_OrgH;
	
private:
	int		Get_LetterSize_Of_Line1(CCharAry& RunRtAry);
	void	RemoveUpDownNoise_In_Line(CCharAry& RunRtAry);
	void	Del_Of_NoiseRect(CCharAry& RunRtAry,int nMode);
	void	Del_Rect(CCharAry& RunRtAry, int id, int mode);
	int		CheckOfPeak(CInsaeRt*pU);
	int		Distance_Between_TwoRect(CInsaeRt*pU, CInsaeRt*pU1);
	void	GetImgYXFromRunRt_Ext(CInsaeRt* pU,BYTE** Img,int nWd,int nHi);
	void	GetAnyOrgThin(BYTE** TempThin,int w,int h);
	int		GetStrokeWidth(CInsaeRt* pU,BYTE** Img,int nWd,int nHi);
	float	GetStrokeWidth(CInsaeRt* pU);

	void	Smooth(float *Boon, int pit, int w_d);
	//1½ÓÀÒÂÝ
	int		FirstMerge_Horizontal(CCharAry& RunRtAry);

	//°¬½£¼®³à
	void	ForcedSegment(CCharAry& RunRtAry);
	int		ForcedCut(CCharAry& RunRtAry,int nId);
	int		ForcedEngCut(CCharAry& RunRtAry,int nId);
	int		Is_Valley1(BYTE* Img,int nWd,int nHi, int nPos[]);
	int		Is_Valley(BYTE** Img,int nWd,int nHi, int nPos[], int mode);
	int		GetCutPosition(int nWd, int nHi,float *BoonPo1, float *BoonPo2, int nPos[], int mode);
	//2½ÓÀÒÂÝ	
	void	SecondMerge_Horizontal(CCharAry& RunRtAry);
	void	FoundCombinePair_InSae(CCharAry& RunRtAry,int *pCombPi);
	int		SecondMerge_dynamic(CCharAry& RunRtAry);
	int		MergePostProcess_KSD(CCharAry& RunRtAry);
	//
	float	Space_ProcessInsae(CCharAry& RunRtAry);
	double	GetConfofChar(BYTE* pImg,int w,int h,int CharSize,WORD &wCode,int &idx,int &font);

	int		GetCharType(int w,int h,int CharSize);
	BOOL	DynamicSegment_ByCCH(CCharAry& RunRtAry);
	inline float GetRectScore(CRect* rts,int nNum);
	int		CandModify(HUBO* cand,TCHAR str[]);

	int		isRecogChar(int mode,unsigned char *Img,int w,int h,int CharSize,void* pCand,int RecogStep=2);

public:	
	//void	outSample2Data(CCharAry &RunAry);
};

#endif  //INSAEDOC_RECOGNITION

