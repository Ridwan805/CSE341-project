.MODEL SMALL
.STACK 100H
.DATA
    correct_pass DB '1234$'       ; Correct pass
    user_input DB 4 DUP('$')       ; Array to store user input
    attempts DB 0                  ; Attempt counter
    msg_prompt DB 'Enter 4-digit PIN: $'
    msg_success DB 13,10,'Access Granted$'
    msg_fail DB 13,10,'Wrong PIN. Try again$'
    msg_alarm DB 13,10,'*** ALARM ACTIVATED ***$'

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

START:
    ; Show prompt
    MOV AH, 9
    LEA DX, msg_prompt
    INT 21H

    ; Take 4 characters input, but display '*' for each key pressed
    MOV SI, 0
READ_LOOP:
    MOV AH, 1
    INT 21H                    ; Get user input
    MOV user_input[SI], AL      ; Store the actual input in the array 
    
    MOV DL, 08H             ;One backspace
    MOV AH, 2
    INT 21H
    
    MOV DL, '*'                 ; Display '*' for each key input
    MOV AH, 2
    INT 21H                    ; Output the '*' symbol
    
    INC SI
    CMP SI, 4
    JNE READ_LOOP

    ; Compare input with correct_pass
    MOV SI, 0
    MOV DI, 0
    MOV CX, 4
    MOV BX, 0  ; match counter

CHECK_LOOP:
    MOV AL, user_input[SI]  ; get the actual digit from user_input
    CMP AL, correct_pass[DI] ; Compare the input with stored password
    JNE FAIL
    INC BX
    INC SI
    INC DI
    LOOP CHECK_LOOP

    ; If BX = 4, success
    CMP BX, 4
    JNE FAIL

    ; Success Message
    MOV AH, 9
    LEA DX, msg_success
    INT 21H
    JMP EXIT

FAIL:
    ; Increase attempts
    INC attempts
    MOV AL, attempts
    CMP AL, 3
    JAE ALARM

    ; Show failure msg
    MOV AH, 9
    LEA DX, msg_fail
    INT 21H
    JMP START

ALARM:
    MOV AH, 2
    LEA DX, msg_alarm
    INT 21H  
    JMP SOUND
    ; Loop infinite or halt here
     
SOUND: 
   MOV AL, 1H
   REPEAT: 
   ;Alarm sound
    MOV AH, 2
    MOV DL, 07h
    INT 21H
    CMP AL, 6
    JGE REPEAT
    
    JMP $
    
EXIT:
    MOV AX, 4C00H
    INT 21H
MAIN ENDP
END MAIN
