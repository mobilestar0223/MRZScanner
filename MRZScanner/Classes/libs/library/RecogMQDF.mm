// RecogMQDF.cpp: implementation of the CRecogMQDF class.
//
//////////////////////////////////////////////////////////////////////

#include "StdAfx.h"
#include "RecogMQDF.h"
#include "imgproc.h"

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

CRecogMQDF::CRecogMQDF()
{
	int i,j;
	m_KohonenReduce = 0;
	m_nDim = GDIM2;
	m_nFontNum = 0;
	m_nCNum = 0;
	m_SelSetId = NULL;
	m_nSelNum = 0;
	//m_HuboFont = new CAND[MAX_FONT]; 
	m_Code =NULL;
	m_TypeMark = NULL;
	for(i=0;i<MAX_FONT;++i){
		m_Dic[i] = NULL;
		m_SubPCAValue[i] = NULL;
		for(j=0;j<CMAXNum;++j){
			m_SubPCAMain[i][j] = NULL;
			m_SubPCAMainId[i][j] = NULL;
		}
	}
}

CRecogMQDF::~CRecogMQDF()
{
	//if(m_HuboFont != NULL)		delete[] m_HuboFont;m_HuboFont=NULL;
	ReleaseEngine();
}
BOOL CRecogMQDF::ReleaseEngine()
{
	int i,j;
	if(m_Code != NULL)			delete[] m_Code;	m_Code=NULL;
	if(m_TypeMark != NULL)		delete[] m_TypeMark;m_TypeMark=NULL;
	for(i=0;i<MAX_FONT;++i){
		if(m_Dic[i] != NULL)		delete[] m_Dic[i];	m_Dic[i]=NULL;
		if(m_SubPCAValue[i] != NULL)delete[] m_SubPCAValue[i];	m_SubPCAValue[i]=NULL;
		for(j=0;j<CMAXNum;++j){
			if(m_SubPCAMain[i][j] != NULL)		delete[] m_SubPCAMain[i][j];	m_SubPCAMain[i][j]=NULL;
			if(m_SubPCAMainId[i][j] != NULL)	delete[] m_SubPCAMainId[i][j];	m_SubPCAMainId[i][j]=NULL;
		}
	}
	if(m_SelSetId != NULL) delete[] m_SelSetId;m_SelSetId=NULL;
	return TRUE;
}
int CRecogMQDF::RecogCharImg(BYTE* pImg,int w,int h,int RecogStep/*=2*/)
{
	RecogImg(pImg,w,h,RecogStep);
	return m_Hubo.Index[0];
}

int	CRecogMQDF::RecogImg(BYTE* pImg,int w,int h,int RecogStep/*=2*/)
{
	int retId; 
	GetFeatureImg(pImg,w,h,m_nFeatureID);
	memset(&m_Hubo,0,sizeof(CAND));
	retId = RecogStepDis();		//  Euclid
	retId = RecogStepMQDF();	//	MQDF, 1th fine classification
	if(RecogStep <= 1)	return retId;
	//if(m_nCMFUse == 1)	retId = RecogFineCMF();		//	CMF,  2th fine classification
	//SetConfidence();
	return retId;
}

