#####################################################################

# Bitmap Display Configuration:
# - Unit width in pixels: 16                         
# - Unit height in pixels: 16
# - Display width in pixels: 512
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)

#####################################################################

.data
	displayAddress: .word 0x10008000
	playerColor: .word 0xe10000
	platformColor: .word 0x00b827
	rocketColor: .word 0xff8a3e
	backgroundColor: .word 0x8bb2ff
	black: .word 0x000000
	textColor: .word 0xffffff
	platformA: .space 8
	platformB: .space 8
	platformC: .space 8
	platformD: .space 8
	rocketPowerup: .space 8
	bombA: .space 8
	bombB: .space 8
	bombC: .space 8
	specialPlatformColor1: .word 0x862e1b 
	specialPlatformColor2: .word 0xae6f61
	player: .space 8
.text

# Game State Loops #######################################################################

StartScreen:
	jal DrawBackground
	li $a0, 5
	li $a1, 5
	jal DrawS
	li $a0, 10
	jal DrawT
	li $a0, 15
	jal DrawA
	li $a0, 20
	jal DrawR
	li $a0, 25
	jal DrawT
	li $a0, 5
	li $a1, 15
	jal DrawP
	li $a0, 10
	jal DrawR
	li $a0, 15
	jal DrawE
	li $a0, 20
	jal DrawS
	li $a0, 25
	jal DrawS
	li $a0, 15
	li $a1, 23
	jal DrawS
	StartScreenLoop:
		jal CheckInput
		j StartScreenLoop
Init:
	li $s0, 31 # last contact point
	li $s1, 0 # flag
	la $s2, platformC # moving platform
	li $s3, 0 # platform direction
	la $s4, platformB # breaking platform
	li $s5, 0 # breaking number
	li $s6, 0 # score
	li $s7, 60 # inverse speed
	li $t6, 0 # number of bombs 
	li $t7, 0 # Draw rocket or not
	jal UpdatePlatforms
	li $a0, 15
	jal UpdatePlayerX
	li $a0, 31
	jal UpdatePlayerY
	jal UpdateBombs
	jal UpdateRocketPowerup

Main:	
	jal CheckInput
	move $a0, $s2
	jal MovePlatform
	jal CheckJump
	jal CheckPlatforms
	jal CheckBombs
	jal CheckOffScreen
	jal DrawBackground
	jal DrawScoreboard
	jal DrawNotification
	jal DrawPlatforms
	jal HandleRocket
	jal DrawBombs
	jal DrawPlayer
	li $v0, 32
	move $a0, $s7
	syscall 
	j Main

GameOver:
	jal DrawDead
	li $a0, 10
	li $a1, 18
	jal DrawD
	li $a0, 15
	jal DrawE
	li $a0, 19
	jal DrawD
	jal DrawScoreboard
	GameOverLoop:
		jal CheckInput
		j GameOverLoop

# Drawing ######################################################################

# Draws the background 
DrawBackground: # Params: none
	lw $t0, displayAddress
	lw $t1, backgroundColor
	li $t2, 0
	WHILE:
		bge $t2, 1024, DONE
		sw $t1, ($t0)
		addi $t0, $t0, 4
		addi $t2, $t2, 1
		j WHILE
	DONE:
	jr $ra

# Draws the scoreboard
DrawScoreboard:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $t5, $ra
	li $t9, 10
	DrawDigit1:
		div $s6, $t9
		li $a0, 20
		li $a1, 10 
		mfhi $a2
		jal DrawNumber
		div $t8, $s6, 10
	DrawDigit2:
		div $t8, $t9
		li $a0, 15
		mfhi $a2
		jal DrawNumber
		div $t8, $t8, 10
	DrawDigit3:
		div $t8, $t9
		li $a0, 10
		mfhi $a2
		jal DrawNumber
		div $t8, $t8, 10
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	move $ra, $t5
	jr $ra		

