.data
	input_file: .asciiz "FLOAT2.BIN"
	.align 2
	first_num: .word 0
	second_num: .word 0
	result: .word 0
.text
	main:
	#mo file
	addi $v0, $zero, 13		#syscall open file
	#la $a0, input_file		#tai dia chi input_file vao $a0
	lui $a0, 4097
	ori $a0, $a0, 0
	addi $a1, $zero, 0		#tai flags la 0
	addi $a2, $zero, 0		#tai mode la 0
	syscall
	addu $s0, $v0, $zero	#di chuyen $v0 den $s0
	
	#tai so thuc dau tien
	addi $v0, $zero, 14		#syscall read file
	addu $a0, $s0, $zero	#di chuyen $s0 den $a0
	#la $a1, first_num		#tai dia chi first_num vao $a1
	lui $a1, 4097
	ori $a1, $a1, 12
	addi $a2, $zero, 4		#tai 4 bytes
	syscall
	
	#tai so thuc thu hai
	addi $v0, $zero, 14		#syscall read file
	addu $a0, $s0, $zero		#di chuyen $s0 den $a0
	#la $a1, second_num		#tai dia chi second_num vao $a1
	lui $a1, 4097
	ori $a1, $a1, 16 
	addi $a2, $zero, 4		#tai 4 bytes
	syscall
	
	#dong file
	addi $v0, $zero, 16		#syscall close file
	addu $a0, $s0, $zero		#di chuyen $s0 den $a0
	syscall
    	
    	#lw $t0, first_num
    	lui $t0, 4097
    	lw $t0, 12($t0)
    	beq $t0, $zero, check_zero
    	#lw $t1, second_num
    	lui $t1, 4097
    	lw $t1, 16($t1)
    	beq $t1, $zero, check_zero
    	
    	#tach so thuc thu nhat (s0 la sign, s1 la exponent, s2 la mantissa)
    	#andi $s0, $t0, 0x80000000  	#tach bit dau cua so dau tien
    	lui $at, 0x8000
    	ori $at, $at, 0
    	and $s0, $t0, $at
    	srl $s0, $s0, 31		#giu  1 bit dau
    	srl  $s1, $t0, 23          	#tach phan exponent
    	andi $s1, $s1, 0xFF        	#giu 8 bit
    	#andi $s2, $t0, 0x007FFFFF  	#tach phan mantissa
    	lui $at, 0x007F
    	ori $at, $at, 0xFFFF
    	and $s2, $t0, $at
    	#ori $s2, $s2, 0x00800000	#them so 1 ngam dinh 
    	lui $at, 0x0080
    	ori $at, $at, 0
    	or $s2, $s2, $at
    
    	#tach so thuc thu hai (s3 la sign, s4 la exponent, s5 la mantissa)
    	#andi $s3, $t1, 0x80000000  	#tach bit dau cua so thu hai
    	lui $at, 0x8000
    	ori $at, $at, 0
    	and $s3, $t1, $at
    	srl $s3, $s3, 31		#giu  1 bit dau
    	srl  $s4, $t1, 23          	#tach phan exponent
    	andi $s4, $s4, 0xFF        	#giu 8 bit
    	#andi $s5, $t1, 0x007FFFFF  	#tach phan mantissa
    	lui $at, 0x007F
    	ori $at, $at, 0xFFFF
    	and $s5, $t1, $at
    	#ori $s5, $s5, 0x00800000	#them so 1 ngam dinh 
    	lui $at, 0x0080
    	ori $at, $at, 0
    	or $s5, $s5, $at
    	
    	jal multiple_floats		#goi ham nhan hai so thuc
    	
    	#lw $t1, result			#tai ket qua vao t1
    	lui $t1, 4097
    	lw $t1, 20($t1)
    	mtc1 $t1, $f12       		#chuyen sang thanh f12 de in
    	addi $v0, $zero,  2            #syscall print float
    	syscall
    	
    	j exit				#ket thuc
    	
    	multiple_floats:
    	addi $sp, $sp, -4		#stack pointer lui 4
    	sw $ra, 0($sp)			#luu dua chi tra ve
	
	#tinh phan sign va exponent
	xor $t0, $s0, $s3		#xor phan sign
	add $t4, $s1, $s4		#cong phan exponent
	#sub $t4, $t4, 127
	addi $at, $zero, 127
	sub $t4, $t4, $at
	
	#tinh phan mantissa
	#nhan phan mantissa
	mult $s2, $s5
	mfhi $t3			#lay phan tren
	mflo $t5			#lay phan duoi
	sll $t3, $t3, 16		#dich trai phan tren
	srl $t5, $t5, 16		#dich phai phan duoi
	or $t3, $t3, $t5		#gop phan tren va duoi
	j normalize_mul
	
	#normalize phep nhan (t3 = mantissa va t4 = exponent)
	normalize_mul:
	lui $t1, 0x8000			#dat t1 la 0x8000
	and $t2, $t3, $t1		#kiem tra bit cao nhat
	beq $t2, $zero, left		#neu bit do bang 0, can phai chuan hoa ve ben trai
	addi $t4, $t4, 1		#nguoc lai, cong 1 cho phan exponent
	srl $t3, $t3, 8			#dich ve lai
	j check_over_and_under 	#chuan hoa xong, kiem tra under va over
	
	left:
	and $t2, $t3, $t1		#kiem tra bit cao nhat
	sll $t3, $t3, 1			#dich trai 1 bit
	beq $t2, $zero, left		#tiep tuc cho den khi bit cao nhat la 1
	srl $t3, $t3, 9			#dich ve lai
	j check_over_and_under		#chuan hoa xong, kiem tra under va over
	
	check_over_and_under:
	#kiem tra underflow va overflow (t1 = exponent)
	#blt $t4, $zero, underflow
	slt $at, $t4, $zero
	bne $at, $zero, underflow
	#bgt $t4, 255, overflow
	addi $t5, $zero, 255
	slt $at, $t5, $t4
	bne $at, $zero, overflow
	j pack_result
	
	underflow:
	#return 
	lw $ra, 0($sp)				# return $ra
	addi $sp, $sp, 4
	
    	addi $t1, $zero, 0			#dat ket qua la 0
    	or $t1, $t1, $t0			#dat dau
    	#sw $t1, result				#luu ket qua
    	lui $t1, 4097
    	sw $t1, 20($t1)
    	jr $ra					#ve main
    	
    	overflow:
	#return 
	lw $ra, 0($sp)				# return $ra
	addi $sp, $sp, 4
	
    	#li $t1, 0x7F800000			#dat ket qua la so rat lon
    	lui $at, 0x7F80
    	ori $t1, $at, 0
    	or $t1, $t1, $t0			#dat dau
    	#sw $t1, result				#luu ket qua
    	lui $t1, 4097
    	sw $t1, 20($t1)
    	jr $ra					#ve main

	#gop cac phan lai voi nhau
	#(t0 = sign, t1 = exponent, t3 = mantissa, t6 = result)
	pack_result:
	lw $ra, 0($sp)				#return $ra
	addi $sp, $sp, 4
	
	#andi $t3, $t3, 0x007FFFFF		#tach phan mantissa
	lui $at, 0x007F
	ori $at, $at, 0xFFFF
	and $t3, $t3, $at
    	sll $t4, $t4, 23			#chuyen phan exponent ve bit 23
    	sll $t0, $t0, 31			#chuyen phan dau ve bit 31
    	or $t6, $t0, $t4			#gop lai hai phan
    	or $t6, $t6, $t3			#gop phan mantissa voi hai phan tren
    	#sw $t6, result				#luu vao result
    	lui $at, 4097
    	sw $t6, 20($at)
    	jr $ra
	
	check_zero:
	addi $a0, $zero, 0		#dat ket qua la 0
	addi $v0, $zero, 1            #syscall print integer
	syscall
	j exit
	
	#ket thuc chuong trinh
	exit:
	addi $v0, $zero, 10		#syscall exit
	syscall 

	