int	CRecogMQDF::RecogImgSelectCharId(BYTE* pImg,int w,int h,int CharIdSet[],int nNum,int RecogStep/*=2*/)
{
	int retId; 
	GetFeatureImg(pImg,w,h,m_nFeatureID);

	int	font, nHuboNum = 0;		
	memset(&m_Hubo,0,sizeof(CAND));
	for(font=0;font<m_nFontNum;font++){
		MakeHuboSimple_SelectId(font,CharIdSet,nNum);
	}
	MakeHuboArrayOnDis(m_HuboFont,m_nFontNum,&m_Hubo);
	 
	retId = RecogStepMQDF();	//	MQDF, 1th fine classification
	if(RecogStep <= 1)	return retId;
	//if(m_nCMFUse == 1) 	retId = RecogFineCMF();		//	CMF,  2th fine classification
	//SetConfidence();
	return retId;
}
int CRecogMQDF::RecogStepDis()
{
	int		font, nHuboNum = 0;		
	for(font=0;font<m_nFontNum;font++){
		MakeHuboSimple(font);
	}
	MakeHuboArrayOnDis(m_HuboFont,m_nFontNum,&m_Hubo);
	return m_Hubo.Index[0];
}
int CRecogMQDF::MakeHuboSimple(int font)
{
	int i,j,Id;
	float	DisOne;
	float*  pDis = new float[m_nCNum];
	int*	Ord = new int[m_nCNum];
	
	memset(pDis,0,sizeof(float)*m_nCNum);
	int sdim = m_nDim;
	float t, *pMean;
	for (i=0;i<m_nCNum;i++){	
		Ord[i] = i;
		if(m_Dic[font][i].num<1){
			pDis[i] = 10000.0f;
			continue;
		}
		DisOne = 0;
		pMean = m_Dic[font][i].p;
		for (j=0;j<sdim;j++){
			t= pMean[j]-m_Bec[j];
			DisOne+=(t*t);	 
		}
		pDis[i] = DisOne;
	}
	memset(&m_HuboFont[font],0,sizeof(CAND));
	int nCandNum = m_nCNum; 
	if(nCandNum>MAX_CAND) nCandNum = MAX_CAND;
	GetSortingAZ(pDis,Ord,m_nCNum,nCandNum);
	j=0;
	for(i=0;i<nCandNum;++i){
		Id = Ord[i];
		if(m_Dic[font][Id].num<1)	continue;
		m_HuboFont[font].Code[j]=m_Code[Id];
        m_HuboFont[font].Index[j]=Id;
		m_HuboFont[font].Dis[j]=pDis[i];
		j++;
	}
	m_HuboFont[font].nCandNum = j;//nCandNum;
	delete pDis;
	delete Ord;
	return m_HuboFont[font].nCandNum;
}
int CRecogMQDF::MakeHuboSimple_SelectId(int font,int CharIdSet[],int nNum)
{
	int i,j,Id;
	float	DisOne;
	float*  pDis = new float[m_nCNum];
	int*	Ord = new int[m_nCNum];
	
	memset(pDis,0,sizeof(float)*m_nCNum);
	int sdim = m_nDim;
	float t, *pMean;
	for (i=0;i<nNum;i++){	
		Ord[i] = i;
		Id = CharIdSet[i];
		if(m_Dic[font][Id].num<1){
			pDis[i] = 10000.0f;
			continue;
		}
		DisOne = 0;
		pMean = m_Dic[font][Id].p;
		for (j=0;j<sdim;j++){
			t= pMean[j]-m_Bec[j];
			DisOne+=(t*t);	 
		}
		pDis[i] = DisOne;
	}
	memset(&m_HuboFont[font],0,sizeof(CAND));
	int nCandNum = nNum;
	if(nCandNum>MAX_CAND) nCandNum = MAX_CAND;
	GetSortingAZ(pDis,Ord,nNum,nCandNum);
	j=0;
	for(i=0;i<nCandNum;++i){
		Id = CharIdSet[Ord[i]];
		if(m_Dic[font][Id].num<1)	continue;
		m_HuboFont[font].Code[j]=m_Code[Id];
        m_HuboFont[font].Index[j]=Id;
		m_HuboFont[font].Dis[j]=pDis[i];
		j++;
	}
	m_HuboFont[font].nCandNum = j;//nCandNum;
	delete pDis;
	delete Ord;
	return m_HuboFont[font].nCandNum;
}
int CRecogMQDF::RecogStepMQDF()
{
	int		font;		
	for(font=0;font<m_nFontNum;font++){
		RefineHubo(font);
	}
	MakeHuboArrayOnDis(m_HuboFont,m_nFontNum,&m_Hubo);
	return m_Hubo.Index[0];
}
int CRecogMQDF::RefineHubo(int font)
{//MQDF
	int nOrder=m_maxCand;
	int i,j,k,Id;

	float* fPCAMatix = NULL;
	BYTE*  bPCAMatix = NULL;
	float* PCAVal,*PCAMean;
	int HuboNum = m_HuboFont[font].nCandNum;
	//float* pDis = new float[HuboNum];
	float pDis[MAX_CAND];
	float scala,thita = m_thita;
	float val = 0,fval,DisOne;

	for (i=0;i<HuboNum;i++){
		Id = m_HuboFont[font].Index[i];
		if(m_KohonenReduce == 0)	fPCAMatix = m_SubPCAMain[font][Id];
		else						bPCAMatix = m_SubPCAMainId[font][Id];
		PCAVal = (float*)(&m_SubPCAValue[font][m_nPCADim*Id]);
		PCAMean = (float*)(m_Dic[font][Id].p);
		val = 0; DisOne = 0;
		for (j=0;j<m_nMaDim/*MARDIM*/;j++)
		{
			scala=0;
			if(m_KohonenReduce == 0){
				for (k=0;k<m_nDim;k++)	scala += (m_Bec[k]-PCAMean[k])*fPCAMatix[k];
			}
			else{
				for (k=0;k<m_nDim;k++){
					fval = m_Bec[k]-PCAMean[k];
					scala += (fval)*m_ValTable[bPCAMatix[k/DQDIM]][k%DQDIM];
				}
			}

			DisOne += (scala*scala)*(1-thita/PCAVal[j]);
			val+=(float)log(PCAVal[j]);
			if(m_KohonenReduce == 0)	fPCAMatix+=m_nDim;
			else						bPCAMatix+=m_nDim/DQDIM;
		}
		pDis[i] = (float)((m_HuboFont[font].Dis[i] - DisOne)/thita + val); 
		if(pDis[i]< 0)pDis[i]=0;
		//pDis[i] = sqrt(pDis[i]);
	
	}

	float d,d1;
	for(i=0;i<HuboNum;i++)
	{
		d=pDis[i];
		for (j = i+1; j <HuboNum ; j++)
			if ( d > pDis[j] )
			{ 
				ExchangeHubo(&m_HuboFont[font],i,j);
				d=pDis[j];   
				d1=pDis[i];pDis[i]=pDis[j];pDis[j]=d1;
			} 
	}
	for(i=0;i<HuboNum;i++)	m_HuboFont[font].Dis[i]=pDis[i];
//	delete pDis;
	
	return m_HuboFont[font].Index[0];
}

