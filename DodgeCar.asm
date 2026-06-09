;COAL PROJECT PHASE 3
;GROUP MEMBERS:
;HAMZA HAIDER 24L-0635 BCS-3H
;HAMZA WYNE 24L-0755 BCS-3H

[org 0x0100]
jmp start

buffer: times 80 dw 0;Buffer to temporary store bottom row while moving screen down
PauseBuffer: times 2000 dw 0;Buffer used to store data before pausing the game, so resume can continue from that point
curCarX: dw 36 ;left side coord also car has width of six
curCarY: dw 19
IncomingX: dw 19
IncomingY: dw 1
TickCount: db 0
seed: dw 1
incomingBonusX: dw 19
incomingBonusY: dw 1
UpdateFlag: dw 0
score: dw 0
isPaused: dw 0
isEnded: dw 0
pauseMsg: db 'Are you sure you want to exit the game?(Y) to exit', 0
resumeMsg: db 'Press ESC to Resume', 0
ScoreMsg: db 'SCORE: ', 0
FinalScoreMsg: db 'FINAL SCORE: ', 0
GameEndedMessage: db 'GAME OVER', 0
GameRestartMsg: db 'Press (R) to Restart The Game', 0
;intro data:
GameNameMsg: db ' !!!! belta ki sawaari !!!! ', 0
rollNumMsg1: db ' 24L-0635 BCS-3H ', 0
rollNumMsg2: db ' 24L-0755 BCS-3H ', 0
nameMsg1: db ' HAMZA HAIDER ', 0
nameMsg2 : db ' HAMZA WYNE ', 0
semesterMsg: db ' Semester: Fall 2025 ', 0
gameRuleMsg: db ' Avoid The Cars And Collect the Bonus Objects ! ' , 0
gameStartMsg: db ' PRESS ANY KEY TO START ! ', 0
GameExitMsg: db 'Press (E) to Terminate The Game', 0

xpos: dw 16;Used by getCords
ypos:dw  0;Used by getCords
speedCounter: db 0;used in timer to slow down the game is required
oldkbisr: dd 0 ;old kbisr
oldTimerisr: dd 0;old timer isr

clrscr:
push ax
push cx
push di
mov ax, 0xB800
mov es,ax
mov cx, 2000
mov di, 0
cld
mov ax,0x0720
rep stosw
pop di
pop cx
pop ax
ret

getLength:;stores the length of 0 terminated message in cx
    push ax
    push si
    xor cx, cx

nextCharLenCheck:
    lodsb
    test al, al
    jz doneGetLength
    inc cx
    jmp nextCharLenCheck

doneGetLength:
    pop si
    pop ax
    ret


printUsingSoftwareInt:
  ; DH=row, DL=col, BL=color, CX=len, SI=string

    push ax
    push bx
    push cx
    push dx
    push si
    push es

    push cs
    pop es
    mov bp, si   ; BP = string offset

    mov ah, 13h  ; Write String
    mov al, 00h  ; donot Update cursor after writing
    mov bh, 0    ; Page 0 always
    int 10h

    pop es
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

printIntroScreen:
mov cx, 2000
mov ax, 0xB800
mov es, ax
mov ax, 0x1F20
mov di, 0
rep stosw;fill blue screen
;printing Name of Game
mov bl, 0x70
mov si, GameNameMsg
call getLength
mov dh, 3
mov dl, 30
call printUsingSoftwareInt

mov si, nameMsg1;Haider name
call getLength
MOV dh, 6
mov dl, 30
call printUsingSoftwareInt
mov si, rollNumMsg1;Haider rollNum
call getLength
MOV dh, 7
mov dl, 30
call printUsingSoftwareInt

mov si, nameMsg2;Wyne name
call getLength
MOV dh, 11
mov dl, 30
call printUsingSoftwareInt
mov si, rollNumMsg2;Wyne rollNum
call getLength
MOV dh, 12
mov dl, 30
call printUsingSoftwareInt

mov si, semesterMsg
call getLength
mov dh, 16
mov dl, 30
call printUsingSoftwareInt

MOV si, gameRuleMsg
call getLength
mov dh, 19
mov dl, 20
call printUsingSoftwareInt


