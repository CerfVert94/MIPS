/*
*******************************************
*Auteur : FAYE Mohamet Cherif  / KO Roqyun*
*******************************************/
#include<stdio.h>
#include<string.h>
#include<malloc.h>
#include"bitmap.h"


int ceiling(int x, int divider)
{
	int ceilingValue = 0;
	ceilingValue = (x / divider);
	if((x % divider) > 0) {
		ceilingValue += 1;
	}
	return ceilingValue;

}

int densityIndexOfBlock(struct RGBSQUAD palette[], char **bmImage, int biWidth, int biHeight, int blockWidth, int blockHeight, int line, int column)
{
	int index = 0;
	double avgBrightness = 0.0;
	double brightness,sumRGB;
	int i, j;

    if(column + blockWidth <= biWidth)
    {
        blockWidth = biWidth - column;
    }
    if(line + blockHeight <= biHeight)
    {
        blockHeight = biHeight - line;

    }
	for(i = line; i < line + blockHeight; i++) {
		for(j = column; j < column + blockWidth; j++) {

			index = bmImage[line][column];
			sumRGB = (palette[index].rgbRed + palette[index].rgbGreen + palette[index].rgbBlue);
            brightness = sumRGB / (3*255.0);
            //brightness = (palette[index].rgbRed * 0.2126 + palette[index].rgbGreen * 0.7152 + palette[index].rgbBlue * 0.0722)/255.0;
			avgBrightness += brightness;
		}
	}
	avgBrightness /= (double)(blockHeight * blockWidth);
	index = (GRAYSCALE_LENGTH - 1) * avgBrightness;
	return index;
}
