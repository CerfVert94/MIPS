.data
msg1 : .asciiz "Saisir le chemin pour votre image, svp:\n"
msg2 : .asciiz " est ouvert.\n"
msg3 : .asciiz " octets sont alloues pour l'image.\n"
msg4 : .asciiz "Le largeur maximum de l'image (La taille de caracteres)?\n"
msg5 : .asciiz "Le largeur maximum depasse le largeur de l'image.\n"
msg6 : .asciiz "Quel est le nom du fichier que vous voudriez sauvegarder le resultat?\n"
msg7 : .asciiz "Bloc : "
msg8 : .asciiz " x "
RetourChariot :.asciiz "\r"
NouvelleLigne :.asciiz "\n"
err : .asciiz "Erreur!!\n"
msg_info1 : .asciiz "bfType : "
msg_info2 : .asciiz "bfSize : "
msg_info3 : .asciiz "bfOffBits : "
msg_info4 : .asciiz "Width : "
msg_info5 : .asciiz "Height : "
msg_info6 : .asciiz "biBitCount : "
msg_info7 : .asciiz "biCompression : "
niveauxDeGris: .asciiz "$@B%8&WM#*oahkbdpqwmZO0QLCJUYXzcvunxrjft/\\|()1{}[]?-_+~<>i!lI;:,\"^`\'. "

output: .space 256
chemin: .space 256
ch : .byte 0
.align 2
fichier : .space 4
fichier_output : .space 4
bfHeader: .space 16
bmiHeader: .space 40
bmiColors: .space 64
sommeRGB: .word 0
image: .word 0
codage: .word 0
imageTaille: .word 0
.text
main:
	la $a0, msg1 			# 
	jal fncAfficherChaine		# printf("Saisir le chemin pour votre image, svp:\n");

	ori $v0, $zero, 8		# //Service 8 : fgets($a0, $a1, stdin)
	la $a0, chemin			# //...
	ori $a1, $zero, 256		# //...
	syscall				# fgets(&chemin[0], 256, stdin);

	ori $t0, $zero, '\n'		# //Enlever une caratere de nouvelle ligne.
chercherNouvelleLigne1:			# while (chemin[i] == '\n') { 
	lb $t1, 0($a0)			# 	
	beq $t1, $t0, suite1		# 	 	
	addi $a0, $a0, 1		# 	i++;
	j chercherNouvelleLigne1	# }
suite1:					#
	sb $zero, 0($a0)		# chemin[i] = '\0';
					#
	ori $v0, $zero, 13 		# //Service 13 : fopen($a0,$a1)
	la $a0, chemin			# //...
	ori $a1, $zero, 0		# //...
	syscall				# $v0 = fopen(chemin, "rb");
	bltz  $v0, ERREUR		# //Si $v0 < 0, Afficher erreur et quitter 
	sw $v0, fichier			# RAM[fichier] = $v0
					#
	la $a0, chemin			# //Message pour l'utilisateur : l'image est ouvert.
	jal fncAfficherChaine		# 
	la $a0, msg2			# 
	jal fncAfficherChaine		# printf("%s est ouvert.\n",chemin);
	
						
	la $a1, bfHeader		# //Lire le "file header". 
	ori $a2, $zero, 2		# //Lire d'abord 2 octets.
	jal fread_bitmap		# fread(bfHeader, 2, 1,fichier);
							
	ori $a2, $zero, 12		# // Lire le reste (12 octets)
	la $a1, bfHeader + 4		# // Decalage de 2 octets pour alignement
					# // (les premiers 2 octets sont deja lus. Donc, 2+2 = 4)
	jal fread_bitmap		# fread((bfHeader + 4), 12, 1,fichier);
	
	jal fncEstFileHeaderValide 	# //Verifier la validite du "file header" du bitmap image.
					# //Si ce n'est pas valide, afficher erreur et quitter.
							
					# //Lire le "bitmap info header".
	ori $a2, $zero, 40		# //C'est bien en alignement et il vaut 40 octets.
	la $a1, bmiHeader		#
	jal fread_bitmap		# fread(bmiHeader, 2, 1,fichier);

	jal fncEstInfoHeaderValide 	# //Verifier la validite de Bitmap Info  de notre bitmap.
					# //Si ce n'est pas valide, afficher erreur et quitter.
							
					# //Lire la palette de notre bitmap.
	ori $a2, $zero, 64		# //Lire 64 octets (16 coleurs * 4 octets).
	la $a1, bmiColors		#
	jal fread_bitmap		# fread(bmiColors, 64, 1,fichier);
				