mov si, gameStartMsg
call getLength
mov bl, 0x87
mov dh, 22
mov dl, 25
call printUsingSoftwareInt
IntroInputWait:
mov ah, 0x01
int 0x16
jz IntroInputWait  

ret

printScore:;FOR PRINTING THE SCORE, di has coordinates
push es
push ax
push bx
push cx
push dx
push di
push ds

push cs
pop ds
 
mov ax, 0xB800
mov es, ax
mov ax, [score]
mov bx, 10
mov cx, 0 

DigitToAscii:
mov dx, 0
div bx
add dx, 0x30
push dx;store right most digit to stack for reverse printing
inc cx ;gets length of number in cx
cmp ax, 0
jnz DigitToAscii

;di has coordinate to print number at

PrintingScore:
pop dx              
mov al, dl;get digit in al
mov ah, 0x40 ;red background
stosw
loop PrintingScore ;loops using cx to print all digits

pop ds
pop di
pop dx
pop cx
pop bx
pop ax
pop es

ret



getCords:;stores coordinates in ax using xpos and ypos
push bp
push dx
mov bp, sp
sub word sp, 2
mov word [bp-2], 2
mov ax, 80
mul word [ypos]
add ax, [xpos]
mul word [bp-2]
mov sp, bp
pop dx
pop bp
ret

fillCol:;fills the whole collumn by the given ascii
push bp
mov bp, sp;bp+4 holds xposition, bp+6 holds ascii values to print
push ax
push bx
push word [xpos]
push word [ypos]

mov ax, [bp+4]
mov [xpos], ax
mov ax, 0xB800
mov es, ax
mov word [ypos], 0
filling:
call getCords
mov bx,ax
mov ax, [bp+6]
mov word [es:bx], ax
add word [ypos], 1
cmp word [ypos], 25
jne filling
pop word [ypos]
pop word [xpos]
pop bx
pop ax
pop bp

ret 4

AlternateFillCol:;fills the whole collumn by the given ascii and then another given ascii 
push bp
mov bp, sp;bp+4 holds xposition, bp+6 holds ascii values to print, bp+8 holds second ascii to print
push ax
push bx
push word [xpos]
push word [ypos]
push cx

mov ax, [bp+4]
mov [xpos], ax
mov ax, 0xB800
mov es, ax
mov word [ypos], 0

fillingAlternate:; for even printing across 25 rows, prints 3 of one ascii and 2 of another ascii consecutively, 5 times (5*5 = 25)
mov cx, 3;for looping an ascii printing 3 times
fillThreeTimes:
call getCords
mov bx,ax
mov ax, [bp+6]
mov word [es:bx], ax
add word [ypos], 1
loop fillThreeTimes
mov cx, 2; for looping printing two times
fillTwoTimes:
call getCords
mov bx,ax
mov ax, [bp+8]
mov word [es:bx], ax
add word [ypos], 1
loop fillTwoTimes
cmp word [ypos], 25
jne fillingAlternate

doneFillingAlternate:

pop cx
pop word [ypos]
pop word [xpos]
pop bx
pop ax
pop bp

ret 6


printLane:
push ax

mov ax, 0xB800
mov es,ax

mov ax, 15
printingRoad:;add Road Color
push word 0x77DB
push ax
call fillCol
add ax, 1
cmp ax, 65
jne printingRoad

mov ax, 31
printingLanes:;add lane markings
push word 0x77DB
push word 0x7FDB
push ax
call AlternateFillCol
add ax, 17
cmp ax, 65
jne printingLanes

pop ax
ret

printCar:
push ax
push bx
push cx
push di
push si
push word [xpos]
push word [ypos]
push dx

mov ax, 0xB800
mov es, ax
mov dx, [curCarX];36 +or- 15
mov bx, [curCarY]; 19
;Siren light:
push bx
add bx, 2;21
mov word [xpos], dx
mov word [ypos], bx
pop bx;19
call getCords
mov di, ax
mov cx, 8; width
mov ax, 0xC112
rep stosw

