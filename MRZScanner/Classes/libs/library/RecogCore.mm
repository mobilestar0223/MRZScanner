// RecogCore.cpp: implementation of the CRecogCore class.
//
//////////////////////////////////////////////////////////////////////

#include "StdAfx.h"
#include "RecogCore.h"
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
typedef struct tagFGd{
	BYTE	directId;
	float   grad;
}FGd;
CRecogCore::CRecogCore()
{
	//Create Gause Filter
	int i,j;
	float alpa = 1.218754f;
	float d=15;
	float pr2 = (d*d)/(4*alpa);
	
	d=2;
	pr2 = (d*d)/(4*alpa);
	for(i=0;i<5;i++)for(j=0;j<5;j++){
		m_ExpW1[i][j]=(float)((exp( (-1)*(i-2)*(i-2)/(2*pr2) )*exp( (-1)*(j-2)*(j-2)/(2*pr2) ))/(2*3.141592*pr2));
	}
	/////////////////////////////////	
	float thita = PI / 32.0f; 
	for(i=0;i<8;i++){
		m_tan[i]=(float)tan(thita);
		m_itan[i]=(int)(m_tan[i]*10000.0);

		thita += PI / 16.0f;

	}
	m_nFeatureID = FEATURE_GRAD_BIN_200;
	m_nPrnHnd = MODE_PRINT;
	m_nAsianNum = 0;
}

CRecogCore::~CRecogCore()
{

}

void CRecogCore::GetSortingAZOrder(float* buf,int* ord,int SortNum)
{
	int i,j,tm;
	float d;
	for(i=0;i<SortNum;i++)	ord[i]=i;	
	for(i=0;i<SortNum;i++)
	{
		d=buf[ord[i]];
		for (j = i+1; j <SortNum; j++)
		{
			if ( d > buf[ord[j]] )
			{ 
				tm =  ord[j] ;  ord[j] = ord[i] ; ord[i] = tm;    
				d = buf[ord[i]]; 
			} 
		}	
	}
}
void CRecogCore::GetSortingZAOrder(float* buf,int* ord,int SortNum)
{
	int i,j,tm;
	float d;
	for(i=0;i<SortNum;i++)	ord[i]=i;	
	for(i=0;i<SortNum;i++)
	{
		d=buf[ord[i]];
		for (j = i+1; j <SortNum; j++)
		{
			if ( d < buf[ord[j]] )
			{ 
				tm =  ord[j] ;  ord[j] = ord[i] ; ord[i] = tm;    
				d = buf[ord[i]]; 
			} 
		}	
	}
}
void CRecogCore::GetSortingAZ(float *buf,int *ord,int n,int SortNum)
{
	int i,j,m;
	float d;
	if(SortNum > n) SortNum=n;
	for(i=0;i<SortNum;i++)
	{
		for (j = i+1; j <n ; j++){
			if ( buf[i]  > buf[j] )
			{ 	
				d = buf[i];	buf[i] = buf[j]; buf[j] = d;  
				m = ord[i];	ord[i] = ord[j]; ord[j] = m;    
			}
		}
	}
}
int CRecogCore::SearchCode(WORD *buf,int nLen,WORD c)
{
	int i;
	for(i=0;i<nLen;++i){
		if(buf[i]== c) return i;
	}
	return -1;
}

int CRecogCore::GetFeatureImg(BYTE* pImg,int w,int h,int nFeatureID)
{
	BYTE F[GH1][GW1];
	int nFeatureDim;
	if(nFeatureID == FEATURE_GRAD_GRAY_200 )
		nFeatureDim = GetFeatureGradH2Gray(pImg,w,h);
	else if(nFeatureID == FEATURE_GRAD_GRAY_160 )
		nFeatureDim = GetFeatureGradH4Gray(pImg,w,h);
	else if(nFeatureID == FEATURE_GRAD_BIN_200 )
		nFeatureDim = GetFeatureGradH2Bin(pImg,w,h);
	else if(nFeatureID == FEATURE_GRAD_BIN_160 )
		nFeatureDim = GetFeatureGradH4Bin(pImg,w,h);
	else{
		GetOnlyNormalize(pImg,w,h,F);
		NoizeProcess(F);
		nFeatureDim = GetFeatureNormal(F,nFeatureID);
	}
	return nFeatureDim;
}
int CRecogCore::GetFeatureNormal(BYTE F[GH1][GW1],int nFeatureID)
{
	int nFeatureDim;
	if(nFeatureID == FEATURE_GRAD_BIN_200)
		nFeatureDim = GetFeatureGradH2_New(F);
	else if(nFeatureID == FEATURE_GRAD_BIN_392)
		nFeatureDim = GetFeatureGrad3(F);
	else
		nFeatureDim = GetFeaturePloveNormal(F);
	return nFeatureDim;
}
int CRecogCore::GetFeatureGradH2Bin(BYTE* pImg,int w,int h)
{
	int i;
	BYTE F2[GH2+2][GW2+2];
	
	LinearNormalizeH2Bin(pImg,w,h,F2);
	//Contrast_Enhancement((BYTE*)F2,GW4+2,GH4+2);
	if(max(w,h)>20){
		for(i=0;i<1;i++)	MeanFilterH2Gray(F2);
	}
	int nDim = GetGradientBectorH2Gray(F2);
	return nDim;
}
int CRecogCore::GetFeatureGradH2_New(BYTE F[GH1][GW1])
{
	BYTE F1[GH2][GW2];
	memset(F1,0,GH2*GW2);
	int i,j;
	for(i=0;i<GH1;i++)for(j=0;j<GW1;j++){
		if(	F[i][j]==1) F1[i+8][j+8]=255;
	}
	for(i=0;i<2;i++)	MeanFilterH2(F1);
	int nDim = GetGradientBectorH2_New(F1);
	return nDim;
}
void CRecogCore::MeanFilterH2(BYTE F[][GW2])
{
	int i, j;
	int gh2 = GH2 + 2;
	int gw2 = GW2 + 2;
	BYTE FS[GH2 + 2][GW2 + 2];
	int Buff=0;
	//for(i=0;i<GH2+2;i++)for(j=0;j<GW2+2;j++) FS[i][j]=0;
	memset(FS, 0, gh2 * gw2 * sizeof(BYTE));
	for(i=1;i<=GH2;i++)for(j=1;j<=GW2;j++) FS[i][j]=F[i-1][j-1];
	
	for(i=1;i<=GH2;i++)for(j=1;j<=GW2;j++){
		Buff=0;
		Buff=FS[i][j]+FS[i][j+1]+FS[i-1][j+1]+FS[i-1][j]+FS[i-1][j-1]
			+FS[i][j-1]+FS[i+1][j-1]+FS[i+1][j]+FS[i+1][j+1];
		F[i-1][j-1]=Buff/9;
	}
}
int CRecogCore::GetGradientBectorH2_New(BYTE F[][GW2])
{
	int i,j,k,l,m;
	float FS[GH2+2][GW2+2];
	memset(FS,0,sizeof(float)*(GH2+2)*(GW2+2));
	FGd Fg[GH2][GW2];
	int dir=0;
	float Max=0,Ave=0;
	int num=0;
	float x[8];memset(x,0,sizeof(float)*8);
	float* bec = m_Bec;
	memset(bec,0,sizeof(float)*5*5*8);

	Max=F[0][0];
	for (i=0;i<GH2;i++) for (j=0;j<GW2;j++){
		if(F[i][j]==0)continue;
		num++;
		Ave+=(float)F[i][j];
		if(Max<F[i][j]) Max=(float)F[i][j];
	}
	if(num == 0) return GDIM2;
	Ave=Ave/(float)num;
	if(Max-Ave!=0)for(i=1;i<=GH2;i++)for(j=1;j<=GW2;j++) FS[i][j]=((float)F[i-1][j-1]-Ave)/(Max-Ave);
/////////////// 32��?Egradient�����б� //////////
	float GradX=0,GradY=0,Grad,tanVal;
	for (i=1;i<=GH2;i++) for (j=1;j<=GW2;j++){
		GradX=0,GradY=0;
		x[0]=FS[i][j+1];x[1]=FS[i-1][j+1];x[2]=FS[i-1][j];x[3]=FS[i-1][j-1];
	    x[4]=FS[i][j-1];x[5]=FS[i+1][j-1];x[6]=FS[i+1][j];x[7]=FS[i+1][j+1];
		GradX = x[0]+x[1]+x[7]-x[3]-x[4]-x[5];
		GradY = x[1]+x[2]+x[3]-x[5]-x[6]-x[7];
		
		if( GradX==0 && GradY==0 ){ 
			Fg[i-1][j-1].directId=0;Fg[i-1][j-1].grad=0;
			continue;
		}
		if( GradX==0 && GradY>0 ){ 
			Fg[i-1][j-1].directId=8;Fg[i-1][j-1].grad=GradY;
			continue;
		}
		if( GradX==0 && GradY<0 ){ 
			Fg[i-1][j-1].directId=24;Fg[i-1][j-1].grad=-GradY;
			continue;
		}
		if( GradY==0 && GradX>0 ){ 
			Fg[i-1][j-1].directId=0;Fg[i-1][j-1].grad=GradX;
			continue;
		}
		if( GradY==0 && GradX<0 ){ 
			Fg[i-1][j-1].directId=16;Fg[i-1][j-1].grad=-GradX;
			continue;
		}
		Grad = (float)sqrt((GradX*GradX + GradY*GradY));//���˶� ����
		tanVal = (float)(fabs(GradY)/fabs(GradX));//���˶� ����Ӻ�E
		for (k=0;k<8;k++) {
			if(tanVal < m_tan[k]) break;
		}
		if( GradY>0 && GradX>0 ){ //1������E
			Fg[i-1][j-1].directId=k;Fg[i-1][j-1].grad=Grad;
			continue;
		}
		if( GradY>0 && GradX<0 ){ //2������E
			Fg[i-1][j-1].directId=16-k;Fg[i-1][j-1].grad=Grad;
			continue;
		}
		if( GradY<0 && GradX<0 ){ //3������E
			Fg[i-1][j-1].directId=16+k;Fg[i-1][j-1].grad=Grad;
			continue;
		}
		if( GradY<0 && GradX>0 ){ //4������E
			if(k==0) Fg[i-1][j-1].directId=0;
			else Fg[i-1][j-1].directId=32-k;
			Fg[i-1][j-1].grad=Grad;
			continue;
		}
	}
////////////////////////////////////////////////////
	float Be[9][9][32],Be1[9][9][16],BB[13][13][8];
	memset(Be,0,sizeof(float)*9*9*32);
	memset(Be1,0,sizeof(float)*9*9*16);
	memset(BB,0,sizeof(float)*13*13*8);

	//9*9��̩ ��E���������溷 ������ɰ��?��˾ ���˺��E���ٳ�.
	for (i=0;i<9;i++) for (j=0;j<9;j++){
		for (k=0;k<16;k++) for (l=0;l<16;l++){
				Be[i][j][Fg[i*8+k][j*8+l].directId] += Fg[i*8+k][j*8+l].grad; 
		}
		for (k=2;k<14;k++) for (l=2;l<14;l++){
			Be[i][j][Fg[i*8+k][j*8+l].directId] += Fg[i*8+k][j*8+l].grad; 
		}
		for (k=4;k<12;k++) for (l=4;l<12;l++){
			Be[i][j][Fg[i*8+k][j*8+l].directId] += Fg[i*8+k][j*8+l].grad; 
		}
		for (k=6;k<10;k++) for (l=6;l<10;l++){
			Be[i][j][Fg[i*8+k][j*8+l].directId] += Fg[i*8+k][j*8+l].grad; 
		}
	}
	//��˧�����߶���Ͷ�?���ױ� ̡���� BB?E��˾ �����ٳ�.
	//���� 1 4 6 4 1 filter̮ 1 2 1 filter�� ��˦���� 8����˺��E�����ٳ�.
	for(i=0;i<9;i++) for(j=0;j<9;j++){
		for(k=0;k<14;k++){
			Be1[i][j][k] = Be[i][j][k*2] + Be[i][j][2*k+1]*4 + Be[i][j][2*k+2]*6 + Be[i][j][2*k+3]*4  + Be[i][j][2*k+4];
		}
		Be1[i][j][14] = Be[i][j][28] + Be[i][j][29]*4 + Be[i][j][30]*6 + Be[i][j][31]*4  + Be[i][j][0];
		Be1[i][j][15] = Be[i][j][30] + Be[i][j][31]*4 + Be[i][j][0]*6 + Be[i][j][1]*4  + Be[i][j][2];
	}
	for(i=0;i<9;i++) for(j=0;j<9;j++){
		for(k=0;k<7;k++){
			BB[i+2][j+2][k] = Be1[i][j][k*2] + Be1[i][j][2*k+1]*2 + Be1[i][j][2*k+2];
		}
		BB[i+2][j+2][7] = Be1[i][j][14] + Be1[i][j][15]*2 + Be1[i][j][0];
	}

	//BB?E��˧�����߶���Ͷ�?���ٳ�.
	//������?�ڻ�˼ 2�����?���̼��ر� �������� 
	//9*9�� ���߼� �ڻ�˺��E������E���ߺ㲁E5*5��E����.
	//���� ����Ͱ��Ե��?�ڻ�˼ [2,2]��E����.
	for (i=0;i<5;i++) for (j=0;j<5;j++){//�ڻ�˺��E������E����
		for (k=0;k<5;k++) for (l=0;l<5;l++){//����ͺ�?E
			for (m=0;m<8;m++){//��?E
				bec[(i*5+j)*8+m] += (BB[i*2+k][j*2+l][m]*m_ExpW1[k][l]);
			}
		}
	}
	for (i=0;i<GDIM2;i++)	bec[i]= powf(bec[i],0.4f);
	Max=0.0f;
	for (i=0;i<GDIM2;i++){
		if(Max<bec[i]) Max=bec[i];
	}
	for (i=0;i<GDIM2;i++) bec[i]/=Max;
	return GDIM2;
}
int CRecogCore::GetFeatureGradH2Gray(BYTE* pImg,int w,int h)
{
	int i,nDim;
	BYTE F2[GH2+2][GW2+2];
	
	LinearNormalizeH2Gray(pImg,w,h,F2);
	Contrast_Enhancement((BYTE*)F2,GW2+2,GH2+2);
	for(i=0;i<1;i++)	MeanFilterH2Gray(F2);
	nDim = GetGradientBectorH2Gray(F2);
	return nDim;
}
void CRecogCore::MeanFilterH2Gray(BYTE F[GH2+2][GW2+2])
{
	int i,j;
	BYTE FS[GH2+2][GW2+2];
	int Buff=0;
	memcpy(FS,F,(GH2+2)*(GW2+2));
	for(i=1;i<=GH2;i++)for(j=1;j<=GW2;j++){
		Buff=0;
		Buff=FS[i][j]+FS[i][j+1]+FS[i-1][j+1]+FS[i-1][j]+FS[i-1][j-1]
			+FS[i][j-1]+FS[i+1][j-1]+FS[i+1][j]+FS[i+1][j+1];
		F[i][j]=Buff/9;
	}
}