deplacerPos:
	ori $s0, $zero, 118		# //La position actuelle est 118eme octet.
	la $t1, bfHeader		# //Maintenant, on veut lire le codage de l'image.
	lw $s1,	12($t1)			# //Donc, on se deplace (bfOffBits - 118) octets
	sub $s1, $s1, $s0		# cste = bfOffBits - 118;
	ori $s0, $zero, 0		# i = 0;

	ori $a2, $zero, 1		# 	
	la $a1, ch			#	
fseek:					# while (i <= bfOffBits - 118) {	
	beq $s0, $s1, calculerTaille	#
	jal fread_bitmap		#	fread(&ch, 1, 1, fichier); 
	addi $s0, $s0, 1		# 	i++;
	j fseek				# }
calculerTaille:
	la $a0, msg4			#
	jal fncAfficherChaine		# printf("Le largeur maximum de l'image (La taille de caracteres)?\n");
	ori $v0, $zero, 5		# //Service 5 : scanf("%d",$a0);
	syscall

	la $t0, bmiHeader		#
	lw $t0,	4($t0)			# $s3 = bmiHeader->biWidth
	slt $t1, $t0, $v0		# $t1 = biWidth < largeurMax
	bgtz $t1, ERREUR_DEPASSEMENT	# //Si $t0 >= 1, alors sauter vers ERREUR	
					#
	div $t0, $v0			# biWidth / largeurMax;
	mflo $a0			# blockWidth = biWidth / largeurMax;
					#
	ori $t1, $zero, 15		# cste = 15;
	mult $a0, $t1			# blockWidth * 15;
	mflo $a1			# blockHeight = blockWidth *15; 
	ori $t1, $zero, 10		# cste = 10;
	div $a1, $t1			# (blockWidth * 15) / 10
	mflo $a1			# blockHeight = (int)(blockWidth *1.5); 
	

	addiu $sp, $sp, -16		# //Empilage
	sw $fp, 12($sp)			# 
	sw $a1, 8($sp)			# //Sauvegarde blockHeight
	sw $a0, 4($sp)			# //Sauvegarde blockWidth
	addi $fp, $sp, 16		#
	la $a0, msg7			# //Afficher la taille de bloc calculee.
	jal fncAfficherChaine		#
	lw $a0, 4($sp)			#
	jal fncAfficherEntier		#
	la $a0, msg8			#
	jal fncAfficherChaine		#
	lw $a0, 8($sp)			#
	jal fncAfficherEntier		#
	jal fncAfficherNouvelleLigne	# printf("Bloc : %d x %d\n",blockWidth, blockHeight);

	la $a0, msg6
	jal fncAfficherChaine		# printf("Quel est le nom du fichier que vous voudriez sauvegarder le resultat?\n",blockWidth, blockHeight);

	ori $v0, $zero, 8		# //Service 8 : fgets($a0,$a1,stdin);
	la $a0, output
	ori $a1, $zero, 256		# fgets(output,256,stdin);
	syscall
	
	la $a0, output
	ori $t0, $zero, '\n'		# //Enlever une caratere de nouvelle ligne.
chercherNouvelleLigne2:			# while (chemin[i] == '\n') { 
	lb $t1, 0($a0)			# 	
	beq $t1, $t0, suite2		# 	 	
	addi $a0, $a0, 1		# 	i++;
	j chercherNouvelleLigne2	# }