;Red body:
push bx
add bx, 1;20
mov word [xpos], dx
mov word [ypos], bx
pop bx;19
call getCords
mov di, ax
mov cx, 8
mov ax, 0x44DB
rep stosw
cmp word [isEnded], 1
je noScorePrintOnCar
;printing Score on car:
sub di, 10
call printScore

noScorePrintOnCar:
;Red body next row:
push bx;19
add bx, 3
mov word [xpos], dx
mov word [ypos], bx;22
pop bx
call getCords
mov di, ax
mov cx, 8
mov ax, 0x44DB
rep stosw
;Black endings of car:
mov word [xpos], dx
mov word [ypos], bx;19
call getCords
mov di, ax
mov cx, 8
mov ax, 0x00DB
rep stosw

push bx
add bx, 4
mov word [xpos], dx
mov word [ypos], bx;23
pop bx
call getCords
mov di, ax
mov cx, 8
mov ax, 0x00DB
rep stosw

;Yellow Headlights:
mov word [xpos], dx
mov word [ypos], bx;19
call getCords
mov di, ax
mov ax, 0x0E4F
mov word [es:di], ax

add dx, 7

mov word [xpos], dx
mov word [ypos], bx;19
call getCords
mov di, ax
mov ax, 0x0E4F
mov word [es:di], ax

pop dx
pop word [ypos]
pop word [xpos]
pop si
pop di
pop cx
pop bx
pop ax
ret


;Printing incoming Car:
printIncomingCar:
push ax
push bx
push cx
push di
push si
push word [xpos]
push word [ypos]
push dx

mov ax, 0xB800
mov es, ax
mov dx, [IncomingX];36 +or- 15?
mov bx, [IncomingY]; 19
;Yellow middle part:
push bx
add bx, 2;21
mov word [xpos], dx
mov word [ypos], bx
pop bx;19
call getCords
mov di, ax
mov cx, 8;7 width
mov ax, 0x0EDb
rep stosw

;blue body:
push bx
add bx, 1;20
mov word [xpos], dx
mov word [ypos], bx
pop bx;19
call getCords
mov di, ax
mov cx, 8
mov ax, 0x01DB;Blue square
rep stosw

push bx;19
add bx, 3
mov word [xpos], dx
mov word [ypos], bx;22
pop bx
call getCords
mov di, ax
mov cx, 8
mov ax, 0x01DB
rep stosw
;brown endings of car:
mov word [xpos], dx
mov word [ypos], bx;19
call getCords
mov di, ax
mov cx, 8
mov ax, 0x06DB;brown squae
rep stosw

push bx
add bx, 4
mov word [xpos], dx
mov word [ypos], bx;23
pop bx
call getCords
mov di, ax
mov cx, 8
mov ax, 0x06DB
rep stosw

;Red Headlights:
add bx, 4
mov word [xpos], dx
mov word [ypos], bx;
call getCords
mov di, ax
mov ax, 0x144F
mov word [es:di], ax

add dx, 7

mov word [xpos], dx
mov word [ypos], bx;
call getCords
mov di, ax
mov ax, 0x144F
mov word [es:di], ax

pop dx
pop word [ypos]
pop word [xpos]
pop si
pop di
pop cx
pop bx
pop ax
ret

printBonusObject:;collision with Bonus Object increases Score by 1
push ax
push bx
push cx
push di
push si
push word [xpos]
push word [ypos]
push dx

mov ax, 0xB800
mov es, ax
mov dx, [incomingBonusX];from random generator
mov bx, [incomingBonusY]; 1
add dx, 3
mov word [xpos], dx
mov word [ypos], bx
call getCords
mov di, ax

sub di, 6
mov ah, 0x2F;attribute byte for bonus Object
mov cx, 3
mov al, '+'
rep stosw
mov al, '/'
stosw
mov al, 92 ;ascii for '\'
stosw
mov cx, 3
mov al, '+'
rep stosw
add di, 160
sub di, 16
mov cx, 3
mov al, '+'
rep stosw
mov al, 92 ;ascii for '\'
stosw
mov al, '/'
stosw
mov cx, 3
mov al, '+'
rep stosw
pop dx
pop word [ypos]
pop word [xpos]
pop si
pop di
pop cx
pop bx
pop ax
ret

