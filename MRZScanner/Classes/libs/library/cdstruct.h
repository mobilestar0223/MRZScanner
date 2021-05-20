#ifndef TBLSTRUCT_H
#define TBLSTRUCT_H

#pragma once

#include "cdtypes.h"
#include <string>
#include <vector>

#define CARD_TYPE_PAN		0
#define CARD_TYPE_AADHAR	1

#define CARD_TYPE_INDIA_BACK	6

#define PARAM_AADHAR_FRONT		11
#define PARAM_AADHAR_BACK		12


typedef struct tagWordResult {
	std::string _strWord;
	float _conf;
	
	tagWordResult() {
		_conf = 0.0f;
	}
}WordResult;

typedef struct tagLineResult {
	std::string _strLine;
	float _conf;
	std::vector<WordResult> _vecWords;
	
	tagLineResult() {
		_conf = 0.0f;
	}
}LineResult;

typedef struct tagCardData {
	int _nCardType;
	int _nCardParam;
	int _nDirect;
	double _fRot;
	std::string _strCardType; 
	std::string _strName;
	std::string _strSex;
	std::string _strFather;
	std::string _strMother;
	std::string _strBirthday;
	std::string _strPAN; //Permanent Account Number
	std::string _strAddress;

	std::string _strExpiry;
	std::string _strDLType;
	std::string _strCond;

	IRECT _rtName;
	IRECT _rtSex;
	IRECT _rtFather;
	IRECT _rtBirthday;
	IRECT _rtPAN;
	IRECT _rtAddress;
	IRECT _rtFace;
	IRECT _rtSign;
	IRECT _rtQR;

	tagCardData(){
		_nCardType = -1;
		_nCardParam = -1;
		_nDirect = -1;
		_fRot = 0.0f;
		memset(&_rtName, 0, sizeof(IRECT));
		memset(&_rtSex, 0, sizeof(IRECT));
		memset(&_rtFather, 0, sizeof(IRECT));
		memset(&_rtBirthday, 0, sizeof(IRECT));
		memset(&_rtPAN, 0, sizeof(IRECT));
		memset(&_rtAddress, 0, sizeof(IRECT));
		memset(&_rtFace, 0, sizeof(IRECT));
		memset(&_rtSign, 0, sizeof(IRECT));
		memset(&_rtQR, 0, sizeof(IRECT));
	}
}CardData;

#endif
