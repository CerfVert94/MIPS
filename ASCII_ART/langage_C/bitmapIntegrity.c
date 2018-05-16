/*
*******************************************
*Auteur : FAYE Mohamet Cherif  / KO Roqyun*
*******************************************/
#include<stdio.h>
#include<string.h>
#include<malloc.h>
#include"bitmap.h"
//#define ASCII_COLOR "@B%#KWQYuf([+!,."
//#define ASCII_COLOR "@8$kqOJznt([>;^."


//Librer l'espace de mémoire pour bitmapImage
void freeBitmapImage(char** bmImage, int biHeight, int nullLines)
{
	int line;
	if(!bmImage) {
		fputs("Pas d'espace mémoire alloué (Niveau 1).", stderr);
	}
	for(line = biHeight - 1; line >= nullLines; line--) {
		if(!bmImage[line]) {
			fputs("Pas d'espace mémoire alloué (Niveau 2).", stderr);
		}
		free(bmImage[line]);
	}
	free(bmImage);
}

bool isFileHeaderValid(struct bitmapFileHeader bfHeader)
{
	if(bfHeader.bfType != 0x4D42) {
		fputs("L'image n'est pas bitmap.\n", stderr);
		return false;
	}
	if(bfHeader.bfSize <= (SIZE_FILE_HEADER + SIZE_BITMAP_INFO)) {
		fputs("La taille de l'entête est invalide.\n", stderr);
		return false;
	}
	return true;
}

bool isInfoHeaderValid(struct bitmapInfoHeader bmiHeader)
{
	if(bmiHeader.biWidth <= 0 || bmiHeader.biHeight <= 0) {
		fputs("La taille de l'image n'est pas lisible.\n", stderr);
		return false;
	}
	if(bmiHeader.biCompression != BI_RGB) {
		fputs("Le format compressé n'est pas supporté.\n", stderr);
		return false;
	}
	if(bmiHeader.biPlanes != BIPLANE_CONSTANT) {
		fputs("Bitplane supérieur à 1 n'est pas supporté.\n", stderr);
		return false;
	}
	if(bmiHeader.biBitCount != FOUR_BPP)	{
		fputs("Veuillez choisir un bitmap image de 16 couleurs.\n", stderr);
		return false;
	}
	return true;
}