int CRecogCore::GetGradientBectorH2Gray(BYTE F[GH2+2][GW2+2])
{
	int i,j,k,l,m;
	int FS[GH2+2][GW2+2];
	memset(FS,0,sizeof(int)*(GH2+2)*(GW2+2));
	BYTE directId[GH2][GW2];
	int GRAD[GH2][GW2];
	int dir=0;
	int Max=0,Ave=0;
	int num=0;
	int x[8];
	Max=F[0][0];
	for (i=0;i<GH2+2;i++) for (j=0;j<GW2+2;j++){
		//if(F[i][j]==0)continue;
		num++;
		Ave+=F[i][j];
		if(Max<F[i][j]) Max=F[i][j];
	}
	if(num==0)num=1;
	Ave=(int)((float)Ave/num+0.5f);
	if(Max-Ave!=0)for(i=0;i<GH2+2;i++)for(j=0;j<GW2+2;j++) FS[i][j]=(((int)F[i][j]-Ave)*256)/(Max-Ave);
/////////////// 32���� gradient�����б� //////////
	int GradX=0,GradY=0,Grad;
	int tanVal;
	int* mtan = m_itan;
	for (i=1;i<=GH2;i++) for (j=1;j<=GW2;j++){
		GradX=0,GradY=0;
		x[0]=FS[i][j+1];x[1]=FS[i-1][j+1];x[2]=FS[i-1][j];x[3]=FS[i-1][j-1];
	    x[4]=FS[i][j-1];x[5]=FS[i+1][j-1];x[6]=FS[i+1][j];x[7]=FS[i+1][j+1];
		GradX = x[0]+x[1]+x[7]-x[3]-x[4]-x[5];
		GradY = x[1]+x[2]+x[3]-x[5]-x[6]-x[7];
		if(GradX==0){
			if(GradY==0){
				directId[i-1][j-1]=0;GRAD[i-1][j-1]=0;
				continue;
			}
			if(GradY>0){ 
				directId[i-1][j-1]=8;GRAD[i-1][j-1]=GradY;
				continue;
			}
			if(GradY<0){ 
				directId[i-1][j-1]=24;GRAD[i-1][j-1]=-GradY;
				continue;
			}
		}
		if(GradY==0){
			if(GradX>0){ 
				directId[i-1][j-1]=0;GRAD[i-1][j-1]=GradX;
				continue;
			}
			if(GradX<0){ 
				directId[i-1][j-1]=16;GRAD[i-1][j-1]=-GradX;
				continue;
			}
		}
		//Grad = (int)(sqrt((float)(GradX*GradX + GradY*GradY))+0.5f);//���˶� ����
		//tanVal = (float)(fabs((float)GradY/(float)GradX));//���˶� ����Ӻ�?
		Grad = (int)(sqrt((float)(GradX*GradX + GradY*GradY))+0.5f);
		tanVal = abs(GradY*10000/GradX);

		for (k=0;k<8;k++)	if(tanVal < mtan[k]) break;
 
		if( GradY>0){
			if( GradX>0 ){ //1������
				directId[i-1][j-1]=k;GRAD[i-1][j-1]=Grad;
				continue;
			}
			if( GradX<0 ){ //2������
				directId[i-1][j-1]=16-k;GRAD[i-1][j-1]=Grad;
				continue;
			}
		}
		if( GradY<0 ){
			if( GradX<0 ){ //3������
				directId[i-1][j-1]=16+k;GRAD[i-1][j-1]=Grad;
				continue;
			}
			if( GradX>0 ){ //4������
				if(k==0) directId[i-1][j-1]=0;
				else directId[i-1][j-1]=32-k;
				GRAD[i-1][j-1]=Grad;
				continue;
			}
		}
	}
////////////////////////////////////////////////////
	int Be[9][9][32],Be1[9][9][16],BB[13][13][8];
	memset(Be,0,sizeof(int)*9*9*32);
 	memset(Be1,0,sizeof(int)*9*9*16);
 	memset(BB,0,sizeof(int)*13*13*8);

	int* pBe;
	for (i=0;i<9;i++) for (j=0;j<9;j++){
		pBe = Be[i][j];
		for (k=0;k<8;k++) for (l=0;l<8;l++){
			pBe[directId[i*4+k][j*4+l]] += GRAD[i*4+k][j*4+l]; 
		}
		for (k=2;k<6;k++) for (l=2;l<6;l++){
			pBe[directId[i*4+k][j*4+l]] += GRAD[i*4+k][j*4+l]; 
		}

	}
	int* pBe1;
	for(i=0;i<9;i++) for(j=0;j<9;j++){
		pBe1 = Be1[i][j];
		pBe = Be[i][j];
		for(k=0;k<14;k++){
			pBe1[k] = pBe[k*2] + pBe[2*k+1]*4 + pBe[2*k+2]*6 + pBe[2*k+3]*4  + pBe[2*k+4];
		}
		pBe1[14] = pBe[28] + pBe[29]*4 + pBe[30]*6 + pBe[31]*4  + pBe[0];
		pBe1[15] = pBe[30] + pBe[31]*4 + pBe[0]*6 + pBe[1]*4  + pBe[2];
	}
	for(i=0;i<9;i++) for(j=0;j<9;j++){
		pBe = BB[i+2][j+2];
		pBe1 = Be1[i][j];
		for(k=0;k<7;k++){
			pBe[k] = pBe1[k*2] + pBe1[2*k+1]*2 + pBe1[2*k+2];
		}
		pBe[7] = pBe1[14] + pBe1[15]*2 + pBe1[0];
	}

	float* bec = m_Bec;
	memset(bec,0,sizeof(float)*GDIM2);
	int vid=0;
	float fMax=0.0f;
	float (*Expw1)[5] = m_ExpW1; 
	for (i=0;i<5;i++) for (j=0;j<5;j++){
		for (m=0;m<8;m++){
			for (k=0;k<5;k++) for (l=0;l<5;l++){
				bec[vid] += ((float)BB[i*2+k][j*2+l][m]*Expw1[k][l]);
			}
			if(fMax<bec[vid]) fMax=bec[vid];
			vid++;
		}
	}
	if(fMax==0.0f)	return GDIM4;
	for (i=0;i<GDIM2;i++) {
		bec[i]/=fMax;
		bec[i]= powf(bec[i],0.4f);
	}
	return GDIM2;
}