int CRecogMQDF::GetCharType(int w,int h,int CharSize)///////
{
	float fw=(float)w;
	float fh=(float)h;
	
	float wth=3.0f;
	float hth=2.0f;
	int nCharType;
	
	if(fh<CharSize/hth  &&  fw<CharSize/wth)//Dot Type
	{
		nCharType = DOT_TYPE;
		if(fw>fh*2.5)// - Type
			nCharType = UNDER_LINE_TYPE;
	}
	else if(fh>fw*3)//I Type
		nCharType = I_TYPE;
	else if(fw>fh*2.5)// - Type
		nCharType = UNDER_LINE_TYPE;
	else	// Char Type 
		nCharType = RECT_TYPE;
	
	return nCharType;
}

BOOL CRecogMQDF::LoadDic(LPCTSTR FName)
{
	BYTE* pBuff;
	int fLen;
	CFile file;
	if(file.Open(FName,CFile::modeRead)== FALSE) return FALSE;
	fLen = (int)file.GetLength();
	pBuff = new BYTE[fLen];
	file.Read(pBuff,fLen);
	file.Close();
	BOOL rc = LoadDicRes(pBuff,fLen);
	delete pBuff;
	return rc;
}
BOOL CRecogMQDF::LoadDicRes(BYTE* pDicBuf,DWORD resLen)
{
	ReleaseEngine();
	BOOL rc;
	int	nFloatWord;// 0:float, 1:WORD;
	BYTE* pBuff = pDicBuf+MARK_SIZE;	
	memcpy(&nFloatWord,pBuff,sizeof(int));
	if(nFloatWord == 0)		rc = LoadDic_float(pDicBuf,resLen);
	else					rc = LoadDic_WORD(pDicBuf,resLen);
	return rc;
}
BOOL CRecogMQDF::LoadDic_float(BYTE* pDicBuf,DWORD resLen)
{
	int i,j,font;
	int	nFloatWord;// 0:float, 1:WORD;
	
	WORD *pw;
	BYTE* pBuff;
	UINT nCellLen;
		
	pBuff = pDicBuf+MARK_SIZE;
	memcpy(&nFloatWord,pBuff,sizeof(int));		pBuff+=sizeof(int);
	memcpy(&m_nCMFUse,pBuff,sizeof(int));		pBuff+=sizeof(int);
	{//m_nDim,m_nSeDim,m_nPCADim,m_nMaDim,m_nCMFDim,m_nFontNum;
		memcpy(&m_nDim,pBuff,sizeof(int));		pBuff+=sizeof(int);
		memcpy(&m_nPCADim,pBuff,sizeof(int));	pBuff+=sizeof(int);
		memcpy(&m_nMaDim,pBuff,sizeof(int));	pBuff+=sizeof(int);
		memcpy(&m_nCMFDim,pBuff,sizeof(int));	pBuff+=sizeof(int);
		memcpy(&m_nFontNum,pBuff,sizeof(int));	pBuff+=sizeof(int);
		memcpy(&m_KohonenReduce,pBuff,sizeof(int));	pBuff+=sizeof(int);
		memcpy(&m_nFeatureID,pBuff,sizeof(int));	pBuff+=sizeof(int);
		memcpy(&m_nPrnHnd,pBuff,sizeof(int));	pBuff+=sizeof(int);
		pBuff+= sizeof(int)*256;
	}
	{//m_nCNum,m_Code
		memcpy(&m_nCNum,pBuff,sizeof(int));		pBuff+=sizeof(int);
	}
	{
		pw = (WORD*)pBuff;		pBuff+=sizeof(WORD)*m_nCNum;
		m_Code = new WORD[m_nCNum];	
		memcpy(m_Code,pw,sizeof(WORD)*m_nCNum);		
		
		m_maxCand = min(MAX_CAND,m_nCNum);
	}
	{//LdaAve,nDim = NFONT * m_nCNum;//here NFONT == 1
		for(font=0;font<m_nFontNum;font++){
			m_Dic[font] = new Diction[m_nCNum];
			memcpy(m_Dic[font],pBuff,sizeof(Diction)*m_nCNum); 
			pBuff +=sizeof(Diction)*m_nCNum;
		}
	}
	{//SubPCA eigenvalue
		int nSubPCASize = m_nPCADim*m_nCNum;
		for(font=0;font<m_nFontNum;font++){
			m_SubPCAValue[font] = new float[nSubPCASize];	
			memcpy(m_SubPCAValue[font],pBuff,sizeof(float)*nSubPCASize); 
			pBuff+=sizeof(float)*nSubPCASize;
		}
	}	
	{//theta
		memcpy(&m_thita,pBuff,sizeof(float));	pBuff+=sizeof(float);
	}
	{//SubPCA eigenvector	
		int MaxDIM;
		if(m_nCMFUse == 0)	MaxDIM = m_nMaDim;
		else				MaxDIM = max(m_nMaDim,m_nCMFDim);
		if(m_KohonenReduce == 0){
			nCellLen = m_nDim*MaxDIM;
			for(font=0;font<m_nFontNum;font++){
				for(j=0;j<m_nCNum;j++){
					if(m_Dic[font][j].num < 1) continue;
					m_SubPCAMain[font][j]=new float[nCellLen];	
					memcpy(m_SubPCAMain[font][j],pBuff,sizeof(float)*nCellLen);
					pBuff +=sizeof(float)*nCellLen;
				}
			}
		}
		else{
			int nItemNum;
			memcpy(&nItemNum,pBuff,sizeof(int));	pBuff+=sizeof(int);

			for(i=0;i<LNum;++i){
				memcpy(m_ValTable[i],pBuff,sizeof(float)*DQDIM);	pBuff+=sizeof( float )* DQDIM;
			}
			
			nCellLen = (MaxDIM*m_nDim)/DQDIM;
			for(font=0;font<m_nFontNum;font++){
				for(i=0;i<m_nCNum;i++){
					if(m_Dic[font][i].num < 1){
						continue;
					}
					m_SubPCAMainId[font][i] = new BYTE[nCellLen];
					memcpy(m_SubPCAMainId[font][i],pBuff,nCellLen);	pBuff += nCellLen;
				}
			}
		}		
	}	
	//Symbol Id Determine
	//SetSymbolIDs();
	return TRUE;
}
BOOL CRecogMQDF::LoadDic_WORD(BYTE* pDicBuf,DWORD resLen)
{
	int i,j,font;
	int	nFloatWord;// 0:float, 1:WORD;
	
	WORD *pw;
	BYTE* pBuff;
	UINT nCellLen;
		
	pBuff = pDicBuf+MARK_SIZE;
	memcpy(&nFloatWord,pBuff,sizeof(int));		pBuff+=sizeof(int);
	memcpy(&m_nCMFUse,pBuff,sizeof(int));		pBuff+=sizeof(int);
	{//m_nDim,m_nSeDim,m_nPCADim,m_nMaDim,m_nCMFDim,m_nFontNum;
		memcpy(&m_nDim,pBuff,sizeof(int));		pBuff+=sizeof(int);
		memcpy(&m_nPCADim,pBuff,sizeof(int));	pBuff+=sizeof(int);
		memcpy(&m_nMaDim,pBuff,sizeof(int));	pBuff+=sizeof(int);
		memcpy(&m_nCMFDim,pBuff,sizeof(int));	pBuff+=sizeof(int);
		memcpy(&m_nFontNum,pBuff,sizeof(int));	pBuff+=sizeof(int);
		memcpy(&m_KohonenReduce,pBuff,sizeof(int));	pBuff+=sizeof(int);
		memcpy(&m_nFeatureID,pBuff,sizeof(int));	pBuff+=sizeof(int);
		memcpy(&m_nPrnHnd,pBuff,sizeof(int));	pBuff+=sizeof(int);
		pBuff+= sizeof(int)*256;
	}
	{//m_nCNum,m_Code
		memcpy(&m_nCNum,pBuff,sizeof(int));		pBuff+=sizeof(int);
	}
	{
		pw = (WORD*)pBuff;		pBuff+=sizeof(WORD)*m_nCNum;
		m_Code = new WORD[m_nCNum];
		memcpy(m_Code,pw,sizeof(WORD)*m_nCNum);		
		
		m_maxCand = min(MAX_CAND,m_nCNum);
	}
	{//LdaAve,nDim = NFONT * m_nCNum;//here NFONT == 1
		DictionWORD* pDic;
		for(font=0;font<m_nFontNum;font++){
			m_Dic[font] = new Diction[m_nCNum];
			for(i=0;i<m_nCNum;i++){
				pDic = (DictionWORD*)pBuff;		pBuff +=(sizeof(UINT)+sizeof(WORD)*m_nDim);
				m_Dic[font][i].num = pDic->num;
				for(j=0;j<m_nDim;j++){
					m_Dic[font][i].p[j]=WordTofloat(pDic->p[j]);
				}
			}
		}
	}
	{//SubPCA eigenvalue
		
		int nSubPCASize = m_nPCADim*m_nCNum;
		for(font=0;font<m_nFontNum;font++){
			pw = (WORD*)pBuff;						pBuff+=sizeof(WORD)*nSubPCASize;
			m_SubPCAValue[font] = new float[nSubPCASize];
			for(i=0;i<nSubPCASize;i++){
				m_SubPCAValue[font][i]= WordTofloat(pw[i]);
			}
		}
	}	
	{//theta
		memcpy(&m_thita,pBuff,sizeof(float));	pBuff+=sizeof(float);
	}
	{//SubPCA eigenvector	
		int k=0,fLen;
		int MaxDIM;
		if(m_nCMFUse == 0)	MaxDIM = m_nMaDim;
		else				MaxDIM = max(m_nMaDim,m_nCMFDim);
		BYTE* p;
		if(m_KohonenReduce == 0){
			nCellLen = m_nDim*MaxDIM;
			memcpy(&fLen,pBuff,sizeof(float));	pBuff+=sizeof(int);
			for(font=0;font<m_nFontNum;font++){
				for(j=0;j<m_nCNum;j++){
					if(m_Dic[font][j].num < 1) continue;
					k++;
					pw = (WORD*)pBuff;			pBuff +=sizeof(WORD)*m_nDim*MaxDIM;
					m_SubPCAMain[font][j]=new float[nCellLen];
					for(i=0;i<nCellLen;i++){
						p = (BYTE*)(&pw[i]);
						m_SubPCAMain[font][j][i]=WordTofloat(pw[i]);
					}
				}
			}
		}
		else{
			int nItemNum;
			memcpy(&nItemNum,pBuff,sizeof(int));	pBuff+=sizeof(int);
		
			for(i=0;i<LNum;++i){
				memcpy(m_ValTable[i],pBuff,sizeof(float)*DQDIM);	pBuff+=sizeof( float )* DQDIM;
			}
			
			nCellLen = (MaxDIM*m_nDim)/DQDIM;
			for(font=0;font<m_nFontNum;font++){
				for(i=0;i<m_nCNum;i++){
					if(m_Dic[font][i].num < 1){
						continue;
					}
					m_SubPCAMainId[font][i] = new BYTE[nCellLen];
					memcpy(m_SubPCAMainId[font][i],pBuff,nCellLen);	pBuff += nCellLen;
				}
			}
		}		
	}	
	//Symbol Id Determine
	//SetSymbolIDs();
	return TRUE;
}