suite2:			
	sb $zero, 0($a0)		# chemin[i] = '\0';
	la $a0, output			# //Message pour l'utilisateur : l'image est ouvert.

	ori $v0, $zero, 13 		# //Service 13 :  fopen($a0,$a1)
	la $a0, output			# //...
	ori $a1, $zero, 1		# //...
	syscall				# $v0 = fopen(output, "wb");
	bltz  $v0, ERREUR		# Si $v0 < 0, il y a un erreur.
	sw $v0, fichier_output		# RAM[fichier_output] = $v0
					#
	la $t0, bmiHeader		#
	lw $s3,	4($t0)			# $s3 = bmiHeader->biWidth
	lw $s4,	8($t0)			# $s4 = bmiHeader->biHeight
	mult $s3,$s4			# biWidth * biHeight
	mflo $t1			# cste = biWidth * biHeight
	addi $t1, $t1, 1		# cste = biWidth * biHeight + 1
					#
	la $t0, imageTaille		# //Le nombre de pixels totals : biWidth * biHeight. 
	sw $t1, 0($t0)			# RAM[imageTaille] = biWidth * biHeight. 
					#
	ori $v0, $zero, 9		# //Charger service 9 : malloc($a0)
	or $a0, $zero, $t1		#
	syscall				# 
	la $t0, image			# 
	sw $v0, 0($t0)			# image = (char*)malloc(sizeof(char) * (biWidth * biHeight));
	or $s2, $zero, $v0		# $s2 = image;
					#
					# //Calculer le nombre d'octets par ligne de pixels dans $t1.
	or $a0, $zero, $s3		# 
	ori $a1, $zero, 8		# 
	jal fncFloorFraction		# //Appeler fonction plancher
	ori $t0, $zero, 4		# 
	mult $t0, $v0			# 
	mflo $t1			# cste = 4 * floor(biWidth / 8);
					#
	ori $v0, $zero, 9		# //Charger service 9 : malloc($a0)
	or $a0, $zero, $t1		# 
	syscall				# 
	la $t0, codage			# 
	sw $v0, 0($t0)			# codage = malloc(sizeof(char) * (4 * floor(biWidth / 8));
					#
					# Lire l'image
	or $s5,	$zero, $v0		# $s5 = codage.
	or $s6, $zero, $t1		# $s6 = 4 * floor(biWidth / 8).
	ori $s0 $zero, 0		# $s0 = 0
					#
	la $t0, imageTaille		#
	lw $t1, 0($t0)			# cste = RAM[imageTaille]
	or $s0, $zero, $s2		# 
	add $s0, $s0, $t1		# $s0 = image + imageTaille;
	addiu $s0, $s0, -1		# $s0 = image + imageTaille - 1;
prochaineLigne:				# while($s0 != image + imageTaille) {
	beq $s0, $s2, affichage		# 
	sub $s0, $s0, $s3		# 	i--; //image -= biWidth;
	or $a1, $zero, $s5		# 	$a1 = codage;
	or $a2, $zero, $s6		# 	$a2 = 4 * floor(biWidth / 8);
	jal fread_bitmap		# 	fread(codage, 4 * floor(biWidth / 8), 1, fichier)
					#
	or $s7, $zero, $s5		# 	$s7 <- codage
	or $s1, $zero, 0		# 	j = 0;
					#		
prochainData:				# 	while(j <= biWidth) {
					# 	//premierPixel:
	lbu $a0, 0($s7)			# 
	srl $a0, $a0, 4			#		$a0 = (*codage) >> 4
	jal EnregistrerPixel		# 		image[i][j++] = $a0
	jal estHorsLimite		# 		if(j > biWidth) break;
					#	//deuxiemePixel:
	lbu $a0, 0($s7)			#
	andi $a0, $a0, 15		# 		$a0 = (*codage) & 0x0F;
	addi $s7, $s7, 1		# 		codage++; 
	jal EnregistrerPixel		# 		image[i][j++] = $a0;
	jal estHorsLimite		#	}
	j prochainData			# }