DrawNumber: # Params: number, x, y
	addi $sp, $sp, -4
	sw $ra, 4($sp)
	beq $a2, 0, DrawZero
	beq $a2, 1, DrawOne
	beq $a2, 2, DrawTwo
	beq $a2, 3, DrawThree
	beq $a2, 4, DrawFour
	beq $a2, 5, DrawFive
	beq $a2, 6, DrawSix
	beq $a2, 7, DrawSeven
	beq $a2, 8, DrawEight
	beq $a2, 9, DrawNine
	DrawZero: jal Draw0
	DrawOne: jal Draw1	
	DrawTwo: jal Draw2
	DrawThree: jal Draw3
	DrawFour: jal Draw4
	DrawFive: jal Draw5
	DrawSix: jal Draw6
	DrawSeven: jal Draw7
	DrawEight: jal Draw8
	DrawNine: jal Draw9

# Draws the player at a given coordinate		
DrawPlayer: # Params: none
	lw $t0, displayAddress
	lw $t1, playerColor
	la $t2, player
	lw $t3, 0($t2)
	lw $t4, 4($t2)
	sll $t4, $t4, 5
	add $t4, $t3, $t4
	sll $t4, $t4, 2
	add $t4, $t0, $t4 
	sw $t1, ($t4)
	beq $s0, 0, RocketOn
	beq $s0, 1, RocketOff
	jr $ra
	RocketOn:
		li $s0, 1
		j DrawPlayerRocket
	RocketOff:
		li $s0, 0
		j DrawPlayerRocketDone
	DrawPlayerRocket:
		lw $t5, rocketColor
		lw $t3, 0($t2)
		lw $t4, 4($t2)
		addi $t4, $t4, 1
		sll $t4, $t4, 5
		add $t4, $t3, $t4
		sll $t4, $t4, 2
		add $t4, $t0, $t4 
		sw $t5, ($t4)
	DrawPlayerRocketDone:
		jr $ra


# Draw bomb at a given coordinate
DrawBomb: # Params: address
	lw $t0, displayAddress
	lw $t1, black
	lw $t3, 0($a0)
	lw $t4, 4($a0)
	sll $t4, $t4, 5
	add $t4, $t3, $t4
	sll $t4, $t4, 2
	add $t4, $t0, $t4 
	sw $t1, ($t4)
	jr $ra

# Draw all bombs scales as level progresses
DrawBombs:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	beq $t6, 0, DrawBombsDone
	beq $t6, 1, DrawOneBomb
	beq $t6 2, DrawTwoBombs
	bge, $t6, 3, DrawThreeBombs
	DrawOneBomb:
		la $a0, bombA
		jal DrawBomb
		j DrawBombsDone
	DrawTwoBombs:
		la $a0, bombA
		jal DrawBomb
		la $a0, bombB
		jal DrawBomb
		j DrawBombsDone
	DrawThreeBombs: 
		la $a0, bombA
		jal DrawBomb
		la $a0, bombB
		jal DrawBomb
		la $a0, bombC
		jal DrawBomb
	DrawBombsDone:
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra

# Draws a notification on screen
DrawNotification:
	addi $sp, $sp, -4
	sw $ra, 4($sp)
	move $t5, $ra
	beqz $s6, DrawNotificationDone
	# Check Divisible by 25
	li $t0, 50
	div $s6, $t0
	mfhi $t0
	beqz $t0, DrawPoggest
	# Check Divisible by 10
	li $t0, 10
	div $s6, $t0
	mfhi $t0
	beqz $t0, DrawPoggers
	# Check Divisible by 5
	li $t0, 5
	div $s6, $t0
	mfhi $t0
	beqz $t0, DrawPog
	bnez $t0, DrawNotificationDone
	DrawPoggest:
		li $a0, 3,
		li $a1, 24
		jal DrawP
		li $a0, 7
		jal DrawO
		li $a0, 11
		jal DrawG
		li $a0, 15
		jal DrawG
		li $a0, 19
		jal DrawE
		li $a0, 23
		jal DrawS
		li $a0, 27
		jal DrawT
		j DrawNotificationDone
	DrawPoggers:
		li $a0, 3,
		li $a1, 24
		jal DrawP
		li $a0, 7
		jal DrawO
		li $a0, 11
		jal DrawG
		li $a0, 15
		jal DrawG
		li $a0, 19
		jal DrawE
		li $a0, 23
		jal DrawR
		li $a0, 27
		jal DrawS
		j DrawNotificationDone
	DrawPog:
		li $a0, 10
		li $a1, 24
		jal DrawP
		li $a0, 15
		jal DrawO
		li $a0, 20
		jal DrawG
	DrawNotificationDone:
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		move $ra, $t5
		jr $ra


