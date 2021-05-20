
	#define chA    0x41
	#define chB    0x42
	#define chC    0x43
	#define chD    0x44
	#define chE    0x45
	#define chF    0x46
	#define chG    0x47
	#define chH    0x48
	#define chI    0x49
	#define chJ    0x4A
	#define chK    0x4B
	#define chL    0x4C
	#define chM    0x4D
	#define chN    0x4E
	#define chO    0x4F
	#define chP    0x50
	#define chQ    0x51
	#define chR    0x52
	#define chS    0x53
	#define chT    0x54
	#define chU    0x55
	#define chV    0x56
	#define chW    0x57
	#define chX    0x58
	#define chY    0x59
	#define chZ    0x5A

	#define cha    0x61
	#define chb    0x62
	#define chc    0x63
	#define chd    0x64
	#define che    0x65
	#define chf    0x66
	#define chg    0x67
	#define chh    0x68
	#define chi    0x69
	#define chj    0x6A
	#define chk    0x6B
	#define chl    0x6C
	#define chm    0x6D
	#define chn    0x6E
	#define cho    0x6F
	#define chp    0x70
	#define chq    0x71
	#define chr    0x72
	#define chs    0x73
	#define cht    0x74
	#define chu    0x75
	#define chv    0x76
	#define chw    0x77
	#define chx    0x78
	#define chy    0x79
	#define chz    0x7A

	#define ch0    0x30
	#define ch1    0x31
	#define ch2    0x32
	#define ch3    0x33
	#define ch4    0x34
	#define ch5    0x35
	#define ch6    0x36
	#define ch7    0x37
	#define ch8    0x38
	#define ch9    0x39

 
#define LineFeed	0x0a0d

#define UNDERLINE		0x005F//_
#define MINUS			0x002D//-
#define EQUAL			0x003D//=
#define TILDA			0x007E//~

#define DEL_KEY				0x2e
#define BS_KEY				0x08

#define SPACE_NO			0
#define SPACE_YES			1
#define SPACE_LN			2
#define SPACE_FUZZY			4
#define SPACE_DOT			8

#define NONJUSTIFY			0//cch
#define JUSTIFY				1//cch

#define chCOMMA				0x2C	//","
#define chMINUS				0x2D	//"-"
#define chDOT				0x2E	//"."
#define chUNDERLINE			0x5F	//"_"
#define	chOPENSYMBOL		0x300A	//CKOREANNum+1//1666
#define chQUERY				0x003F	//"?"

#define chJaum0				0x3147
#define chCLOSEBRACKET		0x29//)
#define chCLOSEBRACKET3		0x5D//]
#define chCLOSEBRACKET4		0x7D//}
#define ID_JAUMG	(-1)
#define ID_JAUMH	(-1)
#define chCIRCLE1	0x2460//(CKOREANNum + 105)
#define chCIRCLE9	0x2468//(CKOREANNum + 113)
#define ID_CIRCLEG	(-1)
#define ID_CIRCLEH	(-1)
#define chCIRCLE_G	0x3260	//Circle gu
#define chCIRCLE_H	0x326D	//Circle hu
#define ID_CIRCLEGA	(-1)
#define ID_CIRCLEHA	(-1)
#define CIRCLE_GA	0x326E	
#define CIRCLE_HA	0x327B
#define chTRIANGLE	0x25B3//(CKOREANNum + 95)
#define ID_EQUAL_SIDERECT	(-1)
#define ID_DEGREEK (-1)	
#define ID_DOLLAR1 (-1)
#define ID_DOLLAR2 (-1)
#define ID_DOLLAR3 (-1)

// #define SMB_DOLLAR1_CHBUNI 0xEB66
// #define SMB_DOLLAR2_CHBUNI 0xEB68
// #define SMB_DOLLAR3_CHBUNI 0xEB67

#define SMB_ACCORDING		0x2234//ADA2
#define SMB_BECAUSE			0x2235//BDA2

