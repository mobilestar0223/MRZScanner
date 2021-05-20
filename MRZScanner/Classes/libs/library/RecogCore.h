// RecogCore.h: interface for the CRecogCore class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_RECOGCORE_H__7DDD4323_860F_447F_B77B_9F5605B0FE5E__INCLUDED_)
#define AFX_RECOGCORE_H__7DDD4323_860F_447F_B77B_9F5605B0FE5E__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000


#define MODE_PRINT			0
#define MODE_HANDWRITTEN	1

#define GH1			64
#define GW1			64 
#define GH2			40//80//54//55//66//50//66//54//50
#define GW2			40//80//54//55//66//50//63//54//50 
#define GH3			78//55//66//50//66//54//50
#define GW3			78//55//66//50//63//54//50 
#define GH4			40
#define GW4			32


#define PDIM		768
#define GDIM2		200	//±¸¹èÆ¯Â¡·®Â÷¿ø¼ö
#define GDIM3		392	//±¸¹èÆ¯Â¡·®Â÷¿ø¼ö
#define GDIM4		160	//±¸¹èÆ¯Â¡·®Â÷¿ø¼ö

#define HISDIM		500 //Histogram MaxValue in RecogRough

#define FEATURE_GRAD_BIN_200			0
#define FEATURE_GRAD_BIN_392			1
#define FEATURE_PLOVE_BIN_768			2
#define FEATURE_GRAD_GRAY_200			3
#define FEATURE_GRAD_GRAY_392			4
#define FEATURE_GRAD_GRAY_160			5
#define FEATURE_GRAD_BIN_160			6

#define STDIM		0	//Start Dimension 
#define ENDIM		16	//End Dimension
#define SeSTDIM		0//1//

#define SeENDIM		100//200//2Â÷´ëºÐ·ù Â÷¿ø¼ö//Beijing_2009_05_14
#define MARDIM		11//17// MQDF½Äº°±â Â÷¿ø¼ö//Beijing_2009_05_14
#define PCADIM		99//199//ÀÚÁ¾º° ÁÖ¼ººÐºÐ¼® Â÷¿ø¼ö´ëÃ¼·Î SeENDIM-1//Beijing_2009_05_14
#define CMFDIM		40//40//CMF¿¡¼­ ¸®¿ëÇÏ´Â µÚºÎºÐ Â÷¿ø¼ö°³¼ö


#define NFONT		1//4//6
#define MAX_FONT	6

#ifndef MAX_CAND
#define MAX_CAND	10//10//max number of candidate
#endif



#define MARK_SIZE			256

#define	ASIAN_CODE			1 
#define	DIGIT_CODE      	2 
#define	BIG_ENGLISH_CODE	4 
#define	SMALL_ENGLISH_CODE	8 
#define	SYMBOL_CODE			16 
#define	ENGLISH_CODE		(BIG_ENGLISH_CODE | SMALL_ENGLISH_CODE)
#define	ALL_LANGUAGE_CODE	(ASIAN_CODE | DIGIT_CODE | ENGLISH_CODE | SYMBOL_CODE)
#define SEL_CODETABLE_CODE   32

#define DOT_TYPE		0	//
#define UNDER_LINE_TYPE	1
#define I_TYPE			2
#define RECT_TYPE		3	//
#define I_TYPE_STRONG	4
#define SYMBOL_TYPE		5

#define RECT_ASIAN_SET			0
#define RECT_ENGLISH_SET		1
#define RECT_ALL_LANGUAGE_SET	2
#define RECT_PICK_ASIAN_SET		3
#define RECT_PICK_SYMBOL_SET	4
#define ITYPE_ASIAN_SET			5
#define ITYPE_OTHER_SET			6
#define DOT_SET					7
#define UNDERLINE_SET			8

#define DIGIT_SET			1
#define ENGLISH_SET			2
#define DIGIT_ITYPE_SET		3
#define ENGLISH_ITYPE_SET	4
#define ALL_ITYPE_SET		5
#define ALL_SET				6

