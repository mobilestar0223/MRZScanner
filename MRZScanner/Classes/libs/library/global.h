#ifndef GLOBAL_H
#define GLOBAL_H

#include "StdAfx.h"

typedef struct tagMainDataT
{
#ifdef TESS
	tesseract::TessBaseAPI *g_api;
#endif
	//CardData* g_pCardData;
	void* g_hFaceHandle;
	BYTE *g_pbyGray;
	BYTE *g_pbySpec;
	BYTE *g_pbyMono;

	int *g_pnStroke;

	BYTE *g_pbyTemp0;
	BYTE *g_pbyTemp1;

	int *g_pnTemp0;

	int g_nWidth;
	int g_nHeight;
	
	tagMainDataT(){
		//g_api = NULL;
		//g_pCardData = NULL;
		g_pbyGray = NULL;
		g_pbySpec = NULL;
		g_pbyMono = NULL;

		g_pnStroke = NULL;

		g_pbyTemp0 = NULL;
		g_pbyTemp1 = NULL;

		g_pnTemp0 = NULL;

		g_nWidth = 0;
		g_nHeight = 0;

		g_hFaceHandle = NULL;
	}

}MainDataT;

extern MainDataT* g_pdata_t;

#define MAX_STROKE_NUM		2500
#define MAX_LETTER_NUM		300

typedef struct tagSTROKE
{
	int		nPointNum;
	RECT	rtRegion;
	int		nFirst;
	int		nCol;

	tagSTROKE() {
		nPointNum = 0;
		memset((void*)&rtRegion, 0x0, sizeof(RECT));
		nFirst = 0;
		nCol = 0;
	}
} STROKE;


#define SEG_TYPE_NONE		0

#define SEG_TYPE_I				50
#define SEG_TYPE_A			51
#define SEG_TYPE_W			52

#define SEG_TYPE_UPENG		100	//"A~Z"
#define SEG_TYPE_LOENG		101	//"a~z"
#define SEG_TYPE_DIGIT		102 

#define SEG_TYPE_PT			200	//"."
#define SEG_TYPE_SPT			201	//","
#define SEG_TYPE_UPT			202	//"'"

#define SEG_TYPE_HANJA		300

#define IMG_WIDTH_FACE	500
#define IMG_WIDTH		800//1140//570 //800
	

typedef struct tagSEGMENT
{
	RECT	rtRegion;
	int		nStyle;
	RECT	rtEnd;
	int nAvgH;
	int nBlob;
	float rot_ang;
	
	char szData[1024];
	float fconf;
	
	tagSEGMENT() {
		nStyle = 0;
		nAvgH = 0;
		nBlob = 0;
		rot_ang = 0.0f;
		memset((void*)&rtEnd, 0x0, sizeof(RECT));
		memset((void*)&rtRegion, 0x0, sizeof(RECT));
		memset(szData, 0, 1024);
	}
} SEGMENT;

//RECT related functions
RECT getRect(int x0, int y0, int x1, int y1);
int getRectWidth(RECT x);
int getRectHeight(RECT x);
bool isIncludeRect(RECT x, RECT y, int nTh = 0);
bool isIntersectRect(RECT x, RECT y);
RECT boundRect(RECT rt, int nWidth, int nHeight);
//RECT glo_scale_rect(RECT rt, float fRate);

//global functions
bool glo_alloc_mem(int nW, int nH);
void glo_free_mem();

void glo_paint_stroke(BYTE* pbImg, int nW, int nFirst, int* pnStroke, BYTE nCol);
void glo_sub_binary(BYTE* pbyGray, int* pnSum, int* lpOut, int nWidth, int nHeight, int x0, int x1, int y0, int y1, int rw, int rh);
int glo_detect_strokes(BYTE *pbIn, BYTE *pbOut, int *pnStroke, STROKE pStroke[], RECT rtRegion,
					   int nWidth, int nHeight, int nMaxNum, BYTE nBk,
					   int nSmallNum, int nSmallW, int nSmallH, bool bSmallRemove, int nMode = 8);

void glo_sort_y_rects(RECT*pRt, int nNum);
void glo_sort_x_rects(RECT*pRt, int nNum);

void glo_sort_y_segs(SEGMENT *pSegs, int nNum);
void glo_sort_x_segs(SEGMENT *pSegs, int nNum);
void glo_sort_yx_segs(SEGMENT *pSegs, int nNum);

int glo_segment_by_hist(BYTE* pbyImg, int nW, int nH, int nLetterW, int nLetterH, SEGMENT* &pSegAry);
void glo_get_left_right(BYTE *pbIn, int nWidth, int nHeight, long &x0, long &x1, long y0, long y1);
void glo_get_top_bottom(BYTE *pbyImg, int nW, int nH, long x0, long x1, long &y0, long &y1);

void glo_Resize(BYTE *pSrc, int nSrcW, int nSrcH, int nC, BYTE *pDst, int nDstW, int nDstH);
int glo_get_char_height(SEGMENT* pSegs, int nSegs, int minTh);

int GetBlkId(RECT cRt, RECT cSubAllRt[50], int nNum);
void GetLUAngle(RECT cRt1, RECT cRt2, double& ang1, double& ang2);
//double glo_get_angle_image(BYTE* pbyImg, int w, int h);
int glo_get_image_quality(BYTE* pbyImg, int nW, int nH, RECT rtRoi, RECT rtFace, RECT rtQR);
int glo_get_image_similarity(BYTE* pbyPre, int npW, int npH, BYTE* pbyCur, int ncW, int ncH);

//long getCurTime();
//double getElaspedTime(long start);

//////////////////////
//rotation
/////////////////////////
void glo_RotateRight_Img(BYTE *pImg, BYTE* pOut, int w, int h, int c = 1);
void glo_RotateLeft_Img(BYTE *pImg, BYTE* pOut, int w, int h, int c = 1);
void glo_Rotate180_Img(BYTE *pImg, BYTE* pOut, int w, int h, int c = 1);

#endif 
