/*
*******************************************
*Auteur : FAYE Mohamet Cherif  / KO Roqyun*
*******************************************/
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include"bitmap.h"

int main(int argc, char *argv[])
{
	FILE *file;
	char fileName[256] = "Test.bmp";

	if(argc <= 1) {
		fputs("./projet --chemin\n",stderr);
		fputs("Par defaut : chemin = ./Test.bmp\n",stderr);
	}
	else if(argc <= 2) {
    	strcpy(fileName,argv[1]);
	}
	else {
		fputs("Trop d'arguments.\n",stderr);
	}

	file = fopen(fileName,"rb");

	if(!file)
	{
		fputs("Echec de l'ouverture du fichier\n",stderr);
		return -1;
	}


	readBitmapFile(file);
	fclose(file);
	return 0;
}
