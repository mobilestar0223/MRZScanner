// LineRecogPrint.cpp: implementation of the CLineRecogPrint class.
//
//////////////////////////////////////////////////////////////////////
#include "StdAfx.h"

#include "ImageBase.h"
#include "Binarization.h"
#include "LineRecogPrint.h"
#include "Modify_Ex.h"
#include "imgproc.h"

//#include "RecogInterface.h"
//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////
float	g_th_char_korea = 900.0f;//500.0f;
float	g_th_char_symbol = 850.0f;
float	g_th_forcedcut = 1.4f;
float	g_th_lettersize = 1.2f;
float	g_th_char_final = 1000.0f;//500.0f;

#ifdef _ANDROID
#ifdef _DEBUG
#undef THIS_FILE
static char THIS_FILE[]=__FILE__;
#define new DEBUG_NEW
#endif
#endif

#define GRAY_CHINA		0
#define PASSPORT_BOTTOM 1
#define BIGENG_DIGIT	2

CLineRecogPrint::CLineRecogPrint()
{
	m_CharSize = 0;
	m_LineOrientation = 0;

	m_OrgImg = NULL;
	
	m_SpaceTh = 0;
	m_bGrayMode = false;

}

CLineRecogPrint::~CLineRecogPrint()
{
	if(m_OrgImg != NULL)	delete m_OrgImg;m_OrgImg = NULL;
	
}
void CLineRecogPrint::LineRecog(BYTE* pImg, BYTE* pGrayImg, int w, int h, double& dis, TCHAR* str, BOOL bNoise, int mode)
{	
	m_Mode = mode;
    m_pGrayImg = pGrayImg;

	m_bNoise = bNoise;
	//DWORD t = GetTickCount();
	CInsaeRtProc runProc;
	m_w = w; m_h = h;
	runProc.MakeConnectComponentFromImg(pImg, w, h, m_CharAry);
	runProc.SortByOption(m_CharAry, 0, m_CharAry.GetSize(), SORT_CENTER_X);
	m_CharSize = GetRealCharHeight();

	InseaGeneralPickInLine(m_CharAry, 2);
// 	if(m_Mode==MODE_PASSPORT_LINE1)
// 	{
// 		int i;
// 		for(i = 0;i<m_CharAry.GetSize();i++)
// 		{
// 			HUBO *hubo = &(m_CharAry[i]->Hubo);
// 			if(hubo->Code[0] == '0') hubo->Code[0] = 'O';
// 			if(hubo->Code[0] == '1') hubo->Code[0] = 'I';
// 		}
// 	}
	
	int i = 0;
	int nRSize = 0;
	int wd, hi;
	dis = 0;
	if (mode == MODE_ANY_LINE) {
		int nLenText = 0;
		for (i = 0; i < m_CharAry.GetSize(); i++)
		{
			HUBO* hubo = &(m_CharAry[i]->Hubo);
			wd = m_CharAry[i]->m_Rect.Width();
			hi = m_CharAry[i]->m_Rect.Height();
			int nTypeChar = GetCharType(wd, hi, m_CharSize);
			if (nTypeChar == I_TYPE && hubo->Dis[0] > 4000.0 && hubo->Dis[1] > 4000)
				continue;
			if ( hubo->Dis[0] > 5000.0 && hubo->Dis[1] > 6000)
				continue;
			if (nTypeChar == RECT_TYPE)
			{
				if (hubo->Dis[1] != 0)
					dis += hubo->Dis[0] * hubo->Dis[0] / hubo->Dis[1];
				else
					dis += hubo->Dis[0];
				nRSize++;
			}
			TCHAR sz[10];
			memset(sz, 0, sizeof(TCHAR) * 10);
			sz[0] = m_CharAry[i]->Hubo.Code[0];
			//memcpy(sz,&m_CharAry[i]->Hubo.Code,2);
			if (nLenText > 0) {
				if (m_CharAry[i]->m_Rect.left - m_CharAry[i - 1]->m_Rect.right > m_CharAry[i]->m_Rect.Width()) {
					str[nLenText] = ' ';
					nLenText++;
				}
			}
			str[nLenText] = sz[0];
			nLenText++;
		}
		str[nLenText] = 0;
	}
	else {
		for (i = 0; i < m_CharAry.GetSize(); i++)
		{
			HUBO* hubo = &(m_CharAry[i]->Hubo);

			wd = m_CharAry[i]->m_Rect.Width();
			hi = m_CharAry[i]->m_Rect.Height();
			if (GetCharType(wd, hi, m_CharSize) == RECT_TYPE)
			{
				if (hubo->Dis[1] != 0)
					dis += hubo->Dis[0] * hubo->Dis[0] / hubo->Dis[1];
				else
					dis += hubo->Dis[0];
				nRSize++;
			}
			TCHAR sz[10];
			memset(sz, 0, sizeof(TCHAR) * 10);
			sz[0] = m_CharAry[i]->Hubo.Code[0];
			//memcpy(sz,&m_CharAry[i]->Hubo.Code,2);
			str[i] = sz[0];
		}
		str[i] = 0;
	}

	if(nRSize == 0)
		dis = 9999;
	else
		dis /= nRSize;
	m_LineRt = runProc.GetRealRect(m_CharAry);
	runProc.RemoveAllRunRt(m_CharAry);
	return;
}

int CLineRecogPrint::GetRealCharHeight()
{
	int cc = 0;
	int num = m_CharAry.GetSize();
	float minHei = 5;
	float maxHei = 100;
	float tot = 0;
	
	for(int i=0;i<num;i++)
	{
		if (m_CharAry[i]->m_Rect.Height()>minHei &&
			m_CharAry[i]->m_Rect.Height()<maxHei)
		{
			cc++;
			tot+=m_CharAry[i]->m_Rect.Height();
		}
	}
	return cc ? (int)(tot/cc) : 30;
}

void CLineRecogPrint::InseaGeneralPickInLine(CCharAry& RunRtAry, int nStep)
{
	if (m_Mode == MODE_ANY_LINE)
	{
		BYTE* pB;
		int wd, hi, nCharType;
		CInsaeRt* pU;
		CInsaeRtProc cRunProc;
		int nCharNum = RunRtAry.GetSize();
		for (int i = 0; i < nCharNum; ++i) {
			pU = RunRtAry.GetAt(i);
			if (m_bGrayMode) {
				pB = CImageBase::CropImg(m_pGrayImg, m_w, m_h, RunRtAry[i]->m_Rect);
				wd = RunRtAry[i]->m_Rect.Width();
				hi = RunRtAry[i]->m_Rect.Height();
			} else {
				pB = cRunProc.GetImgFromRunRt(pU, wd, hi);
			}
			
			nCharType = GetCharType(wd, hi, m_CharSize);
			pU->nRecogType = nCharType;

#ifdef LOG_VIE
			cv::Mat matChar = getMatImage(pB, wd, hi, 0);
			DisplayMatImage(matChar, false);
#endif //LOG_VIEW

			isRecogChar(m_Mode, pB, wd, hi, m_CharSize, (void*)&pU->Hubo, 2);
			delete pB; pB = NULL;
		}

		return;
	}
	//m_Mode=0(HANZA_NAME),1(BOTTOM1),2(DOWN_BOTTOM2),3(ENG_NAME)
	{//ENG_DIGIT
		//CharRecogInLine(RunRtAry);
		//ForcedSegment(RunRtAry);
		if(DynamicSegment_ByCCH(RunRtAry) == TRUE)
			return;
        else
		{
            CInsaeRtProc::RemoveAllRunRt(RunRtAry);
            return;
        }
	}

	if(m_Mode == MODE_PASSPORT_ENGNAME)
		return;
	
	int num = RunRtAry.GetSize();

		if(m_bNoise)
			RemoveUpDownNoise_In_Line(RunRtAry);

		m_CharSize = Get_LetterSize_Of_Line1(RunRtAry);
		num = FirstMerge_Horizontal(RunRtAry);
		Del_Of_NoiseRect(RunRtAry, 9);
		m_CharSize = Get_LetterSize_Of_Line1(RunRtAry);

		if(nStep == 0)
			return;
		SecondMerge_Horizontal(RunRtAry);
		CharRecogInLine(RunRtAry);
	//	ForcedSegment(RunRtAry);
	// 	CString str;
	 //	str.Format(_T("%d "),pBlock->m_nAvCharW);
	 //	AfxMessageBox(str);	
	//	if(m_nLanguage==KOREAN)
	//		SecondMerge_Horizontal(RunRtAry);
	//	else 
		num = SecondMerge_dynamic(RunRtAry);
	
	//	if(m_bNoise)
	//		Del_Of_NoiseRect(RunRtAry,11);
		CharRecogInLine(RunRtAry);
		if(m_bNoise)
			RemoveBeforAfterDot(RunRtAry);  //2010.1.29
	//	outSample2Data(RunRtAry);
	//	Space_ProcessInsae(RunRtAry);/////////		
}	

int CLineRecogPrint::MergePostProcess_KSD(CCharAry& RunRtAry)
{
	int i,nCharNum=RunRtAry.GetSize();
	if(nCharNum == 0)		return 0;
	BYTE *pImg;
	BYTE* pG;
	int ww,hh;
	CInsaeRtProc cRunProc;
	CInsaeRt* pTemp;
	for(i=0;i < nCharNum-1; i++)
	{
		if(RunRtAry[i+1]->m_Rect.left < RunRtAry[i]->m_Rect.right){
			pTemp = new CInsaeRt();
			pTemp->Copy(RunRtAry[i]);
			pTemp->Append(RunRtAry[i+1]);
			if(pTemp->m_Rect.Width()>m_CharSize*1.9f || pTemp->m_Rect.Width()/float(pTemp->m_Rect.Height())>1.9f){
				delete pTemp;
				continue;
			}
			pImg = cRunProc.GetImgFromRunRt(pTemp,ww,hh);
			pG = CImageBase::CropImg(m_pGrayImg,m_w,m_h,pTemp->m_Rect);
			isRecogChar(GRAY_CHINA,pG,ww,hh,m_CharSize,(void*)&pTemp->Hubo);
			if(pTemp->Hubo.Dis[0]<500 && pTemp->Hubo.Dis[0] < (RunRtAry[i]->Hubo.Dis[0]+RunRtAry[i+1]->Hubo.Dis[0])/2){
				RunRtAry[i]->Append(RunRtAry[i+1]);
				RunRtAry[i]->nRecogFlag = 0;
				RunRtAry[i+1]->bUse=FALSE;
				i++;
			}
			delete []pImg;
			delete []pG;
			delete pTemp;
		}
	}
	nCharNum = RemoveNoneUseRects(RunRtAry);
	return nCharNum;

}
void CLineRecogPrint::RemoveBeforAfterDot(CCharAry& RunRtAry)  //2010.1.29
{
	CRect cLnRt(0,0,m_w,m_h);
	int nNum = RunRtAry.GetSize();

	if(nNum <2)return;

	int i;
	for(i=0;i<nNum;i++)
	{
		CInsaeRt *pRt = RunRtAry[i];
		if(pRt->Hubo.Dis[0] > g_th_char_final * 4 || pRt->Hubo.Code[0] == '.' || pRt->Hubo.Code[0] == ',') 
		{
			delete RunRtAry.GetAt(i);
			RunRtAry.RemoveAt(i);
			nNum --; i --;
		}
	}	
	//----------------------------------------------------------
}

#define MOUM_A	0x314F//A4B4//	0xB4A4	'	
#define MOUM_YI	0x3163//A4C8//	0xC8A4
bool IsMoum(WORD wCode)
{
	if(wCode >= MOUM_A && wCode <= MOUM_YI)
		return true;
	return false;
}
void CLineRecogPrint::CharRecogInLine(CCharAry& RunRtAry)	//char recog
{
	BYTE* pB;
	int wd,hi,nCharType;
	CInsaeRt* pU;
	CInsaeRtProc cRunProc;
	int nCharNum = RunRtAry.GetSize();
	int i;
	for(i = 0; i < nCharNum; ++i){
		pU = RunRtAry.GetAt(i);
		if(pU->nRecogFlag > 0) continue;
		pB = cRunProc.GetImgFromRunRt(pU, wd, hi);
// 		BYTE* pB1 = RevisionRect(pB,wd,hi);
// 		if(pB1 != NULL){delete[] pB; pB = pB1;}
		
		nCharType = GetCharType(wd,hi,m_CharSize);
		pU->nRecogType = nCharType;

#ifdef LOG_VIE
		cv::Mat matChar = getMatImage(pB, wd, hi, 0);
		DisplayMatImage(matChar, false);
#endif //LOG_VIEW
 
		isRecogChar(m_Mode, pB, wd, hi, m_CharSize, (void*)&pU->Hubo, 2); 
		delete pB;pB = NULL;

		if(pU->Hubo.Dis[0] < g_th_char_final && nCharType!=DOT_TYPE && nCharType!=I_TYPE
			&& nCharType!=UNDER_LINE_TYPE && pU->Hubo.Code[0] != SMB_INFINITE
			&& IsMoum(pU->Hubo.Code[0]) == FALSE)
			pU->nRecogFlag = 2;
		else
			pU->nRecogFlag = 1;
	}

	int *nTemp = new int[nCharNum];
	memset(nTemp, 0 , nCharNum * sizeof(int));
	for(i = 0; i < nCharNum ; ++i)
		nTemp[i] = RunRtAry[i]->nRecogFlag;
	for(i = 0; i < nCharNum; ++i)
	{
		if((i > 0 && nTemp[i - 1] == 1) || 
			(i < nCharNum - 1 && nTemp[i + 1] == 1))
		{
			RunRtAry[i]->nRecogFlag = 1;
		}
	}
	delete []nTemp;
//	afxDump<<nCharFile<<"\n";
}

