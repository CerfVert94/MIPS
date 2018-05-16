/*
*******************************************
*Auteur : FAYE Mohamet Cherif  / KO Roqyun*
*******************************************/
#include<stdio.h>
#include<string.h>
#include<malloc.h>
#include"bitmap.h"
#define MAX_FILE_NAME 256
void printFileHeader(struct bitmapFileHeader bfHeader);
void printInfoHeader(struct bitmapInfoHeader bmiHeader);

bool readBitmapFile(FILE *file)
{
    int blockWidth, blockHeight, maxWidth;
	struct bitmapFileHeader bfHeader;
	struct bitmapInfo bmi;
	struct RGBSQUAD *palette;
	char **bmImage;
	int pos;
	if(!file) {
		fputs("Echec de l'ouverture du fichier.",stderr);
		return false;
	}

	bfHeader = readFileHeader(file);
	// Si 'File Header' est valide, alors on continue.
	if(!isFileHeaderValid(bfHeader)) {
		fputs("Echec de l'ouverture du fichier.",stderr);
		return false;
	}

	bmi.bmiHeader = readBitmapInfoHeader(file);
	//Si 'Information Header' est valide, alors on continue.
	if(!isInfoHeaderValid(bmi.bmiHeader)) {
		return false;
	}
    //Recopier la palette de l'image.
	palette = readPalette(file);
	if(!palette){
		return false;
	}
	memcpy(bmi.bmiColors,palette,sizeof(struct RGBSQUAD) * PALETTE_SIZE);

    puts("Le largeur maximum de l'image (La taille de caracteres)?");
    scanf("%d", &maxWidth);
    fgetc(stdin);
    if(maxWidth > bmi.bmiHeader.biWidth) {
            fputs("Le largeur maximum depasse le largeur de l'image.",stderr);
    }
    blockWidth = (int)((double)bmi.bmiHeader.biWidth / maxWidth);
    blockHeight = (int)(blockWidth * 1.5);

    printf("Bloc : %d x %d\n",blockWidth,blockHeight);


	//Sauter aux données de l'image.
	pos = ftell(file);
	if(pos != EOF) {
		pos = bfHeader.bfOffBits - pos;
	}
	fseek(file, pos, SEEK_CUR);

	//Lire l'image
	bmImage = decodeBitmapImage(file,bmi.bmiHeader.biWidth,bmi.bmiHeader.biHeight);
	//Afficher l'image en texte.
	printImage(palette,bmImage, bmi,blockWidth,blockHeight);

	//Librer les pointeurs
	freeBitmapImage(bmImage,bmi.bmiHeader.biHeight,0);
	free(palette);
	return true;
}

struct bitmapInfoHeader readBitmapInfoHeader(FILE *file)
{
	struct bitmapInfoHeader bmiHeader;
	fread(&bmiHeader, sizeof(struct bitmapInfoHeader), 1, file);
	printInfoHeader(bmiHeader);
	return bmiHeader;

}
struct RGBSQUAD readRGBSQUAD(FILE *file)
{
	struct RGBSQUAD color;
	fread(&color.rgbBlue, sizeof(struct RGBSQUAD), 1, file);
	printf("RGB(%u,%u,%u,%u)\n",color.rgbRed, color.rgbGreen, color.rgbBlue, color.rgbReserved);
	return color;

}

struct RGBSQUAD* readPalette(FILE *file)
{
	struct RGBSQUAD *palette = (struct RGBSQUAD*)malloc(sizeof(struct RGBSQUAD) * PALETTE_SIZE);
	int indexColor = 0;

	if (!palette)
		return NULL;
	for (indexColor = 0; indexColor < PALETTE_SIZE; indexColor++) {
		printf("bmiColors[%d] = ",indexColor);
		palette[indexColor] = readRGBSQUAD(file);
	}
	return palette;
}