#define COL		0xCF5C//0xbbbf//¿»
#define CUL		0xCFE8//c4bf//¿Ä
#define RYOL	0xB8D4//ecb5//µì
#define ROM		0xB86C//e5b5//µå
#define ROP		0xB876//e9b5//µé
#define RUM		0xB8F8//f5b5//µõ 
#define BUL		0xBD88//A6B9//¹¦ 
#define RYUL	0xB960//fCB5//µü 
#define CNL		0xD074//D0BF//¿Ð 

#define YUN		0xC724//b3cb//Ë³ 
#define YUL		0xC728//b4cb//Ë´ 
#define YUM		0xC730//b5cb//Ëµ 
#define YUB		0xC731//b6cb//Ë¶
#define UOAL	0xC648//B2CC//Ì²

#define OL		0xC62C//0xf2ca//Êò
#define UL		0xC6B8//0xaacb//Ëª
#define UNL		0xC744//0xbecb//Ë¾

#define PA		0xD30C//c4c1//ÁÄ
#define GOA		0xACFC//e1b1//±á

#define ROL		0xB864//e4b5//µä
#define RUL		0xB8F0//f4b5//µô
#define RNL		0xB97C//a6b6//¶¦

#define NUN		0xB208//e6b2//²æ
#define	NON		0xB17C//d3b2//²Ó
#define	NN		0xB294//f7b2//²÷

#define TL		0xD2C0//E6C0 //Àæ
#define TUL		0xD234//D8C0 //ÀØ 
#define TOL		0xD1A8//CEC0 //ÀÎ

#define DOL		0xB3CC//AEB4 //´®
#define DUL		0xB458//BBB4 //´»
#define DL		0xB4E4//C9B4 //´É

#define ON		0xC628//F1CA //Êñ
#define UUN		0xC6B4//A9CB //Ë©
#define UN		0xC740//BCCB //Ë¼

#define OI		0xC774//CBCB //ËË
#define AE		0xC5D0//E6CB //Ëæ
#define GE		0xAC8C//C2B1 //±Â

#define	MUR		0xBB3C//cfb7//·Ï
#define	MOR		0xBAB0//bfb7//·¿

#define DA		0xB2E4//deb3//³Þ

#define UI		0xC758//A9CC //Ì©
#define HAN		0xD55C//D9C2 //ÂÙ
#define EE		0xC5D0//E6CB //Ëæ
#define KIM		0xAE40//AEB1
#define IL		0xC77C//CECB
#define SUNG	0xC131//C2BA
#define JONG	0xC815//B3BC
#define SUK		0xC219//E4B4

#define DIGIT_0				0x0030//B0A3
#define DIGIT_1				0x0031//B1A3
#define DIGIT_2				0x0032//B2A3
#define DIGIT_3				0x0033//B3A3
#define DIGIT_4				0x0034//B4A3
#define DIGIT_5				0x0035//B5A3
#define DIGIT_6				0x0036//B6A3
#define DIGIT_7				0x0037//B7A3
#define DIGIT_8				0x0038//B8A3
#define DIGIT_9				0x0039//B9A3

#define SMB_DEGREE			0x00B0//A1A8//¨¡
#define SMB_DEGREEC			0x2103//A4A8//¨¤			
#define SMB_DEGREEF			0x2109//A5A8//¨¥
#define SMB_DEGREEK			0xEB34 //chambuk ksd2013 ?

#define SMB_PERCENT			0xFF05//ACA8//%
#define SMB_PERMILA			0x2030//ADA8//¨­
#define SMB_CC				0x33C4//AFA8//¨¯

#define SMB_NANOMETER		0x339A//BFA8
#define SMB_MICROMETER		0x339B//C0A8
#define SMB_MILIMETER		0x339C//B5A8
#define SMB_CENTIMETER		0x339D//B2A8
#define SMB_KILOMETER		0x339E//BBA8
#define SMB_DESIMETER		0x3377//B8A8