drawTree:
; bp+4 = x position (root), bp+6 = y position (root/bottom)
push bp
mov bp, sp
push ax
push bx
push cx
push di
push word [xpos]
push word [ypos]

mov ax, 0xB800
mov es, ax

; Get root position
mov ax, [bp+4]  ; x position
mov bx, [bp+6]  ; y position (bottom of tree)

; Row 6 (bottom): Brown trunk
mov [xpos], ax
mov [ypos], bx
call getCords
mov di, ax
mov ax, 0x26DB  ; Brown block on green background
stosw

; Row 5: Brown trunk
sub bx, 1
mov [ypos], bx
call getCords
mov di, ax
mov ax, 0x26DB  ; Brown block on green background
stosw

; Row 4: Green leaves (3 wide)
sub bx, 1
push ax
mov ax, [bp+4]
sub ax, 1  ; Start one position left
mov [xpos], ax
pop ax
mov [ypos], bx
call getCords
mov di, ax
mov cx, 3
mov ax, 0x2ADB  ;Dark green leaves
rep stosw

; Row 3: Green leaves (5 wide)
sub bx, 1
push ax
mov ax, [bp+4]
sub ax, 2  ; Start two positions left
mov [xpos], ax
pop ax
mov [ypos], bx
call getCords
mov di, ax
mov cx, 5
mov ax, 0x2ADB  ; Dark green leaves
rep stosw

; Row 2: Green leaves (3 wide)
sub bx, 1
push ax
mov ax, [bp+4]
sub ax, 1
mov [xpos], ax
pop ax
mov [ypos], bx
call getCords
mov di, ax
mov cx, 3
mov ax, 0x2ADB  ; Dark green leaves
rep stosw

; Yellow star
sub bx, 1
mov ax, [bp+4]
mov [xpos], ax
mov [ypos], bx
call getCords
mov di, ax
mov ax, 0x2E2A  ; (star on top)
stosw

pop word [ypos]
pop word [xpos]
pop di
pop cx
pop bx
pop ax
pop bp
ret 4  ;
 


printLandScape:
;from x position 0-16 && 64-80
mov word [xpos], 0
mov word [ypos], 0
mov cx, 0
printingGreen:
call getCords
mov bx, ax
mov word [es:bx], 0x22DB
add word [ypos],1
cmp word [ypos], 25
jne printingGreen
mov word [ypos], 0
add word [xpos], 1
cmp word [xpos], 15
jb printingGreen
mov word [xpos], 64
mov word[ypos], 0
add cx, 1
add [xpos], cx
cmp word [xpos], 80
jne printingGreen

;footpath:
mov ax, 0x0EDB
push ax
mov ax, 0x00DB 
push ax
mov ax, 14
push ax
call AlternateFillCol
mov ax, 0x0EDB
push ax
mov ax, 0x00DB 
push ax
mov ax, 65
push ax
call AlternateFillCol
;drawing trees

mov ax, 10
push ax
mov ax, 6
push ax
call drawTree
mov ax, 22
push ax
mov ax, 8
push ax
call drawTree
mov ax, 18
push ax
mov ax, 76
push ax
call drawTree
mov ax, 5
push ax
mov ax, 70
push ax
call drawTree
ret

drawBelowCar:;draws the road below the car otherwise the car is moved down as well
	push cx
	push ax
	push di
	
	mov cx, 8
	mov ax, [curCarX]
	mov [xpos], ax
	mov ax, [curCarY]
	mov [ypos], ax
	call getCords
	add ax, 5*160
	mov di, ax;coords of row part right below the car
	mov ax, 0x77DB;road grey color
	rep stosw
	
	pop di
	pop ax
	pop cx
	ret
	