# Draws the rocket powerup at a given coordinate
DrawRocketPowerup: # Params: none
	beq $s0, 1, DrawRocketPowerupDone
	beq $s0, 0, DrawRocketPowerupDone
	lw $t0, displayAddress
	lw $t1, rocketColor
	la $t2, rocketPowerup
	lw $t3, 0($t2)
	lw $t4, 4($t2)
	sll $t4, $t4, 5
	add $t4, $t3, $t4
	sll $t4, $t4, 2
	add $t4, $t0, $t4 
	sw $t1, ($t4)
	DrawRocketPowerupDone:
		jr $ra

isBroken:
	beq $s5, 2, Broken
	beq $s5, 1, Color2 
	Color1: 
		lw $a1, specialPlatformColor1
		j SecondLayer
	Color2:
		lw $a1, specialPlatformColor2
		j SecondLayer
	Broken:
		j DrawPlatformDone

# Draws a platform at a given coordinate
DrawPlatform: # Params: platform address, color
	lw $t0, displayAddress 
	lw $t1, 0($a0)
	lw $t2, 4($a0)
	beq $s4, $a0, isBroken
	SecondLayer:
		addi $t3, $t2, 1
		sll $t3, $t3, 5
		add $t3, $t1, $t3
		sll $t3, $t3, 2
		add $t3, $t3, $t0
	FirstLayer:
		sll $t2, $t2, 5
		add $t1, $t1, $t2
		sll $t1, $t1, 2
		add $t1, $t0, $t1
	move $t4, $a1	
	DrawBothLayers:
		sw $a1, 0($t1)
		sw $a1, 4($t1)
		sw $a1, 8($t1)
		sw $a1, 12($t1)
		sw $a1, 16($t1)
		sw $a1, 20($t1)
		sw $a1, 4($t3)
		sw $a1, 8($t3)
		sw $a1, 12($t3)
		sw $a1, 16($t3)
	DrawPlatformDone:
		jr $ra

# Draws all platforms
DrawPlatforms: # Params: none
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, platformA
	lw $a1, platformColor
	jal DrawPlatform
	la $a0, platformB
	lw $a1, platformColor
	jal DrawPlatform
	la $a0, platformC
	lw $a1, platformColor
	jal DrawPlatform
	la $a0, platformD
	lw $a1, platformColor
	jal DrawPlatform
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra	
			
# Game Object Updates #############################################################

# Update player x
UpdatePlayerX: # Params: x
	la $t0, player
	sw $a0, 0($t0)
	jr $ra	
	
# Update player y
UpdatePlayerY: # Params: y	
	la $t0, player
	sw $a0, 4($t0)
	jr $ra	
# Update a single platform x and y values
UpdatePlatform: # Params: platform address, y value
	move $t0, $a0
	move $t1, $a1
	li $v0, 42
	li $a0, 0
	li $a1, 25
	syscall
	sw $a0, 0($t0)
	sw $t1, 4($t0)
	jr $ra