#define CODE_DA		0xB2E4//deb3//��
float CLineRecogPrint::Space_ProcessInsae(CCharAry& RunRtAry)
{

	int i,j,k,nNum,nCount,nOldMode=0;
	int nCharNum = RunRtAry.GetSize();
	for(i=0;i<nCharNum;i++)
		RunRtAry.GetAt(i)->Hubo.nSpLn = 0;
	if(nCharNum<=2) return 1000.0;

	//	RECT* chRts = new RECT[nCharNum];  
	RECT chRts[500];  
	int sp[500],wd[500],hi[500],wd1[500];//,top[500],bot[500];
	int sp1[500],sp2[500];
	int Type[500];
	int maxGap=0;
	double globalBig,globalTh;
	double widthBig,widthSmall;
	double koreaBig;
	double aveGap,BigGap,nBig,SmallGap,nSmall;
	double aveHigh,aveWidth;//,aveTop,aveBot;
	double spth = 0.0;

	
	CInsaeRt* pU;
	BYTE *pB;
	CInsaeRtProc cRunProc;
	int ww,hh;
	
	memset(Type,0,sizeof(int)*nCharNum);
	for(k=0;k<nCharNum;++k){
		pU = RunRtAry.GetAt(k);
		pB = cRunProc.GetImgFromRunRt(pU,ww,hh);
		nCount = 0;
		if(ww>5) {
			for(i=0;i<hh;++i){
				if(pB[i*ww+ww-3] == 1 || pB[i*ww+ww-4]==1)	nCount++;
			}
			if(nCount > hh/2) Type[k] = 1;
		}
		delete pB;
	}
	for(i=0;i<nCharNum;i++){
		memcpy(&chRts[i],&RunRtAry[i]->m_Rect,sizeof(RECT));
	}
	nNum = nCharNum-1;
	aveGap=aveHigh=aveWidth=0;//aveTop=aveBot=0;

	for(i=0;i<nNum;i++)
	{
		sp[i]=max(0,chRts[i+1].left - chRts[i].right);
		wd[i]=chRts[i].right-chRts[i].left; 
		hi[i]=chRts[i].bottom-chRts[i].top; 
// 		top[i] = chRts[i].top;
// 		bot[i] = chRts[i].bottom;
		aveGap += min(sp[i],3*m_CharSize); 
		aveHigh += hi[i];
		aveWidth += wd[i];
// 		aveTop += top[i];
// 		aveBot += bot[i];
		if((Type[i]==1 && (chRts[i].right-chRts[i].left)>(chRts[i].bottom-chRts[i].top)/2)
			|| RunRtAry[i]->nRecogType == I_TYPE) 
			sp[i]=max(0,sp[i]-(chRts[i].bottom - chRts[i].top)/8);
		if(Type[i] == 0) 	maxGap = max(maxGap,sp[i]+5);
		else				maxGap = max(maxGap,sp[i]);
	}
	aveGap /= nNum;	aveHigh /= nNum;	aveWidth /= nNum;//	aveTop /= nNum;	aveBot /= nNum;

	for(i=0;i<nNum;i++)
	{
		if(hi[i]<aveHigh/2){
			wd[i]=int(aveHigh*2/3);
// 			top[i]=aveTop;
// 			bot[i]=aveBot;
		}
	}
// 	int wMin,wMax,wAve,wDev;
// 	int tMin,tMax,tAve,tDev;
// 	int bMin,bMax,bAve,bDev;
// 	CBaseFunc::GetStatisticValue(wd,nNum,wMin,wMax,wAve,wDev);
// 	CBaseFunc::GetStatisticValue(top,nNum,tMin,tMax,tAve,tDev);
// 	CBaseFunc::GetStatisticValue(bot,nNum,bMin,bMax,bAve,bDev);

	
 	memcpy(sp2,sp,sizeof(int)*nNum);
// 	for(i=0;i<nNum;i++)
// 	{
// 		if(i==0){
// 			if(sp2[i]>sp2[i+1]*2 && sp2[i]>aveGap){
// 				sp1[i] = sp2[i+1];
// 			}
// 			else{
// 				sp1[i] = sp2[i];
// 			}
// 			continue;
// 		}
// 		if(sp2[i]>sp2[i-1]*2 && sp2[i]>aveGap){
// 			sp1[i] = sp2[i-1];
// 		}
// 		else
// 			sp1[i] = sp2[i];
// 	}
// 	memcpy(sp2,sp1,sizeof(int)*nNum);
// 	aveGap=0;
// 	for(i=0;i<nNum;i++)	{ aveGap += sp2[i];	}
// 	aveGap /= nNum;
// 	for(i=0;i<nNum;i++)
// 	{
// 		if(i==0){
// 			if(sp2[i]>sp2[i+1]*2 && sp2[i]>aveGap){
// 				sp1[i] = sp2[i+1];
// 			}
// 			else{
// 				sp1[i] = sp2[i];
// 			}
// 			continue;
// 		}
// 		if(sp2[i]>sp2[i-1]*2 && sp2[i]>aveGap){
// 			sp1[i] = sp2[i-1];
// 		}
// 		else
// 			sp1[i] = sp2[i];
// 	}
// 	memcpy(sp2,sp1,sizeof(int)*nNum);

	sp1[0] = (sp2[0]+sp2[1])/2;
	sp1[nNum-1] = (sp2[nNum-2]+sp2[nNum-1])/2;
	for(i=1;i<nNum-1;i++)
	{
		sp1[i] = (sp2[i-1]+sp2[i]+sp2[i+1])/3;
	}
	{

		
		{
			wd1[0] = (wd[0]+wd[1])/2;
			wd1[nNum-1] = (wd[nNum-2]+wd[nNum-1])/2;
			for(i=1;i<nNum-1;i++)
			{
				wd1[i] = (wd[i-1]+wd[i]+wd[i+1])/3;
			}
			aveGap=0;
			for(i=0;i<nNum;i++)	aveGap += wd1[i];
			aveGap /= nNum;
			BigGap = nBig = SmallGap = nSmall = 0;
			for(i=0;i<nNum;i++)
			{
				if(wd1[i]>aveGap){	BigGap+=wd1[i];		nBig++;	}
				else			{	SmallGap+=wd1[i];	nSmall++;}
			}
			BigGap/=nBig;
			SmallGap/=nSmall;
			if(SmallGap/BigGap > 0.75) {
				nOldMode = 1;
			}
			widthBig=BigGap;
			widthSmall=SmallGap;
		}


		aveGap=0;
		for(i=0;i<nNum;i++)	aveGap += sp1[i];
		aveGap /= nNum;
		BigGap = nBig = SmallGap = nSmall = 0;
		for(i=0;i<nNum;i++)
		{
			if(sp1[i]>aveGap){		BigGap+=sp1[i];		nBig++;	}
			else			{		SmallGap+=sp1[i];	nSmall++;}
		}
		if(nBig) BigGap/=nBig;
		else BigGap = m_CharSize;
		if(nSmall) SmallGap/=nSmall;
		else SmallGap = m_CharSize/3;
		if(BigGap < SmallGap*2 || nOldMode == 1) {
			memcpy(sp2,sp,sizeof(int)*nNum);
			nOldMode = 1;
		}
		else{
			for(i=0;i<nNum;i++){
				sp2[i] = max(0,sp[i]-sp1[i]);
			}
			
			aveGap=0;nCount=0;
			for(i=0;i<nNum;i++)
			{
				if(wd[i]<(widthBig+widthSmall)/2 || hi[i]<aveHigh*2/3)	continue;
				aveGap += min(sp[i],3*m_CharSize); 
				nCount++;
			}
			if(nCount)	aveGap /= nCount;
			else		aveGap = m_CharSize/2;
			BigGap = nBig = SmallGap = nSmall = 0;
			for(i=0;i<nNum;i++)
			{
				if(wd[i]<(widthBig+widthSmall)/2 || hi[i]<aveHigh*2/3)	continue;
				if(sp[i]>aveGap*1.4 && sp[i]<aveGap*8)
				{
					BigGap+=sp[i];
					nBig++;
				}
				if(sp[i]<=aveGap*1.4)
				{
					SmallGap+=sp[i];
					nSmall++;
				}
				
			}
			if(nBig) BigGap/=nBig;
			else BigGap = m_CharSize;
			if(nSmall) SmallGap/=nSmall;
			else SmallGap = m_CharSize/3;
			if(BigGap<m_CharSize*2/3 && maxGap<m_CharSize) BigGap=maxGap;//*3/4;
			koreaBig = (SmallGap+BigGap)/2;
		}
	}
	
	aveGap=0;nCount=0;
	for(i=0;i<nNum;i++)
	{
		if( hi[i]<aveHigh/2)	continue;
		aveGap += min(sp2[i],3*m_CharSize); 
		nCount++;
	}
	if(nCount)	aveGap /= nCount;
	else		aveGap = m_CharSize/2;
	BigGap = nBig = SmallGap = nSmall = 0;
	for(i=0;i<nNum;i++)
	{
		if(sp2[i]>aveGap*1.4 && sp2[i]<aveGap*12 && hi[i]>aveHigh*2/3)
		{
			BigGap+=sp2[i];
			nBig++;
		}
		if(sp2[i]<=aveGap*1.4)
		{
			SmallGap+=sp2[i];
			nSmall++;
		}
		
	}
	if(nBig) BigGap/=nBig;
	else BigGap = m_CharSize/2;
	if(nSmall) SmallGap/=nSmall;
	else SmallGap = m_CharSize/3;
	double spglbth;
	if(maxGap< m_CharSize)	spglbth=(SmallGap*8/10+BigGap*12/10)/2;
	else					spglbth=(SmallGap+BigGap)/2;
	spglbth = max(spglbth, m_CharSize*0.1);
	
	globalBig = BigGap;
	globalTh = spglbth;

	if(spglbth<m_CharSize/3.0 && nNum < 12){
		if((maxGap<aveHigh/2) || BigGap<aveHigh/3)
			return (float)spglbth;
	}
/*	spglbth=max(spglbth,m_CharSize*0.25);*/
	//if(nCharNum<23)
		nOldMode=0;

	if(nOldMode == 0){//New Mode
		for(i=0;i<nCharNum-1;i++){
			if(sp2[i]<=spglbth)
			{
				RunRtAry[i]->Hubo.nSpLn = SPACE_NO;
			}
			else
			{
				RunRtAry[i]->Hubo.nSpLn = SPACE_YES;
			}
		}
	}
	else{//Old Mode
#define VOTELEN 15
		int x,y;
		
		for(i=0;i<max(1,nCharNum-1-VOTELEN/2);i++)
		{
			x=max(i-VOTELEN/2,0);
			y=min(i+VOTELEN/2,nCharNum-2);
			aveGap = 0;
			for(j=x;j<=y;j++)
			{
				aveGap += min(sp2[j-x],3*m_CharSize); 
			}
			if(aveGap) aveGap/=(y-x+1);
			else aveGap = m_CharSize/3;
			BigGap = nBig = SmallGap = nSmall = 0;
			for(j=x;j<=y;j++)
			{
				if(sp2[j-x]>aveGap*1.4 && sp2[j-x]<aveGap*8)
				{
					BigGap+=sp2[j-x];
					nBig ++;
				}
				if(sp2[j-x]<aveGap*1.4)
				{
					SmallGap+=sp2[j-x];
					nSmall ++;
				}
				
			}
			if(nBig) BigGap/=nBig;
			else BigGap = m_CharSize;
			if(nSmall) SmallGap/=nSmall;
			else SmallGap = m_CharSize/3;
			spth = (SmallGap+BigGap)/2;
			spth = max(spth, m_CharSize*0.1);
			spth = max(spth,spglbth*0.93);
			spth = min(spth,spglbth*1.12);
			for(j=x;j<=y;j++)
			{
				if(RunRtAry[j+1]->m_Rect.left - RunRtAry[j]->m_Rect.right<=spth)
					RunRtAry[j]->Hubo.nSpLn-=1;
				else
					RunRtAry[j]->Hubo.nSpLn+=1;
			}
		}
		for(i=0;i<nCharNum-1;i++){
			nCount = RunRtAry[i]->Hubo.nSpLn;
			if(nCount<=0)
			{
				RunRtAry[i]->Hubo.nSpLn = SPACE_NO;
			}
			else
			{
				RunRtAry[i]->Hubo.nSpLn = SPACE_YES;
			}
		}		
	}

/*	if(m_Language == ENGLISH) */return (float)spth;

}
bool isReal_1(BYTE* pImg,int w,int h)
{
	if(w>h/2) return true;
	if(pImg == NULL) return false;
	int i,j;
	int s = 0;
	for(i = 0; i < w / 2; i++)
		for(j = 0;j < h; j ++)
			if (pImg[j*w+i] == 1)
				s ++;
	if(s > w / 2 * h /2) return false;
	return true;
}