void CRecogCore::LinearNormalizeH2Gray(BYTE* pImg,int w1,int h1,BYTE F[GH2+2][GW2+2])
{
	int i,j,size;
	float i0,j0;
	int w = GW2+2,h = GH2+2;
	float iscale=(float)(w1-1)/(float)(w-1);
	float jscale=(float)(h1-1)/(float)(h-1);
	
	float	offi[GW2+2];
	float	offj[GH2+2];
	int		Wi[GW2+2];
	int		Hj[GH2+2];
	size = (w1 + 2) * (h1 + 2);
	BYTE *pOrgPlusImg = new BYTE[size];
	memset(pOrgPlusImg,255, size);
	for(i=0;i<h1;i++)
	{
		memcpy(pOrgPlusImg+i*(w1+2), pImg+(i)*w1, w1);
	}
	memset(F,0,(GW2+2)*(GH2+2));
	for(i=0;i<GW2+2;i++) {
		i0=iscale*i;//+0.5f;
		Wi[i]=(int)i0;
		offi[i] = (i0-Wi[i]);
	}
	for(i=0;i<GH2+2;i++) {
		j0=jscale*i;//+0.5f;
		Hj[i]=(int)j0;
		offj[i] = (j0-Hj[i]);
	}
	int x ,y;
	float val00,val01,val10,val11;
	int w2 = w1+2;
	for(j=0;j<h;j++){
		y = Hj[j];
		for(i=0;i<w;i++){ 
			x= Wi[i];
			val00 = (float)pOrgPlusImg[y*w2+x];
			val01 = (float)pOrgPlusImg[y*w2+x+1];
			val10 = (float)pOrgPlusImg[(y+1)*w2+x];
			val11 = (float)pOrgPlusImg[(y+1)*w2+x+1];
			
			int newval = (int)(floor(((val00 * (1-offj[j]) *  (1-offi[i]) +
				val01 * (1-offj[j]) *   offi[i]    +
				val10 *  offj[j]    *  (1-offi[i]) +
				val11 *  offj[j]    *   offi[i]  ))));
			if(newval >= 255) newval = 255;
			if(newval <= 0) newval = 0;
			F[j][i]=(BYTE)newval;
		}
	}
	delete pOrgPlusImg;
}

void CRecogCore::LinearNormalize(BYTE *OrgImg,int w,int h,BYTE F[GH1][GW1])
{
	int i,j;
	int Bufi[GW1],Bufj[GH1];
	double iscale=(double)(w)/(double)(GW1);
	double jscale=(double)(h)/(double)(GH1);
	for(i=0;i<GW1;i++) 	Bufi[i]=(int)((i+0.5)*iscale);
	for(i=0;i<GH1;i++) 	Bufj[i]=(int)((i+0.5)*jscale);
	for (j = 0; j < GH1; j++) {
		int pos_x = Bufj[j] * w;
		for (i = 0; i < GW1; i++) {
			F[j][i] = OrgImg[pos_x + Bufi[i]];
		}
	}
}
int CRecogCore::GetFeatureGradH4Bin(BYTE* pImg,int w,int h)
{
	int i;
	BYTE F2[GH4+2][GW4+2];
	
	LinearNormalizeH4Bin(pImg,w,h,F2);
	//Contrast_Enhancement((BYTE*)F2,GW4+2,GH4+2);
	if(max(w,h)>20){
		for(i=0;i<1;i++)	MeanFilterH4Gray(F2);
	}
	int nDim = GetGradientBectorH4Gray(F2);
	return nDim;
}

void CRecogCore::LinearNormalizeH2Bin(BYTE* pImg,int w1,int h1,BYTE F[GH2+2][GW2+2])
{

	int i,j;
	float i0,j0;
	int w = GW2,h = GH2;
	float iscale=(float)(w1+2)/(float)(w);
	float jscale=(float)(h1+2)/(float)(h);
	BYTE* pNewImg = new BYTE[(w1+2)*(h1+2)];
	float	offi[GW2];
	float	offj[GH2];
	int		Wi[GW2];
	int		Hj[GH2];
	memset(F,0,(w+2)*(h+2));
	memset(pNewImg,0,(w1+2)*(h1+2));
	for(i=0;i<h1;i++)for(j=0;j<w1;j++){pImg[i*w1+j]==0 ? pNewImg[(i+1)*(w1+2)+j+1]=0 : pNewImg[(i+1)*(w1+2)+j+1] = 255;}
	for(i=0;i<w;i++) {
		i0=iscale*i;//+0.5f;
		Wi[i]=(int)i0;
		offi[i] = (i0-Wi[i]);
	}
	for(i=0;i<h;i++) {
		j0=jscale*i;//+0.5f;
		Hj[i]=(int)j0;
		offj[i] = (j0-Hj[i]);
	}
	int x ,y,xx,yy;
	float val00,val01,val10,val11;
	w1=w1+2;
	h1=h1+2;
	for(j=0;j<h;j++){
		y = Hj[j];
		if(y>=h1-1) yy=y;
		else yy=y+1;
		for(i=0;i<w;i++){ 
			x= Wi[i];
			if(x>=w1-1) xx=x;
			else xx=x+1;
			val00 = (float)pNewImg[y*w1+x];
			val01 = (float)pNewImg[y*w1+xx];
			val10 = (float)pNewImg[yy*w1+x];
			val11 = (float)pNewImg[yy*w1+xx];

			int newval = (int)(floor(((val00 * (1-offj[j]) *  (1-offi[i]) +
				val01 * (1-offj[j]) *   offi[i]    +
				val10 *  offj[j]    *  (1-offi[i]) +
				val11 *  offj[j]    *   offi[i]  ))));
			if(newval >= 255) newval = 255;
			if(newval <= 0) newval = 0;
			F[j+1][i+1]=(BYTE)newval;
		}
	}
	delete[] pNewImg;
}
void CRecogCore::LinearNormalizeH4Bin(BYTE* pImg,int w1,int h1,BYTE F[GH4+2][GW4+2])
{
	int i,j, pos, pos1, size;
	float i0,j0;
	int w = GW4,h = GH4;
	float iscale=(float)(w1+2)/(float)(w);
	float jscale=(float)(h1+2)/(float)(h);

	float	offi[GW4];
	float	offj[GH4];
	int		Wi[GW4];
	int		Hj[GH4];

	size = (w1 + 2) * (h1 + 2);
	BYTE* pNewImg = new BYTE[size];
	memset(pNewImg, 0, size);
	size = (w + 2) * (h + 2);
	memset(F, 0, size);
	
	for(i=0;i<h1;i++)for(j=0;j<w1;j++){pImg[i*w1+j]==0 ? pNewImg[(i+1)*(w1+2)+j+1]=0 : pNewImg[(i+1)*(w1+2)+j+1] = 255;}
	for(i=0;i<w;i++) {
		i0=iscale*i;//+0.5f;
		Wi[i]=(int)i0;
		offi[i] = (i0-Wi[i]);
	}
	for(i=0;i<h;i++) {
		j0=jscale*i;//+0.5f;
		Hj[i]=(int)j0;
		offj[i] = (j0-Hj[i]);
	}
	int x ,y,xx,yy;
	float val00,val01,val10,val11;
	w1=w1+2;
	h1=h1+2;
	for(j=0;j<h;j++){
		y = Hj[j];
		if(y>=h1-1) yy=y;
		else yy=y+1;
		pos = y * w1;
		pos1 = yy * w1;
		for(i=0;i<w;i++){ 
			x= Wi[i];
			if(x>=w1-1) xx=x;
			else xx=x+1;
			val00 = (float)pNewImg[pos +x];
			val01 = (float)pNewImg[pos +xx];
			val10 = (float)pNewImg[pos1 +x];
			val11 = (float)pNewImg[pos1 +xx];

			int newval = (int)(floor(((val00 * (1-offj[j]) *  (1-offi[i]) +
				val01 * (1-offj[j]) *   offi[i]    +
				val10 *  offj[j]    *  (1-offi[i]) +
				val11 *  offj[j]    *   offi[i]  ))));
			if(newval >= 255) newval = 255;
			if(newval <= 0) newval = 0;
			F[j+1][i+1]=(BYTE)newval;
		}
	}
	delete[] pNewImg;
}
int CRecogCore::GetFeatureGradH4Gray(BYTE* pImg,int w,int h)
{
	int i;
	BYTE F2[GH4+2][GW4+2];
	
	LinearNormalizeH4Gray(pImg,w,h,F2);
	//Contrast_Enhancement((BYTE*)F2,GW4+2,GH4+2);
	if(max(w,h)>20){
		for(i=0;i<1;i++)	MeanFilterH4Gray(F2);
	}
	int nDim = GetGradientBectorH4Gray(F2);
	return nDim;
}