# Update all platform x and y values 
UpdatePlatforms: # Params: # none
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, platformA
	li $a1, 30
	jal UpdatePlatform
	la $a0, platformB
	li $a1, 21
	jal UpdatePlatform
	la $a0, platformC
	li $a1, 17
	jal UpdatePlatform
	la $a0, platformD
	li $a1, 5
	jal UpdatePlatform
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Update a rocket powerup x and y value
UpdateRocketPowerup: # Params: none
	la $t0, rocketPowerup
	li $v0, 42
	li $a0, 0
	li $a1, 31
	syscall
	sw $a0, 0($t0)
	li $v0, 42
	li $a0, 0
	li $a1, 31
	syscall
	sw $a0, 4($t0)
	jr $ra

# Update a bomb x and y value
UpdateBomb: # Params: address
	move $t0, $a0
	li $v0, 42
	li $a0, 0
	li $a1, 10
	syscall
	addi $a0, $a0, 10
	sw $a0, 0($t0)
	li $v0, 42
	li $a0, 0
	li $a1, 10
	syscall
	addi $a0, $a0, 10
	sw $a0, 4($t0)
	jr $ra

# Update all bomb locations
UpdateBombs:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, bombA
	jal UpdateBomb
	la $a0, bombB
	jal UpdateBomb
	la $a0, bombC
	jal UpdateBomb
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# User Inputs ######################################################################
		
# Checks if any key is pressed
CheckInput: # Params: none
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	lw $t0, 0xffff0000
	beq $t0, 1, CheckKey
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	
# Checks which key was pressed	
CheckKey: # Params: none
	lw $t1, 0xffff0004
	beq $t1, 0x6a, MovePlayerLeft
	beq $t1, 0x6b, MovePlayerRight
	beq $t1, 0x73, Init
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

CheckInputDead: # Params: none
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	lw $t0, 0xffff0000
	beq $t0, 1, CheckKeyDead
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

CheckKeyDead: # Params: none
	lw $t1, 0xffff0004
	beq $t1, 0x73, Init
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Player Logic #######################################################################

MovePlayerLeft: # Params: none
	la $t2, player
	lw $t3, 0($t2)
	addi $t3, $t3, -1
	ble $t3, -1, OffLeft
	move $a0, $t3
	jal UpdatePlayerX
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	OffLeft:
		li $a0, 31
		jal UpdatePlayerX
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra
	
MovePlayerRight: # Params: none
	la $t2, player
	lw $t3, 0($t2)
	addi $t3, $t3, 1
	bge $t3, 32, OffRight
	move $a0, $t3
	jal UpdatePlayerX
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	OffRight:
		li $a0, 0
		jal UpdatePlayerX	
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra	
SetFlag:
	li $s1, 1
		
# Handles player jumping logic
CheckJump: # Params: none
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	addi $t0, $s0, -14
	la $t1, player
	lw $t2, 4($t1)
	beqz $s1, Jump
	bnez $s1, Fall

# Moves the player up until jump height
Jump: # Params: none
	beq $t2, $t0, SetFlag
	addi $a0, $t2, -1
	jal UpdatePlayerY
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Moves the player down
Fall: # Params: none
	addi $a0, $t2, 1
	jal UpdatePlayerY
	lw $ra, 0($sp)
	addi $sp, $sp, 4	
	jr $ra

# Collisions #############################################################################

# Checks if a player collided with the platform
CheckPlatform: # Params: platform address
	la $t0, player
	lw $t1, 0($t0)
	lw $t2, 4($t0)
	lw $t3, 0($a0)
	lw $t4, 4($a0)
	bge $t1, $t3, CheckLessThan
	blt $t1, $t3, CheckPlatformDone
	CheckLessThan: 
		addi $t3, $t3, 5
		ble $t1, $t3, CheckY
		bgt $t1, $t3, CheckPlatformDone
	CheckY:
		addi $t4, $t4, -1
		beq $t4, $t2, CheckFalling
		bne $t4, $t2, CheckPlatformDone
	CheckFalling:
		bnez $s1, Collide
		beqz $s1, CheckPlatformDone