#define SMB_MICROGRAM		0x338D//C3A8
#define SMB_MILIGRAM		0x338E//C4A8//ó®òç??
#define SMB_KILOGRAM		0x338F//C5A8//?ò¿??


#define SMB_PIKOWATU		0x33BA//D1A8
#define SMB_NANOWATU		0x33BB//D2A8
#define SMB_MICROWATU		0x33BC//D3A8//
#define SMB_MILIWATU		0x33BD//D4A8//ó®òçüÆ÷©
#define SMB_KILOWATU		0x33BE//D5A8//?ò¿üÆ÷©
#define SMB_MEGAWATU		0x33BF//D6A8//óÅ?üÆ÷©

#define SMB_PIKOCHO			0x33B0//E1A8//ps
#define SMB_NANOCHO			0x33B1//E2A8//ns
#define SMB_MICROCHO		0x33B2//E3A8//us
#define SMB_MILICHO			0x33B3//E4A8//ms

#define SMB_SQUARE			0x33A1//B0A8//?óóóÅ?
#define SMB_CENTISQUARE		0x33A0//B3A8//?óó??óÅ?
#define SMB_MILISQUARE		0x339F//B6A8//?óóó®òçóÅ?
#define SMB_KILOSQUARE		0x33A2//BCA8//?óó?ò¿óÅ?
#define SMB_DESISQUARE		0x3378//B9A8

#define SMB_MILICUBIC		0x33A3//B7A8//òìóóó®òçóÅ?
#define SMB_CENTICUBIC		0x33A4//B4A8//òìóó??óÅ?
#define SMB_CUBIC			0x33A5//B1A8//òìóóóÅ?
#define SMB_KILOCUBIC		0x33A6//BDA8//òìóó?ò¿óÅ?
#define SMB_DESICUBIC		0x3379//BAA8

#define SMB_PIKOVOLT		0x33B4//C6A8
#define SMB_NANOVOLT		0x33B5//C7A8//ðé??÷©
#define SMB_MICROVOLT		0x33B6//C8A8//
#define SMB_MILIVOLT		0x33B7//C9A8//ó®òç?÷©
#define SMB_KILOVOLT		0x33B8//CAA8//?ò¿?÷©
#define SMB_MEGAVOLT		0x33B9//CBA8//óÅ??÷©


#define SMB_PIKOAMPEIA		0x3380//CCA8//
#define SMB_NANOAMPEIA		0x3381//CDA8//ðé?ûÞ?ûÕ
#define SMB_MICROAMPEIA		0x3382//CEA8
#define SMB_MILIAMPEIA		0x3383//CFA8//ó®òçûÞ?ûÕ
#define SMB_KILOAMPEIA		0x3384//D0A8//?ò¿ûÞ?ûÕ

#define SMB_KILOOMEGA		0x33C0//D8A8//?ò¿?
#define SMB_MEGAOMEGA		0x33C1//D9A8//óÅ??
#define SMB_OMEGA			0x2126//D7A8//?

#define SMB_HERZ			0x3390//DAA8//ø×òÜ?
#define SMB_KILOHERZ		0x3391//DBA8//?ò¿ø×òÜû£
#define SMB_MEGAHERZ		0x3392//DCA8//óÅ?ø×òÜû£
#define SMB_GIGAHERZ		0x3393//DDA8//??ø×òÜû£
#define SMB_TERAHERZ		0x3394//DEA8//÷Ä?ø×òÜû£

#define SMB_LETER			0x2113//ECA8//òç?
#define SMB_MICROLETER		0x3395//EDA8
#define SMB_MILILETER		0x3396//EEA8//ó®òçòç?
#define SMB_DESILETER		0x3397//EFA8//??òç?
#define SMB_KILOLETER		0x3398//F0A8//?ò¿òç?

