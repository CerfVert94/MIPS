/*
*******************************************
*Auteur : FAYE Mohamet Cherif  / KO Roqyun*
*******************************************/
#include<stdbool.h>


#ifndef _STRUCT_SIZE_
#define _STRUCT_SIZE_

#define SIZE_FILE_HEADER	14
#define SIZE_INFO_HEADER	sizeof(struct bitmapInfoHeader)
#define SIZE_BITMAP_INFO	sizeof(struct bitmapInfo)
#endif

#ifndef _BITMAP_INFO_
#define POSITION_BITMAP_DATA   	0x76
#define RESERVED_VALUE		    0x00
#define BIPLANE_CONSTANT	    0x01
#define	FOUR_BPP		        0x04
#define LOWER_4BIT_MASK	    	0x0F
#define UPPER_4BIT_MASK	    	0xF0
#define PALETTE_SIZE		    0X10
#define GRAYSCALE               "$@B%8&WM#*oahkbdpqwmZO0QLCJUYXzcvunxrjft/\\|()1{}[]?-_+~<>i!lI;:,\"^`\'. "
#define GRAYSCALE_LENGTH        70
#endif
/*
Référencé de https://msdn.microsoft.com/en-us/library/dd183374.aspx
*/


struct bitmapFileHeader{		// 14 octets; Une structure qui contient l'entete du fichier bitmap (16 Octets en vrai)
	unsigned short bfType;		//  2 Octets; La signature du fichier. Fixée à "BM".
	unsigned int bfSize;		//  4 Octets; La taille d'un bitmap en octet.
	unsigned short bfReserved1;	//  2 Octets; Fixé à 0
	unsigned short bfReserved2;	//  2 Octets; Idem.
	unsigned int bfOffBits;		//  4 OCtets; La position du début de données de l'image. Fixé à 118 (14 + 104 octets) pour cette programme.
};

/*
Référencé de https://msdn.microsoft.com/en-us/library/dd183376.aspx
*/
struct bitmapInfoHeader {		// 40 Octets; Une structure qui contient l'information de l'entête du bitmap.
	unsigned int biSize;		//  4 Octets; La taille de cette structure
	int  biWidth;			//  4 Octets; Le largeur du bitamp en pixel
	int  biHeight;			//  4 Octets; Le hauteur du bitmap en pixel
	unsigned short  biPlanes;	//  2 Octets; Le plan du image : fixé à 1
	unsigned short  biBitCount;	//  2 Octets; Bits per pixel (bpp). Cette programme ne veut que 4 bpp comme valeur.
	unsigned int biCompression;	//  4 Octets; Le type de compression. Expliquer en détail en bas.
	unsigned int biSizeImage;	//  4 Octets; La taille de l'image en octet.
	int biXPelsPerMeter;		//  4 Octets; La résolution horizontale (Pixels-per-meter)
	int biYPelsPerMeter;		//  4 Octets; La résolution verticale (IDEM)
	unsigned int biClrUsed;		//  4 Octets; Le nombre de couleurs indexées dans la palette utilisées. 0 pour toutes les couleurs indexées.
	unsigned int biClrImportant;	//  4 Octets; Le nombre de couleurs indexées essentielles pour afficher le bitmap.
};
#ifndef _BI_COMPRESSION_TYPE_
#define _BI_COMPRESSION_TYPE_

#define BI_RGB		0x00		// Format non-compressé
#define BI_RLE8		0x01		// Format RLE 8 bpp 		  (Non utilisé pour cette programme)
#define BI_RLE4 	0x02		// Format RLE 4 bpp		  (Non utilisé pour cette programme)
#define BI_BITFIELDS	0x03		// Format avec masques.(16/32bpp) (Non utilisé pour cette programme)
#define BI_JPEG		0x04		// Format JPG/JPEG 		  (Non utilisé pour cette programme)
#define BI_PNG		0x05		// Format PNG			  (Non utilisé pour cette programme)

#endif


/*
Référencé de https://msdn.microsoft.com/en-us/library/dd162938.aspx.
*/
struct RGBSQUAD {			// 4 Octets; Une structure qui contient l'information de l'intensité d'une couleur dans un pixel.
	unsigned char rgbBlue;		// 1 Octet;  L'intensité du bleu.
	unsigned char rgbGreen;		// 1 Octet;  L'intensité du vert.
	unsigned char rgbRed;		// 1 Octet;  L'intensité du rouge.
	unsigned char rgbReserved;	// 1 Octet;  Fixé à 0.
};

/*
Référencé de https://msdn.microsoft.com/en-us/library/dd183375.aspx
*/
struct bitmapInfo { 				// 104 Octets; Une structure qui définit les dimension et l'information des colueurs pour le bitmap.
	struct bitmapInfoHeader bmiHeader;	// 40 Octets;
	struct RGBSQUAD         bmiColors[16];	// 64 Octets; Une palette de 16 couleurs pour 4bpp bitmap. 2^16.
};



/* * * * * * * *
 * bitmapIO.c  *
 * * * * * * * */
 
//
bool 	readBitmapFile(FILE *file);
char**	decodeBitmapImage(FILE *file, int biWidth, int biHeight);

//Lire les entetes.
struct bitmapInfo	readBitmapInfo(FILE *file);
struct bitmapFileHeader	readFileHeader(FILE *file);
struct bitmapInfoHeader	readBitmapInfoHeader(FILE *file);

//Lire la palette
struct RGBSQUAD		readRGBSQUAD(FILE *file);
struct RGBSQUAD*	readPalette(FILE *file);
void printImage(struct RGBSQUAD palette[],char **bmImage, struct bitmapInfo bmi, int blockWidth, int blockHeight);

/* * * * * * * * *
 * bitmapCalc.c  *
 * * * * * * * * */
char *determineBrightness(struct RGBSQUAD palette[]);
int densityIndexOfBlock(struct RGBSQUAD palette[], char **bmImage, int biWidth, int biHeight, int blockWidth, int blockHeight, int line, int column);
int ceiling(int x, int divider);

/* * * * * * * * * * *
 * bitmapIntegrity.c *
 * * * * * * * * * * */
void freeBitmapImage(char** bmImage, int biHeight, int nullLines);
bool isFileHeaderValid(struct bitmapFileHeader bfHeader);
bool isInfoHeaderValid(struct bitmapInfoHeader bmi);


