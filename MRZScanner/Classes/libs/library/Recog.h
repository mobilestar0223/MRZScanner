// Recog.h: interface for the CRecog class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_RECOG_H__2B348192_B981_4E89_B359_75C912DE7A38__INCLUDED_)
#define AFX_RECOG_H__2B348192_B981_4E89_B359_75C912DE7A38__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#define Engine_NONE			0
#define Engine_BN			1
#define Engine_Mlp			2
#define Engine_Nn			3
#define Engine_LDA_PCA		4
#define Engine_MQDF			5
#define Engine_LDA_MQDF_NN	6
#define Engine_SVM			7

enum ID_TYPE { ID_ASIAN, ID_DIGIT_0,ID_DIGIT_9,ID_DIGIT_A,ID_DIGIT_Z,ID_DIGIT_a,ID_DIGIT_z};

#include "RecogCore.h"
class CRecog
{
public:
	CRecog();
	virtual ~CRecog();

//protected:
	char	m_szEngineMark[256];
	int		m_EngineType;
	void*	m_pRecog;
	CAND	m_Cand;

	int		RecogCharImg(BYTE* pImg,int w,int h,DWORD dwLanguage,int ChSize,int RecogStep=2);
	int		RecogCharImgByCharSet(BYTE* pImg,int w,int h,int nCharSet);
	int		RecogCharImgSelectCharId(BYTE* pImg,int w,int h,int CharIdSet[],int nNum,int RecogStep=2);
	int		RecogCharImgSelectCharId(BYTE* pImg,int w,int h,int RecogStep=2);
	int		RecogNormalImg(BYTE* pNorImg);//64*64 size
	void*	GetCode(int& nCNum);
	int		GetSpecialIndex(int idType);
	int		GetIndexInmCode(WORD cd);
	void	SetPrintHandMode(int nPrintHandMode);

	BOOL	LoadDic(LPCTSTR FName);
	BOOL	LoadDicRes(BYTE* pDicBuf,DWORD resLen);


	void	DeleteEngine();

	BOOL	SetSelCodeIdTable(WORD* UniCodeTable,int CodeNum);

};

#endif // !defined(AFX_RECOG_H__2B348192_B981_4E89_B359_75C912DE7A38__INCLUDED_)