#define CODE_DIGIT1		0x0031//B1A3	//"1"
#define CODE_EXCLA_MARK	0x0021//AAA1	//"!"
#define CODE_OI			0xC774//CBCB //��
int CLineRecogPrint::SecondMerge_dynamic(CCharAry& RunRtAry)
{
	int i,j,nCharNum;
	nCharNum=RunRtAry.GetSize();
	if(nCharNum == 0)
		return 0;
	struct tagDynamic
	{
		int _prev;
		double val;
	};
	tagDynamic a[1000];
	BYTE *pImg;
	CInsaeRtProc cRunProc;
	int ww,hh;
	double dist;
	double symboldist[1000];
	WORD code[1000];
	WORD wCode;
	int idx;
	int font;
	int nCurChar = 0,nEndChar;
    BYTE* pG;
	do
	{
		if(RunRtAry.GetAt(nCurChar)->nRecogFlag == 2) 
		{
			nCurChar ++;
			continue;
		}
		for(i = nCurChar + 1;i < nCharNum; i ++)
			if(RunRtAry.GetAt(i)->nRecogFlag == 2)
				break;
		nEndChar = i;
		for(i = nCurChar;i < nEndChar; i++)
		{
			a[i].val = -1;
			a[i]._prev = i-1;
			code[i] = 0;
			if(i!=nCurChar) continue;

			pImg = cRunProc.GetImgFromRunRt(RunRtAry.GetAt(i),ww,hh);
            pG = CImageBase::CropImg(m_pGrayImg,m_w,m_h,RunRtAry.GetAt(i)->m_Rect);
			dist = GetConfofChar(pImg,ww,hh,m_CharSize,wCode,idx,font);
			code[i] = wCode;
			if((wCode==CODE_DIGIT1 || wCode==CODE_EXCLA_MARK || wCode == chCOMMA || wCode == chDOT))
				if(RunRtAry.GetAt(i)->nReserved1) dist=max(dist,(double)g_th_char_symbol * 2);
			
			symboldist[i]=dist;
			delete[] pImg; pImg = NULL;delete pG;
			a[i].val = dist;
				
			//delete pTemp;
		}
		CInsaeRt* pTemp;
		bool btemp=false;
		bool bReal1 = false;
		bool bMoum = false;
		for(i=nCurChar + 1;i < nEndChar; i++)
		{
			pTemp = new CInsaeRt();
			//pTemp->Append(RunRtAry[i]);
			btemp=false;
			bReal1 = false;
			bMoum = false;
			for(j = i - 1; j >= max(nCurChar - 1,i - 3); j --)
			{
				//if(Distance_Between_TwoRect(RunRtAry[j+1],RunRtAry[i])>m_CharSize/3) break;
				  pTemp->Append(RunRtAry[j+1]);
				  if(j!=i-1 &&( pTemp->m_Rect.Width()>m_CharSize*1.9f || pTemp->m_Rect.Width()/float(pTemp->m_Rect.Height())>1.9f)) break;
				 pImg = cRunProc.GetImgFromRunRt(pTemp,ww,hh);
  			     dist = GetConfofChar(pImg,ww,hh,m_CharSize,wCode,idx,font);
 				 if((wCode==CODE_DIGIT1 || wCode==CODE_EXCLA_MARK
					 || wCode == chCOMMA || wCode == chDOT) && j==i-1)
				 {
					 if(RunRtAry.GetAt(j+1)->nReserved1) 
					{
						dist = max(dist, (double)g_th_char_symbol * 2);
					 //if((RunRtAry.GetAt(j+1)->nReserved1 & 0x01)==1)
						btemp=true;
					}
					 if(isReal_1(pImg,ww,hh) && (dist<g_th_char_symbol || ww>hh/2))
						 bReal1 = true;
					dist = max((double)g_th_char_korea / 5,dist);
					btemp = true;
				 }
				 if(j == i - 1 && IsMoum(wCode))
					 bMoum = true;
				 if(j!=i-1 && btemp==true) {
					 if(j== i-2 && (code[j + 1] == CODE_DIGIT1 || code[j + 1] == CODE_EXCLA_MARK))
						 dist = max((double)g_th_char_korea,dist);
// 					 else if(dist < g_th_char_symbol && idx<m_RecogChina.GetSpecialIndex(ID_ASIAN) && wCode != CODE_OI)
// 					 {
// 						dist = dist * 2 / 3;
// 					 }
					 if(wCode == CODE_OI && (font == 1 || font == 2))  //01 process, gothic, myongjo
					 {
						 if(bReal1 || ww>hh)
							dist = dist * 2;
						else
							dist = dist / 2;
					 }
					 bReal1 = false;
					 btemp=false;
				 }
				 //Moum Process
// 				 if(j!=i-1 && bMoum == true && idx<m_RecogChina.GetSpecialIndex(ID_ASIAN) && dist<g_th_char_symbol)
// 					 dist = 0;
				 if(j == i-1 && wCode == 0xb0b4 && float(ww)/float(hh) < 0.4f) //LH
				 {
					 dist = g_th_char_symbol;
				 }
				 delete[] pImg; pImg = NULL;
				 if(j == nCurChar - 1)
				 {
					 if(a[i].val==-1 || a[i].val>dist*(i-j))
					 {
						 a[i].val=dist*(i-j);
						 a[i]._prev=j;
						 code[i] = wCode;
					}
				 }
				 else if(a[i].val==-1 || a[i].val>a[j].val+dist*(i-j))
				 {
					 a[i].val=a[j].val+dist*(i-j);
					 a[i]._prev=j;
					 code[i] = wCode;
				 }
			}
			delete pTemp;
		}
		int now = nEndChar - 1;
		while(now != nCurChar - 1)
		{
			for(i=now-1;i>a[now]._prev;i--)
			{
				RunRtAry[now]->Append(RunRtAry[i]);
				RunRtAry[now]->nRecogFlag = 0;
				RunRtAry[i]->bUse=FALSE;
			}
			
			now=a[now]._prev;
		}
		nCurChar = nEndChar;
	}while(nCurChar < nCharNum);
	nCharNum = RemoveNoneUseRects(RunRtAry);
	return nCharNum;

}
void CLineRecogPrint::SecondMerge_Horizontal(CCharAry& RunRtAry)
{
	int j,k,p,m,nCharNum,nCount;
	float fRate;
	BOOL bCheck;
//	BYTE *pImg;
	CRect Rt;
	CSize Sz;
	CInsaeRt* pU,*pU1;
	
	nCharNum = RunRtAry.GetSize();
//	double dist,dist1,dist2;
	int *pCombPi = new int[nCharNum];
//	int font;
//	WORD wCode;
	do
	{
		nCount = 0;
		nCharNum = RunRtAry.GetSize();			
		if(nCharNum <= 1) continue;
		for(j=0; j<nCharNum; j++) pCombPi[j] = -1;
		
		FoundCombinePair_InSae(RunRtAry,pCombPi);
		
		for(j=0; j<nCharNum; j++)
		{
			k = pCombPi[j];
			if(k == -1) continue;
			if(pCombPi[k] == j)
			{
				p = j;
				m = k;
				pU = RunRtAry.GetAt(p);
				pU1 = RunRtAry.GetAt(m);
//				ASSERT(p < m );
				Rt.UnionRect(pU->m_Rect, pU1->m_Rect);
				if(1)
				{
					fRate = (float)pU->m_Rect.Height() / (float)pU1->m_Rect.Height();
					if((fRate > 0.88f && fRate < 1.0f) && Distance_Between_TwoRect(pU1, pU) < 0)
					{
						//pU->m_Rect = Rt; 
						pU->Append(pU1);
						pU1->bUse = FALSE;
						pCombPi[k] = -1;
						nCount++;
					}
					else 
					{
					/*	int ww,hh;
						CInsaeRtProc cRunProc;
						pImg = cRunProc.GetImgFromRunRt(pU,ww,hh);
						dist = GetConfofChar(pImg,ww,hh,m_CharSize,wCode,idx,font);
						delete pImg; pImg = NULL;
						pImg = cRunProc.GetImgFromRunRt(pU1,ww,hh);
						dist1 = GetConfofChar(pImg,ww,hh,m_CharSize,wCode,idx,font);
						delete pImg; pImg = NULL;
						CInsaeRt* pTemp = new CInsaeRt();
						pTemp->Append(pU);
						pTemp->Append(pU1);
						pImg = cRunProc.GetImgFromRunRt(pTemp,ww,hh);
						dist2 = GetConfofChar(pImg,ww,hh,m_CharSize,wCode,idx,font);
						delete pImg; pImg = NULL;
						delete pTemp;
						bCheck=(dist2*2)<(dist+dist1);*/
						bCheck = TRUE;
						//bCheck=dist2<g_th_char_korea;
						if(bCheck == TRUE)
						{
							//pU->m_Rect = Rt; 
							pU->Append(pU1);
							pU1->bUse = FALSE;
							nCount++;
						}
 						pCombPi[k] = -1;
					}
				}
				else
				{
					//pU->m_Rect = Rt; 
					pU->Append(pU1);
					pU1->bUse = FALSE;
					pCombPi[k] = -1;
					nCount++;
				}
			}
		}
		RemoveNoneUseRects(RunRtAry);
	}while(nCount != 0);
	
	delete []pCombPi;
}
void CLineRecogPrint::FoundCombinePair_InSae(CCharAry& RunRtAry,int *pCombPi)
{
	int i,k,p,nY1,nY2,nDisL,nDisR,nMid,nCharNum;
	int nWdL,nHiL,nWdR = 0,nHiR = 0,nSumL,nSumR,nWdLimit,nHiLimit,nDisLimit;
	float fRateL,fRateR,fWHRateChar,fHWRateVowel1,fHWRateVowel2;
	CRect RL,RR;
	BOOL bml,bmr;

	CInsaeRt *pU,*pU1,*pU2;

	fWHRateChar = 1.2f;

	fHWRateVowel1 = 2.5f;
	fHWRateVowel2 = 2.7f;
	nMid = (int)((float)m_LineRt.Height() * 0.2f);
	nY1 = m_LineRt.top + nMid;
	nY2 = m_LineRt.bottom - nMid;
//	char str[50];
//	sprintf(str,"charsz=%d",m_CharSize);
//	AfxMessageBox(str);
	
	nWdLimit = (int)((float)m_CharSize * fWHRateChar);//1.2f);
	nHiLimit = (int)((float)m_CharSize * 0.64f);
	nDisLimit = (int)((float)m_CharSize * 0.35f);

	nCharNum = RunRtAry.GetSize();

	for(i=0; i<nCharNum; i++)
	{
		pU = RunRtAry.GetAt(i);
		if(i == 0)
		{
			p = i + 1;
			pU2 = RunRtAry.GetAt(p);
			nDisR = Distance_Between_TwoRect(pU2, pU);
			if(nDisR > nDisLimit) continue;
			//if(pU->m_Rect.Height() > nHiLimit && (float)pU->m_Rect.Height() / (float)pU->m_Rect.Width() > fHWRateVowel2 && nDisR > 0) continue;
			if(pU2->m_Rect.top > pU->m_Rect.CenterPoint().y && nDisR > 0) continue;
			if(pU2->m_Rect.Height() < nMid && pU2->m_Rect.top > nY1 && pU2->m_Rect.bottom < nY2 && nDisR > 0) continue; 
			if(pU->m_Rect.Height() < nMid && pU->m_Rect.top > nY1 && pU->m_Rect.bottom < nY2 && nDisR > 0) continue; 
			//if(pU2->m_Rect.Height() > nHiLimit && pU2->m_Rect.Width() > pU2->m_Rect.Height() * 0.5f
			//	&& pU->m_Rect.Height() > nHiLimit) continue;
			RR.UnionRect(pU->m_Rect, pU2->m_Rect);
			nWdR = RR.Width();
			nHiR = RR.Height();
			if(nWdR > nWdLimit || nHiR < nHiLimit) continue;
			if((float)nWdR / (float)nHiR > fWHRateChar) continue; 
			pCombPi[i] = p; 
		}
		else if(i == nCharNum - 1)
		{
			k = i - 1;
			pU1 = RunRtAry.GetAt(k);
			nDisL = Distance_Between_TwoRect(pU, pU1);
			if(nDisL > nDisLimit) continue;
			//if(pU1->m_Rect.Height() > nHiLimit && (float)pU1->m_Rect.Height() / (float)pU1->m_Rect.Width() > fHWRateVowel2 && nDisL > 0) continue;
			if(pU->m_Rect.top > pU1->m_Rect.CenterPoint().y && nDisL > 0) continue;
			if(pU1->m_Rect.top > pU->m_Rect.CenterPoint().y && nDisL > 0) continue;
			if(pU1->m_Rect.Height() < nMid && pU1->m_Rect.top > nY1 && pU1->m_Rect.bottom < nY2 && nDisL > 0) continue; 
			//if(pU->m_Rect.Height() > nHiLimit && pU->m_Rect.Width() > pU->m_Rect.Height() * 0.5f
			//	&& pU1->m_Rect.Height() > nHiLimit) continue;
			RL.UnionRect(pU->m_Rect, pU1->m_Rect);
			nWdL = RL.Width();
			nHiL = RL.Height();
			if(nWdL > nWdLimit || nHiL < nHiLimit) continue;
			if((float)nWdR / (float)nHiR > fWHRateChar) continue;
			pCombPi[i] = k;
		}
		else
		{
			k = i - 1;
			p = i + 1;
			pU1 = RunRtAry.GetAt(k);
			pU2 = RunRtAry.GetAt(p);

			RL.UnionRect(pU->m_Rect, pU1->m_Rect);
			RR.UnionRect(pU->m_Rect, pU2->m_Rect);
			nWdL = RL.Width(); nHiL = RL.Height();
			nWdR = RR.Width(); nHiR = RR.Height();
			fRateL = (float)nWdL / (float)nHiL;
			fRateR = (float)nWdR / (float)nHiR;
			bml = (fRateL < fWHRateChar && nWdL < nWdLimit && nHiL > nHiLimit) ? TRUE: FALSE;
			bmr = (fRateR < fWHRateChar && nWdR < nWdLimit && nHiR > nHiLimit) ? TRUE: FALSE;

			if(!bml && !bmr) continue;
			else if(bml && !bmr) goto ll;
			else if(!bml && bmr) goto rr;
			else
			{
				nSumL = nSumR = 0;
				nDisL = Distance_Between_TwoRect(pU, pU1);
				nDisR = Distance_Between_TwoRect(pU2, pU);

				if(nDisL <= nDisLimit) nSumL++;
				if(nDisR <= nDisLimit) nSumR++;
				
				if(pU1->m_Rect.top < pU->m_Rect.CenterPoint().y && (float)pU->m_Rect.Height() / (float)pU1->m_Rect.Height() > 1.25f) nSumL++; 
				if(pU->m_Rect.top < pU2->m_Rect.CenterPoint().y && (float)pU2->m_Rect.Height() / (float)pU->m_Rect.Height() > 1.25f) nSumR++; 

				if((float)pU->m_Rect.Height() / (float)pU->m_Rect.Width() > fHWRateVowel1) nSumL++; 
				if((float)pU2->m_Rect.Height() / (float)pU2->m_Rect.Width() > fHWRateVowel1) nSumR++; 

				if(pU->m_Rect.top > pU1->m_Rect.CenterPoint().y && nDisL > 0) nSumL -= 2;
				if(pU2->m_Rect.top > pU->m_Rect.CenterPoint().y && nDisR > 0) nSumR -= 2;

				if(pU1->m_Rect.top > pU->m_Rect.CenterPoint().y && nDisL > 0) nSumL -= 2;
				if(pU->m_Rect.top > pU2->m_Rect.CenterPoint().y && nDisR > 0) nSumR -= 2;

				if(pU1->m_Rect.Height() < nMid && pU1->m_Rect.top > nY1 && pU1->m_Rect.bottom < nY2 && nDisL > 0) nSumL -= 2; 
				if(pU->m_Rect.Height() < nMid && pU->m_Rect.top > nY1 && pU->m_Rect.bottom < nY2 && nDisR > 0) nSumR -= 2; 

				//if(pU1->m_Rect.Height() > nHiLimit && (float)pU1->m_Rect.Height() / (float)pU1->m_Rect.Width() > fHWRateVowel2 && nDisL > 0) nSumL--; 
				//if(pU->m_Rect.Height() > nHiLimit && (float)pU->m_Rect.Height() / (float)pU->m_Rect.Width() > fHWRateVowel2 && nDisR > 0) nSumR--; 

				if(nSumL == nSumR) pCombPi[i] = k;
//				if(nSumL == nSumR) continue;
				else if(nSumL > nSumR) pCombPi[i] = k;
				else              pCombPi[i] = p;
				continue;
			}
ll:	
			nDisL = Distance_Between_TwoRect(pU, pU1);
			if(nDisL > nDisLimit) continue;
			//if(pU1->m_Rect.Height() > nHiLimit && (float)pU1->m_Rect.Height() / (float)pU1->m_Rect.Width() > fHWRateVowel2 && nDisL > 0) continue; 
			if(pU->m_Rect.top > pU1->m_Rect.CenterPoint().y && nDisL > 0) continue;
			if(pU1->m_Rect.top > pU->m_Rect.CenterPoint().y && nDisL > 0) continue;
			if(pU->m_Rect.Height() < nMid && pU->m_Rect.top > nY1 && pU->m_Rect.bottom < nY2 && nDisL > 0) continue; 
			if(pU1->m_Rect.Height() < nMid && pU1->m_Rect.top > nY1 && pU1->m_Rect.bottom < nY2 && nDisL > 0) continue; 
			pCombPi[i] = k;
			continue;
rr:		
			nDisR = Distance_Between_TwoRect(pU2, pU);
			if(nDisR > nDisLimit) continue;
			//if(pU->m_Rect.Height() > nHiLimit && (float)pU->m_Rect.Height() / (float)pU->m_Rect.Width() > fHWRateVowel2 && nDisR > 0) continue; 
			if(pU2->m_Rect.top > pU->m_Rect.CenterPoint().y) continue;
			if(pU->m_Rect.top > pU2->m_Rect.CenterPoint().y && nDisR > 0) continue;
			if(pU->m_Rect.Height() < nMid && pU->m_Rect.top > nY1 && pU->m_Rect.bottom < nY2 && nDisR > 0) continue; 
			if(pU2->m_Rect.Height() < nMid && pU2->m_Rect.top > nY1 && pU2->m_Rect.bottom < nY2 && nDisR > 0) continue; 
			pCombPi[i] = p; 
		}
	}
}