void CRecogCore::MeanFilterH4Gray(BYTE F[GH4+2][GW4+2])
{
	int i,j;
	BYTE FS[GH4+2][GW4+2];
	int Buff=0;
	memcpy(FS,F,(GH4+2)*(GW4+2));
	for(i=1;i<=GH4;i++)for(j=1;j<=GW4;j++){
		Buff=0;
		Buff=FS[i][j]+FS[i][j+1]+FS[i-1][j+1]+FS[i-1][j]+FS[i-1][j-1]
			+FS[i][j-1]+FS[i+1][j-1]+FS[i+1][j]+FS[i+1][j+1];
		F[i][j]=Buff/9;
	}
}

int CRecogCore::GetGradientBectorH4Gray(BYTE F[GH4+2][GW4+2])
{
	int i,j,k,l,m;
	int FS[GH4+2][GW4+2];
	memset(FS,0,sizeof(int)*(GH4+2)*(GW4+2));
	BYTE directId[GH4][GW4];
	int GRAD[GH4][GW4];
	int dir=0;
	int Max=0,Ave=0;
	int num=0;
	int x[8];
	Max=F[0][0];
	for (i=0;i<GH4+2;i++) for (j=0;j<GW4+2;j++){
		//if(F[i][j]==0)continue;
		num++;
		Ave+=F[i][j];
		if(Max<F[i][j]) Max=F[i][j];
	}
	if(num==0)num=1;
	Ave=(int)((float)Ave/num+0.5f);
	if(Max-Ave!=0)for(i=0;i<GH4+2;i++)for(j=0;j<GW4+2;j++) FS[i][j]=(((int)F[i][j]-Ave)*256)/(Max-Ave);
	int GradX=0,GradY=0,Grad;
	int tanVal;
	int* mtan = m_itan;
	for (i=1;i<=GH4;i++) for (j=1;j<=GW4;j++){
		GradX=0,GradY=0;
		x[0]=FS[i][j+1];x[1]=FS[i-1][j+1];x[2]=FS[i-1][j];x[3]=FS[i-1][j-1];
	    x[4]=FS[i][j-1];x[5]=FS[i+1][j-1];x[6]=FS[i+1][j];x[7]=FS[i+1][j+1];
		GradX = x[0]+x[1]+x[7]-x[3]-x[4]-x[5];
		GradY = x[1]+x[2]+x[3]-x[5]-x[6]-x[7];
		if(GradX==0){
			if(GradY==0){
				directId[i-1][j-1]=0;GRAD[i-1][j-1]=0;
				continue;
			}
			if(GradY>0){ 
				directId[i-1][j-1]=8;GRAD[i-1][j-1]=GradY;
				continue;
			}
			if(GradY<0){ 
				directId[i-1][j-1]=24;GRAD[i-1][j-1]=-GradY;
				continue;
			}
		}
		if(GradY==0){
			if(GradX>0){ 
				directId[i-1][j-1]=0;GRAD[i-1][j-1]=GradX;
				continue;
			}
			if(GradX<0){ 
				directId[i-1][j-1]=16;GRAD[i-1][j-1]=-GradX;
				continue;
			}
		}
		Grad = (int)(sqrt((float)(GradX*GradX + GradY*GradY))+0.5f);
		tanVal = abs(GradY*10000/GradX);

		for (k=0;k<8;k++)	if(tanVal < mtan[k]) break;
 
		if( GradY>0){
			if( GradX>0 ){
				directId[i-1][j-1]=k;GRAD[i-1][j-1]=Grad;
				continue;
			}
			if( GradX<0 ){ 
				directId[i-1][j-1]=16-k;GRAD[i-1][j-1]=Grad;
				continue;
			}
		}
		if( GradY<0 ){
			if( GradX<0 ){ 
				directId[i-1][j-1]=16+k;GRAD[i-1][j-1]=Grad;
				continue;
			}
			if( GradX>0 ){ 
				if(k==0) directId[i-1][j-1]=0;
				else directId[i-1][j-1]=32-k;
				GRAD[i-1][j-1]=Grad;
				continue;
			}
		}
	}
////////////////////////////////////////////////////
	int Be[9][7][32],Be1[9][7][16],BB[13][11][8];
	memset(Be,0,sizeof(int)*9*7*32);
 	memset(Be1,0,sizeof(int)*9*7*16);
 	memset(BB,0,sizeof(int)*13*11*8);

	int* pBe;
	for (i=0;i<9;i++) for (j=0;j<7;j++){
		pBe = Be[i][j];
		for (k=0;k<8;k++) for (l=0;l<8;l++){
			pBe[directId[i*4+k][j*4+l]] += GRAD[i*4+k][j*4+l]; 
		}
		for (k=2;k<6;k++) for (l=2;l<6;l++){
			pBe[directId[i*4+k][j*4+l]] += GRAD[i*4+k][j*4+l]; 
		}

	}
	int* pBe1;
	for(i=0;i<9;i++) for(j=0;j<7;j++){
		pBe1 = Be1[i][j];
		pBe = Be[i][j];
		for(k=0;k<14;k++){
			pBe1[k] = pBe[k*2] + pBe[2*k+1]*4 + pBe[2*k+2]*6 + pBe[2*k+3]*4  + pBe[2*k+4];
		}
		pBe1[14] = pBe[28] + pBe[29]*4 + pBe[30]*6 + pBe[31]*4  + pBe[0];
		pBe1[15] = pBe[30] + pBe[31]*4 + pBe[0]*6 + pBe[1]*4  + pBe[2];
	}
	for(i=0;i<9;i++) for(j=0;j<7;j++){
		pBe = BB[i+2][j+2];
		pBe1 = Be1[i][j];
		for(k=0;k<7;k++){
			pBe[k] = pBe1[k*2] + pBe1[2*k+1]*2 + pBe1[2*k+2];
		}
		pBe[7] = pBe1[14] + pBe1[15]*2 + pBe1[0];
	}

	float* bec = m_Bec;
	memset(bec,0,sizeof(float)*GDIM2);
	int vid=0;
	float fMax=0.0f;
	float (*Expw1)[5] = m_ExpW1; 
	for (i=0;i<5;i++) for (j=0;j<4;j++){
		for (m=0;m<8;m++){
			for (k=0;k<5;k++) for (l=0;l<5;l++){
				bec[vid] += ((float)BB[i*2+k][j*2+l][m]*Expw1[k][l]);
			}
			if(fMax<bec[vid]) fMax=bec[vid];
			vid++;
		}
	}
	if(fMax==0.0f)	return GDIM4;
	for (i=0;i<GDIM4;i++) {
		bec[i]/=fMax;
		bec[i]= powf(bec[i],0.4f);
	}
	return GDIM4;
}

void CRecogCore::LinearNormalizeH4Gray(BYTE* pImg,int w1,int h1,BYTE F[GH4+2][GW4+2])
{
	int i,j,pos,pos1;
	float i0,j0;
	int w = GW4+2,h = GH4+2;
	float iscale=(float)(w1-1)/(float)(w-1);
	float jscale=(float)(h1-1)/(float)(h-1);
	
	float	offi[GW4+2];
	float	offj[GH4+2];
	int		Wi[GW4+2];
	int		Hj[GH4+2];
	memset(F,0,(GW4+2)*(GH4+2));
	for(i=0;i<GW4+2;i++) {
		i0=iscale*i;//+0.5f;
		Wi[i]=(int)i0;
		offi[i] = (i0-Wi[i]);
	}
	for(i=0;i<GH4+2;i++) {
		j0=jscale*i;//+0.5f;
		Hj[i]=(int)j0;
		offj[i] = (j0-Hj[i]);
	}
	int x ,y,xx,yy;
	float val00,val01,val10,val11;
	for(j=0;j<h;j++){
		y = Hj[j];
		if(y>=h1-1) yy=y;
		else yy=y+1;
		pos = y * w1;
		pos1 = yy * w1;
		for(i=0;i<w;i++){ 
			x= Wi[i];
			if(x>=w1-1) xx=x;
			else xx=x+1;
			val00 = (float)pImg[pos +x];
			val01 = (float)pImg[pos +xx];
			val10 = (float)pImg[pos1 +x];
			val11 = (float)pImg[pos1 +xx];
			
			int newval = (int)(floor(((val00 * (1-offj[j]) *  (1-offi[i]) +
				val01 * (1-offj[j]) *   offi[i]    +
				val10 *  offj[j]    *  (1-offi[i]) +
				val11 *  offj[j]    *   offi[i]  ))));
			if(newval >= 255) newval = 255;
			if(newval <= 0) newval = 0;
			F[j][i]=(BYTE)newval;
		}
	}
}