affichage:				#
	lw $fp, 12($sp)			# 
	lw $a1, 8($sp)			# //Charger blockHeight
	lw $a0, 4($sp)			# //Charger blockWidth
	addiu $sp, $sp, 16		#
	jal fncSauvegarderImage		#
fermer:					#
	ori $v0,$zero,16		# Fermer fichier
	la $a0, fichier			#
	lw $a0, 0($a0)			#
	syscall				#fclose(fichier);
					#
	ori $v0, $zero, 16		#//Service 16 : fclose($a0)
	la $a0, fichier_output		#
	lw $a0, 0($a0)			#
	syscall				#fclose(fichier_output);
EXIT: 					#
	ori $v0, $zero, 10		#
	syscall				#//Quitter
	
estHorsLimite:	
	addi $s1, $s1, 1		# j++;
	sle $t0, $s3, $s1		# $t0 = (biWidth <= j)
	bgtz $t0, prochaineLigne 	# //Si $t0 > 0, sauter vers prochaineLigne
	jr $ra				#
EnregistrerPixel:
	or $t0, $zero, $s0		# $t0 = image; // image + tailleImage - biWidth * i
	add $t0, $t0, $s1		# image += j;
	sb $a0, 0($t0)			# RAM[image] = $a0;
	jr $ra
ERREUR: 
	la $a0, err 			# Message : erreur.
	jal fncAfficherChaine		# prinptf("Erreur!!\n");
	j EXIT
ERREUR_DEPASSEMENT:
	la $a0, err 			# Message : erreur.
	jal fncAfficherChaine		# prinptf("Erreur!!\n");
	la $a0, msg5 			# Message : erreur.
	jal fncAfficherChaine		# prinptf("Erreur!!\n");
	j EXIT


fncEstFileHeaderValide:
	addiu $sp, $sp, -16		# //Prologue
	sw $fp, 12($sp)			#
	sw $ra, 0($sp)			#
	addiu $fp, $sp, 16		# //Fin de prologue
					#
	la $t6, bfHeader		# $t6 = bfHeader;
					#
	la $a0, msg_info1 		# 
	lh $a1, 0($t6)			# 
	jal fncAfficherInfo		# printf("bfType:%d\n",bfType);
	ori $t1, $zero, 19778		# //La signature du fichier BMP = 4D 42
	bne $t1, $a1, ERREUR		# Si bfType != 0x4D42, alors sauter vers ERREUR.
	la $a0, msg_info2 		# 
	lw $a1, 4($t6)			# 
	jal fncAfficherInfo		# printf("bfSize:%d\n", bfSize);
	slti $t0, $a1, 55		# $t0 = (bfSize < 55);
	bgtz $t0, ERREUR		# Si $t0 > 0, alors sauter vers ERREUR
	la $a0, msg_info3		# 
	lw $a1, 12($t6)			# 
	jal fncAfficherInfo		# printf("bfOffBits:%d\n",bfOffBits);
	slti $t0, $a1, 118		# $t0 = (bfOffBits < 118);
	bgtz $t0,ERREUR			# Si $t0 > 0, alors sauter vers ERREUR

	lw $fp, 12($sp)			# //Epilogue
	lw $ra, 0($sp)			#
	addiu $sp, $sp, 16		#
	jr $ra				# Fin de fncEstFileHeaderValide