void CLineRecogPrint::ForcedSegment(CCharAry& RunRtAry)
{
	int i,n,lb,lm,wd,hi,count;
//	BYTE *pImg;
	BOOL bCheck;
	CSize Sz;
	int nCharNum;
	CInsaeRt*pU;

	count = 0;
	lb = (int)((float)m_CharSize * 0.5f); 
	lm = (int)((float)m_CharSize * 0.35f); 

	nCharNum = RunRtAry.GetSize();
	for(i=0; i<nCharNum; i++)
	{
		pU = RunRtAry.GetAt(i);	
		wd = pU->m_Rect.Width(); 
		hi = pU->m_Rect.Height();
// 		if(pU->nRecogFlag == 2 || 
// 			(pU->nRecogFlag != 0 && pU->Hubo.Dis[0] < g_th_char_korea) || 
// 			(pU->Hubo.Index[0] == DIGIT_0_ID && pU->Hubo.Dis[0] < g_th_char_symbol)
// 			|| (pU->Hubo.Index[0] >= chA && pU->Hubo.Index[0]<=chz &&	pU->Hubo.Dis[0] < g_th_char_symbol))
// 		{
// 			if((pU->Hubo.Code[0] != CODE_OI || pU->Hubo.Font[0] != 1)
// 				&& pU->Hubo.Code[0] != SMB_INFINITE)
// 				continue;
// 		}
		if(m_Mode<MODE_PASSPORT_ENGNAME)
		{
			if(wd > hi*1.2 && wd > m_CharSize*0.7 && hi > m_CharSize*0.5)
			{
				bCheck = TRUE;

			}
			else bCheck = FALSE;
		}else {
			bCheck = TRUE;
			if(pU->nRecogFlag == 2 || 
				(pU->nRecogFlag != 0 && pU->Hubo.Dis[0] < g_th_char_korea) || 
				(pU->Hubo.Code[0] == ch0 && pU->Hubo.Dis[0] < g_th_char_symbol)
				|| (pU->Hubo.Code[0] >= chA && pU->Hubo.Code[0]<=chz &&	pU->Hubo.Dis[0] < g_th_char_symbol))
			{
				 bCheck = FALSE;
			}
			if(wd < hi/3 || wd < m_CharSize*0.3 )
			{
				bCheck = FALSE;

			}

		}
		
		if(bCheck)
		{
			n=0;
			n = ForcedEngCut(RunRtAry,i);
			if(n != 0)
			{
				Del_Rect(RunRtAry, i, 0);
				//i+=n;
				nCharNum += n;
			}

			if(n == 0)
			{
				n = ForcedCut(RunRtAry,i);
				if(n != 0)
				{
					Del_Rect(RunRtAry, i, 0);
					//i+=n;
					nCharNum += n;
				}
			}
// 		     if(m_Language!=0 && n==0)
// 			{
 				
// 			}
		}
	}
}
int	CLineRecogPrint::ForcedEngCut(CCharAry& RunRtAry,int nId)
{
	CRunProc cRunProc;
	CInsaeRt* pU=RunRtAry[nId],*pU1;
	int w,h,p;
	BYTE* Img=cRunProc.GetImgFromRunRt(RunRtAry[nId],w,h);
	float nThick = GetStrokeWidth(RunRtAry[nId]);
	int* hist = new int[w+1];
	int* hist1 = new int[w+1];
	memset(hist,0,(w+1)*sizeof(int));
	memset(hist1,0,(w+1)*sizeof(int));
	int i,j,k;
	for(i=0;i<w;i++)
	{
		for(j=0;j<h;j++)
			hist[i]+=Img[j*w+i];
	}
	for(i=2;i<w-3;i++)
	{
		hist1[i]=hist[i-2]+hist[i-1]+hist[i]+hist[i+1]+hist[i+2];
		
	}
	int nCutNum=0,nPos[300];
	nPos[0]=RunRtAry[nId]->m_Rect.left;
	bool bdowning=false;
	for(i=5;i<w-5;i++)
	{
		if(hist1[i-1]>hist1[i]) bdowning=true;
		if(bdowning && hist1[i]>hist1[i-1])
		{
// 			if(hist1[i+1]<hist[i] && hist[i+1]<nThick*2 && hist[i+1]<hist[i])
// 				nPos[++nCutNum]=i+RunRtAry[nId]->m_Rect.left;
			if(hist[i]<nThick*2)
				nPos[++nCutNum]=i+RunRtAry[nId]->m_Rect.left;
			bdowning = false;
		}
	}
	nPos[nCutNum+1]=RunRtAry[nId]->m_Rect.right;
	delete []hist;delete[]hist1;
	delete Img;
	if(!nCutNum) return 0;
//	int u;
	/*for(i=1;i<=nCutNum;i++)
	{
		
		for(u=0;u<3;u++)
		{
			k=0;
			for(j=0;j<h-h/5;j++)
			{
				if(Img[j*w+nPos[i]+u-RunRtAry[nId]->m_Rect.left]==1)
				{
					k=1;
					break;
				}
			}
			if(k==0) break;
			if(u==0) continue;
			for(j=0;j<h-h/5;j++)
			{
				if(Img[j*w+nPos[i]-u-RunRtAry[nId]->m_Rect.left]==1)
				{
					k=1;
					break;
				}
			}
			if(k==0) {u=-1*u;break;}
		}
		if(u==3)
		{
			for(j=i;j<=nCutNum;j++)
			{
				nPos[j]=nPos[j+1];
			}
			nCutNum--;i--;
		}
		else
			nPos[i]+=u;
	}
	if(!nCutNum) return 0;
*/
	int L,R,T,B;
	int nRunCount = 0;
	int nInsertIdx = nId + 1;
	for(i=0; i<=nCutNum; i++)
	{
		T = 10000; B = 0; k = i + 1;
		nRunCount = 0;
		for(j=0; j<pU->nRunNum; j += 2)
		{
			L = max(nPos[i], (int)(LOWORD(pU->pRunData[j])));
			R = min(nPos[k], (int)(LOWORD(pU->pRunData[j + 1])));
			if(R - L <= 0) continue;
			p = (int)(HIWORD(pU->pRunData[j]));
			T = min(T, p);
			B = max(B, p); 
			nRunCount ++;
		}
		pU1 = new CInsaeRt;
		pU1->pRunData = new DWORD[nRunCount*2];
		pU1->pRunLabel = new short[nRunCount*2];
		nRunCount = 0;
		for(j=0; j<pU->nRunNum; j += 2)
		{
			L = max(nPos[i], (int)(LOWORD(pU->pRunData[j])));
			R = min(nPos[k], (int)(LOWORD(pU->pRunData[j + 1])));
			if(R - L <= 0) continue;
			p = (int)(HIWORD(pU->pRunData[j]));
			pU1->pRunData[nRunCount]=MAKELONG(L,p);pU1->pRunLabel[nRunCount++]=pU->pRunLabel[j];
			pU1->pRunData[nRunCount]=MAKELONG(R,p);pU1->pRunLabel[nRunCount++]=pU->pRunLabel[j+1];
		}
		pU1->nRunNum = nRunCount;
		pU1->m_Rect = CRect(nPos[i], T, nPos[k], B + 1);
		pU1->nReserved1 = 1;
		RunRtAry.InsertAt(nInsertIdx++, pU1);
	}
	return nCutNum;
}
int CLineRecogPrint::ForcedCut(CCharAry& RunRtAry,int nId)
{
	int i,j,k,w,h,p,nPos[100],nCutNum;
	CInsaeRtProc cRtProc;
	CInsaeRt *pU,*pU1;
	pU = RunRtAry.GetAt(nId);
	w = pU->m_Rect.Width()+2;
	h = pU->m_Rect.Height()+2;
	if(w<h*0.5f) return 0;
	BYTE* Img = new BYTE[w*h];
	BYTE* ImgThin = new BYTE[w*h];
	BYTE** TempImg = (BYTE **)new BYTE[w * sizeof(BYTE*)];
	BYTE** TempThin = (BYTE **)new BYTE[w * sizeof(BYTE*)];
	for(i=0; i<w; i++) TempImg[i] = &Img[i * h];
	for(i=0; i<w; i++) TempThin[i] = &ImgThin[i * h];
	memset(Img,0,w*h);
	memset(ImgThin,0,w*h);
	//�����������Ϲ� �����װ� �����������Ϲ�˾ 0˺�� ������ �����б�
	GetImgYXFromRunRt_Ext(pU,TempImg,w,h);
	memcpy(ImgThin,Img,w*h);

// 	BYTE* tt = new BYTE[w*h];
// 	for(i=0;i<w;i++)for(k=0;k<h;++k) tt[k*w+i] = TempThin[i][k];
// 	CString FName;FName.Format(_T("C:\\Temp1.bmp"));//,nId);
// 	CImageIO::SaveImgToFile(FName,tt,w,h,1);

	//divide with connect component
	
	CInsaeRtProc runProc;
	int ww,hh;
	BYTE* pImg = runProc.GetImgFromRunRt(pU,ww,hh);
	CCharAry runAry;
	runProc.MakeConnectComponentFromImg(pImg,ww,hh,runAry);
	FirstMerge_Horizontal(runAry);
	int ncc = runAry.GetSize();
	delete []pImg;
	if(ncc == 2)
	{
		runProc.SortByOption(runAry,0,2,SORT_CENTER_X);
		nPos[0] = 0;
		nPos[1] = (runAry[1]->m_Rect.left + runAry[0]->m_Rect.right) / 2;
		nPos[2] = w - 1;
		nCutNum = 1;
		runProc.RemoveAllRunRt(runAry);
	}
	else
	{
		runProc.RemoveAllRunRt(runAry);
		
		{
			nCutNum = Is_Valley(TempImg,w,h, nPos, 1);
		//	if(nCutNum==0 || m_nLanguage==ENGLISH)
		//	{
				int nPos1[10];
				int nn;
				nn = Is_Valley(TempImg,w,h, nPos1, 0);
				if(nn)
				{
					for(i=1;i<=nn;i++)
						nPos[nCutNum+i] = nPos1[i];
					nCutNum+=nn;
					nPos[nCutNum+1] = w;
					for(i=0;i<nCutNum;i++)
						for(j=i+1;j<=nCutNum;j++)
						{
							if(nPos[i]>nPos[j])
							{
								nn=nPos[i];nPos[i]=nPos[j];nPos[j]=nn;
							}
						}
					for(i=0;i<nCutNum;i++)
						if(nPos[i+1]-nPos[i]<5)
						{
							memcpy(&nPos[i+1], &nPos[i+2], sizeof(int) * (nCutNum - i));
							nCutNum--;
							i--;
						}
				}
			//}
		}
	}
	if(/*m_mode==1 && */nCutNum==0){
		nPos[0]=0;nPos[1]=w/2;nPos[2]=w-1;
		nCutNum=1;
		// 		nPos[0]=0;nPos[1]=w/4;nPos[2]=w/2;nPos[3]=w*3/4;nPos[4]=w-1;
		// 		nCutNum=3;
	}
	int splitLoc[100];memset(splitLoc,0,sizeof(int)*100);
	for(i=1;i<=nCutNum;i++)
	{
		splitLoc[i]=1;
		for(k = max(0,nPos[i] - 2);k < min(nPos[i] + 3,w - 1); k++)
		{
			for(j=0;j<h;j++)
			{
				if(TempImg[k][j] == 1)
					break;
			
			}
			if(j == h)
			{
				splitLoc[i] = 0;
				break;
			}
		}
	}
	delete[] Img;
	delete[] ImgThin;
	delete TempImg;
	delete TempThin;

//	int num = StrokeAry.GetSize();
//	for(i=0;i<num;i++) delete [] (CTwoPoint*)StrokeAry.GetAt(i);
//	StrokeAry.RemoveAll();

	if(!nCutNum) return nCutNum;

	int L,R,T,B;
	for(p=nCutNum+1, i=0; i<=p; i++)
	{
		if(i == p)	nPos[i] = pU->m_Rect.right;
		else        nPos[i] += pU->m_Rect.left; 
	}
	int nRunCount = 0;
	int LL,RR;
	int nErrCount = 0;
	int nInsertIdx = nId + 1;
	for(i=0; i<=nCutNum; i++)
	{
		T = 10000; B = 0; k = i + 1;
		LL = 10000; RR = 0;
		nRunCount = 0;
		for(j=0; j<pU->nRunNum; j += 2)
		{
			L = max(nPos[i], (int)(LOWORD(pU->pRunData[j])));
			R = min(nPos[k], (int)(LOWORD(pU->pRunData[j + 1])));
			if(R - L <= 0) continue;
			p = (int)(HIWORD(pU->pRunData[j]));
			T = min(T, p);
			B = max(B, p); 
			LL = min(LL, L);
			RR = max(RR, R);
			nRunCount ++;
		}
		if(nRunCount == 0 || LL>=RR || T>=B)
		{
			//nCutNum --;
			nErrCount ++;
			continue;
		}
		pU1 = new CInsaeRt;
		pU1->pRunData = new DWORD[nRunCount*2];
		pU1->pRunLabel = new short[nRunCount*2];
		nRunCount = 0;
		for(j=0; j<pU->nRunNum; j += 2)
		{
			L = max(nPos[i], (int)(LOWORD(pU->pRunData[j])));
			R = min(nPos[k], (int)(LOWORD(pU->pRunData[j + 1])));
			if(R - L <= 0) continue;
			p = (int)(HIWORD(pU->pRunData[j]));
			pU1->pRunData[nRunCount]=MAKELONG(L,p);pU1->pRunLabel[nRunCount++]=pU->pRunLabel[j];
			pU1->pRunData[nRunCount]=MAKELONG(R,p);pU1->pRunLabel[nRunCount++]=pU->pRunLabel[j+1];
		}
		pU1->nRunNum = nRunCount;
		pU1->m_Rect = CRect(LL, T, RR, B + 1);
		pU1->nReserved1 = splitLoc[i]*2+splitLoc[k];
		RunRtAry.InsertAt(nInsertIdx++, pU1);
	}
	return nCutNum - nErrCount;
}

