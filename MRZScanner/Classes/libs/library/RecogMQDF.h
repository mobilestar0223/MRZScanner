// RecogMQDF.h: interface for the CRecogMQDF class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_RECOGMQDF_H__BC28A219_47BA_46D1_8493_27729A54CE6F__INCLUDED_)
#define AFX_RECOGMQDF_H__BC28A219_47BA_46D1_8493_27729A54CE6F__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include "RecogCore.h"
#define CMAXNum	100//400
class CRecogMQDF : public CRecogCore  
{
public:
	CRecogMQDF();
	virtual ~CRecogMQDF();
public:
	int		RecogCharImg(BYTE* pImg,int w,int h,int RecogStep=2);
	int		RecogImgSelectCharId(BYTE* pImg,int w,int h,int CharIdSet[],int nNum,int RecogStep=2);

	BOOL	LoadDic(LPCTSTR FName);
	BOOL	LoadDicRes(BYTE* pDicBuf,DWORD resLen);
	BOOL	LoadDic_float(BYTE* pDicBuf,DWORD resLen);
	BOOL	LoadDic_WORD(BYTE* pDicBuf,DWORD resLen);
	void	SetCodeTable(WORD* CodeTable, int CodeNum);

	int		MakeHuboSimple(int font);
	int		MakeHuboSimple_SelectId(int font,int CharIdSet[],int nNum);
	int		RefineHubo(int font);
public:
	int		m_nDim;	//GDIM2 or PDIM
	int		m_nPCADim;
	int		m_nMaDim;
	int		m_nCMFDim;
	int		m_nFontNum;

	int		m_KohonenReduce;
	int		m_nCMFUse;
	
	int		m_nCNum;
	WORD*	m_Code;
	CAND	m_HuboFont[MAX_FONT];
	
	int		m_maxCand;
	
	int		m_nType;
	int		m_nCharSize;
	int		m_RecogStep;
	int		m_nRecogSet;
	
	Diction*m_Dic[MAX_FONT];
	float	m_thita;
	float*	m_SubPCAValue[MAX_FONT];
	float*	m_SubPCAMain[MAX_FONT][CMAXNum];

	float	m_ValTable[LNum][DQDIM];	
	BYTE	*m_SubPCAMainId[MAX_FONT][CMAXNum];
	BYTE*	m_TypeMark;	
	int*	m_SelSetId;
	int		m_nSelNum;

public:
	BOOL	ReleaseEngine();
	int		RecogImg(BYTE* pImg,int w,int h,int RecogStep=2);
	
	int		RecogStepDis();
	int		RecogStepMQDF();//MQDF		10
//	int		RecogStepCMF();//CMQDF	
	
	void	SetConfidence();
	
	int		GetCharType(int w,int h,int CharSize);

	void	ExchangeHubo(CAND* Hubo,int i,int j);
	BOOL	SetSelCodeIdTable(WORD* CodeTable, int CodeNum);

};

#endif // !defined(AFX_RECOGMQDF_H__BC28A219_47BA_46D1_8493_27729A54CE6F__INCLUDED_)