MoveScreen: ; Move screen down by one row, last row goes to top

    push ds
    push es
	push ax
	push cx
	push bx
	cld
    ; copy last row (row 24) to buffer
    mov ax, 0xB800
    mov ds, ax           
    mov si, 3840        
    mov ax, cs
    mov es, ax           
    mov di, buffer
    mov cx, 80           
    cld
    rep movsw

    ; scroll screen down
    mov ax, 0xB800
    mov ds, ax
    mov es, ax
    std                 
    mov si, 3998 - 80*2  
    mov di, 3998        
    mov cx, 24*80        
    rep movsw
    cld                

    ; copy buffer (old bottom row) to top row and also skip the cars printing
    mov ax, 0xB800
    mov es, ax
    mov di, 0
    mov ax, cs
    mov ds, ax
    mov si, buffer
    mov cx, 80
	cld
	mov bx, [curCarX]
	shl bx, 1
	LoadBufferToTop:
	lodsw
	stosw
	;if buffer is not road, not grass and not lane markings then it must be incoming cars or bonus object which must not be printed:
	mov ax, di
	cmp ax, 30;road area entered
	jb stopCheck
	cmp ax, 129;check if not exceeding the road area
	ja stopCheck
	
	cmp word [si], 0x77DB
	je stopCheck
	cmp word [si], 0x7FDB
	je stopCheck
	mov word [si], 0x77DB
	
	stopCheck:
	cmp di, bx;if equal that means di is at the cars location and it should not copy these car coordinates to the top row as well thus make appropriate changes so it skips the car's coordinates
	jne DontSkip
	add di, 16;car width is 7 and 7*2 = 14 and +2 to go next 
	add si, 16
	sub cx, 8
	call drawBelowCar;draws road below car, so the car is not moved down to the last row
	
	DontSkip:
	loop LoadBufferToTop
	pop bx
	pop cx
	pop ax
    pop es
    pop ds
    ret
	
getRand:;uses seed to generate a random number for object and incoming cars spawning
    push bx
    push cx
    push dx

    mov ax, [seed]      ; Load current seed
    mov bx, 25173   
    mul bx           

    add ax, 13849     ; Add increment
    mov [seed], ax      ; Update seed

    xor dx, dx
    mov cx, 3
    div cx            ; remainder in DX

    mov al, dl        ; Move to AL, dl = 0-2
    mov bl, 17
    mul bl            ; multiply by 17 to switch lane ex: 17*2 + 19 = 53 which is the rightmost lane coordinate for player car
	add al, 19
    pop dx
    pop cx
    pop bx
    ret

initSeed:;USES CURRENT SYSTEM TIME TO TO GET A SEED WHICH IS FURTHER USED TO GENERATE RANDOM NUMBERS
	push ax
	push dx
    mov ah, 00h
    int 1Ah           ;gets the current time of the system in CX:DX
    mov [seed], dx      ; Store seed
	pop dx
	pop ax
    ret

	



CheckCollision:;Function To Check for incoming cars collision with player car
push ax
push bx
push di
push word [xpos]
push word [ypos]
push cx
mov ax, [curCarX]
mov bx, [curCarY]
mov [xpos], ax
mov [ypos], bx

call getCords

mov di, ax;Compares Top left block of our car to check for collisions with incoming car
mov ax,[es:di]
cmp ax,  0x77DB
je noFrontCollision
cmp ax, 0x144F ;check collision of front with red headlight of incoming
je CollisionFound
cmp ax, 0x01DB;check collision with blue body of incoming Car
je CollisionFound
cmp ax, 0x0EDb ;check collision with yellow middle area of incoming Car
je CollisionFound
cmp ax, 0x06DB ;check collision with brown ending of incoming Car
je CollisionFound

noFrontCollision:
add di, 160*4;last bottom left block of car
mov ax, [es:di];Compares bottom left block of our car to check for collisions with incoming car
cmp ax, 0x44DB
je noCollision ;if last block is equal to the red body after screen moves down it has not collided
cmp ax, 0x01DB ;check collision with blue body of incoming Car
je CollisionFound
cmp ax, 0x0EDb ;check collision with yellow middle area of incoming Car
je CollisionFound
cmp ax, 0x06DB ;check collision with brown ending of incoming Car
je CollisionFound

jmp noCollision