fncEstInfoHeaderValide:
	addiu $sp, $sp, -16		#//Prologue
	sw $fp, 12($sp)			#
	sw $ra, 0($sp)			#
	addiu $fp, $sp, 16		#
					#
	la $t6, bmiHeader 		#	
	
	la $a0, msg_info4 		# 
	lw $a1, 4($t6)			# 
	jal fncAfficherInfo		# printf("Width:%d\n",biWidth);
	blez $a1, ERREUR		# Si biWidth < 1, alors sauter vers ERREUR.
	
	la $a0, msg_info5 		#
	lw $a1, 8($t6)			#
	jal fncAfficherInfo		# printf("Height:%d\n",biHeight);
	blez $a1, ERREUR		# Si biHeight < 1, alors sauter vers ERREUR.

	ori $t1, $zero, 4		# //L'image BMP que l'on veut est toujours 4 bits.
	la $a0, msg_info6 		# 
	lh $a1, 14($t6)			# 
	jal fncAfficherInfo		# printf("biBitCounts:%d\n",biBitCounts);
	bne $t1, $a1, ERREUR		# Si biBitCounts != 4, sauter vers ERREUR

	la $a0, msg_info7 		# //On veut un image sans compression.
	lw $a1, 16($t6)			# 
	jal fncAfficherInfo		# printf("biCompression:%d\n",biCompression);
	bne $zero, $a1, ERREUR		# Si biCompression > 0, sauter vers ERREUR

	lw $fp, 12($sp)			#//Epilogue
	lw $ra, 0($sp)			#
	addiu $sp, $sp, 16		#
	jr $ra				# Fin de fncEstInfoHeaderValide
	
fncAfficherCaractere:
	ori $v0, $zero, 11 	# //Service 11 : putchar($a0)
	syscall			# putchar($a0);
	jr $ra			# //Fin de fncAfficherCaractere.
fncAfficherChaine:
	ori $v0, $zero, 4 	# //Service 4 : printf("%s",$a0)
	syscall			# printf("%s",$a0);
	jr $ra			# Fin de fncAfficherChaine
fncAfficherNouvelleLigne:
	ori $v0, $zero, 4 	# Charger service 4 : puts($a0);
	la $a0, RetourChariot	# 
	syscall			# puts("\r");
	ori $v0, $zero, 4 	# Charger service 4 : puts($a0);
	la $a0, NouvelleLigne	# 
	syscall			# puts("\r");
	jr $ra			# Fin de fncAfficherNouvelleLigne
fncAfficherEntier:
	ori $v0, $zero, 1	# // service 1 : : printf("%d",$a0)
	syscall			# printf("%d",$a0);
	jr $ra			# //Fin de fncAfficherEntier
fncAfficherInfo:	
	addiu $sp, $sp, -16	# //Prologue
	sw $fp, 12($sp)		#
	sw $a0, 4($sp)		#
	sw $ra, 0($sp)		#
	addiu $fp, $sp, 16	#
				#
	or $a0, $zero, $a0	#
	jal fncAfficherChaine 	# printf("%s",$a0)
	or $a0, $zero, $a1	#
	jal fncAfficherEntier	# printf("%d",$a1);
	jal fncAfficherNouvelleLigne # putchar("\r\n");
	
	lw $fp, 12($sp)		# //Epilogue
	lw $a0, 4($sp)		#
	lw $ra, 0($sp)		#
	addiu $sp, $sp, 16	#
	jr $ra			# //Fin de fncAfficherInfo
	
fread_bitmap:
	ori $v0, $zero, 14 	# //Service 14 : fread($a1,$a2,1,$a0)
	la $t0, fichier		#
	lw $a0, 0($t0)		# 
	syscall 		# $v0 = fread($a1,$a2,1,fichier)
	blez $v0, ERREUR	# Si $v0 < 0, il existe l'erreur de lecture/EOF. Sauter vers ERREUR.
	jr $ra			# //Fin de fread_bitmap
	
fncSommerRVB:			# $a0 <- RVB
	ori $v0, $zero, 0	# sommeRVB = 0;
	lbu $t1, 0($a0)		# cste = RVB.rgbBlue;
	lbu $t2, 1($a0)		# cste = RVB.rgbGreen;
	lbu $t3, 2($a0)		# cste = RVB.rgbRed;
	add $v0, $v0, $t1	# sommeRVB = sommeRVB + RVB.rgbBlue
	add $v0, $v0, $t2	# sommeRVB = sommeRVB + RVB.rgbGreen
	add $v0, $v0, $t3	# sommeRVB = sommeRVB + RVB.rgbRed
	jr $ra				# return sommeRVB;