#define SpaceTwo	0x0020

#define SPACE_NO			0
#define SPACE_YES			1
#define SPACE_LN			2
#define SPACE_FUZZY			4
#define SPACE_DOT			8

#define		RC_FALSE		0
#define		RC_OK			1

#define		ACCEPT			0
#define		REJECT			1
#define		ACCEPT_ERROR	2
#define		REJECT_ERROR	3

typedef struct tagCAND{
	WORD	Code[MAX_CAND];		//Candidate codes
	int     Index[MAX_CAND];	//Candidate Indexes
	double	Dis[MAX_CAND];		
	int		Font[MAX_CAND];
	double	Conf[MAX_CAND];//Candidate Confidences
	int		nCandNum;		//number of Candiates
	int		nRej;			//REJECT or ACCEPT
	int		ntf;			//=0:Confirm,=1:not Confirm,=2:MisSegmentation
	int		nRHuboId;
	int		nSpLn;
	int		nModifyRst;	//°ä¼³¼Çµù¶¦ ±ýÀ°³­²÷ ±¨¸Ë
	int		nMustModify;//0: °ä¼³ÂÚºã ÊÖËÁ , 1: °ä¼³ÂÚºã ËØËÁ
	int		nCharNum;
}CAND;

typedef struct tagDiction //  LDA Average Diction
{	
	UINT	num;		//train sample number
	float	p[GDIM3];   //average value size = nSeDim
}Diction;
typedef struct tagDiction3 //  LDA Average Diction
{	
	UINT	num;		//train sample number
	float	p[PDIM];   //average value
}Diction3;
typedef struct tagDictionWORD //  LDA Average Diction
{	
	UINT	num;		//train sample number
	WORD	p[GDIM3];	//[SeENDIM]; //average value
}DictionWORD;

#define DQDIM		1//2//1//
#define LNum		256
typedef struct tagKonenPCA{
	float	WW[LNum][DQDIM];
}KonenPCA;

typedef struct tagFDirect{
	//float direc[4];
	char direc[4];
}FDirect;

#define AVAILABLE_FALSE	0
#define AVAILABLE_OK	1
class CNn{
public:
	BYTE	SelId;
	WORD	Id1,Id2;
	int		nDim;
	BYTE	nConvergence;
	BYTE	nAvailable;
	float	WW[PDIM+1];
public:
	CNn(){	/*WW = NULL;*/SelId=0;Id1=0;Id2=0;nDim=0;nConvergence=0;nAvailable=AVAILABLE_FALSE;};
	//	virtual ~CNn(){	
	//	if(WW != NULL) delete[] WW;	WW=NULL;
	//};
	//void CreateData(int nDim0){	
	//	nDim = nDim0;
	//	if(WW != NULL) delete[] WW;
	//	WW = new float[nDim+1];	
	//};
};


class CRecogCore  
{
public:
	float	m_Bec[PDIM];
	CAND	m_Hubo;
	int		m_nFeatureID;
	int		m_nPrnHnd;//0:Print,1:Hand

	int		m_nAsianNum;
	DWORD	m_dwLanguage;
	int		m_idAsian,m_id0,m_id9,m_idA,m_idZ,m_ida,m_idz;

	int		m_w,m_h;
public:
	CRecogCore();
	virtual ~CRecogCore();

	int		GetFeatureNormal(BYTE F[GH1][GW1],int nFeatureDim);
	int		GetFeatureImg(BYTE* pImg,int w,int h,int nFeatureID);
	void	NoizeProcess(BYTE F64[GH1][GW1]);
	void	GetOnlyNormalize(BYTE* pImg,int w,int h,BYTE F[GH1][GW1]);
	void	LinearNormalize(BYTE *OrgImg,int w,int h,BYTE F[GH1][GW1]);

//protected:
//bin img feature
	int		GetFeatureGradH2_New(BYTE F[GH1][GW1]);
	void	MeanFilterH2(BYTE F[][GW2]);
	int		GetGradientBectorH2_New(BYTE F[][GW2]);