BOOL CRecogCore::Contrast_Enhancement(BYTE* Img,int w,int h)
{
	CRect subRt = CRect(0,0,w,h);
	return Contrast_EnhancementInSubRt(Img,w,h,subRt);
}
BOOL CRecogCore::Contrast_EnhancementInSubRt(BYTE* Img,int w,int h,CRect subRt,BOOL bAllArea/*=TRUE*/)
{	
	int ki[8]={-1,-1,0,1,1,1,0,-1};
	int kj[8]={0,1,1,1,0,-1,-1,-1};
	int x0,x1,y0,y1;
	int i,j,k=0,c,tmin=0,tmax=0,med;
	int n[256];
	GetHistogram(Img,w,h,subRt,n,tmin,tmax);
	if((tmax-tmin)<=0) return FALSE;
	
	k=0;j=0;
	for(i=tmin;i<=tmax;i++) { k+=(n[i]*i);j+=n[i];}
	med=k/j;//Average Brightness

	if(bAllArea == TRUE)	{ x0 = 0; y0 = 0; x1 = w; y1 = h; }
	else					{ x0 = subRt.left,x1=subRt.right,y0=subRt.top,y1=subRt.bottom;
	}

	//Brightness Correction
	med=128-med;
	for(i=y0;i<y1;i++)for(j=x0;j<x1;j++)
	{
		k=Img[i*w+j]+med;
		if(k<0) k=0;
		if(k>255) k=255;
		Img[i*w+j]=(BYTE)k;
	}
	tmin=tmin+med;
	if(tmin<0) tmin=0;if(tmin>255) tmin=255;
	tmax=tmax+med;
	if(tmax<0) tmax=0;if(tmax>255) tmax=255;
	if( tmax-tmin <= 5) return FALSE;

	//Contrast Enhancement
	for(i=y0;i<y1;i++)for(j=x0;j<x1;j++)
	{
		k=Img[i*w+j];
		c=(255*(k-tmin))/(tmax-tmin);
		if(c<0) c=0;
		if(c>255)c=255;
		Img[i*w+j]=(BYTE)c;
	}
	return TRUE;
}
void CRecogCore::GetHistogram(BYTE *pImg, int w, int h, CRect subRt,int Hist[256],int& tmin,int& tmax)
{
	int x0=subRt.left,x1=subRt.right,y0=subRt.top,y1=subRt.bottom;
	int	wid = x1-x0,high = y1-y0 ;
	int i,j,k=0;
	int Th = wid;//*2;
	
	memset(Hist,0,sizeof(int)*256);
	for(i=y0;i<y1;i++)for(j=x0;j<x1;j++) Hist[pImg[i*w+j]]++;
	k = 0;
	for(i=0;i<256;i++){
		k+=Hist[i];
		if(k>(Th)) {tmin=i;break;}// min gray level 
	}
	k = 0;
	for(i=255;i>=0;i--){
		k+=Hist[i];
		if(k>(Th)) {tmax=i;break;}// max gray level
	}
}


void CRecogCore::NoizeProcess(BYTE F64[GH1][GW1])
{
	int i,j;
	BYTE B[GH1+2][GW1+2];
	memset(B,0,(GH1+2)*(GW1+2));
	for(i=0;i<GH1;i++) for(j=0;j<GW1;j++) B[i+1][j+1]=F64[i][j];
	for(i=1;i<GH1+1;i++) for(j=1;j<GW1+1;j++)
		if(B[i][j]==0)
			if((B[i-1][j-1]+B[i-1][j]+B[i-1][j+1]+B[i][j-1]+B[i][j+1]==5)
				||(B[i+1][j-1]+B[i+1][j]+B[i+1][j+1]+B[i][j-1]+B[i][j+1]==5)
				||(B[i-1][j-1]+B[i][j-1]+B[i+1][j-1]+B[i-1][j]+B[i+1][j]==5)
				||(B[i-1][j+1]+B[i][j+1]+B[i+1][j+1]+B[i-1][j]+B[i+1][j]==5))
				F64[i-1][j-1]=1;  
			for(i=0;i<GH1;i++) for(j=0;j<GW1;j++) B[i+1][j+1]=F64[i][j];
			for(i=1;i<GH1+1;i++) for(j=1;j<GW1+1;j++)
				if(B[i][j]==1)
					if((B[i-1][j-1]+B[i-1][j]+B[i-1][j+1]+B[i][j-1]+B[i][j+1]==0)
						||(B[i+1][j-1]+B[i+1][j]+B[i+1][j+1]+B[i][j-1]+B[i][j+1]==0)
						||(B[i-1][j-1]+B[i][j-1]+B[i+1][j-1]+B[i-1][j]+B[i+1][j]==0)
						||(B[i-1][j+1]+B[i][j+1]+B[i+1][j+1]+B[i-1][j]+B[i+1][j]==0))
						F64[i-1][j-1]=0;  
}


int CRecogCore::GetFeaturePloveNormal(BYTE F[GH1][GW1])
{
	BYTE F64[GH1][GW1];
	FDirect FD[GH1][GW1];
	BYTE F_COL[GH1][GW1],F_ROW[GH1][GW1],F_DIGR[GH1][GW1],F_DIGN[GH1][GW1];
	memcpy(F64,F,GH1*GW1);
	bound_point(F64,F_COL,F_ROW,F_DIGR,F_DIGN);
	bound_tracking64(F64,FD);
	int nDim = P_LOVE_feature(FD,m_Bec,F_COL,F_ROW,F_DIGR,F_DIGN);
	return nDim;
}
void CRecogCore::bound_point(BYTE F[GH1][GW1],BYTE F_COL[GH1][GW1]
							 ,BYTE F_ROW[GH1][GW1],BYTE F_DIGR[GH1][GW1],BYTE F_DIGN[GH1][GW1])
{
	int i,j;
	BYTE FS[GH1+2][GW1+2];
	//Median_Filter(F);
	// initialization
	for(i=0;i<GW1;i++)for(j=0;j<GH1;j++)
		F_COL[j][i]=F_ROW[j][i]=F_DIGR[j][i]=F_DIGN[j][i]=0;
	for(i=0;i<GW1+2;i++)for(j=0;j<GH1+2;j++) FS[j][i]=0;
	for(i=1;i<=GW1;i++)for(j=1;j<=GH1;j++) FS[j][i]=F[j-1][i-1];
	
	// boundary points in 8-directin 
	for(i=1;i<=GW1;i++){
		for(j=1;j<=GH1;j++){
			//1.Horizontal direction scanning
			if((FS[j][i]-FS[j][i-1])==1) 
				F_COL[j-1][i-1]++;//LEFT->RIGHT
			if((FS[j][i]-FS[j][i+1])==1) 
				F_COL[j-1][i-1]++;//RIGHT->LEFT
			//2.Vertical direction  scanning
			
			if((FS[j][i]-FS[j-1][i])==1) 
				F_ROW[j-1][i-1]++;//UP->DOWN
			if((FS[j][i]-FS[j+1][i])==1) 
				F_ROW[j-1][i-1]++;//DOWN->UP
			//3.Right  diagonal direction scanning
			if((FS[j][i]-FS[j-1][i-1])==1) F_DIGR[j-1][i-1]++;//RIGHT DIRECTION
			if((FS[j][i]-FS[j+1][i+1])==1) F_DIGR[j-1][i-1]++;//INVERSE DIRECTION
			//4.Negative   diagonal direction scanning
			if((FS[j][i]-FS[j-1][i+1])==1) F_DIGN[j-1][i-1]++;//RIGHT DIRECTION
			if((FS[j][i]-FS[j+1][i-1])==1) F_DIGN[j-1][i-1]++;//INVERSE DIRECTION
		}
	}
	
}
void CRecogCore::bound_tracking64(BYTE F[GH1][GW1],FDirect FD[GH1][GW1])