fncCalculLuminance: 		# $a0:sommeRVB
	ori $t0, $zero, 100	# cste = 100;
	mult $a0, $t0		# sommeRVB*100; 
	mflo $t0		# cste = sommeRVB*100;
	ori $t1, $zero, 765	# cste = 255 * 3;
	div $t0, $t1		# (sommeRGB*100)/(255*3);
	mflo $v0		# $v0 = (sommeRGB*100)/(255*3); 
	jr $ra			# return (sommeRGB*100)/(255*3); //Luminance en % (0~100)
	
fncIndiceLuminance:		# $a0 <-Nombre de coleurs, $a1 <- Lum_Pourcentage
	addiu $a0, $a0, -1	#
	mult $a0, $a1		# (Nombre de coleurs - 1) * Lum_Pourcentage
	mflo $t0		# cste = (Nombre de coleurs - 1) * Lum_Pourcentage
	ori $t1, $zero, 100	# cste = 100;
	div $t0, $t1		# ((Nombre de coleurs - 1) * Lum_Pourcentage) / 100
	mflo $v0		# $v0 <- ((Nombre de coleurs - 1) * Lum_Pourcentage) / 100
	jr $ra			# return $v0; //un indice de niveauxDeGris
	
fncFloorFraction:		# $a0 <- entier x, $a1 <- entier y
	div $a0, $a1		# x / y
	mflo $v0		# $v0 = x / y
	mfhi $t0		# cste = x % y
	beq $t0, $zero, retourFF# //Il n'y a pas de reste, on retoune directement le quotient.
arrondir:			#
	addi $v0, $v0, 1	# //Il y a un reste, on ajoute 1 au quotient
retourFF:			#
	jr $ra			# return $v0;

fputc:
	ori $v0, $zero, 15	#//Service 15: fwrite($a1,$a2,1,$a0);
	la $a1, ch		# char ch;
	sb $a0, 0($a1)		# ch = $a0;
	ori $a2, $zero, 1	# cste = 1;
	la $a0, fichier_output	#
	lw $a0, 0($a0)		# $a0 = RAM[fichier_output]
	syscall			# fwrite(ch, 1, 1, fichier_output);
	bltz $v0, ERREUR	# //Si $v0 < 0, Afficher erreur et quitter 
	jr $ra			# Fin de fputc
	
fncSauvegarderImage:
	addiu $sp,$sp,-40		# Prologue
	sw $fp, 36($sp)			#
	sw $ra, 32($sp)			#
	sw $s6, 28($sp)			#
	sw $s5, 24($sp)			#
	sw $s4, 20($sp)			#
	sw $s3, 16($sp)			#
	sw $s2, 12($sp)			#
	sw $s1, 8($sp)			#
	sw $s0, 4($sp)			#
	addi $fp, $sp, 40		#
	
	ori $s0, $zero, 0 		# $s0 = 0;
	or $s5, $zero, $a0		# $s5 = blockWidth
	or $s6, $zero, $a1		# $s6 = blockHeight
					# //Calculer novelle dimension

	j commencerBoucle
insererNouvelleLigne:
	addu $s0, $s0, $s6			# 	line += blockHeight;
	jal fncAfficherNouvelleLigne		#
	la $a0, RetourChariot			#
	lbu $a0, 0($a0)				#
	jal fputc				# fputs("\r",fichier_output);
	la $a0, NouvelleLigne			#
	lbu $a0, 0($a0)				#
	jal fputc				# fputs("\n",fichier_output);
commencerBoucle:				# while(line < biHeight) {
	bge $s0, $s4, finFncSI			#
	ori $s1, $zero, 0 			# 	column = 0;