# Bounces the player off the platform	
Collide: # Params: none
	beq $a0, $s4, IncrementBreak
	move $s0, $t4 
	li $s1, 0 # flag to jump again
	addi $s6, $s6, 1 # Update Score 
	jr $ra 
	IncrementBreak:
		bge $s5, 2, SkipCollision 
		addi $s5, $s5, 1
		move $s0, $t4
		li $s1, 0
		addi $s6, $s6, 1 
		SkipCollision:
		jr $ra

CheckPlatformDone:
	jr $ra
	
# Checks all platforms for collisions with player	 
CheckPlatforms:	# Params: none
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, platformA
	jal CheckPlatform
	la $a0, platformB
	jal CheckPlatform
	la $a0, platformC
	jal CheckPlatform
	la $a0, platformD
	jal CheckPlatform
	lw $ra, 0($sp)
	addi $sp, $sp, 4
 	jr $ra

# Check rocket powerup for collisions
CheckRocketPowerup:
	la $t0, player
	la $t1, rocketPowerup
	lw $t2, 0($t0)
	lw $t3, 4($t0)
	lw $t4, 0($t1)
	lw $t5, 4($t1)
	beq $t2, $t4, CheckRocketY
	bne $t2, $t4, CheckRocketDone
	CheckRocketY:
		beq $t3, $t5, ActivateRocket
		bne $t3, $t5, CheckRocketDone
	ActivateRocket:
		li $s0, 1
		li $s1, 0
	CheckRocketDone:
		jr $ra


# Check bomb for collisions
CheckBomb: # Params: address
	la $t0, player
	move $t1, $a0
	lw $t2, 0($t0)
	lw $t3, 4($t0)
	lw $t4, 0($t1)
	lw $t5, 4($t1)
	beq $t2, $t4, CheckBombY
	bne $t2, $t4, CheckBombDone
	CheckBombY:
		beq $t3, $t5, Explode
		bne $t3, $t5, CheckBombDone 
	CheckBombDone:
		jr $ra

# Checks all active bombs for collisions
CheckBombs: # Params: none
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	beq $t6, 0, CheckBombsDone
	beq $t6, 1, CheckOneBomb
	beq $t6, 2, CheckTwoBombs
	bge $t6, 3, CheckThreeBombs 
	CheckOneBomb:
		la $a0, bombA
		jal CheckBomb
		j CheckBombsDone
	CheckTwoBombs:
		la $a0, bombA
		jal CheckBomb
		la $a0, bombB
		jal CheckBomb
		j CheckBombsDone
	CheckThreeBombs:
		la $a0, bombA
		jal CheckBomb
		la $a0, bombB
		jal CheckBomb
		la $a0, bombC
		jal CheckBomb
	CheckBombsDone:
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra

Explode:
	move $a2, $t4,
	move $a3, $t5
	FirstRing:
		lw $a0, rocketColor
		addi $a3, $a3, -1
		jal DrawColoredPixel
		addi $a3, $a3, 2
		jal DrawColoredPixel
		addi $a2, $a2, -1
		addi $a3, $a3, -1
		jal DrawColoredPixel
		addi $a2, $a2, 2
		jal DrawColoredPixel
		li $v0, 32
		li $a0, 60
		syscall
	UndoFirstRing:
		lw $a0, backgroundColor
		jal DrawColoredPixel
		addi $a2, $a2, -2
		jal DrawColoredPixel
		addi $a2, $a2, 1
		addi $a3, $a3, -1
		jal DrawColoredPixel
		addi $a3, $a3, 2
		jal DrawColoredPixel
		li $v0, 32
		li $a0, 60
		syscall
	SecondRing:
		lw $a0, rocketColor
		addi $a3, $a3, 2
		jal DrawColoredPixel
		addi $a2, $a2, 2
		addi $a3, $a3, -1
		jal DrawColoredPixel
		addi $a2, $a2, 1
		addi $a3, $a3, -2
		jal DrawColoredPixel
		addi $a2, $a2, -1
		addi $a3, $a3, -2
		jal DrawColoredPixel
		addi $a2, $a2, -2
		addi $a3, $a3, -1
		jal DrawColoredPixel
		addi $a2, $a2, -2
		addi $a3, $a3, 1
		jal DrawColoredPixel
		addi $a2, $a2, -1
		addi $a3, $a3, 2
		jal DrawColoredPixel
		addi $a2, $a2, 1
		addi $a3, $a3, 2
		jal DrawColoredPixel
		li $v0, 32
		li $a0, 60
		syscall
	j GameOver