{
	int i,j,width,height;
	int kki[8]={-1,0,1,0};
	int kkj[8]={0,1,0,-1};
	int k0,l0,k,l,i0,j0,i1,j1,k2,l2,i2,j2;
	int ki[15]={-1,-1,0,1,1,1,0,-1,-1,-1,0,1,1,1,0};
	int kj[15]={0,1,1,1,0,-1,-1,-1,0,1,1,1,0,-1,-1};
	
	width=GW1+2;height=GH1+2;
	
	BYTE FS[GH1+2][GW1+2];
	FDirect FDD[GH1+2][GW1+2];
	
	for(i=0;i<GH1+2;++i)for(j=0;j<GW1+2;++j)for(k=0;k<4;k++)
		FDD[i][j].direc[k]=0;
	
	for(i=0;i<height;i++) FS[i][0]=FS[i][width-1]=0;
	for(j=0;j<width;j++)FS[0][j]=FS[height-1][j]=0;
	for(i=1;i<height-1;i++)for(j=1;j<width-1;j++) 
		FS[i][j]=F[i-1][j-1];
	
	
	// tracking	of boundary	including extraction of 
	//			directional information( considering width=1)
	
	
	for(j=1;j<=GH1;j++)
		for(i=1;i<=GW1;i++)
		{
			if((FS[j][i]==1)&&(FS[j][i-1]==0))
			{
				/* boundary detection */
				k0=i; l0=j; /* first point address */
				for(k=0;k<8;k++){
					i1=i+ki[k];j1=j+kj[k];
					if(FS[j1][i1]==1) {		/* from left of first point */
						k2=i1;l2=j1;
						break;
					} /* second point address */
				}
				if(k<8) // no isolated point
				{	
					FS[j][i]=FS[j1][i1]=2;
					//FDD[j][i].direc[FDD[j][i].n]=k;FDD[j][i].n++;
					//	FDD[j1][i1].direc[FDD[j1][i1].n]=k+4;FDD[j1][i1].n++;
					do {
						k+=5;k%=8;   
						for(l=k;l<(k+8);l++){
							i2=i1+ki[l];j2=j1+kj[l];
							if(FS[j2][i2]>0){
								FS[j2][i2]=2;
								
								FDD[j1][i1].direc[(l%8)%4]++;
								FDD[j2][i2].direc[(l%8)%4]++;
								i0=i1;j0=j1;i1 = i2 ; j1 = j2 ;
								k = l;
								break;
							}
						}
					} while(( i0!=k0)||(j0!=l0)||(i2!=k2)||(j2!=l2));
				}
			}
		}	
		
		for(i=1;i<=GW1;i++)for(j=1;j<=GH1;j++){
			//for(k=0;k<4;++k){
			//	if(FDD[j][i].direc[k] == 4)	FDD[j][i].direc[k] = 2;
			//}
			FD[j-1][i-1]=FDD[j][i];
			if(FS[j][i]==2)	F[j-1][i-1]=1;
			else F[j-1][i-1]=0;
		}
}
int CRecogCore::P_LOVE_feature(FDirect FD[GH1][GW1],float *buff,
								 BYTE F_COL[GH1][GW1],BYTE F_ROW[GH1][GW1],
								 BYTE F_DIGR[GH1][GW1],BYTE F_DIGN[GH1][GW1])
{
	// directional element feature of hierchical surface contour
	int i,j,i1,j1,k,h,p,q,t,s,m,n,d,r,c,depth,mask,num,u;
	float h1,s1,n1,p1;

	depth=3;// boundary depth to search
	mask=1;// Window size=(mask+2)^2
	num=8; // field number
	for(i=0;i<PDIM;i++) buff[i]=0;// initialization
	
	FDirect FDD[GH1+2][GW1+2];

	for(i=0;i<GH1+2;++i)for(k=0;k<4;k++)
		FDD[i][0].direc[k]=FDD[i][GW1+1].direc[k]=0;	
	for(i=0;i<GW1+2;++i)for(k=0;k<4;k++)
		FDD[0][i].direc[k]=FDD[GH1+1][i].direc[k]=0;
	
	for(i=1;i<=GH1;++i)for(j=1;j<=GW1;++j)
		FDD[i][j]=FD[i-1][j-1];	
	d=0;k=0;
	do{
		//1. vertical direction searching  
		for(m=0;m<num;m++)
		{
			h1=p1=s1=n1=0;r=0; 
			for(i=m*GW1/num;i<(m+1)*GW1/num;i++)for(j=0;j<GH1;j++)
			{
				if(F_ROW[j][i]>0)
				{
 					i1=i+1;j1=j+1;h=p=s=n=0;
					for(q=-mask;q<=mask;q++)for(t=-mask;t<=mask;t++)
					{
						h+=FDD[j1+q][i1+t].direc[0];p+=FDD[j1+q][i1+t].direc[1];
						s+=FDD[j1+q][i1+t].direc[2];n+=FDD[j1+q][i1+t].direc[3];
					}
					F_ROW[j][i]--;r++;
					q=h+s+p+n;
					if(q>0)
					{
						h1+=(float)h/(float)q;p1+=(float)p/(float)q;
						s1+=(float)s/(float)q;n1+=(float)n/(float)q;
					}
					break;
				}
			}
			if(r>0)
			{
				r=8;
				buff[d]=h1/r;d++;buff[d]=p1/r;d++;
				buff[d]=s1/r;d++;buff[d]=n1/r;d++;
			}
			else if(r==0) d+=4;
			//if(r==0){buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;}
			h1=p1=s1=n1=0;r=0;
			for(i=m*GW1/num;i<(m+1)*GW1/num;i++)for(j=GH1-1;j>=0;j--)
			{
				if(F_ROW[j][i]>0)
				{
					i1=i+1;j1=j+1;	h=p=s=n=0;
					for(q=-mask;q<=mask;q++)for(t=-mask;t<=mask;t++)
					{
						h+=FDD[j1+q][i1+t].direc[0];p+=FDD[j1+q][i1+t].direc[1];
						s+=FDD[j1+q][i1+t].direc[2];n+=FDD[j1+q][i1+t].direc[3];
					}
					F_ROW[j][i]--;r++;
					q=h+s+p+n;
					if(q>0)
					{
						h1+=(float)h/(float)q;p1+=(float)p/(float)q;
						s1+=(float)s/(float)q;n1+=(float)n/(float)q;
					}
					break;
				}
			}
			if(r>0)
			{
				r=8;
				buff[d]=h1/r;d++;buff[d]=p1/r;d++;
				buff[d]=s1/r;d++;buff[d]=n1/r;d++;
			}
			else if(r==0) d+=4;
			//if(r==0){buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;}
		}
	//2. horizontal direction searching
		for(m=0;m<num;m++)
		{
		h1=p1=s1=n1=0;c=0;
			for(j=m*GH1/num;j<(m+1)*GH1/num;j++)for(i=0;i<GW1;i++)
			{
				if(F_COL[j][i]>0)
				{
					i1=i+1;j1=j+1;	h=p=s=n=0;
					for(q=-mask;q<=mask;q++)for(t=-mask;t<=mask;t++)
					{
						h+=FDD[j1+q][i1+t].direc[0];p+=FDD[j1+q][i1+t].direc[1];
						s+=FDD[j1+q][i1+t].direc[2];n+=FDD[j1+q][i1+t].direc[3];
					}
					F_COL[j][i]--;c++;	
					q=h+s+p+n;
					if(q>0)
					{
						h1+=(float)h/(float)q;p1+=(float)p/(float)q;
						s1+=(float)s/(float)q;n1+=(float)n/(float)q;
					}
					break;
				}
			}
			if(c>0)
			{
				c=8;
				buff[d]=h1/c;d++;buff[d]=p1/c;d++;
				buff[d]=s1/c;d++;buff[d]=n1/c;d++;
			}
			else if(c==0) d+=4;
			//if(c==0){buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;}
			h1=p1=s1=n1=0;c=0;
			for(j=m*GH1/num;j<(m+1)*GH1/num;j++)for(i=GW1-1;i>=0;i--)
			{
				if(F_COL[j][i]>0)
				{
					i1=i+1;j1=j+1;h=p=s=n=0;
					for(q=-mask;q<=mask;q++)for(t=-mask;t<=mask;t++)
					{
						h+=FDD[j1+q][i1+t].direc[0];p+=FDD[j1+q][i1+t].direc[1];
						s+=FDD[j1+q][i1+t].direc[2];n+=FDD[j1+q][i1+t].direc[3];
					}
					F_COL[j][i]--;c++;	
					q=h+s+p+n;
					if(q>0)
					{
						h1+=(float)h/(float)q;p1+=(float)p/(float)q;
						s1+=(float)s/(float)q;n1+=(float)n/(float)q;
					}
					break;
				}
			}
			if(c>0)
			{
				c=8;
			buff[d]=h1/c;d++;buff[d]=p1/c;d++;
			buff[d]=s1/c;d++;buff[d]=n1/c;d++;
			}
			else if(c==0) d+=4;
			//if(c==0){buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;}
		}	
		//3.Right  diagonal direction searching
		int W3;
		c=-(GW1-1);
		W3=GW1*2;
		for(m=0;m<num;m++)
		{
		h1=p1=s1=n1=0;r=0; 
			for(u=c+m*W3/num;u<c+(m+1)*W3/num;u++)
			for(i=0;i<GW1;i++)
			{
				j=i-u;
				if((j>=0)&&(j<GH1)&&(F_DIGR[j][i]>0))
				{
					i1=i+1;j1=j+1;	h=p=s=n=0;
					for(q=-mask;q<=mask;q++)for(t=-mask;t<=mask;t++)
					{
						h+=FDD[j1+q][i1+t].direc[0];p+=FDD[j1+q][i1+t].direc[1];
						s+=FDD[j1+q][i1+t].direc[2];n+=FDD[j1+q][i1+t].direc[3];
					}
					F_DIGR[j][i]--;r++;	
					q=h+s+p+n;
					if(q>0)
					{
						h1+=(float)h/(float)q;p1+=(float)p/(float)q;
						s1+=(float)s/(float)q;n1+=(float)n/(float)q;
					}
					break;
				}
			}
			if(r>0)
			{
				r=16;
				buff[d]=h1/r;d++;buff[d]=p1/r;d++;
				buff[d]=s1/r;d++;buff[d]=n1/r;d++;
			}
			else if(r==0) d+=4;
			//if(r==0){buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;}
			h1=p1=s1=n1=0;r=0; 
			for(u=c+m*W3/num;u<c+(m+1)*W3/num;u++)
			for(i=GW1-1;i>=0;i--)
			{
				j=i-u;
				if((j>=0)&&(j<GH1)&&(F_DIGR[j][i]>0))
				{
					i1=i+1;j1=j+1;h=p=s=n=0;
					for(q=-mask;q<=mask;q++)for(t=-mask;t<=mask;t++)
					{
						h+=FDD[j1+q][i1+t].direc[0];p+=FDD[j1+q][i1+t].direc[1];
						s+=FDD[j1+q][i1+t].direc[2];n+=FDD[j1+q][i1+t].direc[3];
					}
					F_DIGR[j][i]--;r++;	
					q=h+s+p+n;
					if(q>0)
					{
						h1+=(float)h/(float)q;p1+=(float)p/(float)q;
						s1+=(float)s/(float)q;n1+=(float)n/(float)q;
					}
					break;
				}
			}
			if(r>0)
			{
				r=16;
				buff[d]=h1/r;d++;buff[d]=p1/r;d++;
				buff[d]=s1/r;d++;buff[d]=n1/r;d++;
			}
			else if(r==0) d+=4;
			//if(r==0){buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;}
		}
		//4.  Negative   diagonal direction  searching
		for(m=0;m<num;m++)
		{
			h1=p1=s1=n1=0;r=0; 
			for(u=m*W3/num;u<(m+1)*W3/num;u++)
			for(i=0;i<GW1;i++)
			{
				j=-(i-u);
				if((j>=0)&&(j<GH1)&&(F_DIGN[j][i]>0))
				{
					i1=i+1;j1=j+1;h=p=s=n=0;
					for(q=-mask;q<=mask;q++)for(t=-mask;t<=mask;t++)
					{
						h+=FDD[j1+q][i1+t].direc[0];p+=FDD[j1+q][i1+t].direc[1];
						s+=FDD[j1+q][i1+t].direc[2];n+=FDD[j1+q][i1+t].direc[3];
					}
					F_DIGN[j][i]--;r++;	
					q=h+s+p+n;
					if(q>0)
					{
						h1+=(float)h/(float)q;p1+=(float)p/(float)q;
						s1+=(float)s/(float)q;n1+=(float)n/(float)q;
					}
					break;
				}
			}
			if(r>0)
			{
				r=16;
				buff[d]=h1/r;d++;buff[d]=p1/r;d++;
				buff[d]=s1/r;d++;buff[d]=n1/r;d++;
			}
			else if(r==0) d+=4;
			//if(r==0){buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;}
			h1=p1=s1=n1=0;r=0; 
			for(u=m*W3/num;u<(m+1)*W3/num;u++)
			for(i=GW1-1;i>=0;i--)
			{
				j=-(i-u);
				if((j>=0)&&(j<GH1)&&(F_DIGN[j][i]>0))
				{
					i1=i+1;j1=j+1;h=p=s=n=0;
					for(q=-mask;q<=mask;q++)for(t=-mask;t<=mask;t++)
					{
						h+=FDD[j1+q][i1+t].direc[0];p+=FDD[j1+q][i1+t].direc[1];
						s+=FDD[j1+q][i1+t].direc[2];n+=FDD[j1+q][i1+t].direc[3];
					}
					F_DIGN[j][i]--;r++;		
					q=h+s+p+n;
					if(q>0)
					{
						h1+=(float)h/(float)q;p1+=(float)p/(float)q;
						s1+=(float)s/(float)q;n1+=(float)n/(float)q;
					}
					break;
				}
			}
			if(r>0)
			{
				r=16;
				buff[d]=h1/r;d++;buff[d]=p1/r;d++;
				buff[d]=s1/r;d++;buff[d]=n1/r;d++;
			}
			else if(r==0) d+=4;
			//if(r==0){buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;buff[d]=-0.1F;d++;}
		}
		k++;
	}while(k<depth);
	//float *pbuff=new float[PDIM];
	float pbuff[PDIM];
	memcpy(pbuff,buff,sizeof(float)*PDIM);
	n=0;
	for(i=0;i<3;++i){//depth
		for(j=0;j<4;++j){//scan direc
			for(k=0;k<8;k++){//sub interval
				for(m=0;m<4;++m){	
					buff[n]=pbuff[i*256+j*64+k*2*4+m];
					n++;
				}
			}
			for(k=0;k<8;++k){//sub interval
				for(m=0;m<4;++m){
					buff[n]=pbuff[i*256+j*64+(k*2+1)*4+m];
					n++;
				}
			}
		}
	}
	
	//if(pbuff) delete[] pbuff;pbuff=NULL;
	return PDIM;
	k=0;
	float sum = 0;
	for (i=0;i<PDIM;i++){
		sum +=m_Bec[i];
		k++;
	}
	if(sum == 0) sum = 1;
	for (i=0;i<PDIM;i++)	m_Bec[i]=m_Bec[i]/sum*350;

}
int CRecogCore::GetFeatureGrad3(BYTE F[GH1][GW1])
{
// 	FGd Fg[GH3][GW3];
	BYTE F1[GH1][GW1];
	int i,j;
	memcpy(F1,F,GH1*GW1);
	for(i=0;i<GH1;i++)for(j=0;j<GW1;j++){
		if(	F1[i][j]==1) F1[i][j]=255;
		else  F1[i][j]=0;
	}
	BYTE F2[GH3][GW3];

	LinearNormalize3(F1,F2);
	for(i=0;i<2;i++)	Filter3(F2);
// 	Gradient(F2,Fg);
// 	BectorGradient(Fg);
	int nDim = GetGradientBector3(F2);
	return nDim;
	
}
void CRecogCore::LinearNormalize3(BYTE F1[GH1][GW1],BYTE F[GH3][GW3])
{
	int i,j;
	double i0,j0;
	int w1 = GW1,h1 = GH1;
	int w = GW3,h = GH3;
	double iscale=(double)(w1-1)/(double)(w-1);
	double jscale=(double)(h1-1)/(double)(h-1);
	
	double	offi[GW3];
	double	offj[GH3];
	int		Wi[GW3];
	int		Hj[GH3];
	BYTE  FF[GH1+2][GW1+2];
	memset(FF,0,(GW1+2)*(GH1+2));
	for(i=0;i<h1;i++)
	{
		memcpy(FF[i],F1[i],w1);
	}
	memset(F,0,GW3*GH3);
	for(i=0;i<GW3;i++) {
		i0=(double)i*iscale;
		//if(i0<0.0)i0=0.0;
		Wi[i]=(int)floor(i0);
		//if(Wi[i]<0)Wi[i]=0;
		offi[i] = (i0-(double)Wi[i]);
	}
	for(i=0;i<GH3;i++) {
		j0=(double)i*jscale;
		//if(j0<0.0)j0=0.0;
		Hj[i]=(int)floor(j0);
		//if(Hj[i]<0)Hj[i]=0;
		offj[i] = (j0-(double)Hj[i]);
	}
	int x ,y;
	double val00,val01,val10,val11;
	for(j=0;j<h;j++){
		y = Hj[j];
		for(i=0;i<w;i++){ 
			x= Wi[i];
			val00 = (double)FF[y][x];
			val01 = (double)FF[y][x+1];
			val10 = (double)FF[y+1][x];
			val11 = (double)FF[y+1][x+1];
			
			int newval = (int)(floor(((val00 * (1.0-offj[j]) *  (1.0-offi[i]) +
				val01 * (1.0-offj[j]) *      offi[i]    +
				val10 *     offj[j]    *  (1.0-offi[i]) +
				val11 *     offj[j]    *      offi[i]  ))));
			if(newval >= 255) newval = 255;
			if(newval <= 0) newval = 0;
			F[j][i]=(BYTE)newval;///pk0(i,j):
		}
	}
	
}
//void CRecogCore::LinearNormalize3(BYTE F1[GH1][GW1],BYTE F[GH3][GW3])
//{
//	int i,j;
//	float i0,j0;
//	int w1 = GW1,h1 = GH1;
//	int w = GW3,h = GH3;
//	float iscale=(float)(w1-1)/(float)(w-1);
//	float jscale=(float)(h1-1)/(float)(h-1);
//
//	float	offi[GW3];
//	float	offj[GH3];
//	int		Wi[GW3];
//	int		Hj[GH3];
//	BYTE  FF[GH1+2][GW1+2];
//	memset(FF,0,(GW1+2)*(GH1+2));
//	for(i=0;i<h1;i++)
//	{
//		memcpy(FF[i],F1[i],w1);
//	}
//	memset(F,0,GW3*GH3);
//	for(i=0;i<GW3;i++) {
//		i0=iscale*i;
//		Wi[i]=(int)floor(i0);
//		offi[i] = (i0-Wi[i]);
//	}
//	for(i=0;i<GH3;i++) {
//		j0=jscale*i;//+0.5f;
//		Hj[i]=(int)floor(j0);
//		offj[i] = (j0-Hj[i]);
//	}
//	int x ,y;
//	float val00,val01,val10,val11;
//	for(j=0;j<h;j++){
//		y = Hj[j];
//		for(i=0;i<w;i++){ 
//			x= Wi[i];
//			val00 = (float)FF[y][x];
//			val01 = (float)FF[y][x+1];
//			val10 = (float)FF[y+1][x];
//			val11 = (float)FF[y+1][x+1];
//
//			int newval = (int)(floor(((val00 * (1-offj[j]) *  (1-offi[i]) +
//				val01 * (1-offj[j]) *   offi[i]    +
//				val10 *  offj[j]    *  (1-offi[i]) +
//				val11 *  offj[j]    *   offi[i]  ))));
//			if(newval >= 255) newval = 255;
//			if(newval <= 0) newval = 0;
//			F[j][i]=(BYTE)newval;///pk0(i,j):
//		}
//	}
//}
void CRecogCore::Filter3(BYTE F[][GW3])
{
	int i,j;
	BYTE FS[GH3+2][GW3+2];
	int Buff=0;
	for(i=0;i<GH3+2;i++)for(j=0;j<GW3+2;j++) FS[i][j]=0;
	for(i=1;i<=GH3;i++)for(j=1;j<=GW3;j++) FS[i][j]=F[i-1][j-1];
	
	for(i=1;i<=GH3;i++)for(j=1;j<=GW3;j++){
		Buff=0;
		Buff=FS[i][j]+FS[i][j+1]+FS[i-1][j+1]+FS[i-1][j]+FS[i-1][j-1]
			+FS[i][j-1]+FS[i+1][j-1]+FS[i+1][j]+FS[i+1][j+1];
		F[i-1][j-1]=Buff/9;
	}
}