jmp noCollision
mov cx,8; to loop collision found
CollisionFound:;with delays to make a blinking effect
mov word [isEnded], 1
call EnlargeCar
call Delay
call Delay
call Delay
call Delay
call Delay
call Delay
call Delay
call Delay
call Delay
call Delay
call Delay
call Delay
call Delay
call Delay
call Delay
call Delay
call Delay
loop CollisionFound
pop cx
pop word [ypos]
pop word [xpos]
pop di
pop bx
pop ax
mov al, 0x20;EOI
out 0x20, al
jmp EndGame


noCollision:
pop cx
pop word [ypos]
pop word [xpos]
pop di
pop bx
pop ax
ret

EnlargeCar:;blinks the car for when collision occurs
push ax
push bx
push di
push word [xpos]
push word [ypos]
push cx

mov ax, [curCarX]
mov bx, [curCarY]
mov [xpos], ax
mov [ypos], bx
call getCords
mov di, ax

mov cx, 8;widht of car
mov bx, 5;height of car
mov ax, 0xFCDB;pink color ascii to fill the car with
printLargeCar:
rep stosw
mov cx, 8
add di, 160
sub di, 16
dec bx
jnz printLargeCar

pop cx
pop word [ypos]
pop word [xpos]
pop di
pop bx
pop ax
ret

CollectBonusObject:;when collected, highlight the car and enlarge it this way it will also remove the bonus Object completely
push ax
push bx
push di
push word [xpos]
push word [ypos]
push cx
push es

mov ax, 0xB800
mov es,ax

sub si, 2;The function is called when the object is found at coordinates si, so we use si to replace a row above it(as object is two rows) to avoid collecting the object twice
sub si, 160
mov cx, 8
mov ax, 0x77DB
ReplaceBonusObj:
mov word [es:si], ax
add si ,2
loop ReplaceBonusObj

call EnlargeCar

pop es
pop cx
pop word [ypos]
pop word [xpos]
pop di
pop bx
pop ax
ret


checkBonusCollision:
push ds
push es
push word [xpos]
push word [ypos]
push di
push bx
push ax
mov ax ,[curCarX]
mov bx, [curCarY]
mov [xpos],ax
mov [ypos], bx
call getCords
mov si, ax

mov cx, 5

push es
pop ds
cld
checkingBonus:
lodsw 
cmp ah, 0x2F;0x2F attribute byte of bonus object
je foundBonus
add si, 160
sub si, 2
loop checkingBonus
add si, 160
sub si, 16
mov cx, 8
dec bx
jnz checkingBonus
jmp NoBonusFound
foundBonus:
add word [cs:score], 1 ;ds is pointing to video memory right now, hence need cs:score
call CollectBonusObject
NoBonusFound:

pop ax
pop bx
pop di
pop word [ypos]
pop word [xpos]
pop es
pop ds

ret

Delay:
push cx
mov cx,0xFFFF
del:
loop del
pop cx
ret

drawroadOnCar:;draws road on car's old location after it has moved
push ax
push bx
push di
push cx
mov ax, [curCarX]
mov bx, [curCarY]
mov [xpos], ax
mov [ypos], bx
call getCords
mov di, ax
mov cx, 8;for width
mov ax, 0x77DB;roads ascii
mov bx, 5;for height
printingRoadOnCar:
rep stosw
mov cx, 8
add di, 160
sub di, 16
sub bx, 1
jnz printingRoadOnCar
pop cx
pop di
pop bx
pop ax
ret

pauseGame:;pauses the game by using the interrupt mask port and disabling timer and returning to old kbisr
push ax
push si
push di
push cx
push es
push ds
in al, 0x21;mask timer interrupts
or al, 1
out 0x21, al
mov cx, 2000
mov di, PauseBuffer
mov si, 0
push cs
pop es
mov ax, 0xB800
mov ds,ax
rep movsw
call clrscr
mov ax, 0xB800
mov es, ax

push cs
pop ds

mov bl, 0x07;set attribute for printing using software Interrupts
printingPauseText:; DH=row, DL=col, BL=color, CX=len, SI=string
	
	mov dh, 14
	mov dl, 18
	
	mov si, pauseMsg
	call getLength;in cx
	call printUsingSoftwareInt
  
    
 

printingResumeText:
mov dh, 10
mov dl, 30
mov si, resumeMsg
call getLength
call printUsingSoftwareInt