DrawColoredPixel: # Params: color, x, y
	lw $t0, displayAddress
	sll $t2, $a3, 5
	add $t2, $a2, $t2
	sll $t2, $t2, 2
	add $t2, $t0, $t2 
	sw $a0, 0($t2)	
	jr $ra


# Offscreen Logic #######################################################################

# Checks if player goes off screen
CheckOffScreen: # Params: none
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $t0, player
	lw $t1, 4($t0)
	bltz $t1, OffTop
	bgt $t1, 32, OffBottom
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

# Handles if player leaves the screen through the top
OffTop: # Params: none
	li $t2, 31
	li $s0, 31
	li $s5, 0 # breaking platform
	addi $s6, $s6, 25 # update score
	addi $s7, $s7, -2 # increases speed
	addi $t6, $t6, 1 # increases number of bombs, capped at 3
	li $v0, 42
	li $a0, 0
	li $a1, 3
	syscall
	move $t7, $a0
	sw $t2, 4($t0)
	jal UpdatePlatforms
	jal UpdateBombs
	jal UpdateRocketPowerup
	BreakingPlatform:
		li $v0, 42
		li $a0, 0
		li $a1, 3
		syscall
		beq $a0, 0, A1 
		beq $a0, 1, B1
		beq $a0, 2, C1
		beq $a0, 3, D1
		A1: la $s4, platformA
		j MovingPlatform
		B1: la $s4, platformB
		j MovingPlatform
		C1: la $s4, platformC
		j MovingPlatform
		D1: la $s4, platformD
	MovingPlatform:
		li $v0, 42
		li $a0, 0
		li $a1, 3
		syscall
		beq $a0, 0, A 
		beq $a0, 1, B
		beq $a0, 2, C
		beq $a0, 3, D
		A: la $s2, platformA
		j OffTopDone
		B: la $s2, platformB
		j OffTopDone
		C: la $s2, platformC
		j OffTopDone
		D: la $s2, platformD
		j OffTopDone

	OffTopDone:	
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra

# Handles if player leaves the screen through the bottom
OffBottom: # Params: none
	j GameOver

# Platform Logic ################################################################

Flip:
	not $s3, $s3
	
# Moves the platform horizontally
MovePlatform: # Params: platform address
	lw $t0, 0($a0)
	beqz $s3, MovePlatformRight
	bnez $s3, MovePlatformLeft
	jr $ra
	MovePlatformRight:
		beq $t0, 25, Flip 
		addi $t0, $t0, 1
		sw $t0, 0($a0)
		jr $ra
	MovePlatformLeft: 
		beq $t0, 0, Flip
		addi $t0, $t0, -1
		sw $t0, 0($a0)
		jr $ra

# Powerup Logic ##########################################################################

# Decides when a rocket is available
HandleRocket:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	beq $t7, 1, CheckRocket
	bne $t7, 1, HandleRocketDone
	CheckRocket:
		jal CheckRocketPowerup
		jal DrawRocketPowerup
	HandleRocketDone:
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra



# Letter/Number Drawing ##################################################################

DrawDead: # Params: none
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	lw $t2, displayAddress
	lw $t8, black
	li $t9, 0
	DEAD_WHILE:
		bge $t9, 1024, DEAD_DONE
		sw $t8, ($t2)
		addi $t2, $t2, 4
		addi $t9, $t9, 1
		jal CheckInputDead
		li $v0, 32
		li $a0, 1
		syscall
		j DEAD_WHILE
	DEAD_DONE:
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