int CRecogCore::GetGradientBector3(BYTE F[][GW3])
{
	int i,j,k,l,m;
	float FS[GH3+2][GW3+2];
	FGd Fg[GH3][GW3];
	int dir=0;
	float Max=0;
	float x[8];memset(x,0,sizeof(float)*8);
	Max=F[0][0];
	for (i=0;i<GH3;i++) for (j=0;j<GW3;j++){
		if(Max<F[i][j]) Max=(float)F[i][j];
	}
	for(i=0;i<GH3+2;i++)for(j=0;j<GW3+2;j++) FS[i][j]=0;
	if(Max!=0)for(i=1;i<=GH3;i++)for(j=1;j<=GW3;j++) FS[i][j]=((float)(F[i-1][j-1]))/Max;
/////////////// 32���� gradientȭ���� //////////
	float GradX=0,GradY=0,Grad,tanVal;
	for (i=1;i<GH3+1;i++) for (j=1;j<GW3+1;j++){
		GradX=0,GradY=0;
		x[0]=FS[i][j+1];x[1]=FS[i-1][j+1];x[2]=FS[i-1][j];x[3]=FS[i-1][j-1];
	    x[4]=FS[i][j-1];x[5]=FS[i+1][j-1];x[6]=FS[i+1][j];x[7]=FS[i+1][j+1];
		GradX = x[0]+x[1]+x[7]-x[3]-x[4]-x[5];
		GradY = x[1]+x[2]+x[3]-x[5]-x[6]-x[7];
		
		if( GradX==0 && GradY==0 ){ 
			Fg[i-1][j-1].directId=0;Fg[i-1][j-1].grad=0;
			continue;
		}
		if( GradX==0 && GradY>0 ){ 
			Fg[i-1][j-1].directId=8;Fg[i-1][j-1].grad=GradY;
			continue;
		}
		if( GradX==0 && GradY<0 ){ 
			Fg[i-1][j-1].directId=24;Fg[i-1][j-1].grad=-GradY;
			continue;
		}
		if( GradY==0 && GradX>0 ){ 
			Fg[i-1][j-1].directId=0;Fg[i-1][j-1].grad=GradX;
			continue;
		}
		if( GradY==0 && GradX<0 ){ 
			Fg[i-1][j-1].directId=16;Fg[i-1][j-1].grad=-GradX;
			continue;
		}
		Grad = (float)sqrt((GradX*GradX + GradY*GradY));//���丣 ����
		tanVal = (float)(fabs(GradY)/fabs(GradX));//���丣 ������
		for (k=0;k<8;k++) {
			if(tanVal < m_tan[k]) break;
		}
		if( GradY>0 && GradX>0 ){ //1��б�?
			Fg[i-1][j-1].directId=k;Fg[i-1][j-1].grad=Grad;
			continue;
		}
		if( GradY>0 && GradX<0 ){ //2��б�?
			Fg[i-1][j-1].directId=16-k;Fg[i-1][j-1].grad=Grad;
			continue;
		}
		if( GradY<0 && GradX<0 ){ //3��б�?
			Fg[i-1][j-1].directId=16+k;Fg[i-1][j-1].grad=Grad;
			continue;
		}
		if( GradY<0 && GradX>0 ){ //4��б�?
			if(k==0) Fg[i-1][j-1].directId=0;
			else Fg[i-1][j-1].directId=32-k;
			Fg[i-1][j-1].grad=Grad;
			continue;
		}
	}
////////////////////////////////////////////////////
	float Be[13][13][32],Be1[13][13][16],BB[17][17][8];
	memset(Be,0,sizeof(float)*13*13*32);
	memset(Be1,0,sizeof(float)*13*13*16);
	memset(BB,0,sizeof(float)*17*17*8);

	//9*9���� �� �κб������� ���⺰���谪�� ���� Ư¡������ ���Ѵ�.
	for (i=0;i<13;i++) for (j=0;j<13;j++)
	for (k=0;k<6;k++) for (l=0;l<6;l++){
			Be[i][j][Fg[i*6+k][j*6+l].directId] += Fg[i*6+k][j*6+l].grad; 
	}
	//���콺��������ũ�� ���ϱ� ���Ͽ� BB�� ���� �����Ѵ�.
	//�̶� 1 4 6 4 1 filter�� 1 2 1 filter�� �����Ͽ� 8�������� ����Ѵ�?
	for(i=0;i<13;i++) for(j=0;j<13;j++){
		for(k=0;k<14;k++){
			Be1[i][j][k] = Be[i][j][k*2] + Be[i][j][2*k+1]*4 + Be[i][j][2*k+2]*6 + Be[i][j][2*k+3]*4  + Be[i][j][2*k+4];
		}
		Be1[i][j][14] = Be[i][j][28] + Be[i][j][29]*4 + Be[i][j][30]*6 + Be[i][j][31]*4  + Be[i][j][0];
		Be1[i][j][15] = Be[i][j][30] + Be[i][j][31]*4 + Be[i][j][0]*6 + Be[i][j][1]*4  + Be[i][j][2];
	}
	for(i=0;i<13;i++) for(j=0;j<13;j++){
		for(k=0;k<7;k++){
			BB[i+2][j+2][k] = Be1[i][j][k*2] + Be1[i][j][2*k+1]*2 + Be1[i][j][2*k+2];
		}
		BB[i+2][j+2][7] = Be1[i][j][14] + Be1[i][j][15]*2 + Be1[i][j][0];
	}

	//BB�� ���콺��������ũ�� ���Ѵ�.
	//����ũ�� �߽��� 2��ŭ�� �������ְ� �����Ͽ� 
	//9*9�� ������ �߽����� ���õǴ� �������� 5*5�� �ȴ�.
	//�̶� ����ũ�������?�߽��� [2,2]�� �ȴ�.
	float* bec = m_Bec;
	memset(bec,0,sizeof(float)*7*7*8);
	for (i=0;i<7;i++) for (j=0;j<7;j++){//�߽����� ������ ����
		for (k=0;k<5;k++) for (l=0;l<5;l++){//����ũ��ȯ
			for (m=0;m<8;m++){//����
				bec[(i*7+j)*8+m] += (BB[i*2+k][j*2+l][m]*m_ExpW1[k][l]);
			}
		}
	}
	for (i=0;i<GDIM3;i++)	bec[i]= powf(bec[i],0.4f);
	return GDIM3;
}