#define SMB_pF				0x338A//E5A8
#define SMB_nF				0x338B//E6A8
#define SMB_MICROF			0x338C//E7A8

#define SMB_PASCAL			0x33A9//E8A8
#define SMB_KILOPASCAL		0x33AA//E9A8
#define SMB_MEGAPASCAL		0x33AB//EAA8
#define SMB_GIGAPASCAL		0x33AC//EBA8

#define SMB_MICRO			0x03BC//CCA6//ƒÊ

#define SMB_TWODOT			0x2025//ABA1
#define SMB_THREEDOT		0x2026//ACA1

#define SMB_COMMA			0x002C//,
#define SMB_DOT				0x002E//.
#define SMB_COLON			0x003A//;
#define SMB_EQUAL			0x003D//=
#define SMB_MINUS			0x002D//-
#define SMB_UNDERLINE		0x005F//_
#define SMB_TILDA			0x007E//~
#define SMB_EXCLA_MARK		0x0021//!


//BRACKET
#define SMB_OPENPOINTBRACKET		0x2018//open '
#define SMB_CLOSEPOINTBRACKET		0x2019//close '
#define SMB_OPENTWOPOINTBRACKET		0x201C//open "
#define SMB_CLOSETWOPOINTBRACKET	0x201D//close "
#define SMB_OPENBRACKET				0x300A//D4A1	// "¡Ô"
#define SMB_CLOSEBRACKET			0x300B//D5A1	// "¡Õ"
#define SMB_OPENROUND_BRACKET		0x0028//E6A2	// "("
#define SMB_CLOSEROUND_BRACKET		0x0029//E6A2	// ")"
#define SMB_OPENSQUARE_BRACKET		0x005B//E6A2	// "["
#define SMB_CLOSESQUARE_BRACKET		0x005D//E6A2	// "]"
#define SMB_TRIANGLE				0x25B3//E6A2	// "¢æ"

#define SMB_gal				0x33FF//F1A8	
#define SMB_cal				0x3388//F2A8
#define SMB_kcal			0x3389//F3A8
#define SMB_rad				0x33AD//F4A8
#define SMB_Hg				0x32CC//F7A8					
#define SMB_Wb				0x33DD//F8A8
#define SMB_dB				0x33C8//F9A8
#define SMB_erg				0x32CD//FAA8
#define SMB_eV				0x32CE//FBA8
#define SMB_mol				0x33D6//FCA8
#define SMB_ha				0x33CA//FEA8

#define SMB_A				0x41//C1A3
#define SMB_B				0x42//C2A3
#define SMB_C				0x43//C3A3
#define SMB_D				0x44//C4A3
#define SMB_E				0x45//C5A3
#define SMB_F				0x46//C6A3
#define SMB_G				0x47//C7A3
#define SMB_H				0x48//C8A3
#define SMB_I				0x49//C9A3
#define SMB_J				0x4A//CAA3
#define SMB_K				0x4B//CBA3
#define SMB_L				0x4C//CCA3
#define SMB_M				0x4D//CDA3
#define SMB_N				0x4E//CEA3
#define SMB_O				0x4F//CFA3
#define SMB_P				0x50//D0A3
#define SMB_Q				0x51//D1A3
#define SMB_R				0x52//D2A3
#define SMB_S				0x53//D3A3
#define SMB_T				0x54//D4A3
#define SMB_U				0x55//D5A3
#define SMB_V				0x56//D6A3
#define SMB_W				0x57//D7A3
#define SMB_X				0x58//D8A3
#define SMB_Y				0x59//D9A3
#define SMB_Z				0x5A//DAA3