DrawPixel: # Params: x, y
	lw $t0, displayAddress
	lw $t1, textColor
	sll $t2, $a3, 5
	add $t2, $a2, $t2
	sll $t2, $t2, 2
	add $t2, $t0, $t2 
	sw $t1, 0($t2)	
	jr $ra

Draw0: # Params: x, y
	move $a2, $a0
	move $a3, $a1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a3, $a3, -1
	jal DrawPixel
	addi $a3, $a3, -1
	jal DrawPixel
	addi $a3, $a3, -1
	jal DrawPixel
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra
	
Draw1: # Params: x, y
	move $a2, $a0
	move $a3, $a1
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a2, $a2, 1
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, -2
	jal DrawPixel
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra	

Draw2:
	move $a2, $a0
	move $a3, $a1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra	 

Draw3:
	move $a2, $a0
	move $a3, $a1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a2, $a2, 2
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel	
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra	

Draw4: # Params: x, y
	move $a2, $a0
	move $a3, $a1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2 1
	jal DrawPixel
	addi $a3, $a3, -1
	jal DrawPixel
	addi $a3, $a3, -1
	jal DrawPixel
	addi $a3, $a3, 3
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra	

Draw5: # Params: x, y
	move $a2, $a0
	move $a3, $a1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, -2
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra

Draw6: # Params: x, y
	move $a2, $a0
	move $a3, $a1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, -2
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a3, $a3, -1
	jal DrawPixel
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra	 

Draw7: # Params: x, y
	move $a2, $a0
	move $a3, $a1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra	

Draw8: # Params: x, y
	move $a2, $a0
	move $a3, $a1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a3, $a3, -1
	jal DrawPixel
	addi $a3, $a3, 2
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a3, $a3, -1
	jal DrawPixel
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra	

Draw9: # Params: x, y
	move $a2, $a0
	move $a3, $a1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	add $a2, $a2, -1
	jal DrawPixel
	addi $a3, $a3, -1
	jal DrawPixel
	addi $a2, $a2, 2
	addi $a3, $a3, 2
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra	 

DrawA: # Params: x, y
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $a2, $a0
	move $a3, $a1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, -1
	addi $a3, $a3, -2
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a3, $a3, -1
	jal DrawPixel
	addi $a3, $a3, 2
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


DrawD: # Params: x, y
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $a2, $a0
	move $a3, $a1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, -1
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a3, $a3, -1
	jal DrawPixel
	addi $a3, $a3, -1
	jal DrawPixel
	addi $a3, $a3, -1
	jal DrawPixel
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra	

DrawE:  # Params: x, y
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $a2, $a0
	move $a3, $a1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, -2
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, -2
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

DrawG: # Params: x, y
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $a2, $a0
	move $a3, $a1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, -2
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a3, $a3, -1
	jal DrawPixel
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

DrawO: # Params: x, y
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $a2, $a0
	move $a3, $a1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a3, $a3, -1
	jal DrawPixel
	addi $a3, $a3, -1
	jal DrawPixel
	addi $a3, $a3, -1
	jal DrawPixel
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


DrawP: # Params: x, y
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $a2, $a0
	move $a3, $a1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a3, $a3, -1
	jal DrawPixel
	addi $a3, $a3, 2
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra	

DrawR: # Params: x, y
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $a2, $a0
	move $a3, $a1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, -1
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, 1
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, -2
	addi $a3, $a3, -3
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra 



DrawS:  # Params: x, y
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $a2, $a0
	move $a3, $a1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, -2
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	addi $a2, $a2, -1
	jal DrawPixel
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

DrawT: # Params: x, y
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	move $a2, $a0
	move $a3, $a1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, 1
	jal DrawPixel
	addi $a2, $a2, -1
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	addi $a3, $a3, 1
	jal DrawPixel
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


Exit:
	li $v0, 10
	syscall
	