printingScoreText:
mov dh, 5
mov dl, 30
mov si, ScoreMsg
call getLength
call printUsingSoftwareInt
push di
mov di, 880
call printScore
pop di
call clearKeyboardBuffer ;clears the keyboard buffer before processing inputs
waitInput:;handles software interrupts while paused
mov ah, 0x00
int 0x16
cmp al, 'Y'
je EndTheGame
cmp al, 'y'
je EndTheGame
cmp ah, 0x01 ;escape key
je resumeGame
jmp waitInput
EndTheGame:
pop ds
pop es
pop cx
pop di
pop si
pop ax
mov word [isEnded], 1
jmp EndGame;UNCONDITIONAL JUMP TO ENDGAME IF isENDED is 1
jmp PauseDone
resumeGame:
	in al, 0x21
	and al, 0xFC;enables irq 0 and irq1 aka timer and keyboard irq
	out 0x21, al
	call copyFrontPauseBuffer ;copy data from pause buffer to restore the progress of the game from where it was paused
	mov word [isPaused], 0 ;clear pause flag
jmp PauseDone
PauseDone:
pop ds
pop es
pop cx
pop di
pop si
pop ax
ret

resetGame:;resets all required varialbes
mov word [score], 0
mov word [curCarX], 36
mov word [curCarY], 19
mov word [UpdateFlag], 0
mov word [TickCount], 0
mov word [isPaused], 0
ret

fillScreenRed:;fills screen with red for game over screen
mov di, 0
mov cx, 2000
mov ax, 0x44DB
rep stosw
ret

EndGame:;Function to call necessary functions to end game and print end game messages

in al, 0x21;mask timer interrupts
or al, 1
out 0x21, al
call fillScreenRed


printingFinalText:
mov si, FinalScoreMsg
call getLength
mov dh, 5
mov dl, 24
mov bl, 0x40;red color
call printUsingSoftwareInt

push di
mov di, 880
call printScore
pop di

mov si, GameEndedMessage
call getLength
mov dh, 10
mov dl, 35
printingGameEndText:
call printUsingSoftwareInt


mov si, GameRestartMsg
call getLength
mov dh, 14
mov dl, 25

printingGameRestartText:
call printUsingSoftwareInt

mov si, GameExitMsg
call getLength
mov dh, 16
mov dl, 25

printingGameExitText:
call printUsingSoftwareInt

call resetGame;resets all required varialbes
call printCar; :) 

call clearKeyboardBuffer ;clears the keyboard buffer before processing inputs
getRestartInput:;using software interrupts as  required
mov ah, 0x00
int 0x16
cmp al, 'R';check 'R' for restart
je RestartGame
cmp al, 'r'
je RestartGame
 cmp al, 'E'
    jne checkLower
    jmp terminateGame

checkLower:
    cmp al, 'e'
    jne getRestartInput
    jmp terminateGame

RestartGame:
mov word [isEnded], 0
call clrscr
in al, 0x21
and al, 0xFC;enables irq 0 and irq1 aka timer and keyboard irq
out 0x21, al

jmp Restart

;ret

copyFrontPauseBuffer:;copies the wholes screen to the pause buffer
push ax
push si
push di
push cx 
push es
push ds

push cs 
pop ds
mov ax, 0xB800
mov es, ax
mov si, PauseBuffer
mov di, 0
mov cx, 2000
rep movsw


pop ds
pop es
pop cx
pop di
pop si
pop ax
ret

clearKeyboardBuffer:
    push ax
clearLoop:
    mov ah, 0x01    ; Check if key is available
    int 0x16
    jz bufferEmpty  ; If no key, buffer is empty
    mov ah, 0x00    ; Read and discard the key
    int 0x16
    jmp clearLoop   ; Keep clearing until empty
bufferEmpty:
    pop ax
    ret