#define SMB_a				0x61//E1A3
#define SMB_b				0x62//E2A3
#define SMB_c				0x63//E3A3
#define SMB_d				0x64//E4A3
#define SMB_e				0x65//E5A3
#define SMB_f				0x66//E6A3
#define SMB_g				0x67//E7A3
#define SMB_h				0x68//E8A3
#define SMB_i				0x69//E9A3
#define SMB_j				0x6A//EAA3
#define SMB_k				0x6B//EBA3
#define SMB_l				0x6C//ECA3
#define SMB_m				0x6D//EDA3
#define SMB_n				0x6E//EEA3
#define SMB_o				0x6F//EFA3
#define SMB_p				0x70//F0A3
#define SMB_q				0x71//F1A3
#define SMB_r				0x72//F2A3
#define SMB_s				0x73//F3A3
#define SMB_t				0x74//F4A3
#define SMB_u				0x75//F5A3
#define SMB_v				0x76//F6A3
#define SMB_w				0x77//F7A3
#define SMB_x				0x78//F8A3
#define SMB_y				0x79//F9A3
#define SMB_z				0x7A//FAA3

#define SMB_OPENPOINTBRACKET		0x2018//C6A1
#define SMB_CLOSEPOINTBRACKET		0x2019//C7A1
#define SMB_OPENTWOPOINTBRACKET		0x201C//C8A1
#define SMB_CLOSETWOPOINTBRACKET	0x201D//C9A1

#define SMB_DOUBLESPCOMMA	0x22
#define SMB_CENTERDOT		0x00B7//A6A1
#define SMB_NOT				0xFFE2//D1A2
#define JAUM_GG		0x3132//AFA4//üò
#define JAUM_DD		0x3138//B0A4//üó
#define JAUM_BB		0x3143//B1A4//üô
#define JAUM_SS		0x3146//B2A4//üõ
#define JAUM_ZZ		0x3149//B3A4//üö
#define JAUM_GS		0x3133//C9A4//üåüë
#define JAUM_NZ		0x3135//CAA4//üæüì
#define JAUM_NH		0x3136//CBA4//üæüñ
#define JAUM_LG		0x313A//CCA4//üèüå
#define JAUM_LM		0x313B//CDA4//üèüé
#define JAUM_LB		0x313C//CEA4//üèüê
#define JAUM_LS		0x313D//CFA4//üèüë
#define JAUM_LT		0x313E//D0A4//üèüï
#define JAUM_LP		0x313F//D1A4//üèüð
#define JAUM_LH		0x3140//D2A4//üèüñ
#define JAUM_BS		0x3144//D3A4//üêüë
#define JAUM_G			0x3131//A1A4//üå
#define JAUM_N			0x3134//A2A4//üæ
#define JAUM_D			0x3137//A3A4//üç
#define JAUM_L			0x3139//A4A4//üè
#define JAUM_M			0x3141//A5A4//üé
#define JAUM_B			0x3142//A6A4//üê
#define JAUM_S			0x3145//A7A4//üë
#define JAUM_O			0x3147//A8A4//ü÷
#define JAUM_Z			0x3148//A9A4//üì
#define JAUM_CH			0x314A//AAA4//üí
#define JAUM_K			0x314B//ABA4//üî
#define JAUM_T			0x314C//ACA4//üï
#define JAUM_P			0x314D//ADA4//üð
#define JAUM_H			0x314E//AEA4//üñ

#define MOUM_A		0x314F//B4A4		
#define MOUM_U		0x315C//BAA4
#define MOUM_O		0x3157//B8A4
#define MOUM_I			0x3163//BDA4
#define MOUM_YE			0x3156//C1A4
#define MOUM_AE			0x3150//BEA4
#define MOUM_WE			0x315E//C8A4
#define SMB_SUJIK		0x22A5//B1A2

#define ROMA_ONE		0x2160//E1A6
#define ROMA_TWO		0x2161//E2A6//II
#define ROMA_THREE		0x2162//E3A6//III
#define ROMA_FOUR		0x2163//E4A6//IV
#define ROMA_SIX		0x2165//E6A6//VI
#define ROMA_SEVEN		0x2166//E7A6//VII
#define ROMA_EIGHT		0x2167//E8A6//VIII
#define ROMA_NINE		0x2168//E9A6//IX