char** decodeBitmapImage(FILE *file, int biWidth, int biHeight)
{
	int bytesPerLine, column, line, dataCount, dataImparity;
	char **bmImage, *data;
	unsigned short mask[2] = {UPPER_4BIT_MASK ,LOWER_4BIT_MASK};
	unsigned short shift[2] = {0x4, 0x0};

	bytesPerLine = (4 * ceiling(biWidth, 8));

	bmImage = (char **)malloc(sizeof(char *) * biHeight);
	data = (char *)malloc(sizeof(char) * bytesPerLine);

	if(!bmImage) {
		return NULL;
	}

	for(line = biHeight - 1; line >= 0; line--) { // L'image est inversé verticalement.
		bmImage[line] = (char*)malloc(sizeof(char) * biWidth);
		if(!bmImage) {
			freeBitmapImage(bmImage,biHeight,line);
			return NULL;
		}

		dataCount = 0;
		fread(data, bytesPerLine, 1, file);
		//Un octet contient 2 pixels
		for(column = 0; column < biWidth; column++) {
			/* Pour dataImparity = 0,  Lire les 4 bits MSB (most significant digits).
                                   1 = Lire les 4 bits LSB (least significant digits).*/
			dataImparity = column % 2;
			bmImage[line][column] = (data[dataCount] & mask[dataImparity]) >> shift[dataImparity];
			dataCount += dataImparity;
		}
	}
	free(data);
	return bmImage;
}

void printImage(struct RGBSQUAD palette[],char **bmImage, struct bitmapInfo bmi, int blockWidth, int blockHeight)
{
	int line, column, densityIndex, i;
	int biWidth = bmi.bmiHeader.biWidth;
	int biHeight = bmi.bmiHeader.biHeight;
	char asciiColor[] = GRAYSCALE;
    FILE *outputFile;
    char fileName[MAX_FILE_NAME];

    printf("Quel est le nom du fichier que vous voudriez sauvegarder le resultat?\n");
    fgets(fileName, MAX_FILE_NAME, stdin);

    i = 0;
    while(fileName[i++] != '\n');
    fileName[i - 1] = '\0';
    outputFile = fopen(fileName,"wb");

    if(!outputFile)
    {
        fputs("Echec de la creation du fichier.",stderr);
        return;
    }

    for (line = 0; line < biHeight; line += blockHeight) {
        for (column = 0; column < biWidth; column += blockWidth) {
            densityIndex = densityIndexOfBlock(palette,bmImage, biWidth, biHeight, blockWidth, blockHeight, line, column);
            putchar(asciiColor[densityIndex]);
            fputc(asciiColor[densityIndex],outputFile);
        }
        putchar('\r');
        putchar('\n');
        fputc('\r',outputFile);
        fputc('\n',outputFile);
    }
    fclose(outputFile);
}




struct bitmapFileHeader readFileHeader(FILE *file)
{
	struct bitmapFileHeader bfHeader;
	//Alignment ne permet pas de lire entierement la structure.
	fread(&bfHeader.bfType, sizeof(unsigned short), 1, file);
	fread(&bfHeader.bfSize, sizeof(unsigned int), 1, file);
	fread(&bfHeader.bfReserved1, sizeof(unsigned short), 1, file);
	fread(&bfHeader.bfReserved2, sizeof(unsigned short), 1, file);
	fread(&bfHeader.bfOffBits, sizeof(unsigned int), 1, file);
	printFileHeader(bfHeader);
	return bfHeader;
}


void printFileHeader(struct bitmapFileHeader bfHeader)
{
	printf("Type : %hX\n", bfHeader.bfType);
	printf("Size : %u\n", bfHeader.bfSize);
	printf("Reserved1 : %hu\n", bfHeader.bfReserved1);
	printf("Reserved2 : %hu\n", bfHeader.bfReserved2);
	printf("Offset : %u\n", bfHeader.bfOffBits);
}
void printInfoHeader(struct bitmapInfoHeader bmiHeader)
{
	printf("Header Size : %hu\n", bmiHeader.biSize);
	printf("Image Width : %u\n", bmiHeader.biWidth);
	printf("Image Height : %u\n", bmiHeader.biHeight);
	printf("Image Plane : %hu\n", bmiHeader.biPlanes);
	printf("BPP : %u\n", bmiHeader.biBitCount);
	printf("Compression Type : %u\n", bmiHeader.biCompression);
	printf("Image Size : %u bytes\n", bmiHeader.biSizeImage);
	printf("XPPM : %u\n", bmiHeader.biXPelsPerMeter);
	printf("YPPM : %u\n", bmiHeader.biYPelsPerMeter);
	printf("Colors Used : %u\n", bmiHeader.biClrUsed);
	printf("Important Colors : %u\n", bmiHeader.biClrImportant);
}
