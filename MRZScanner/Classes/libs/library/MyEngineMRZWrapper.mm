
#include "MyEngineMRZWrapper.h"
#include "Cardrec.h"
#include <iostream>

#include "opencv2/highgui.hpp"
#include "opencv2/imgproc.hpp"
#include "opencv2/imgcodecs.hpp"

using namespace std;
using namespace cv;

Cardrec *g_Cardrec = nullptr;

bool DetectG(cv::Mat gray)
{
    cv::Mat bi, mean, dev;
    //cv::cvtColor(src, gray, COLOR_BGR2GRAY);

    cv::blur(gray, gray, cv::Size(10, 10));

    double minval, maxval;
    cv::minMaxLoc(gray, &minval, &maxval);
    cv::threshold(gray, bi, maxval - (maxval - minval) / 20, 255, cv::THRESH_BINARY);
    cv::blur(bi, bi, cv::Size(10, 10));
    cv::threshold(bi, bi, 250, 255, THRESH_BINARY);


    vector<vector<cv::Point> > contours;
    vector<cv::Vec4i> hierarchy;
    cv::findContours(bi, contours, hierarchy, cv::RETR_TREE, CHAIN_APPROX_SIMPLE);
    vector<cv::Rect> boundRect(contours.size());
    vector<vector<cv::Point> > contours_poly(contours.size());

    cv::Rect box;
    int minwidth, maxwidth, ismin = 0, ismax = 0;
    for (size_t i = 0; i < contours.size(); i++)
    {
        box = boundingRect(contours[i]);
        if (ismax == 0)
        {
            maxwidth = box.width + box.x;
            ismax = 1;
        }
        else
        {
            if (maxwidth < box.width + box.x)
                maxwidth = box.width + box.x;
        }
        if (ismin == 0)
        {
            minwidth = box.x;
            ismin = 1;
        }
        else
        {
            if (minwidth > box.x)
                minwidth = box.x;
        }
    }

    meanStdDev(bi, mean, dev);
    double i = dev.at<double>(0);

    if (i > 13 && i < 92 && contours.size() < 3)
        return true;
    else
        return false;
}

@implementation MyEngineMRZWrapper

+ (bool) EngineMRZ_Init:(unsigned char *) pDic lenDic:(int) lenDic pDicG:(unsigned char*) pDicG lenDicG:(int) lenDicG {
    bool bRet = false;

    g_Cardrec = Cardrec::getInstance();
    g_Cardrec->init(CARD_TYPE_MRZ);

    int nRet = g_Cardrec->loadDB((char*)pDic, (int)lenDic, (char*)pDicG, (int)lenDicG, nullptr, 0);

    if (nRet >= 0)
        bRet = true;

    return bRet;
}

+ (void) EngineMRZ_Release {
    g_Cardrec->release();
    if (g_Cardrec != nullptr)
        delete g_Cardrec;
}

+ (char*) EngineMRZ_mrzScan1:(unsigned char*) pbyImgRGB width:(int) w height:(int) h {
    char* szMrzData = nullptr;
    int nRet = g_Cardrec->doRecognizeCrop((char*)pbyImgRGB, w, h, 0, 0, -1, -1);

    if (nRet >= 0) {
        if (nRet == 5)
            szMrzData = g_Cardrec->getResult(false, 5);
        else
            szMrzData = g_Cardrec->getResult(false, 0);
    }
    return szMrzData;
}

+ (char*) EngineMRZ_mrzScan2:(unsigned char*) pbyImgRGB width:(int) w height:(int) h {
    char* szMrzData = nullptr;
    int nRet = g_Cardrec->doRecognizeCrop((char*)pbyImgRGB, w, h, 0, 0, -1, -1);

    if (nRet >= 0) {
        if (nRet == 5)
            szMrzData = g_Cardrec->getResult(true, 5);
        else
            szMrzData = g_Cardrec->getResult(true, 1);
    }
    return szMrzData;
}

+ (bool) CheckImageGlare:(unsigned char*) pbyImgRGB width:(int) w height:(int) h {
    bool bGlareCheck = false;
    cv::Mat img_gray, img_bin;

    cv::Mat img_o(h, w, CV_8UC3, pbyImgRGB);

    cv::cvtColor(img_o, img_gray, cv::COLOR_BGR2GRAY);
    bGlareCheck = DetectG(img_gray);
    img_gray.release();
    img_o.release();

    return bGlareCheck;
}

+ (bool) CheckImageBlur:(unsigned char*) pbyImgRGB width:(int) w height:(int) h threshold:(int) threshold {
    bool BlurCheck = false;
    cv::Mat img_gray, img_lap;

    cv::Mat img_o(h, w, CV_8UC3, pbyImgRGB);
    cv::cvtColor(img_o, img_gray, cv::COLOR_BGR2GRAY);

    int kernel_size = 3;
    int scale = 1;
    int delta = 0;
    int ddepth = CV_64F;
    cv::Laplacian(img_gray, img_lap, ddepth, kernel_size, scale, delta);

    cv::Scalar mean;
    cv::Scalar dev;
    meanStdDev(img_lap, mean, dev);
    double M = mean.val[0];
    double D = dev.val[0];

    int laplacian_var = (int)(D * D);
    //laplacian_var = cv2.Laplacian(img_grey, cv2.CV_64F).var()
//    LOGD(" ==== laplacian value : %d =====", laplacian_var);
    if (laplacian_var < threshold)
        BlurCheck = true;

    return BlurCheck;
}

@end