#define ROMA_SMALLTWO	0x2171//F2A6//II
#define ROMA_SMALLTHREE	0x2172//F3A6//III
#define ROMA_SMALLFOUR	0x2173//F4A6//IV
#define ROMA_SMALLSIX	0x2175//F6A6//VI
#define ROMA_SMALLSEVEN	0x2176//F7A6//VII
#define ROMA_SMALLEIGHT	0x2177//F8A6//VIII
#define ROMA_SMALLNINE	0x2178//F9A6//IX

#define SHAPE_CO		0x33C7//DBAC//Co.
#define SHAPE_LTD		0x32CF//DCAC//LTD
#define SHAPE_PTE		0x3250//DDAC//PTE
#define SHAPE_TEL		0x2121//DEAC//TEL
#define SHAPE_FAX		0x213B//DFAC//FAX

#define SHAPE_BLACKBIGCIRCLE	0x25CF//E0A2
#define SHAPE_BLACKBIGRECT		0x25A0//E5A2
#define SMB_INFINITE			0x221E//ACA2
#define MODIFY_BYRATE		0x01 //?????òØü£ ùÍ?ôÊ
#define MODIFY_BYUNIT		0x02 //ñÄü¼???ó§ò¿ ?ó»? ??
#define MODIFY_FORCESPLIT	0x04 //?õÀ? ?òç
#define MODIFY_FORCEMERGE	0x08 //?õÀ? ??


#define CODE_OPENBRACKET	0x300A//D4A1	// "¡Ô"
#define CODE_CLOSEBRACKET	0x300B//D5A1	// "¡Õ"
#define CODE_TRIANGLE		0x25B3//E6A2	// "¢æ"

#define CODE_NON_TAIL_U		0xC73C//BACB	// "Ëº"
#define CODE_SO				0xC18C//CFBA	// "ºÏ"
#define CODE_YO				0xC694//FDCA	// "Êý"
#define CODE_OO				0xC624//EFCA	// "Êï"



#define CODE_NI				0xB2C8//A3B3	// "³£"
#define CODE_GEISS			0xACA0//CAB1	// "±Ê"
#define CODE_HAESS			0xD588//D5C3	// "ÃÕ"
#define CODE_OUSS			0xC5C8//DDCA	// "ÊÝ"
#define CODE_ISS			0xC788//D8CB	// "ËØ"
#define CODE_YUSS			0xC600//EECA	// "Êî"
#define CODE_ZUSS			0xC84C//BEBC	// "¼¾"
#define CODE_SOS			0xC130//    	// "ºÅ"
#define CODE_AS				0xC558//    	// "Ê¾"
#define CODE_NAS			0xB0AC			//"²°"

#define CODE_OU				0xC5B4//CCCA	// "ÊÌ"
#define CODE_SEI			0xC138//BDBB	// "»½"
#define CODE_YEI			0xC608//EFCB	// "Ëï"

#define CODE_HA				0xD558//D7C2	// "Â×"
#define CODE_SI				0xC2DC//A4BB	// "»¤"
#define CODE_ZU				0xC8FC//D1BC	// "¼Ñ"
#define CODE_ZI				0xC9C0//E8BC	// "¼è"

#define SYM_R_SLASH			0x002F//B3A1	// "/"
#define SYM_L_SLASH			0x005C//B4A1	// "\"
#define SYM_R_UP_COMMA		0x00B4//BBA1	// "¡»"
#define SYM_L_UP_COMMA		0xFF40//BCA1	// "¡¼"
#define SYM_SIRCLE_DOT		0x3002//A3A1	// "¡£"
#define SYM_LOGIC_PRODUCT	0x2227//CFA2	// "¢Ï"
#define SYM_SQUARE			0xFF3E//BEA1	// "¡¾"
#define SYM_DOWN_SQUARE		0x02C7//BFA1	// "¡¿"