void CRecogCore::GetOnlyNormalize(BYTE* pImg,int w,int h, BYTE F[GH1][GW1])
{
	LinearNormalize(pImg,w,h,F);
}

#define NMARK 400
void CRecogCore::MakeHuboArrayOnDis(CAND Hubos[MAX_FONT],int nFontNum, CAND* Hubo)
{
	int		i,j,k,m=0,num;
	WORD	Cd,Cds[NMARK];
	int		Id,Ids[NMARK],Font[NMARK],font;
	double	d,DisA[NMARK];
	memset(Cds,0,sizeof(WORD)*NMARK);
	//	Hubo->nTemp=0;
	for(k=0;k<nFontNum;++k){
		num = Hubos[k].nCandNum;
		for(i=0;i<num;i++){
			Id=IsExistCd(Cds,Hubos[k].Code[i]);
			if(Id<0){
				Cds[m]=	Hubos[k].Code[i];
				Ids[m]=Hubos[k].Index[i];
				Font[m]= k;
				DisA[m++]=Hubos[k].Dis[i];
			}
			else{
				if(DisA[Id]>Hubos[k].Dis[i]){
					DisA[Id]=Hubos[k].Dis[i];
					Font[Id]= k;
				}
			}
		}
	}
	for(i=0;i<m;++i){
		for(j=i;j<m;++j){
			if(DisA[i]>DisA[j]){
				d=DisA[i];DisA[i]=DisA[j];DisA[j]=d;
				Cd=Cds[i];Cds[i]=Cds[j];Cds[j]=Cd;
				Id=Ids[i];Ids[i]=Ids[j];Ids[j]=Id;
				font=Font[i];Font[i]=Font[j];Font[j]=font;
			}
		}
	}
	int nCandNum;
	if(m>MAX_CAND) nCandNum = MAX_CAND;
	else		nCandNum = m;
	for(i=0;i<nCandNum;++i){
		Hubo->Code[i]=Cds[i];
		Hubo->Index[i]=Ids[i];
		Hubo->Dis[i]=DisA[i];
		Hubo->Font[i]=Font[i];
	}
	Hubo->nCandNum = nCandNum;
	for(i=nCandNum;i<MAX_CAND;++i){
		Hubo->Code[i] = SpaceTwo;
		Hubo->Index[i]= 0;
		Hubo->Dis[i]  = 1000;
		Hubo->Font[i]=0;
	}
}
int CRecogCore::SearchIndex(WORD* CdTable,int nCNum,WORD w)
{
	int i;
	for(i=0;i<nCNum;++i){
		if(CdTable[i]==w) return i;
	}
	return -1;
}
int CRecogCore::IsExistCd(WORD *Cds,WORD Cd)
{
	int i=0,fg=0;
	do{	
		if(Cds[i]==0)	break;
		if(Cds[i]==Cd){ fg=1;break;}
		i++;
	}while(i<NMARK);
	if(fg==0) return -1;
	return i;
}
void CRecogCore::ExchangeHubo(CAND* Hubo,int i,int j)
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
float CRecogCore::WordTofloat(unsigned short a)
{
	DWORD dw;
	dw = 0x0080 | ((DWORD)(a)) << 16;
	return	*((float*)&dw);
	
}
int CRecogCore::GetCharType(int w,int h,int CharSize)
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
	else{	// Char Type 
		if(fh>fw*2) nCharType = SYMBOL_TYPE;
		else
			nCharType = RECT_TYPE;
	}
	return nCharType;
}
int CRecogCore::GetRecogCharSet(int nType)
{
	int nRecogSet;
	if(nType == RECT_TYPE){
		nRecogSet = RECT_ALL_LANGUAGE_SET;
	}
	else if(nType == I_TYPE){
		nRecogSet = ITYPE_OTHER_SET;
	}
	else if(nType == DOT_TYPE) nRecogSet = DOT_SET;
	else if(nType == UNDER_LINE_TYPE) nRecogSet = UNDERLINE_SET;
	else nRecogSet = RECT_ALL_LANGUAGE_SET;
	
	return nRecogSet;
}