int CLineRecogPrint::Is_Valley1(BYTE* Img,int nWd,int nHi, int nPos[])
{
	int i,j,k,h,nCutNum=0;
	
	float BoonPo1[300];
	if(nWd>200 || nWd < 20) return 0;
	memset(BoonPo1, 0, sizeof(float) * nWd);
	for(i=0; i<nWd; i++) 
	{
		for(k=-1, j=0; j<nHi; j++)    if(Img[j*nWd+i] != 0) { k = j;  break; }
		for(h=-1, j=nHi-1; j>=0; j--) if(Img[j*nWd+i] != 0) { h = j;  break; }
		if(k != -1 && h != -1 && h > k) BoonPo1[i] = (float)(h - k);
	}
	int St = nWd/3;
	int Ed = nWd*2/3+3;
	float nMin = (float)nHi;
	int nMinId=St;
	for(i=St; i<Ed; i++){
		if(BoonPo1[i] < nMin){
			nMin = BoonPo1[i];
			nMinId = i;
		}
	}
	if(nMin<nHi/2){
		nPos[0]=0;
		nPos[1] = nMinId;
		nPos[2] = nWd;
		nCutNum = 1;
	}
	
	return nCutNum;
}
int CLineRecogPrint::Is_Valley(BYTE** Img,int nWd,int nHi, int nPos[], int mode)
{
	int i,j,k,h,nPitch,nCutNum;
	float *BoonPo1 = new float[nWd];
	float *BoonPo2 = new float[nWd];
	float *BoonPo3 = new float[nWd];
	//float BoonPo3[200];
	
	memset(BoonPo2, 0, sizeof(float) * nWd);
	memset(BoonPo3, 0, sizeof(float) * nWd);
	
	for(i=0; i<nWd; i++) 
	{
		for(k=0, j=0; j<nHi; j++)   k += Img[i][j];
		BoonPo3[i] = (float)k;
	}
	
	if(!mode)
	{
		memcpy(BoonPo2,BoonPo3,sizeof(float)*nWd);
		// 		for(i=0; i<nWd; i++) 
		// 		{
		// 			for(k=0, j=0; j<nHi; j++)   k += Img[i][j];
		// 			BoonPo2[i] = (float)k;
		// 		}
	}
	else
	{
		for(i=0; i<nWd; i++) 
		{
			for(k=-1, j=0; j<nHi; j++)    if(Img[i][j] != 0) { k = j;  break; }
			for(h=-1, j=nHi-1; j>=0; j--) if(Img[i][j] != 0) { h = j;  break; }
			if(k != -1 && h != -1 && h > k) BoonPo2[i] = (float)(h - k);
		}
	}
	
	nPitch = max(2,nHi / 7);//4;
	for(i=0; i<2; i++) Smooth(BoonPo2, nPitch, nWd);
	for(i=0; i<nWd; i++) BoonPo1[i] = BoonPo2[i];
	Smooth(BoonPo2, max(2, nHi  / 3), nWd);
	nCutNum = GetCutPosition(nWd, nHi,BoonPo1, BoonPo2, nPos, mode);
	

	delete []BoonPo3;
	delete []BoonPo2;
	delete []BoonPo1;
	
	return nCutNum;
}

void CLineRecogPrint::Smooth(float *Boon, int pit, int w_d)
{
	int i,n,x,q,k;
	float HH;	
	
	q = pit / 2;
	float* BoonPo = new float[w_d];
	
	for(k=0; k<w_d; k++)
	{
		n = 0;  HH = 0.0f;
		for(i=-q; i<q; i++)
		{
			x = k - i;
			if(x < 0) break;
			if(x >= w_d) continue; 
			HH = HH + Boon[x];
			n++; 
		}		
		BoonPo[k] = HH / (float)n;  
	}
	for(i=0; i<w_d; i++) Boon[i] = BoonPo[i];
	delete []BoonPo; 
}
/*
//�ܺ��˶�:GetImgFromRunRt
//����: pRunRt̩ pRunData�� ���� ���������� ���� ������ ������ Img�� �в���.
//�ذ�: �� �ܺ㳭�溷 Img�� (w+2,h+2)�ͱ��� �������� ���ؼӳ�.
//		���� �����ײ� ����˼ �Ժ��� ʭ���� �ۺ�˺�� �� �����˳�.
*/
void CLineRecogPrint::GetImgYXFromRunRt_Ext(CInsaeRt* pU,BYTE** Img,int nWd,int nHi)
{
	int i,j,y,nm,x1,x2;

	DWORD *data = pU->pRunData;
	nm=pU->nRunNum; 
	for(i=0;i<nm;i+=2)
	{
		x1=(int)LOWORD(data[i]) - pU->m_Rect.left+1;
		x2=(int)LOWORD(data[i+1]) - pU->m_Rect.left+1;
		y =(int)HIWORD(data[i]) - pU->m_Rect.top+1;
		for(j=x1; j<x2; j++) Img[j][y] = 1;
	}
}
int CLineRecogPrint::GetStrokeWidth(CInsaeRt* pU,BYTE** Img,int nWd,int nHi)
{
	int i,j,k,p,w,h,x,y;
	
	w = nWd - 1;
	h = nHi - 1;
	
	int num = 0,count = 0;
	int ki[] = {-1,-1,0,1,1,1,0,-1};
	int kj[] = {0,1,1,1,0,-1,-1,-1};
	
	p = 1;
	
	do
	{
		p++; 
		
		for(j=1; j<h; j++) for(i=1; i<w; i++)
		{
			if(Img[i][j] == 1)
			{
				for(k=0; k<8; k++)
				{
					x = i + ki[k];
					y = j + kj[k];
					
					if(Img[x][y] == 1) continue; 
					if(Img[x][y] < p)
					{ 
						Img[i][j] = p;
						num++;
						break;
					}
				}
			}
		}
		count++;
	}while((float)(pU->nPixelNum-num)/(float)pU->nPixelNum>0.05f);
	
	for(j=0;j<h;j++) for(i=0;i<w;i++) if(Img[i][j] != 0) Img[i][j] = 1; 
	
	int nLimit,wd[30];
	
	nLimit = count;
	count *= 2;
	count *= 3;
	if(count > 30) count = 30;
	memset(&wd, 0, sizeof(int) * 30);
	
	for(i=0; i<pU->nRunNum; i+=2)
	{
		p = (int)LOWORD(pU->pRunData[i+1]) - (int)LOWORD(pU->pRunData[i]);
		if(p >= count) continue;
		wd[p]++;
	}
	
	for(k=0, i=nLimit; i<count; i++)
	{
		if(wd[i] > k) { k = wd[i]; p = i; }
	}
	
	return p;
}
float CLineRecogPrint::GetStrokeWidth(CInsaeRt* pU)
{
	
	CInsaeRtProc proc;
	int w,h;
	BYTE* pImg = proc.GetImgFromRunRt(pU,w,h);
		int n1 = 0,n2 = 0;
		int i,j;
		for(i=0;i<h;i++)for(j=0;j<w;j++)
		{
			if(pImg[i*w+j])n1++;
		}
		for(i=1;i<h;i++)for(j=1;j<w;j++)
		{
			if(	pImg[(i-1)*w + (j-1)] && 
				pImg[(i-1)*w + j] && 
				pImg[i*w + (j-1)] && 
				pImg[i*w + j])        n2++;
		}
		float width = (float)n1/(float)(n1-n2);
		delete []pImg;
		return width;
}

void CLineRecogPrint::GetAnyOrgThin(BYTE** TempThin,int w,int h)
{
	int i,j,m,s,wd,hi,lId,rId,tId,bId;;
	char k = 1, s1, s2, x[9], y[9], o[9];
	BOOL flag;

	wd = w - 1;
	hi = h - 1;
	do
	{  
		flag = FALSE;

		for(i=1; i<hi; i++) for(j=1; j<wd; j++)
		{
			if(TempThin[j][i] == 1)
			{
				lId = j - 1;
				rId = j + 1;
				tId = i - 1;
				bId = i + 1;
				x[1] = TempThin[rId][i]; 
				x[2] = TempThin[rId][tId];
				x[3] = TempThin[j][tId];
				x[4] = TempThin[lId][tId];
	    		x[5] = TempThin[lId][i];
				x[6] = TempThin[lId][bId];
				x[7] = TempThin[j][bId];
				x[8] = TempThin[rId][bId];
				
				for(m=1; m<9; m++)
				{
            		if(x[m] == 1)
					{
						y[m]=1; 
						o[m]=1;
					}
            		else
					{
						if (x[m] == -k)
						{
							y[m]=1;
							o[m]=0;
						}
						else
						{
							y[m]=0;
							o[m]=0;
						}
					}
				}
            		
	     		if((y[1] + y[3] + y[5] + y[7]) < 4)
				{
	     			if(y[1] + y[2] + y[3] + y[4] + y[5] + y[6] + y[7] + y[8] > 1)
					{
                		if(o[2] + o[3] + o[4] + o[5] + y[1] + y[6] + y[7] + y[8] > 0)
						{	
							s1 = abs(y[1]-y[2]) + abs(y[2]-o[3]) + abs(o[3]-y[4]) +
								 abs(y[4]-y[5]) + abs(y[5]-y[6]) + abs(y[6]-y[7]) +
								 abs(y[7]-y[8]) + abs(y[8]-y[1]);
		 					s2 = abs(y[1]-y[2]) + abs(y[2]-y[3]) + abs(y[3]-y[4]) +
								 abs(y[4]-o[5]) + abs(o[5]-y[6]) + abs(y[6]-y[7]) +
								 abs(y[7]-y[8]) + abs(y[8]-y[1]);
		    				  
		 					if(s1 == 2 && s2 ==2)
							{
								TempThin[j][i] = -k; 
								flag = TRUE;
							}
		 					else
							{
		 						if(s1 == 4 && s2 == 4)
								{
									if(((y[5] + y[7] + (1 - y[1]) + (1 - y[2]) + (1 - y[3]) + (1 - y[6]) == 6) && (y[4] + y[8] > 0))
			    					  || ((y[3] + y[5] + (1 - y[4]) + (1 - y[7]) + (1 - y[8]) + (1 - y[1]) == 6) && (y[2] + y[6] > 0)))
									{
										TempThin[j][i] = -k;
										flag = TRUE;
									}
			    					else
									{
			    						if((o[2] + o[4] + o[6] + o[8] ==0) &&
			    							((o[5] + o[3] + (1 - o[1]) + (1 - o[7]) == 4) ||
											 (o[1] + o[7] + (1 - o[5]) + (1 - o[3]) == 4) ||
											 (o[5] + o[7] + (1 - o[1]) + (1 - o[3]) == 4) ||
											 (o[1] + o[3] + (1 - o[5]) + (1 - o[7]) == 4)))
										{
											TempThin[j][i] = -k;
											flag = TRUE;
										}
									}
								}
							}
						}
					}
				}
			}
		}
		k++;    
	}
	while(flag != FALSE);
 	
	for (i=0; i<h; i++) for(j=0; j<w; j++)
	{
		if (TempThin[j][i] != 1) TempThin[j][i] = 0;
	}

	for (i=1; i<hi; i++) for(j=1; j<wd; j++)
	{
		if(TempThin[j][i] != 1) continue;
		lId = j - 1;
		rId = j + 1;
		tId = i - 1;
		bId = i + 1;
		x[1]=TempThin[rId][i]; x[2]=TempThin[rId][tId]; x[3]=TempThin[j][tId]; x[4]=TempThin[lId][tId];
	    x[5]=TempThin[lId][i]; x[6]=TempThin[lId][bId]; x[7]=TempThin[j][bId]; x[8]=TempThin[rId][bId];
		s = x[1] + x[2] + x[3] + x[4] + x[5] + x[6] + x[7] + x[8];
		if(s < 3) continue;
		if(x[1]==1 && x[3]==1 && x[5]==1 && x[7]==0){ TempThin[j][i] = 0; continue;}
		if(x[3]==1 && x[5]==1 && x[7]==1 && x[1]==0){ TempThin[j][i] = 0; continue;}
		if(x[5]==1 && x[7]==1 && x[1]==1 && x[3]==0){ TempThin[j][i] = 0; continue;}
		if(x[7]==1 && x[1]==1 && x[3]==1 && x[5]==0){ TempThin[j][i] = 0; continue;}
		
	}

	for (i=1; i<hi; i++)for(j=1; j<wd; j++)
	{
		if(TempThin[j][i] != 1) continue;
		lId = j - 1;
		rId = j + 1;
		tId = i - 1;
		bId = i + 1;
		x[1]=TempThin[rId][i]; x[2]=TempThin[rId][tId]; x[3]=TempThin[j][tId]; x[4]=TempThin[lId][tId];
	    x[5]=TempThin[lId][i]; x[6]=TempThin[lId][bId]; x[7]=TempThin[j][bId]; x[8]=TempThin[rId][bId];
		if(x[3]==1 && x[5]==1 && x[7]==0 && x[8]==0 && x[1]==0){ TempThin[j][i] = 0; continue;}
		if(x[5]==1 && x[7]==1 && x[1]==0 && x[2]==0 && x[3]==0){ TempThin[j][i] = 0; continue;}
		if(x[7]==1 && x[1]==1 && x[3]==0 && x[4]==0 && x[5]==0){ TempThin[j][i] = 0; continue;}
		if(x[1]==1 && x[3]==1 && x[5]==0 && x[6]==0 && x[7]==0){ TempThin[j][i] = 0; continue;}
	}
}

int	CLineRecogPrint::GetCutPosition(int nWd, int nHi, float *BoonPo1, float *BoonPo2, int nPos[], int mode)
{
	int i,j,L = 0,R,nTemp = 0,nCutNum;
	double fDis,fSel;
	BOOL b1 = 0,b2;

	b2 = TRUE;
	nCutNum = 0;
	nPos[nCutNum] = 0;

	fSel = mode == 1?1.0:nHi / 4.0;
	
	for(i=0; i<nWd; i++) 
	{
		if(!i) 
		{
			if(BoonPo1[i] < BoonPo2[i]) b1 = TRUE;
			else b1 = FALSE;
			continue;
		}
		if(b1 && BoonPo1[i] > BoonPo2[i]) b1 = FALSE;
		if(!b1) 
		{
			if(b2 && BoonPo1[i] < BoonPo2[i]) { L = i; b2 = FALSE; }
			if(!b2 && BoonPo1[i] > BoonPo2[i])
			{
				R = i; b2 = TRUE;
				for(j=L+1; j<R; j++)
				{
					if(BoonPo1[j] <= BoonPo1[j + 1])
					{
						fDis = fabs(BoonPo1[j] - BoonPo2[j]);
						if(fDis > fSel/* && BoonPo1[j] < nHi / 2*/) { nCutNum++; nPos[nCutNum] = j; nTemp = R; }
						break;
					}
				}
				if(nCutNum >= 8) break;
				b1 = TRUE;
			}
		}
	}
	nPos[nCutNum + 1] = nWd;

	if(nCutNum)
	{
		for(i=nTemp; i<nWd; i++) if(fabs(BoonPo1[i] - BoonPo2[i]) > 2.0) break;
		if(i == nWd) 
		{
			memcpy(&nPos[nCutNum], &nPos[nCutNum + 1], sizeof(int));
			nCutNum--;
		}
	}
	return nCutNum;
}

int CLineRecogPrint::Distance_Between_TwoRect(CInsaeRt*pU, CInsaeRt*pU1)
{
	int nDis = pU->m_Rect.left - pU1->m_Rect.right;     
	return nDis;
}
int CLineRecogPrint::CheckOfPeak(CInsaeRt*pU)
{
	CInsaeRtProc cRtProc;
	int i,j,k,p,t=0,b=0,mx,wd,hi,pos,num;
	CRect r = pU->m_Rect;
	wd = r.Width();
	hi = r.Height();
	BYTE* Img;// = new BYTE[wd*hi];
	Img=cRtProc.GetImgFromRunRt(pU,wd,hi);

	k = wd / 3;
	pos = 0;
	if(wd<3) return 0;
	for(mx=0, j=0; j<k; j++)
	{ 
		for(t=0, i=0; i<hi; i++)
			t += Img[i*wd+j]; 
		if(t > mx) { mx = t; pos = j; }
	}
	for(i=0; i<hi; i++)    if(Img[i*wd+pos] == 1) { t = i; break; }
	for(i=hi-1; i>=0; i--) if(Img[i*wd+pos] == 1) { b = i; break; }
	for(num=0, i=t; i<b; i++)
	{
		for(p=0, j=0; j<k; j++) if(Img[i*wd+j] == 1) { p = 1; break; }
		if(p == 0) num++;
	}
	
	delete []Img; 

	if((float)mx > (float)hi * 0.9f) k = (num == 0) ? 1: 0;
	else k = 0;
	return k;
}

void CLineRecogPrint::Del_Rect(CCharAry& RunRtAry, int id, int mode)
{
	if(!mode) 
	{
		delete (CInsaeRt*)RunRtAry.GetAt(id);
		RunRtAry.RemoveAt(id);
	}
	else 
	{
		int nCharNum = RunRtAry.GetSize();
		for(int i=0; i<nCharNum; i++) delete (CInsaeRt*)RunRtAry.GetAt(i);
		RunRtAry.RemoveAll();
	}
}
void CLineRecogPrint::Del_Of_NoiseRect(CCharAry& RunRtAry,int nMode)
{
	CInsaeRt *pU,*pU1,*pU2;
	CRect LineRt = m_LineRt;
	CRect myRt;
	int myh,w,h,k,nCharNum,i;
	nCharNum = RunRtAry.GetSize();
	if(nMode == 9){
		h = LineRt.CenterPoint().y;
		myh= LineRt.Height();
		w = (int)((float)m_CharSize * 0.2f);
		for(k=0; k<nCharNum; k++)
		{
			myRt = RunRtAry[k]->m_Rect;
			if(myRt.Height() > w) continue;
			if(myRt.Width()>int(myRt.Height()*1.8f)) continue;
			if(myRt.bottom < LineRt.bottom-myh/3) 
				RunRtAry[k]->bUse = FALSE;
// 			else if(myRt.Height()<w/2)
// 				RunRtAry[k]->bUse = FALSE;
		}
	}
	else if(nMode==10){//10
		w = m_CharSize / 2;
		h = m_LineRt.Height() / 2;
		for(k=1; k<nCharNum-1; k++)
		{
			pU = RunRtAry.GetAt(k);
			pU1 = RunRtAry.GetAt(k-1);
			pU2 = RunRtAry.GetAt(k+1);
			if(pU->m_Rect.Height() >= h) continue;
			if(pU2->m_Rect.Height() < h) continue;
			if(pU1->m_Rect.Height() < h) continue;
			if((float)pU->m_Rect.Width() / (float)pU->m_Rect.Height() > 2.0f) continue;
			if(Distance_Between_TwoRect(pU2, pU1) > w) continue;
			pU->bUse = FALSE;
		}
	}
	else if(nMode==11)
	{
		h=m_CharSize/2;
		w=m_CharSize/2;
		for(k=0;k<nCharNum-1;k++)
		{
			pU = RunRtAry.GetAt(k);
			pU1 = RunRtAry.GetAt(k+1);
			if(pU->m_Rect.Height()>h) break;
			if(pU->m_Rect.Width()>w) break;
			if(Distance_Between_TwoRect(pU1,pU)<m_CharSize*3/2) continue;
			for(i=0;i<=k;i++)
				RunRtAry.GetAt(i)->bUse = FALSE;
		}
		for(k=nCharNum-1;k>0;k--)
		{
			pU = RunRtAry.GetAt(k);
			pU1 = RunRtAry.GetAt(k-1);
			if(pU->m_Rect.Height()>h) break;
			if(pU->m_Rect.Width()>w) break;
			if(Distance_Between_TwoRect(pU,pU1)<m_CharSize*3/2)continue;
			for(i=nCharNum-1;i>=k;i--)
				RunRtAry.GetAt(i)->bUse = FALSE;
		}
	}
	
	RemoveNoneUseRects(RunRtAry);
}
void CLineRecogPrint::RemoveUpDownNoise_In_Line(CCharAry& RunRtAry)
{

	int i,nCharNum;
	CInsaeRt *pU, *pU1;
	CInsaeRtProc runProc;
	
	int Th, nS;
	Th = max(3,m_CharSize / 15);
	nS = Th * Th;
	runProc.DeleteNoizeRects(RunRtAry, CSize(Th,Th));
	
	Th *=3;
	nS *= 5;
	nCharNum = RunRtAry.GetSize();
	int nStart = 0, nEnd = -1;
	CRect rtSubRect, rt1;
	int nDelType, nDist;
	for(i=0; i<nCharNum; i++)
	{
	rtSubRect.SetRectEmpty();
		rt1.SetRectEmpty();
		pU = RunRtAry.GetAt(i);
		if(pU->nPixelNum > nS)
			continue;
		for(nStart = i; nStart >0; nStart --)
		{
			pU1 = RunRtAry.GetAt(nStart);
			if(pU1->bUse == FALSE) continue;
			if(nStart != i)
				rt1.UnionRect(rt1,pU1->m_Rect);
			rtSubRect.UnionRect(rtSubRect, pU1->m_Rect);
			if(pU->m_Rect.left - pU1->m_Rect.right > m_CharSize*1.5 && 
				nStart != i && RunRtAry.GetAt(nStart + 1)->m_Rect.left>pU1->m_Rect.right)
				break;
		}
		for(nEnd = i + 1; nEnd < nCharNum; nEnd ++)
		{
			pU1 = RunRtAry.GetAt(nEnd);
			if(pU1->bUse == FALSE) continue;
			rtSubRect.UnionRect(rtSubRect, pU1->m_Rect);
			rt1.UnionRect(rt1,pU1->m_Rect);
			if(pU1->m_Rect.left - pU->m_Rect.right > m_CharSize*1.5 && 
				RunRtAry.GetAt(nEnd - 1)->m_Rect.right < pU1->m_Rect.left)
				break;
		}
		//if(pU->m_Rect.)
		nDelType = 0;
		if(rt1.IsRectEmpty()) continue;
		if(rt1.bottom == rtSubRect.bottom && rt1.top < rtSubRect.CenterPoint().y)
			nDelType = 1;
		if(rt1.top == rtSubRect.top && rt1.bottom > rtSubRect.CenterPoint().y)
			nDelType = 2;
		if(nDelType == 0)
			continue;
		if(pU->m_Rect.Width() > pU->m_Rect.Height() * 2)
			nDist = max(m_CharSize / 8, pU->m_Rect.Height() * 2);
		else
			nDist = m_CharSize / 15;
		if(nDelType == 1)
		{
			//i process
			if(pU->m_Rect.Width() < m_CharSize / 3 && pU->m_Rect.Height() < m_CharSize / 3)
			{
				if(i > 0)
				{
					pU1 = RunRtAry[i-1];
					if(pU1->m_Rect.Height() > m_CharSize / 2 && pU->m_Rect.Height() > pU->m_Rect.Width() * 2.6)
						nDelType = 0;
				}
				if(i < nCharNum - 1)
				{
					pU1 = RunRtAry[i+1];
					if(pU1->m_Rect.Height() > m_CharSize / 2 && pU->m_Rect.Height() > pU->m_Rect.Width() * 2.6)
						nDelType = 0;
				}
				if(nDelType == 0)
					continue;
			}
			if(rt1.top - pU->m_Rect.bottom < nDist)
				continue;
			//nDist = pU->m_Rect.Height();
			//St=max(St,10);
			//St/=2;
			//nDist = max(St,10);
		}
		else
		{
			if(pU->m_Rect.top - rt1.bottom < nDist)
				continue;
		}
		pU->bUse = FALSE;
	}
	
	RemoveNoneUseRects(RunRtAry);
}

int CLineRecogPrint::FirstMerge_Horizontal(CCharAry& RunRtAry)
{
	int p,n,m,mn,mx,w1,h1,w2,h2,un,count,nSum,mn1,mx1,un1;
	float lm1,lm2,lm3,lm4,rate;
	CRect Ru;
	CInsaeRt* pU,*pU1;
	int nCharNum = RunRtAry.GetSize();

	lm1 = (float)m_CharSize * 0.33f;
	lm2 = (float)m_CharSize * 0.85f;
	lm3 = (float)m_CharSize * 1.2f;
	lm4 = (float)m_CharSize * 0.8f;

	for(n=0; n<nCharNum; n++) {
		pU = RunRtAry.GetAt(n);
		pU->nAddNum = 0;
	}
	do 
	{
		count = 0;
		for(n=0; n<nCharNum; n++) 
		{
			pU = RunRtAry.GetAt(n);
			if(pU->bUse == FALSE) continue;
			w1 = pU->m_Rect.Width(); 
			h1 = pU->m_Rect.Height();
			m= (lm1 > (float)w1 && lm2 < (float)h1) ? 1: 0;
			for(p=n+1; p<nCharNum; p++) 
			{
				pU1 = RunRtAry.GetAt(p);
				if(n == p || pU1->bUse == FALSE) continue;
				w2 = pU1->m_Rect.Width(); 
				h2 = pU1->m_Rect.Height();
				mn = max(pU->m_Rect.left, pU1->m_Rect.left);
				mx = min(pU->m_Rect.right, pU1->m_Rect.right);
				un = mx - mn;
				mn1 = max(pU->m_Rect.top, pU1->m_Rect.top);
				mx1 = min(pU->m_Rect.bottom, pU1->m_Rect.bottom);
				un1 = mx1 - mn1;
				if(un > 0)
				{ 
					mn = min(w1, w2); 
					rate = (float)un / (float)mn;
					if(un1<0.2) rate=0.9f;
					if(	rate > 0.8f) 
					{
						Ru.UnionRect(pU->m_Rect, pU1->m_Rect);
						if(rate > 0.657f || Ru.Width() > m_CharSize)
						{
							//pU->m_Rect = Ru;
							pU->Append(pU1);
							w1 = Ru.Width(); 
							h1 = Ru.Height();
							pU->nAddNum++; 
							pU1->bUse = FALSE; 
							count++;
							continue;
						}
					}
					if((float)h1 / (float)w1 > 2.2f && (float)h2 / (float)w2 > 2.2f) 
					{
						//pU->m_Rect.UnionRect(pU->m_Rect, pU1->m_Rect);
						pU->Append(pU1);
						w1 = pU->m_Rect.Width();
						h1 = pU->m_Rect.Height();
						pU->nAddNum++; 
						pU1->bUse = FALSE; 
						count++;
						continue;
					}
					if(pU->m_Rect.left < pU1->m_Rect.left) 
					if((float)h1 / (float)w1 > 2.2f) 
					if((float)h1 > lm4) continue;//break;
					if(pU1->m_Rect.left < pU->m_Rect.left)
					if((float)h2 / (float)w2 > 2.2f) 
					if((float)h2 > lm4) continue;//break;
					if(( rate>=0.8) )
					{
						//pU->m_Rect.UnionRect(pU->m_Rect, pU1->m_Rect);
						pU->Append(pU1);
						w1 = pU->m_Rect.Width(); 
						h1 = pU->m_Rect.Height();
						pU->nAddNum++; 
						pU1->bUse = FALSE; 
						count++;
					}
				}
				else
				{
					nSum = max(pU->m_Rect.right, pU1->m_Rect.right) - min(pU->m_Rect.left, pU1->m_Rect.left);
					if((float)nSum > lm3) break;
				}
			}
		}
	}while(count != 0);
	nCharNum = RemoveNoneUseRects(RunRtAry);
	return nCharNum;
}


// ����̩ ����ͻ��ͱ���?�в���.
// �������Ͱ� ������Ͱ���?�൹ �޶��� �в���.
int CLineRecogPrint::Get_LetterSize_Of_Line1(CCharAry& RunRtAry)
{
	int CharSize;
	int i,k,nW,nH,maxSz,minSz;
	int p,h,n,nSum;
	int *Sh;
	
	CInsaeRt* pU;
	CInsaeRtProc runProc;
	int nCharNum = RunRtAry.GetSize();
	m_LineRt = runProc.GetRealRect(RunRtAry);
	CRect LineRt = m_LineRt;
	maxSz = LineRt.Height();
	minSz = maxSz/3;
	
	CharSize = 0;
	Sh = new int[maxSz+1]; 
	memset(Sh, 0, sizeof(int) * (maxSz+1));
	for(i=0; i<nCharNum; i++) 
	{
		pU = RunRtAry.GetAt(i);
		nH = pU->m_Rect.Height();
		nW = pU->m_Rect.Width();
		if((float)nW / (float)nH > g_th_lettersize) h = nH;
		else  h = max(nH, nW);
		if(h <= maxSz && (float)h > minSz) 
			Sh[h]++; 
	}
	//Smoothing(Sv,6,maxv);

		for(p=h=n=0, k=1; k<maxSz; k++) 
		{
			nSum = Sh[k - 1] + Sh[k] + Sh[k + 1];
			if(nSum >= 2|| (nSum==1 && nCharNum<15)) { p = max(p, k); n++; }
			else if(nSum != 0) h = max(h, k);
		}
		CharSize = (n != 0) ? p: h; 
	delete []Sh;
	
	return (CharSize+maxSz)/2;
}
int CLineRecogPrint::RemoveNoneUseRects(CCharAry& RunRtAry)
{
	CInsaeRt* pU;
	int i,nCharNum = RunRtAry.GetSize();
	for(i=0;i<nCharNum;++i){
		pU = RunRtAry.GetAt(i);
		if(pU->bUse == FALSE ){
			delete (CInsaeRt*)RunRtAry.GetAt(i);
			RunRtAry.RemoveAt(i);
			i--; nCharNum--;
		}
	}
	return nCharNum;
}

