#pragma once

#ifndef BASETYPES_H
#define BASETYPES_H

#include <math.h>
#include <stdio.h>
#include <memory.h>
/*#ifdef WIN32
#include <tchar.h>
#endif*/
#include <stdlib.h>
#include <assert.h>

#ifdef __cplusplus
extern "C"
{
#endif

	//--------------------------------------------------------------------------
	// Primitive data types
	//--------------------------------------------------------------------------
	typedef unsigned char		uint8;
	typedef uint8				BYTE;
//	typedef uint8*				LPBYTE;
// 	typedef int					XRInt;
// 	typedef bool				BOOL;
// 	typedef short				XRShort;
	typedef unsigned short		WORD;
//	typedef unsigned long       DWORD;
// 	typedef unsigned short	XRUShort;
// 	typedef float				XRFloat;
// 	typedef float*				XRLPFloat;
// 	typedef double				XRDouble;
// 	typedef double*			XRLPDouble;
//	typedef unsigned int		UINT;
// 	typedef long				XRLong;
// 	typedef void*				XRLPVoid;
// 	typedef void *				XRFeatureHandle;
// 	typedef void *				XRVideoHandle;

	typedef struct tagIRECT
	{
		int    left;
		int    top;
		int    right;
		int    bottom;
	} IRECT;

	// -------------------------------------------------------------------------
	// Macro
	// -------------------------------------------------------------------------

#if (defined WIN32 || defined WIN64) && defined LIBCARD_EXPORTS
#define CARD_EXPORTS __declspec(dllexport)
#else
#define CARD_EXPORTS
#endif

/* Define NULL pointer value */
#ifndef NULL
#ifdef __cplusplus
#define NULL    0
#else
#define NULL    ((void *)0)
#endif
#endif

#ifdef __cplusplus
}
#endif
#endif // BASETYPES_H
