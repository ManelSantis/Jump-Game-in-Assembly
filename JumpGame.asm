######################################################################
#      	           Manuel Santos e Erick Henrique                    #
######################################################################
#	Esse programa precisa que o Keyboard and Display MMIO        #
#       e o Bitmap Display estejam conectados ao MIPS.               #
#								     #
#       Configurações do Bitmap Display:                             #
#	Unit Width: 8						     #
#	Unit Height: 8						     #
#	Display Width: 512					     #
#	Display Height: 256					     #
#	Base Address for Display: 0x10008000 ($gp)	             #
#	                                                             #
#       inimigo = -1 vida                                            #
#       quantidade de vidas = 3                                      #
#       pontuação quando inimigo passa do x 31 = 10                  #
#                                                                    #
#       usar a tecla espaço para pular (32 em ASCII)                 #       
######################################################################

.data
#informações
	
#tela
altura: .word 32
largura: .word 64
	
#cores
principal: .word 0x000000 #preto
inimigo: .word 0xFF0000 #vermelho
cenario: .word 0x00FA9A #branco
fundo: .word 0xDCDCDC #cinza
	
#tecla usada
pular: .word 32 #espaço
			
.globl main

.text

main: 
##################################################################
#   Desenhar a o fundo  #
lw $a0, altura
lw $a1, largura
lw $a2, fundo
mul $a3, $a0, $a1
mul $a3, $a3, 4 
add $a3, $a3, $gp 
add $a0, $gp, $zero 
FillLoop:
	beq $a0, $a3, inicio
	sw $a2, 0($a0)
	addiu $a0, $a0, 4 
	j FillLoop
##################################################################
CoordinateToAddress: 		
	lw $v0, largura		
	mul $v0, $v0, $a1	
	add $v0, $v0, $a0	
	mul $v0, $v0, 4		
	add $v0, $v0, $gp	
	jr $ra			
##################################################################
#  Desenhar o pixel  #
desenhaPixel: #$a0 = endereço para desenhar e $a1 = cor 
	sw $a1, 0($a0) 	#desenha
	jr $ra		#retorna
##################################################################	
inicio:

#PLATAFORMA
li $t2, 28		
loopPlat:
li $t1, 0
loopPlat2:
	move $a0, $t1
	la $a1, 0($t2) #seta y
	jal CoordinateToAddress	
	move $a0, $v0	
	lw $a1, cenario	
	jal desenhaPixel	
	add $t1, $t1, 1	
	bne $t1, 64, loopPlat2
addi $t2, $t2, 1
bne $t2, 32, loopPlat

li $s3, 0 #falar que o quadrado vai começar no solo
li $s7, 0 #Inicializar a pontuação
li $s5, 3 #quantidade de vidas

resetar: #para as 3 primeiras colisões
#Desenhar o personagem na posição inicial#
li $t2, 27 #linha1
li $t5, 23 #um valor a mais de onde o quadrado pode ser desenhado

li $t1, 60 #posição x inicial do inimigo
li $s0, 64

jal desenharInimigo
jal desenhar
##################################################################
#  LOOP PRINCIPAL DO JOGO  #
jogo:

li $v0, 32
li $a0, 50
syscall

jal moverInimigo
jal ChecarInput
jal alturaMaxima
jal descendo