double CLineRecogPrint::GetConfofChar(BYTE* pImg,int w,int h,int CharSize,WORD &wCode,int &idx,int &font)
{
	
	int nCharType = GetCharType(w,h,CharSize);
	HUBO Hubo;
    isRecogChar(m_Mode,pImg,w,h,CharSize,(void*)&Hubo,1); 
    
	wCode = Hubo.Code[0];
	double dis=Hubo.Dis[0];
	if(nCharType == DOT_TYPE && (Hubo.Code[0] == chCOMMA || Hubo.Code[0] == chDOT))
	{
		dis = min((double)g_th_char_symbol,dis);
	}
	if(wCode == SMB_INFINITE && (w < h * 1.5 || h > CharSize *2 / 3))
	{
		dis = max(dis, (double)g_th_char_symbol * 2);
	}
	if((Hubo.Code[0] == chCLOSEBRACKET 
		//|| Hubo.Index[0] == CLOSEBRACKETIDX2
		|| Hubo.Code[0] == chCLOSEBRACKET3) && h < w * 2)
	{
		dis = max(dis, (double)g_th_char_symbol * 2);
	}
	idx = Hubo.Index[0];
	font = Hubo.Font[0];
	return dis;
}



int CLineRecogPrint::GetCharType(int w,int h,int CharSize)///////
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
		if(fh>fw*3)
			nCharType = I_TYPE;
	}
	else if(fh>fw*3)//I Type
		nCharType = I_TYPE;
	else if(fw>fh*2.5)// - Type
		nCharType = UNDER_LINE_TYPE;
	else	// Char Type 
		nCharType = RECT_TYPE;
	
	return nCharType;
}
/*
#include "../../RnOCRApp/SampleManager.h"
CSampleManager samManager;
void CLineRecogPrint::outSample2Data(CCharAry &RunAry)
{
	BYTE* pImg;
	int wd;
	int hi;
	HUBO* pHubo;
	int nCharNum = RunAry.GetSize();
	int nId;
	WORD nCode;
	int nFont;
	CCharRt* pU;
	CInsaeRtProc runProc;
	for(int i = 0;i < nCharNum; i ++)
	{
		pU = RunAry[i];
		pHubo = &pU->Hubo;
		pImg = runProc.GetImgFromRunRt(pU,wd,hi);
		if(pImg == NULL)
			continue;
		nId = pHubo->Index[0];
		nCode = pHubo->Code[0];
		nFont = pHubo->Font[0];
		CString s,szSamFileName(theApp.m_szAppPath);
		szSamFileName+=_T("\\");
		s.Format(_T("%d.smp"),nId);
		szSamFileName += s;
		samManager.WriteSample(szSamFileName,pImg,CSize(wd,hi),nCode,0,theWorkSpace.GetCurrentPage()->GetInputFileName());
		delete []pImg;
	}
}*/

int GetMaxValue(int *dif,int n,int& AryNo)
{
	AryNo=0;
	if(n<1) return 0; 
	if(n==1) return dif[0];
	int max=dif[0];
	int i,k=0;
	for(i=1;i<n;++i){
		if(dif[i]>max){max=dif[i];k=i;}
	}
	AryNo=k;
	return max;
}
int GetMinValue(int *dif,int n,int& AryNo)
{
	AryNo=0;
	if(n<1) return 0; 
	if(n==1) return dif[0];
	int min=dif[0];
	int i,k=0;
	for(i=1;i<n;++i){
		if(dif[i]<min){min=dif[i];k=i;}
	}
	AryNo=k;
	return min;
}
double  GetMaxValue(double *dif,int n,int& AryNo)
{
	AryNo=0;
	if(n<1) return 0; 
	if(n==1) return dif[0];
	double max=dif[0];
	int i,k=0;
	for(i=1;i<n;++i){
		if(dif[i]>max){max=dif[i];k=i;}
	}
	AryNo=k;
	return max;

}
float  GetMinValue(float *dif,int n,int& AryNo)
{
	AryNo=0;
	if(n<1) return 0; 
	if(n==1) return dif[0];
	float min=dif[0];
	int i,k=0;
	for(i=1;i<n;++i){
		if(dif[i]<min){min=dif[i];k=i;}
	}
	AryNo=k;
	return min;
}
double GetMinValue(double *dif,int n,int& AryNo)
{
	AryNo=0;
	if(n<1) return 0; 
	if(n==1) return dif[0];
	double min=dif[0];
	int i,k=0;
	for(i=1;i<n;++i){
		if(dif[i]<min){min=dif[i];k=i;}
	}
	AryNo=k;
	return min;
}
void GetStatisticValue(double *buf,int n,
					   double& Min,double& Max,double& Ave,double& Dev)
{
	if(n <=0) return;
	if(n==1){
		Ave = buf[0];Min = buf[0];Max = buf[0];Dev = 0; return;
	}
	int i,AryNo;
	double d =0,dd=0;
	Max = GetMaxValue(buf,n,AryNo);
	Min = GetMinValue(buf,n,AryNo);
	for(i=0;i<n;++i) d += buf[i];
	for(i=0;i<n;++i) dd += buf[i]*buf[i];
	Ave = d / n;
	double b = (n*dd-d*d)/(n*(n-1));
	Dev = sqrt(b);
}
void GetStatisticValue(int *buf,int n,
					   int& Min,int& Max,double& Ave,double& Dev)
{
	if(n <=0) return;
	if(n==1){
		Ave = buf[0];Min = buf[0];Max = buf[0];Dev = 0; return;
	}
	int i,AryNo;
	int d =0,dd=0;
	Max = GetMaxValue(buf,n,AryNo);
	Min = GetMinValue(buf,n,AryNo);
	for(i=0;i<n;++i) d += buf[i];
	for(i=0;i<n;++i) dd += buf[i]*buf[i];
	Ave = (double)d / n;
	double b = (double)(n*dd-d*d)/(n*(n-1));
	Dev = sqrt(b);
}


#define NodeNum  50
#define MaxDataNum  10

typedef struct tagSegData //  PLOVE Diction
{	
	int		stid[NodeNum];   // average value
	int		edid[NodeNum];   // average value
	CRect	rt[NodeNum];
	WORD	code[NodeNum];
	float	removescore; 
	float	rtscore; 
	float	recogDis; 
	float	score; 
}SegData;
typedef struct tagPathData //  PLOVE Diction
{	
	SegData	sgdata[NodeNum][MaxDataNum];   // average value
	int sgdataNum[NodeNum];
}PathData;

#define CalcScore(r1,r2,r3) (r1 + r2*10.0f + r3*7.0f)
inline float CLineRecogPrint::GetRectScore(CRect* rts,int nNum)
{
	if(nNum<2) return 0;
	int* hh = new int[nNum];
	memset(hh,0,sizeof(int)*nNum);
	CRect rt;int i;
	for(i=0;i<nNum;i++){
		rt = rts[i];
		hh[i] = rt.Height();
		//if(i==4 || i==7)hh[i]=hh[i]*1.3;

	}
	int minH,maxH,minGap,maxGap;
	double aveH,devH,aveGap,devGap;
	GetStatisticValue(hh,nNum,minH,maxH,aveH,devH);
	if(m_Mode==MODE_PASSPORT_ENGNAME){ 
		float score = (float)(devH/aveH)*3;
		delete[] hh;
		return score;
	}
	int* gap = new int[nNum];
	memset(gap,0,sizeof(int)*nNum);
	for(i=0;i<nNum-1;i++){
		//gap[i] = rts[i+1].left - rts[i].left;
		gap[i] = rts[i+1].CenterPoint().x - rts[i].CenterPoint().x;
	}
	if(nNum<3)devGap=0;
	else GetStatisticValue(gap,nNum-1,minGap,maxGap,aveGap,devGap);
	float score = (float)((devGap/(aveH) + devH/aveH)*2);
	delete[] hh;
	delete[] gap;
	return score;
}