kbisr:
    push ax
    push bx
    push es
    push ds              
    
    push cs             
    pop ds

    in al, 0x60;get key input in al
	cmp word [isEnded], 1
	je ifEnded
	cmp word [isPaused],1
	je skipLaneMoves

    test al, 0x80;?
    jnz noPress

    cmp al, 0x4B; move left check
    je moveLeft
	
    cmp al, 0x4D ;move right check
    je moveRight

	cmp al, 0x01 ;Escape character check(for pause)
	jne noPress
	mov word [isPaused], 1;set pause flag
	mov al, 0x20        ; Send EOI BEFORE calling pause
    out 0x20, al
	pop ds
    pop es
    pop bx
    pop ax
	call pauseGame ;implemented using Software interrupts as required
	iret
	jmp noPress
	
	
    jmp noPress

moveLeft:
	mov word [isPaused], 0
    cmp word [curCarX], 19
    je noPress
	call CheckCollision
	
	call drawroadOnCar
    sub word [curCarX], 17
    jmp noPress
	
moveRight:
    cmp word [curCarX], 53
    je noPress
	call CheckCollision
	
	call drawroadOnCar
    add word [curCarX], 17
    jmp noPress
	
	skipLaneMoves:;checks for when the game is paused
	
	
	jmp noPress
	
	
	
	ifEnded:;if game has ended
	jmp noPress
	
noPress:
    
	mov al, 0x20;EOI
    out 0x20, al
    pop ds              
    pop es
    pop bx
    pop ax
    jmp far [cs:oldkbisr]

Timer:;timer interrupt

;uncomment below code if game runs too fast on the device(set cmp as required):

;inc byte [cs:speedCounter]
;cmp byte [cs:speedCounter], 1  ; Only move every x timer ticks, to slow down the game a bit
;jb skipMovement
;mov byte [cs:speedCounter], 0  ; Reset counter

call MoveScreen
call checkBonusCollision
call CheckCollision
call printCar
mov word [UpdateFlag], 1;update flag to reduce load on timer

;skipMovement:

mov al, 0x20;send EOI
out 0x20, al
iret

Animation:;HANDLES RANDOM SPAWNING USING THE UPDATE FLAG FROM TIMER, THIS METHOD REDUCES LOAD ON TIMER AND ALLOWS IT TO BE EXECUTED WITHIN ONE TICK, change spawn values to control spawn rate
cmp word [UpdateFlag], 1
jne Animation
mov word [UpdateFlag], 0
inc byte [cs:TickCount]
cmp byte [TickCount], 0 ;spawns bonus 
je SpawnBonus
cmp byte [TickCount], 9 ;spawns bonus
jne NoBonus
SpawnBonus:
call getRand ;rand in ax
mov [incomingBonusX], ax
call printBonusObject
NoBonus:
cmp byte [TickCount], 18 ;every x/18 seconds as tick increases approx 18 every second
jb noSpawn
call getRand;random in ax
mov [IncomingX], ax
call printIncomingCar
mov byte [TickCount], 0
noSpawn:



jmp Animation

start:
call printIntroScreen
;storing kbisr
xor ax, ax
mov es, ax
mov ax, [es:9*4]
mov [oldkbisr], ax
mov ax, [es:9*4+2]
mov [oldkbisr+2], ax

;storing timer:
mov ax, [es:8*4]
mov [oldTimerisr], ax
mov ax, [es:8*4 + 2]
mov [oldTimerisr+2], ax

call initSeed

cli
mov word [es:8*4], Timer;hooked timer which increments tickcount every tick
mov [es:8*4+2], cs

xor ax, ax
mov es, ax

mov word [es:9*4], kbisr
mov [es:9*4 + 2], cs

Restart:
cli
call clrscr
call printLane
call printLandScape
sti
call Animation

terminateGame:
;Unhook interrupts
in al, 0x21
and al, 0xFC;enables irq 0 and irq1 aka timer and keyboard irq if blocked
out 0x21, al
cli
xor ax, ax
mov es, ax
mov ax, [oldkbisr]
mov bx, [oldkbisr+2]
mov [es:9*4], ax;
mov [es:9*4+2],  bx

mov ax, [oldTimerisr]
mov bx, [oldTimerisr+2]
mov [es:8*4], ax
mov [es:8*4 + 2], bx
sti
call clrscr
mov ax, 0x4c00	;terminate the program
int 0x21