j jogo
####################################################################
# MOVIMENTAÇÃO DO INIMIGO #
moverInimigo:
la $s2, 0($ra)
beq $t1, 0, resetarValores
jal apagarInimigo
subi $t1, $t1, 1
subi $s0, $s0, 1
jal desenharInimigo
jr $s2
resetarValores:
jal apagarInimigo
li $t1, 60 #posição x inicial do inimigo
li $s0, 64 
jal desenharInimigo
jr $s2
####################################################################
#   CHECAR SE FOI DIGITADO ALGO VÁLIDO   #																												
ChecarInput:
lui $t0, 0xffff
lw $t9, 0($t0)
andi $t9, $t9, 0x0001
beq $t9, $zero, fimChecar
lw $t7, 4($t0)
beq $t7, 32, Subir
fimChecar:
jr $ra
####################################################################
#   SUBIR O QUADRADO   #
Subir:
li $s3, 1 ##vai falar par o quadrado subir
jr $ra
####################################################################
alturaMaxima:
la $s4, 0($ra)
bne $s3, 1, fimAltura ##vai falar par o quadrado subir
beq $t5, 12, Descer
jal apagar
subi $t2, $t2, 1 
subi $t5, $t5, 1 #um valor a mais de onde o quadrado pode ser desenhado
jal desenhar
fimAltura:
jr $s4
####################################################################
Descer:
li $s3, 0 ##vai falar para o quadrado descer
jr $s4
####################################################################
descendo:
la $s4, 0($ra)
bne $s3, 0, fimDescer##vai falar par o quadrado subir
beq $t5, 23, fimDescer
jal apagar
addi $t2, $t2, 1 
addi $t5, $t5, 1 #um valor a mais de onde o quadrado pode ser desenhado
jal desenhar
fimDescer:
jr $s4
####################################################################				
# desenhando o personagem #		
desenhar: #quadrado 4x4
la $s6, 0($ra)
loopLinha:
li $s1, 31
linha0:
	move $a0, $s1 # x
	la $a1, 0($t2) # y
	jal CoordinateToAddress	
	move $a0, $v0	
	lw $a1, principal
	jal desenhaPixel	
	addi $s1, $s1, 1	
	bne $s1, 35, linha0
subi $t2, $t2, 1
bne $t2, $t5, loopLinha
addi $t2, $t2, 4
jr $s6
####################################################################
# apagando o personagem #
apagar: #quadrado 4x4
la $s6, 0($ra)
AloopLinha:
li $s1, 31
Alinha0:
	move $a0, $s1 # x
	la $a1, 0($t2) # y
	jal CoordinateToAddress	
	move $a0, $v0	
	lw $a1, fundo
	jal desenhaPixel	
	addi $s1, $s1, 1	
	bne $s1, 35, Alinha0
subi $t2, $t2, 1
bne $t2, $t5, AloopLinha
addi $t2, $t2, 4
jr $s6
####################################################################
#desenhando o inimigo#
desenharInimigo: #retangulo 3x4
la $t6, 0($ra)
li $t3, 25
iniLinha:
la $t8, 0($t1)	
iniLinha0:
	move $a0, $t8 # x
	la $a1, 0($t3) # y
	jal CoordinateToAddress	
	move $a0, $v0	
	la $t4, 0($a0)
	lw $a1, inimigo
	jal testarColisao
	jal desenhaPixel	
	addi $t8, $t8, 1	
	bne $t8, $s0, iniLinha0
addi $t3, $t3, 1
bne $t3, 28, iniLinha	
jr $t6
####################################################################
#apagando o inimigo#
apagarInimigo:
la $t6, 0($ra)
li $t3, 25
AiniLinha:
la $t8, 0($t1)	
AiniLinha0:
	move $a0, $t8 # x
	la $a1, 0($t3) # y
	jal CoordinateToAddress	
	move $a0, $v0	
	lw $a1, fundo
	jal desenhaPixel	
	addi $t8, $t8, 1	
	bne $t8, $s0, AiniLinha0
addi $t3, $t3, 1
bne $t3, 28, AiniLinha	
jr $t6
############################################
# TESTE COLISÃO #
testarColisao:

lw $t0, 0($t4)
bne $t0, 0x00000000, fimTestarColisao

subi $s5, $s5, 1 #diminuir as vidas
beq $s5, 0, fim
j resetar
jr $ra

fimTestarColisao:
beq $t8, 31, pontuacao
jr $ra
pontuacao:
addi $s7, $s7, 10
jr $ra

####################################################################
fim:	
div $s7, $s7, 12

li $v0, 1
addi $a0, $s7, 0
syscall

lw $a0, altura
lw $a1, largura
lw $a2, principal
mul $a3, $a0, $a1
mul $a3, $a3, 4 
add $a3, $a3, $gp 
add $a0, $gp, $zero 
TelaPreta:
	beq $a0, $a3, end
	sw $a2, 0($a0)
	addiu $a0, $a0, 4 
	j TelaPreta
end:
