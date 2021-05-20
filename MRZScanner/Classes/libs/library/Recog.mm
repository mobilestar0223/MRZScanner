// Recog.cpp: implementation of the CRecog class.
//
//////////////////////////////////////////////////////////////////////

#include "StdAfx.h"
#include "Recog.h"
#include "RecogMQDF.h"

#ifdef _ANDROID
#ifdef _DEBUG
#undef THIS_FILE
static char THIS_FILE[]=__FILE__;
#define new DEBUG_NEW
#endif
#endif

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

CRecog::CRecog()
{
	m_pRecog = NULL;
	m_EngineType = Engine_NONE;
}

CRecog::~CRecog()
{
	if(m_EngineType != Engine_NONE) DeleteEngine();
}
int	CRecog::RecogCharImg(BYTE* pImg,int w,int h,DWORD dwLanguage,int ChSize,int RecogStep/*=2*/)
{
	int Id = 0;
	if(m_EngineType == Engine_MQDF){
		CRecogMQDF* p = (CRecogMQDF*)m_pRecog;
		p->m_dwLanguage = dwLanguage;
		p->m_nCharSize = ChSize;
		Id = p->RecogCharImg(pImg,w,h,RecogStep);
		memcpy(&m_Cand,&p->m_Hubo,sizeof(CAND));
	}
	else
		return 0;
	
	return Id;
}

int	CRecog::RecogCharImgSelectCharId(BYTE* pImg,int w,int h,int CharIdSet[],int nNum,int RecogStep/*=2*/)
{
	int Id = 0;
	if(m_EngineType == Engine_MQDF){
		CRecogMQDF* p = (CRecogMQDF*)m_pRecog;
		Id = p->RecogImgSelectCharId(pImg,w,h,CharIdSet,nNum,RecogStep);
		memcpy(&m_Cand,&p->m_Hubo,sizeof(CAND));
	}
	else
		return 0;
	
	return Id;
}
int	CRecog::RecogCharImgSelectCharId(BYTE* pImg,int w,int h,int RecogStep/*=2*/)
{
	int Id = 0;
	if(m_EngineType == Engine_MQDF){
		CRecogMQDF* p = (CRecogMQDF*)m_pRecog;
		Id = p->RecogImgSelectCharId(pImg,w,h,p->m_SelSetId,p->m_nSelNum,RecogStep);
		memcpy(&m_Cand,&p->m_Hubo,sizeof(CAND));
	}
	else
		return 0;

	return Id;
}
int	CRecog::RecogNormalImg(BYTE* pNorImg)
{
	return 0;
}
void CRecog::SetPrintHandMode(int nPrintHandMode)
{
	CRecogCore* p = (CRecogCore*)m_pRecog;
	p->m_nPrnHnd = nPrintHandMode;
}
void* CRecog::GetCode(int& nCNum)
{
	if(m_EngineType == Engine_MQDF){
		CRecogMQDF* p = (CRecogMQDF*)m_pRecog;
		nCNum = p->m_nCNum;
		return (void*)p->m_Code;
	}
	nCNum = 0;
	return NULL;
}
BOOL CRecog::LoadDic(LPCTSTR FName)
{
	BYTE* pBuff;
	int fLen;
	CFile file;
	if(file.Open(FName,CFile::modeRead)== FALSE) return FALSE;
	fLen = (int)file.GetLength();
	pBuff = new BYTE[fLen];
	file.Read(pBuff,fLen);
	file.Close();
	BOOL rc = LoadDicRes(pBuff, fLen);
	delete[]pBuff; pBuff = NULL;
	return rc;
}
BOOL CRecog::LoadDicRes(BYTE* pDicBuf,DWORD resLen)
{
	BOOL b = FALSE;
	memcpy(m_szEngineMark,pDicBuf,MARK_SIZE);
	if(strcmp(m_szEngineMark,"PCA-MQDF")==0){
		if(m_EngineType != Engine_NONE) DeleteEngine();
		m_EngineType = Engine_MQDF;
		m_pRecog = (void*)new CRecogMQDF;
		b = ((CRecogMQDF*)m_pRecog)->LoadDicRes(pDicBuf,resLen);
		return b;
	}
	return b;
}
void CRecog::DeleteEngine()
{
	if(m_EngineType == Engine_MQDF){
		CRecogMQDF* p = (CRecogMQDF*)m_pRecog;
		delete p;
	}
}
int	CRecog::GetSpecialIndex(int idType)
{
	int id=-1;
	CRecogCore* p = (CRecogCore*)m_pRecog;
	if(idType == ID_ASIAN) id = p->m_idAsian;
	else if(idType == ID_DIGIT_0) id = p->m_id0;
	else if(idType == ID_DIGIT_9) id = p->m_id9;
	else if(idType == ID_DIGIT_A) id = p->m_idA;
	else if(idType == ID_DIGIT_Z) id = p->m_idZ;
	else if(idType == ID_DIGIT_a) id = p->m_ida;
	else if(idType == ID_DIGIT_z) id = p->m_idz;
	else id = -1;
	return id;
}
int	CRecog::GetIndexInmCode(WORD cd)
{
	int id=-1;
	if(m_EngineType == Engine_MQDF){
		CRecogMQDF* p = (CRecogMQDF*)m_pRecog;
		id = p->SearchIndex(p->m_Code,p->m_nCNum,cd);
	}
	return id;
}
BOOL CRecog::SetSelCodeIdTable(WORD* UniCodeTable,int CodeNum)
{
	BOOL bRet = FALSE;
	if(m_EngineType == Engine_MQDF){
		CRecogMQDF* p = (CRecogMQDF*)m_pRecog;
		bRet = p->SetSelCodeIdTable(UniCodeTable,CodeNum);
	}
	return bRet;
}