insererPixel:					#	while(column < biWidth){
	or $a0, $zero, $s5			# 		
	or $a1, $zero, $s6			#		
	or $a2, $zero, $s0			#		
	or $a3, $zero, $s1			#		
	jal fncLuminanceMoyenne			#	Lum_Pourcentage= fncLuminanceMoyenne(blockWidth,blockHeight,line,column);
	ori $a0, $zero, 70			#		
	or $a1, $zero, $v0			#
	jal fncIndiceLuminance			#	indiceNG = fncIndiceLuminance(70, Lum_Pourcentage);
	or $a0, $zero, $v0			#		
	la $t0, niveauxDeGris			#
	add $t0, $t0, $v0			#		
	lb $a0, 0($t0)				#		
	jal fncAfficherCaractere		#		putchar(niveauxDeGris[indiceNG]);
	jal fputc				#		fwrite(&niveauxDeGris[indiceNG],1,1,fichier_output);
	addu $s1, $s1, $s5			# 		column += blockWidth;
						#	}
	bge $s1, $s3 insererNouvelleLigne	#	putchar('\n');
						#   	fputc('\n',fichier_output);
	j insererPixel				# }
finFncSI:					# 
	lw $fp, 36($sp)				#//Epilogue
	lw $ra, 32($sp)				#
	lw $s6, 28($sp)				#
	lw $s5, 24($sp)				#
	lw $s4, 20($sp)				#
	lw $s3, 16($sp)				#
	lw $s2, 12($sp)				#
	lw $s1, 8($sp)				#
	lw $s0, 4($sp)				#
	addi $sp, $sp, 40			#
	jr $ra					#//Fin de fncSauvegarderImage

fncLuminanceMoyenne:
	addiu $sp,$sp, -40			#//Prologue
	sw $fp, 36($sp)				#
	sw $ra, 32($sp)				#
	sw $s7, 28($sp)				#
	sw $s6, 24($sp)				#
	sw $s5, 20($sp)				#
	sw $s4, 16($sp)				#
	sw $s3, 12($sp)				#
	sw $s2, 8($sp)				#
	sw $s1, 4($sp)				#
	sw $s0, 0($sp)				#
	addi $fp, $sp, 40			#
						# $a0  = blockWidth;
						# $a1  = blockHeight;
						# $a2  = line;
						# $a3  = column;
								
	mult $a0, $a1				# blockWidth * blockHeight;
	add $s0, $a3, $a0			# $s0 = column + blockWidth;		
	add $s1, $a2, $a1			# $s1 = line + blockHeight;
	or $s2, $zero, $a2 			# i = line; 	//($s2)
	or $s3, $zero, $a3			# j = column;	//($s3)
	or $s4, $zero, 0			# $s4 = 0;
	mflo $s5					# $s5 = blockWidth * blockHeight;
	or $s6, $zero, $a0			# $s6 = blockWidth;
	la $t0, image				# 
	lw $s7, 0($t0) 				# $s7 = RAM[image];
	la $t0, bmiHeader
	lw $t1, 4($t0)				# $t1 = biWidth;
	lw $t2, 8($t0)				# $t2 = biHeight;

	sle $t0, $s0, $t1		# $t0 = (column + blockWidth) <= biWidth;
	addiu $t0, $t0, -1
	bltzal $t0, TrunquerLargeur 	# Si $t0 < 0, sauter et liaison vers TrunquerLargeur
	sle $t0, $s1, $t2		# $t0 = (line + blockHeight) <= biHeight;
	addiu $t0, $t0, -1
	bltzal $t0, TrunquerHauteur 	# Si $t0 < 0, sauter et liaison vers TrunquerHauteur
	j initialiser		    	#
TrunquerLargeur:
	or $s0, $zero, $s3		# $s0 = column
	sub $t0, $t1, $s3		# $t0 = biWidth - column
	add $s0, $s0, $t0		# $s0 = column + (biWidth - column)
	or $s6, $zero, $t0		# blockWidth = (biWidth - column)
	jr $ra