	int		GetFeatureGrad3(BYTE F[GH1][GW1]);
	void	LinearNormalize3(BYTE F1[GH1][GW1],BYTE F[GH3][GW3]);
	void	Filter3(BYTE F[][GW3]);
	int		GetGradientBector3(BYTE F[][GW3]);
	
	int		GetFeaturePloveImg(BYTE* pImg,int w,int h);
	int		GetFeaturePloveNormal(BYTE F[GH1][GW1]);
	void	bound_point(BYTE F[GH1][GW1],BYTE F_COL[GH1][GW1],BYTE F_ROW[GH1][GW1],BYTE F_DIGR[GH1][GW1],BYTE F_DIGN[GH1][GW1]);
	void	bound_tracking64(BYTE F[GH1][GW1],FDirect FD[GH1][GW1]);
	int		P_LOVE_feature(FDirect FD[GH1][GW1],float *buff,BYTE F_COL[GH1][GW1],BYTE F_ROW[GH1][GW1],BYTE F_DIGR[GH1][GW1],BYTE F_DIGN[GH1][GW1]);
	
	int		GetFeatureGradH2Bin(BYTE* pImg,int w,int h);
	int		GetFeatureGradH2Bin1(BYTE F[GH1][GW1]);
	
	int		GetFeatureGradH4Bin(BYTE* pImg,int w,int h);
	void	LinearNormalizeH4Bin(BYTE* pImg,int w1,int h1,BYTE F[GH4+2][GW4+2]);

//gray img feature	
//	int		GetFeatureGradH2Bin(BYTE* pImg,int w,int h);
	void	LinearNormalizeH2Bin(BYTE* pImg,int w1,int h1,BYTE F[GH2+2][GW2+2]);

	int		GetFeatureGradH2Gray(BYTE* pImg,int w,int h);
	void	MeanFilterH2Gray(BYTE F[GH2+2][GW2+2]);
	int		GetGradientBectorH2Gray(BYTE F[GH2+2][GW2+2]);
	void	LinearNormalizeH2Gray(BYTE* pImg,int w1,int h1,BYTE F[GH2+2][GW2+2]);

	int		GetFeatureGradH4Gray(BYTE* pImg,int w,int h);	
	void	LinearNormalizeH4Gray(BYTE* pImg,int w1,int h1,BYTE F[GH4+2][GW4+2]);
	void	MeanFilterH4Gray(BYTE F[GH4+2][GW4+2]);
	int		GetGradientBectorH4Gray(BYTE F[GH4+2][GW4+2]);
	
	BOOL	Contrast_Enhancement(BYTE* Img,int w,int h);
	BOOL	Contrast_EnhancementInSubRt(BYTE* Img,int w,int h,CRect subRt,BOOL bAllArea=TRUE);
	void	GetHistogram(BYTE *pImg, int w, int h, CRect subRt,int Hist[256],int& tmin,int& tmax);

	void	GetSortingAZOrder(float* buf,int* ord,int SortNum);
	void	GetSortingZAOrder(float* buf,int* ord,int SortNum);
	void	GetSortingAZ(float *buf,int *ord,int n,int SortNum);

	void	MakeHuboArrayOnDis(CAND Hubos[MAX_FONT],int nFontNum,CAND* Hubo);
	float	WordTofloat(unsigned short a);
	int		SearchCode(WORD *buf,int nLen,WORD c);
	int		SearchIndex(WORD* CdTable,int nCNum,WORD w);
	int		IsExistCd(WORD *Cds,WORD Cd);
	void	ExchangeHubo(CAND* Hubo,int i,int j);


	int		GetCharType(int w,int h,int CharSize);
	int		GetRecogCharSet(int nType);

private:
	float		m_tan[8];
	int			m_itan[8];
	float		m_ExpW1[5][5];
};

#endif // !defined(AFX_RECOGCORE_H__7DDD4323_860F_447F_B77B_9F5605B0FE5E__INCLUDED_)