void CRecogMQDF::ExchangeHubo(CAND* Hubo,int i,int j)
{
	WORD w;
	int Id;//,Font;
	double Dis;//,ri;
	w=Hubo->Code[i];	Hubo->Code[i]=Hubo->Code[j];	Hubo->Code[j]=w;
	Id=Hubo->Index[i];	Hubo->Index[i]=Hubo->Index[j];	Hubo->Index[j]=Id;
	Dis=Hubo->Dis[i];	Hubo->Dis[i]=Hubo->Dis[j];		Hubo->Dis[j]=Dis;
//	Dis=Hubo->FineDis[i];Hubo->FineDis[i]=Hubo->FineDis[j];	Hubo->FineDis[j]=Dis;
// 	ri=Hubo->Conf[i];	Hubo->Conf[i]=Hubo->Conf[j];Hubo->Conf[j]=ri;
//	Font=Hubo->Font[i];	Hubo->Font[i]=Hubo->Font[j];	Hubo->Font[j]=Font;
}
void CRecogMQDF::SetCodeTable(WORD* CodeTable, int CodeNum)
{
	memcpy(m_Code,CodeTable,sizeof(WORD)*CodeNum);
}
void CRecogMQDF::SetConfidence()
{
	int i,nCandNum = m_Hubo.nCandNum;
	double sum=0,d0 = m_Hubo.Dis[0];
	// 	for(i=0;i<nCandNum;++i){
	// 		m_Hubo.Dis[i] = m_Hubo.Dis[i] - d0;
	// 		sum += m_Hubo.Dis[i];
	// 	}
	for(i=0;i<nCandNum;++i){
		m_Hubo.Conf[i] = m_Hubo.Dis[i];//exp(-m_Hubo.Dis[i]/sum);
	}
	for(i=0;i<nCandNum;++i){
		if(i >0 && m_Hubo.Dis[i]>1000) break;
	}
	m_Hubo.nCandNum = i;
	for(i=m_Hubo.nCandNum;i<m_maxCand;++i){
		m_Hubo.Code[i] = SpaceTwo;
		m_Hubo.Index[i]= 0;
		m_Hubo.Dis[i]  = 1000;
	}
	if(m_Hubo.Dis[0]>1000) m_Hubo.ntf=2;//Strong Error
	else if(m_Hubo.Dis[1]>m_Hubo.Dis[0]*2) m_Hubo.ntf=0;//True Char
	else if(m_Hubo.Dis[1]-m_Hubo.Dis[0]>70) m_Hubo.ntf=0;//True Char
	else m_Hubo.ntf=1;//Week Same Char
	
	if(m_Hubo.ntf == 2)		m_Hubo.nRej = REJECT;
	else					m_Hubo.nRej = ACCEPT;
}
BOOL CRecogMQDF::SetSelCodeIdTable(WORD* UniCodeTable,int CodeNum)
{
	int i,k=0,id;
	if(m_SelSetId != NULL) delete[] m_SelSetId;m_SelSetId=NULL;
	m_SelSetId = new int[m_nCNum];
	for(i=0;i<CodeNum;++i){
		id = SearchIndex(m_Code,m_nCNum,UniCodeTable[i]);
		if(id>=0) {
			m_SelSetId[k++] = id;
		}
	}
	m_nSelNum = k;
	if(k == 0) return FALSE;
	return TRUE;
}