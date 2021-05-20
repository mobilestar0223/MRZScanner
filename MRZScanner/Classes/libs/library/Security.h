#ifndef __SECURITY_HEADER__
#define __SECURITY_HEADER__

void B2T(BYTE* pB, int size, BYTE* pT)//size: size of PB,  size * 2:size of PT
{
	char tbl[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	int i;
	for(i=0;i<size;i++)
	{
		pT[2*i]   = tbl[pB[i] & 0xF];
		pT[2*i+1] = tbl[(pB[i] >> 4) & 0xF];
	}
	pT[2*i] = 0;
}
void T2B( char* pT,int size,BYTE* pB)//size: size of PB,  size * 2:size of PT
{
	int tbl[26] = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25};
	int i;
	for(i=0;i<size/2;i++)
	{
		if(pT[2*i] < 'A' || pT[2*i] > 'Z')
		{
			return;
		}
		if(pT[2*i+1] < 'A' || pT[2*i+1] > 'Z')
		{
			return;
		}
		int a = tbl[pT[2*i]-'A']; 
		int b = tbl[pT[2*i+1]-'A'];
		if(a<0 || b<0) return;
		pB[i] = BYTE((b<<4) | a);
	}
}

void BBB1(BYTE* pdata1,BYTE* pdata2, int size) //convert
{
	BYTE tbl1[] = 
	{
		72, 223, 226,  87,  68, 175, 158,  23,  32, 191, 250, 215,  92, 143, 118,  24, 
		120, 159, 146,  88, 244, 111, 206,  25,  80, 127, 170, 216,  12,  79, 166,  26, 
		168,  95,  66,  89, 164,  47, 254,  27, 128,  63,  90, 217, 188,  15, 214,  28, 
		218,  31, 242,  91,  84, 239,  46,  29, 176, 255,  10, 219, 108, 207,   6,  30, 
		8, 224, 162,  93,   4, 177,  94,  33, 225, 192, 186, 220,  34, 144,  54,  35, 
		56, 160,  82,  96, 180, 112, 142,  36,  16, 129, 106, 221, 204,  81, 102,  37, 
		104,  97,   2,  98, 100,  48, 190,  38,  64,  65,  39, 222, 124,  17, 150,  40, 
		152,  41, 178,  99,  20, 240, 238,  42, 113,   0, 202, 227,  44, 208, 198,  43, 
		200, 101, 103,  49, 193,  45,  67,  69,  50, 228, 125,  18, 151,  51, 153,  52, 
		179, 105,  21, 241, 243,  53, 114,   1, 203, 229,  55, 209, 199,  57, 201, 230, 
		107, 109, 196, 181,  58,  59, 161, 194, 122, 231, 232, 145, 246,  60, 248, 163, 
		19, 110, 116, 115,  78,  61, 210, 130,  62, 233, 140,  83,  70,  71,  73, 117, 
		195, 119,  74,  75, 126,  76,   3,  77, 234, 235,  85,  22,  86, 121, 123, 131, 
		132, 133, 212, 245, 174, 134, 135,   5, 138, 236, 237, 211, 136, 137, 139, 247, 
		141, 147, 148, 182, 249, 149, 154, 197, 155, 251, 156, 157, 183, 165, 184, 167, 
		213, 169, 171, 172,  14, 173, 185, 187, 252, 253, 189, 205,   7,   9,  11,  13 } ;
	int i;
	for(i=0;i<size;i++)
		pdata2[i] = tbl1[pdata1[i]];
}
void BBB2(BYTE* pdata1,BYTE* pdata2, int size) //reverse convert
{
	BYTE tbl2[] = 
	{
		121, 151,  98, 198,  68, 215,  62, 252,  64, 253,  58, 254,  28, 255, 244,  45,
		88, 109, 139, 176, 116, 146, 203,   7,  15,  23,  31,  39,  47,  55,  63,  49,
		8,  71,  76,  79,  87,  95, 103, 106, 111, 113, 119, 127, 124, 133,  54,  37, 
		101, 131, 136, 141, 143, 149,  78, 154,  80, 157, 164, 165, 173, 181, 184,  41,
		104, 105,  34, 134,   4, 135, 188, 189,   0, 190, 194, 195, 197, 199, 180,  29,
		24,  93,  82, 187,  52, 202, 204,   3,  19,  35,  42,  51,  12,  67,  70,  33,
		83,  97,  99, 115, 100, 129,  94, 130,  96, 145,  90, 160,  60, 161, 177,  21,
		85, 120, 150, 179, 178, 191,  14, 193,  16, 205, 168, 206, 108, 138, 196,  25,
		40,  89, 183, 207, 208, 209, 213, 214, 220, 221, 216, 222, 186, 224,  86,  13, 
		77, 171,  18, 225, 226, 229, 110, 140, 112, 142, 230, 232, 234, 235,   6,  17,
		81, 166,  66, 175,  36, 237,  30, 239,  32, 241,  26, 242, 243, 245, 212,   5,
		56,  69, 114, 144,  84, 163, 227, 236, 238, 246,  74, 247,  44, 250, 102,   9,
		73, 132, 167, 192, 162, 231, 126, 156, 128, 158, 122, 152,  92, 251,  22,  61,
		125, 155, 182, 219, 210, 240,  46,  11,  27,  43,  48,  59,  75,  91, 107,   1, 
		65,  72,   2, 123, 137, 153, 159, 169, 170, 185, 200, 201, 217, 218, 118,  53,
		117, 147,  50, 148,  20, 211, 172, 223, 174, 228,  10, 233, 248, 249,  38,  57 };
	int i;
	for(i=0;i<size;i++)
		pdata2[i] = tbl2[pdata1[i]];
}
void Mix1(BYTE* key,BYTE* key1,int size,int from)
{
	int i;
	BYTE cur = 23;
	for(i = 0; i < size ; i ++)
	{
		if (i == 0)
		{
			key1[(i+from)%size] = key[(i + from) % size] ^ cur;
		}
		else
		{
			key1[(i+from)%size] = key1[(i + from + size - 1) % size] ^ key[(i+from)%size];
		}
		
	}
}
void Mix2(BYTE* key,BYTE* key1,int size,int from)
{
	int i;
	BYTE cur = 23;
	for(i = size - 1; i >= 0; i --)
	{
		if (i == 0)
		{
			key1[(i+from)%size] = key[(i + from) % size] ^ cur;
		}
		else
		{
			key1[(i+from)%size] = key[(i + from) % size] ^ key[(i+from+size-1)%size];
		}
	}
}
void Encrypt(char* packagename,char* platform,int year,int month,int date,char* encryptResult)
{
	BYTE k1[200],k2[200];
	sprintf((char*)k1,"%s-%s-%d-%d-%d-%s-%s-%d-%d-%d",packagename,platform,year,month,date,packagename,platform,year,month,date);

	
	int sz = int(strlen((char*)k1));
	BBB1(k1,k2,sz);


	int i;
	for(i = 0; i < 160; i ++)
	{
		if(i % 2 == 0)
		{
			Mix1(k2,k1,sz,i);
		}
		else
		{
			Mix1(k1,k2,sz,i);
		}
	}
	B2T(k2,sz,(BYTE*)encryptResult);
}
bool Decrypt(char* encryptedResult,char* packagename,char* platform,int &year,int &month,int &date)
{
	BYTE k1[200],k2[200];
	int sz = int(strlen(encryptedResult));
	T2B(encryptedResult,sz,k1);
	sz = sz / 2;
	int i;
	
	for(i = 159; i >= 0; i --)
	{
		if(i % 2 == 0)
		{
			Mix2(k2,k1,sz,i);
		}
		else
		{
			Mix2(k1,k2,sz,i);
		}
	}
	
	BBB2(k1,k2,sz);

	i = 0;
	// Returns first token 
    char *token = strtok((char*)k2, "-");
   
    // Keep printing tokens while one of the
    // delimiters present in str[].
    while (token != NULL)
    {
        if(i == 0)
		{
			strncpy(packagename,token,100);
		}
		else if(i == 1)
		{
			strncpy(platform,token,100);
		}
		else if(i == 2)
		{
			year = atoi(token);
		}
		else if(i == 3)
		{
			month = atoi(token);
		}
		else if(i == 4)
		{
			date = atoi(token);
		}
        token = strtok(NULL, "-");
		i = i + 1;
    }
	if (i > 4)
	{
		return true;
	}
	return false;
}


#endif // __SECURITY_HEADER__