BOOL CLineRecogPrint::DynamicSegment_ByCCH(CCharAry& RunRtAry)
{
	TCHAR str[50][50];
	int i,j,k,m,n,nn,kk;
	int PaThLen = 44;
	if(m_Mode == MODE_TD1_LINE1)
	{
		PaThLen = 30;
		lstrcpy(str[0],_T("D"));
		lstrcpy(str[1], AN_PZ_19_BIG);
		lstrcpy(str[2], AZ_BIG);
		lstrcpy(str[3], AZ_BIG);
		lstrcpy(str[4], AZ_BIG);
		lstrcpy(str[5], AN_PZ_09_BIG);
		lstrcpy(str[6], NUM_09_BIG);
		lstrcpy(str[7], NUM_09);
		lstrcpy(str[8], AZ_BIG);
		lstrcpy(str[9], NUM_09_BIG);

	}
	if(m_Mode == MODE_TD2_44_LINE1)
	{
		PaThLen = 44;
		lstrcpy(str[0],_T("PV"));
		lstrcpy(str[1], AZ_19_BIG);
		lstrcpy(str[2], AZ_BIG);
		lstrcpy(str[3], AZ_BIG);
		lstrcpy(str[4], AZ_BIG);
		lstrcpy(str[5], AZ_BIG);

	}
	else if(m_Mode == MODE_TD2_36_LINE1)
	{
		PaThLen = 36;
		lstrcpy(str[0],_T("PVICE"));
		lstrcpy(str[1], AZ_19_BIG);
		lstrcpy(str[2], AZ_BIG);
		lstrcpy(str[3], AZ_BIG);
		lstrcpy(str[4], AZ_BIG);
		lstrcpy(str[5], AZ_BIG);

	}
	else if(m_Mode == MODE_TD3_LINE1)
	{
		PaThLen = 30;
		lstrcpy(str[0],_T("ICE"));
		lstrcpy(str[1], AN_PZ_19_BIG);
		lstrcpy(str[2], AZ_BIG);
		lstrcpy(str[3], AZ_BIG);
		lstrcpy(str[4], AZ_BIG);
		lstrcpy(str[5], AN_PZ_09);
		lstrcpy(str[6], AN_PZ_09);
		lstrcpy(str[7], AN_PZ_09_BIG);
	}
	else if(m_Mode == MODE_TD3_LINE2)
	{
		PaThLen = 30;
		lstrcpy(str[0], NUM_09);
		lstrcpy(str[1], NUM_09_BIG);
		lstrcpy(str[7],_T("FM<"));
		lstrcpy(str[15], AZ_BIG);
		lstrcpy(str[16], AZ_BIG);
		lstrcpy(str[17], AZ_BIG);
	}
	else if(m_Mode == MODE_TD3_LINE3)
	{
		PaThLen = 30;
		lstrcpy(str[0], AZ);
		lstrcpy(str[1], AZ_BIG);
	}
	else if(m_Mode == MODE_TD2_LINE2)
	{
		PaThLen = 44;
		lstrcpy(str[0], AZ_09);
		lstrcpy(str[1], AN_PZ_09);
		//lstrcpy(str[2],NUM_09_BIG); //real card
		lstrcpy(str[2], _T("BGY0123456789<"));//byJJH20190814 - fake card inculded
		lstrcpy(str[3], AN_PZ_09_BIG);
		lstrcpy(str[6], NUM_09_BIG);
		//lstrcpy(str[10],AZ_BIG); //real card
		//lstrcpy(str[11],AZ_BIG); //real card
		//lstrcpy(str[12],AZ_BIG); //real card
		lstrcpy(str[10], AZ_BIG_09); //number can be possible if fake card
		lstrcpy(str[11], AZ_BIG_09); //number can be possible if fake card
		lstrcpy(str[12], AZ_BIG_09); //number can be possible if fake card
		lstrcpy(str[20], _T("FM<"));
	}
	else if(m_Mode == MODE_FRA2_LINE2)
	{
		PaThLen = 36;
		lstrcpy(str[0], NUM_09_BIG);
		lstrcpy(str[1], AN_PZ_09);
		lstrcpy(str[13], AZ_BIG);
		lstrcpy(str[34], _T("FM<"));
	}
	else if(m_Mode == MODE_FRA2_LINE1)
	{
		PaThLen = 36;
		lstrcpy(str[0], _T("I"));
		lstrcpy(str[1], AN_PZ_19_BIG);
		lstrcpy(str[2], AZ_BIG);
		lstrcpy(str[3], AZ_BIG);
		lstrcpy(str[4], AZ_BIG);
		lstrcpy(str[5], AZ_BIG);
		lstrcpy(str[30], AZ_09_BIG);
		lstrcpy(str[33], _T("<0123456789"));
	}
	else if(m_Mode == MODE_PASSPORT_ENGNAME)//||m_Mode==4)
	{
		return FALSE;
	}
	else if (m_Mode == MODE_ANY_LINE)
	{
		PaThLen = 5;
	}

	//byLotus20200721, add m_Mode != MODE_TD3_LINE2
	if (m_bUnkownCard && m_Mode != MODE_TD2_LINE2 && m_Mode != MODE_TD3_LINE2)
	{
		if (m_Mode == MODE_ANY_LINE) {
			for (i = 0; i < 50; i++)
				lstrcpy(str[i], AZ_09_LINE);
		}
		else {
			for (i = 0; i < 50; i++)
				lstrcpy(str[i], AZ_09_BIG);
		}
	}

	int minPathLen = PaThLen;
	if(m_Mode == MODE_TD2_LINE2)
		minPathLen = 36;

	int nCharNum;
	nCharNum = RunRtAry.GetSize();
    if(nCharNum > 60) nCharNum = 60;
	if(nCharNum == 0 || minPathLen > nCharNum)
	{
		//{{{
		if (m_Mode == MODE_TD2_44_LINE1 && minPathLen - nCharNum < 3) //2 chars allowed
		{
			PaThLen = nCharNum;
			minPathLen = PaThLen;
		}
		//CInsaeRtProc::RemoveAllRunRt(RunRtAry);
		else//}}} --- byJJH20190613
			return FALSE;
	}

	if (m_Mode == MODE_ANY_LINE) {
		PaThLen = nCharNum;
		minPathLen = PaThLen;
	}

	BYTE *pImg = NULL;
	CInsaeRtProc cRunProc;
	int ww, hh;
	int nCurChar = 0, nEndChar = nCharNum+1;
	float recogdis, score, rtscore, removescore, maxscore;

	PathData* pointData = new PathData[nCharNum+1];
	memset(pointData,0,sizeof(PathData)*(nCharNum+1));

	int firstTH = nCharNum - PaThLen;
	firstTH = max(0, firstTH);

	SegData Segtemp;
	SegData* pSegData,*pMySegData;
	int nCharType;
	CInsaeRt* pTemp = NULL;
	for(i = 1; i < nEndChar; i++)
	{
		pTemp = new CInsaeRt();
		for(j = i-1; j >= 0; j--)
		{
			pTemp->Append(RunRtAry[j]);
			if(m_Mode<MODE_PASSPORT_ENGNAME && j!=i-1 &&( pTemp->m_Rect.Width()>m_CharSize*1.1f || (pTemp->m_Rect.Height()>m_CharSize*1.2 && pTemp->m_Rect.Width()/float(pTemp->m_Rect.Height())>1.2f))) break;
			if(m_Mode==MODE_PASSPORT_ENGNAME && j!=i-1 &&( pTemp->m_Rect.Width()>m_CharSize*1.5f || (pTemp->m_Rect.Height()>m_CharSize*1.2 && pTemp->m_Rect.Width()/float(pTemp->m_Rect.Height())>1.5f))) break;
			
			if(m_bGrayMode == false)
				pImg = cRunProc.GetImgFromRunRt(pTemp, ww, hh);
			else
			{
				pImg = CImageBase::CropImg(m_pGrayImg, m_w, m_h, pTemp->m_Rect);
				ww = pTemp->m_Rect.Width();hh = pTemp->m_Rect.Height();
			}
			nCharType = GetCharType(ww, hh, m_CharSize);
			pTemp->nRecogType = nCharType;
			if(nCharType == DOT_TYPE || nCharType == UNDER_LINE_TYPE){
				delete[] pImg; pImg = NULL;
				continue;
			}
			isRecogChar(m_Mode, pImg, ww, hh, m_CharSize, (void*)&pTemp->Hubo, 1);
			delete[] pImg; pImg = NULL;
			///////////// first register ////////////////////////////////
			if(nEndChar-i>=minPathLen && i<5 && CandModify(&pTemp->Hubo,str[0])!=-1){ 
				//CandModify(&pTemp->Hubo,str[0]);
				int sgNum = pointData[i].sgdataNum[0];
				recogdis = (float)pTemp->Hubo.Dis[pTemp->Hubo.nRHuboId];
				if(recogdis<0)recogdis=0;
				recogdis = sqrtf(recogdis);
				rtscore = 0;removescore=0;
				for(m = j-1; m >= 0; m --) {
					int th = m_CharSize;
					if(m_Mode>=MODE_PASSPORT_ENGNAME) th = m_CharSize;
					if(RunRtAry[j]->m_Rect.left - RunRtAry[m]->m_Rect.right < th)
						removescore += (float)RunRtAry[m]->m_Rect.Height()/m_CharSize;
				}
				score = CalcScore(recogdis,rtscore,removescore);
				memset(&Segtemp,0,sizeof(SegData));
				Segtemp.stid[0] = j;
				Segtemp.edid[0] = i;
				Segtemp.rt[0] = pTemp->m_Rect;
				Segtemp.code[0] = pTemp->Hubo.Code[pTemp->Hubo.nRHuboId];
				Segtemp.recogDis = recogdis;
				Segtemp.rtscore = 0;
				Segtemp.removescore = removescore;
				Segtemp.score = score;	
				if(sgNum<MaxDataNum)
				{
					pMySegData = &(pointData[i].sgdata[0][sgNum]);
					pointData[i].sgdataNum[0]++;
				}else
				{
					maxscore=pointData[i].sgdata[0][0].score;
					nn=0;
					for (n=1;n<sgNum;n++) 
					{
						if(maxscore<pointData[i].sgdata[0][n].score)
						{
							maxscore=pointData[i].sgdata[0][n].score;
							nn=n;
						}
					}
					if(maxscore<score) continue;
					pMySegData = &(pointData[i].sgdata[0][nn]);
				}
				memcpy(pMySegData,&Segtemp,sizeof(SegData));
			}
			////////////////////////////////////////////////////////
			for(k=j;k>=j-1;k--){
				if(k<0)break;
				removescore=0;
				for(m = j-1; m >= k; m--) removescore += (float)RunRtAry[m]->m_Rect.Height()/m_CharSize;
				for (n=0;n<PaThLen-1;n++) {
					if(n==PaThLen-2 && m_Mode<MODE_PASSPORT_ENGNAME){
						for(m = i; m < nCharNum; m++){
							if(RunRtAry[m]->m_Rect.left - RunRtAry[i-1]->m_Rect.right < m_CharSize)
								removescore += (float)RunRtAry[m]->m_Rect.Height()/m_CharSize;
						}
					}
					if(nEndChar-i<minPathLen-n-1) 
						continue;
					for (m=0;m<pointData[k].sgdataNum[n];m++) {
						pSegData = &(pointData[k].sgdata[n][m]);
						memcpy(&Segtemp,pSegData,sizeof(SegData));
						Segtemp.stid[n+1] = j;
						Segtemp.edid[n+1] = i;
						Segtemp.rt[n+1] = pTemp->m_Rect;
						//////////////////////////////////////
						int FindId =-1;
						if(m_Mode==MODE_TD3_LINE1){
							if(n<=5)
								FindId=CandModify(&pTemp->Hubo,str[n+1]);
							else
								FindId=CandModify(&pTemp->Hubo,str[7]);
						}
						if(m_Mode==MODE_TD3_LINE2){
							if(n==6 || n==14 || n==15 || n==16 )
								FindId=CandModify(&pTemp->Hubo,str[n+1]);
							else if( n<14)
								FindId=CandModify(&pTemp->Hubo,str[0]);
							else 
								FindId=CandModify(&pTemp->Hubo,str[1]);
						}
						if(m_Mode==MODE_TD3_LINE3){
							if(n<1 )
								FindId=CandModify(&pTemp->Hubo,str[0]);
							else 
								FindId=CandModify(&pTemp->Hubo,str[1]);
						}
						if(m_Mode==MODE_TD1_LINE1){
							FindId=CandModify(&pTemp->Hubo,str[5]);

// 							if(n<=4)
// 								FindId=CandModify(&pTemp->Hubo,str[n+1]);
// 							else if(n<=13)
// 								FindId=CandModify(&pTemp->Hubo,str[5]);
// 							else if(n<=19)
// 								FindId=CandModify(&pTemp->Hubo,str[6]);
// 							else if(n<29)
// 								FindId=CandModify(&pTemp->Hubo,str[5]);
// 							else
// 								FindId=CandModify(&pTemp->Hubo,str[6]);
						}
						if( m_Mode==MODE_TD2_36_LINE1 || m_Mode==MODE_TD2_44_LINE1){
							if(n<=4)
								FindId=CandModify(&pTemp->Hubo,str[n+1]);
							else
								FindId=CandModify(&pTemp->Hubo,str[5]);
						}
						if(m_Mode==MODE_TD2_LINE2){
							if(n<8)
								FindId=CandModify(&pTemp->Hubo,str[3]);

                            else if(n>=27)
                                FindId=CandModify(&pTemp->Hubo,str[3]);
                            else
							{
								if(n==9 || n==10 || n==11 || n==19 )
									FindId=CandModify(&pTemp->Hubo,str[n+1]);
								else
									FindId=CandModify(&pTemp->Hubo,str[2]);
							}
						}
						if(m_Mode==MODE_FRA2_LINE2){
							if(n<3)
								FindId=CandModify(&pTemp->Hubo,str[0]);
							else if(n<6)
								FindId=CandModify(&pTemp->Hubo,str[1]);
							else if(n<12)
								FindId=CandModify(&pTemp->Hubo,str[0]);
							else if(n<26)
								FindId=CandModify(&pTemp->Hubo,str[13]);
							else if(n<33)
								FindId=CandModify(&pTemp->Hubo,str[0]);
							else if(n==33)
								FindId=CandModify(&pTemp->Hubo,str[34]);
							else
								FindId=CandModify(&pTemp->Hubo,str[0]);
						}
						if(m_Mode==MODE_FRA2_LINE1){
							if(n<4)
								FindId=CandModify(&pTemp->Hubo,str[n+1]);
							else if(n<29)
								FindId=CandModify(&pTemp->Hubo,str[5]);
							else if(n<32)
								FindId=CandModify(&pTemp->Hubo,str[30]);
							else 
								FindId=CandModify(&pTemp->Hubo,str[33]);
						}
						if(m_Mode>=MODE_PASSPORT_ENGNAME) FindId=CandModify(&pTemp->Hubo,str[n+1]);
						if(FindId==-1)
							continue;
						////////////////////////////////////////
						Segtemp.code[n+1] = pTemp->Hubo.Code[pTemp->Hubo.nRHuboId];
						recogdis = (float)pTemp->Hubo.Dis[pTemp->Hubo.nRHuboId];
						if(recogdis<0)recogdis=0;
						recogdis = sqrtf(recogdis);
						Segtemp.recogDis = (Segtemp.recogDis*(n+1)+ recogdis)/(float)(n+2);
						rtscore = GetRectScore(Segtemp.rt,n+2);
						Segtemp.rtscore = rtscore;
						Segtemp.removescore += removescore;
						Segtemp.score = CalcScore(Segtemp.recogDis,Segtemp.rtscore,Segtemp.removescore);
						int sgNum = pointData[i].sgdataNum[n+1];
						if(sgNum<MaxDataNum)
						{
							pMySegData = &(pointData[i].sgdata[n+1][sgNum]);
							pointData[i].sgdataNum[n+1]++;
						}else
						{
							maxscore=pointData[i].sgdata[n+1][0].score;
							nn=0;
							for (kk=1;kk<sgNum;kk++) 
							{
								if(maxscore<pointData[i].sgdata[n+1][kk].score)
								{
									maxscore=pointData[i].sgdata[n+1][kk].score;
									nn=kk;
								}
							}
							if(maxscore<Segtemp.score) continue;
							pMySegData = &(pointData[i].sgdata[n+1][nn]);
						}
						memcpy(pMySegData,&Segtemp,sizeof(SegData));
					}
				}
			}
			//////////////////////
		}
		delete pTemp;
	}

	BOOL rc = FALSE;
	int e = max(nEndChar-6, PaThLen);
	float minscore = 100000000000000000.0f;
	for(i = nEndChar-1; i >= e; i--)
	{ 	
		int sgNum = pointData[i].sgdataNum[PaThLen-1];
		for (n = 0; n < sgNum; n++)
		{
			pSegData = &(pointData[i].sgdata[PaThLen-1][n]);
			score = pSegData->score;
			if(minscore > score){
				minscore = score;
				memcpy(&Segtemp, pSegData, sizeof(SegData));
				rc = TRUE;
			}
		}
	}
	if(rc==FALSE && m_Mode==MODE_TD2_LINE2)
	{
		PaThLen = 36;
		e = max(nEndChar-3,PaThLen);
		for(i=nEndChar-1;i>=e;i--)
		{ 	
			int sgNum = pointData[i].sgdataNum[PaThLen-1];
			for (n=0;n<sgNum;n++)
			{
				pSegData = &(pointData[i].sgdata[PaThLen-1][n]);
				score = pSegData->score;
                if(pSegData->stid[0]>3)
                {
                    continue;
                }
				if(minscore>score){
					minscore=score;
					memcpy(&Segtemp,pSegData,sizeof(SegData));
					rc=TRUE;
				}
			}
		}
		if(rc==TRUE)
		{
			//if(Segtemp.code[0]=='P') rc=FALSE;
		}
	}
    
	if(m_Mode>=MODE_PASSPORT_ENGNAME && Segtemp.removescore>1 && Segtemp.recogDis>40) rc=FALSE;
	if(m_Mode < MODE_PASSPORT_ENGNAME && Segtemp.rtscore > 0.5 && Segtemp.recogDis > 40) rc = FALSE;
	if(Segtemp.recogDis > 60) rc = FALSE;
	if(rc == TRUE){
		CCharAry RunRtAry1;
		//cRunProc.RemoveAllRunRt(RunRtAry);
		for (n = 0; n < PaThLen; n++)
		{
			pTemp = new CInsaeRt;
			for (i = Segtemp.stid[n]; i < Segtemp.edid[n]; i++)
			{
				pTemp->Append(RunRtAry[i]);
			}
			if(m_Mode >= MODE_PASSPORT_ENGNAME){

				pImg = cRunProc.GetImgFromRunRt(pTemp,ww,hh);
				nCharType = GetCharType(ww,hh,m_CharSize);
				pTemp->nRecogType = nCharType;
				isRecogChar(m_Mode,pImg,ww,hh,m_CharSize,(void*)&pTemp->Hubo,1);
				delete[] pImg; pImg = NULL;
			} else {
				pTemp->Hubo.Code[0] = Segtemp.code[n];
				pTemp->Hubo.Index[0] = 0;
				pTemp->Hubo.nCandNum = 1;
			}
			pTemp->m_Rect = Segtemp.rt[n];
			pTemp->Hubo.Dis[0] = Segtemp.recogDis*Segtemp.recogDis;
			pTemp->Hubo.Dis[1] = Segtemp.recogDis*Segtemp.recogDis;
			//if(n==4 || n==7 || n==10 || n==13)pTemp->Hubo.nSpLn = SPACE_YES;
			pTemp->bUse = TRUE;
			pTemp->nRecogFlag=2;
			pTemp->nRecogType= RECT_TYPE;
			RunRtAry1.Add(pTemp);
		}

		CInsaeRtProc::RemoveAllRunRt(RunRtAry);
		for (i = 0; i < RunRtAry1.GetSize(); i++)
		{
			RunRtAry.Add(RunRtAry1[i]);
		}
		RunRtAry1.RemoveAll();
	}
	else{
		if(m_Mode>=MODE_PASSPORT_ENGNAME)
			CInsaeRtProc::RemoveAllRunRt(RunRtAry);
	}

	delete[] pointData; pointData = NULL;
	return rc;
}
int  CLineRecogPrint::CandModify(HUBO* cand,TCHAR str[])
{
	cand->nRHuboId = 0;
	int i,j;
	int nCandNum = min(5, cand->nCandNum); //5 - byJJH20190313
	int len = (int)lstrlen(str);
	for(i = 0; i < nCandNum; i ++)
	{
		for(j = 0; j < len; j ++)
			if(cand->Code[i] == str[j])
			{
				cand->nRHuboId = i;
				return 1;
			}
	}
	return -1;
}
int	CLineRecogPrint::isRecogChar(int mode,unsigned char *Img,int w,int h,int CharSize,void* pCand,int RecogStep/*=2*/)
{
	if(m_bGrayMode==false)
	{
		m_RecogBottomLine1.RecogCharImg(Img,w,h,ALL_LANGUAGE_CODE,RecogStep);
		memcpy(pCand,&m_RecogBottomLine1.m_Cand,sizeof(CAND));
	}
	else
	{
		m_RecogBottomLine1Gray.RecogCharImg(Img,w,h,ALL_LANGUAGE_CODE,RecogStep);
		memcpy(pCand,&m_RecogBottomLine1Gray.m_Cand,sizeof(CAND));
	}

	return ((CAND*)pCand)->Index[0];
}