TrunquerHauteur:
	or $s1, $zero, $s2		# $s1 = line
	sub $t0, $t2, $s2		# $t0 = biHeight - line
	add $s1, $s1, $t0		# $s1 = line - (biHeight - line)
	jr $ra
initialiser:	
	mult $t1, $s2			# line * biWidth;
	mflo $t2			# $t2 = line * biWidth; //Ecrase biHeight
	add $s7, $s7, $t2		# $s7 = &image[line][0];
	sub $s7, $s7, $t1		# $s7 = &image[line - 1][0];
	add $s7, $s7, $s0		# $s7 = &image[line - 1][column + blockWidth];
					# //On fait -blockWidth au 2e indice lors du debut la boucle
					# //On fait +1 au 1er indice lors du debut la boucle
					# //Donc, on fait -1 et +blockWidth respt. 
								
	addiu $sp, $sp, -16		# //Empilage
	sw $fp, 12($sp)			# 
	sw $t1, 8($sp)			# //Sauvegarde biWidth 
	sw $s3, 4($sp)			# //Sauvegarde column 
	addi $fp, $sp, 16		#
	
parcourirLigne:				# i = line;
	beq $s2, $s1, finFncLM		# while(i != line + biHeight) {
	lw $s3,4($sp)			# 	j = column;
	addi $s2, $s2, 1		# 	i++;
	lw $t1, 8($sp)			# 	$t1 = biWidth
	sub $s7, $s7, $s6		#   
	add $s7, $s7, $t1		#  	$s7 = &image[i - 1 + 1][j + blockWidth - blockWidth]; //ou $s7 = &image[i][j];
					# 	$s7 = &image[i][j]; //ou $s7 = &image[i][j];
parcourirColonne:			#	while(j != column + blockWidth) {
	lbu $t2, 0($s7)			# 		$t2 = RAM[image[i][j]]; //(Ecrase biWidth * i)
	la $a0, bmiColors		# 		$a0 = bmiColors; //(Ecrase biWidth - (j + blockWidth))
	ori $t3, $zero, 4		#		$t3 = 4; //Un element de bmiColors vaut 4 octets.
	mult $t2, $t3			#		image[i][j] * 4
	mflo $t2			#		$t2 = image[i][j] * 4;
	add $a0, $a0, $t2		# 		$a0 = bmiColors[image[i][j]]
	jal fncSommerRVB		#
	or $a0, $zero, $v0		# 		sommeRVB = fncSommerRVB(bmiColors[image[i][j]]);
	jal fncCalculLuminance		#
	add $s4, $s4, $v0		# 		sommeLum <- sommeLum + fncCalculLuminance(sommeRVB);
	addi $s7, $s7, 1		# 		$s7 <- image + 1;
	addi $s3, $s3, 1		# 		j++;
	beq $s3, $s0, parcourirLigne	# 	}
	j parcourirColonne		# }
					# calculer la luminance moyenne
	div $s4, $s5			# sommeLum / (blockWidth * blockHeight);
	mflo $v0 			# $v0 = sommeLum / (blockWidth * blockHeight);
finFncLM:	
	lw $fp, 12($sp)			#//Epilogue
	lw $t1, 8($sp)			#
	lw $s3, 0($sp)			#
	addi $sp, $sp, 16		#
	lw $fp, 36($sp)			#
	lw $ra, 32($sp)			#
	lw $s7, 28($sp)			#
	lw $s6, 24($sp)			#
	lw $s5, 20($sp)			#
	lw $s4, 16($sp)			#
	lw $s3, 12($sp)			#
	lw $s2, 8($sp)			#
	lw $s1, 4($sp)			#
	lw $s0, 0($sp)			#
	addi $sp, $sp, 40		#
	jr $ra				#//Fin de fncLuminanceMoyenne
