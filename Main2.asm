.MODEL SMALL
.STACK 100H
.DATA
    correct_pass DB '1234$'        ; Correct pass
    user_input DB 4 DUP('$')        ; Array to store user input
    new_pass DB 4 DUP('$')          ; New PIN to be set
    password_hint DB 20 DUP('$')    ; Store the password hint (max 20 chars)
    security_question DB 100 DUP('$')  ; Security question answer
    attempts DB 0                   ; Attempt counter
    sec_attempts DB 0               ; Security question attempt counter

    ; Messages
    msg_prompt DB 'Enter 4-digit PIN: $'
    msg_success DB 13,10,'Access Granted$'
    msg_fail DB 13,10,'Wrong PIN. Try again$'
    msg_alarm DB 13,10,'*** ALARM ACTIVATED ***$'
    msg_update_pin DB 13,10,'Press P to update PIN, H to update hint, S to set security question.$'
    msg_reset_prompt DB 13,10,'Forgot your PIN? Enter a new one: $'
    msg_reset_success DB 13,10,'PIN successfully changed!$'
    msg_invalid_input DB 13,10,'Invalid input. Please try again.$'
    msg_hint_prompt DB 13,10,'Enter a hint for your PIN (max 20 chars): $'
    msg_hint_success DB 13,10,'Hint saved!$'
    msg_forgot_prompt DB 'Forgot your PIN? (Y/N): $'
    msg_invalid_y_n DB 13,10, 'Please press y/n: $'
    msg_security_question DB 'Enter a security question answer: $'
    msg_security_question_prompt DB 13,10,'Security Question Answer: $'

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

START:
    ; Show prompt for PIN entry
    MOV AH, 9
    LEA DX, msg_prompt
    INT 21H
   
    MOV SI, 0 
    
READ_LOOP:
    MOV AH, 1
    INT 21H                    ; Get user input
    MOV user_input[SI], AL      ; Store the actual input in the array 
    
    MOV DL, 08H             ; One backspace
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
    MOV BX, 0  

CHECK_LOOP:
    MOV AL, user_input[SI]  ; get the actual digit from user_input
    CMP AL, correct_pass[DI] ; Compare the input with stored password
    JNE FAIL                  ; Jump to FAIL if the PIN doesn't match
    INC BX
    INC SI
    INC DI
    LOOP CHECK_LOOP

    ; If BX = 4, success (correct PIN)
    CMP BX, 4
    JNE FAIL                  ; If incorrect, jump to FAIL

    ; Success Message
    MOV AH, 9
    LEA DX, msg_success
    INT 21H
     
    MOV attempts, 0
    

    ; Present options to update PIN, hint, or set security question
    MOV AH, 9
    LEA DX, msg_update_pin
    INT 21H

    ; Wait for user input: P, H, or S for respective actions
    MOV AH, 1
    INT 21H
    MOV BL, AL

    CMP BL, 'P'           ; If 'P' is pressed, update PIN
    JE RESET_PIN
    CMP BL, 'H'           ; If 'H' is pressed, update hint
    JE UPDATE_HINT
    CMP BL, 'S'           ; If 'S' is pressed, set security question
    JE SET_SECURITY_QUESTION

    JMP START

FAIL:
    ; This label is used when the PIN does not match
    INC attempts
    MOV AL, attempts
    CMP AL, 3
    JGE LOCK_DOOR            ; If failed 3 times, lock door and activate alarm

    ; Show failure msg after first failed attempt
    MOV AH, 9
    LEA DX, msg_fail
    INT 21H
    JMP ASK_RESET
    

LOCK_DOOR:
    ; Lock the door after 3 failed attempts, play alarm continuously
    MOV AH, 2
    MOV DL, 07h  ; Buzzer sound (beep)

SOUND:
    INT 21H        ; Trigger the sound
    MOV CX, 5      ; Repeat the sound 5 times (adjust as needed)
    LOOP SOUND     ; Keep ringing indefinitely
    JMP SOUND      ; Loop again for continuous sound

ASK_RESET:
    ; Ask if user wants to reset PIN after 1st failure
     MOV AH, 9
    LEA DX, msg_forgot_prompt
    INT 21H

    ; Read user input for Y/N
    MOV AH, 1
    INT 21H              ; Get input
    MOV BL, AL              ; Store the input in BL
    CMP BL, 'y'          ; If 'Y' for Yes, reset PIN
    JE RESET_PIN
    CMP BL, 'n'          ; If 'N' for No, continue attempts
    JE START             ; Re-prompt for the PIN if 'N' is pressed
    
    ; If input is invalid, show the invalid input message
    MOV AH, 9
    LEA DX, msg_invalid_y_n
    INT 21H 
    JMP ASK_RESET  ; Re-prompt if input is invalid
    
RESET_PIN:
    ; Prompt for password reset
    MOV AH, 9
    LEA DX, msg_reset_prompt
    INT 21H

    ; Take new PIN input
    MOV SI, 0

NEW_PIN_LOOP:
    MOV AH, 1
    INT 21H                    ; Get user input for the new PIN
    MOV new_pass[SI], AL        ; Store the new PIN
    
    MOV DL, 08H                ; One backspace
    MOV AH, 2
    INT 21H
    
    MOV DL, '*'                 ; Display '*' for each key input
    MOV AH, 2
    INT 21H                     ; Output the '*' symbol
    
    INC SI
    CMP SI, 4                   ; Check if 4 digits are entered
    JNE NEW_PIN_LOOP            ; Continue loop until 4 digits are entered

    ; Validate new PIN: make sure it’s not the same as the old one
    MOV SI, 0
    MOV DI, 0
    MOV CX, 4


COMPARE_NEW_PIN:
    MOV AL, new_pass[SI]
    CMP AL, correct_pass[DI]
    JNE VALID_PIN
    INC SI
    INC DI
    LOOP COMPARE_NEW_PIN

    ; Show error if PIN is the same as the old one
    MOV AH, 9
    LEA DX, msg_invalid_input
    INT 21H
    JMP RESET_PIN

VALID_PIN:
    ; Save the new PIN in correct_pass
    MOV SI, 0
    MOV DI, 0
    MOV CX, 4

UPDATE_PIN_DONE:
    MOV AL, new_pass[SI]
    MOV correct_pass[DI], AL    ; Store the new PIN in the correct_pass
    INC SI
    INC DI
    LOOP UPDATE_PIN_DONE

    MOV AH, 9
    LEA DX, msg_reset_success
    INT 21H
    JMP START

UPDATE_HINT:
    ; Update hint prompt
    MOV AH, 9
    LEA DX, msg_hint_prompt
    INT 21H

    ; Take hint input
    MOV SI, 0
HINT_LOOP:
    MOV AH, 1
    INT 21H                    ; Get user input for hint
    MOV password_hint[SI], AL   ; Store the hint in password_hint
    
    MOV DL, 08H                ; One backspace
    MOV AH, 2
    INT 21H
    
    MOV DL, '*'                ; Display '*' for each key input
    MOV AH, 2
    INT 21H                     ; Output the '*' symbol
    
    INC SI
    CMP SI, 20  ; Max 20 chars for hint
    JNE HINT_LOOP

    ; Show success message for hint
    MOV AH, 9
    LEA DX, msg_hint_success
    INT 21H
    JMP START

SET_SECURITY_QUESTION:
    ; Set Security Question prompt
    MOV AH, 9
    LEA DX, msg_security_question
    INT 21H

    ; Take security question input
    MOV SI, 0
    MOV sec_attempts, 0  ; Reset security question attempts
SECURITY_LOOP:
    MOV AH, 1
    INT 21H                    ; Get user input for the security question answer
    MOV security_question[SI], AL   ; Store the answer in security_question
    
    MOV DL, 08H                ; One backspace
    MOV AH, 2
    INT 21H
    
    MOV DL, '*'                ; Display '*' for each key input
    MOV AH, 2
    INT 21H                     ; Output the '*' symbol
    
    INC SI
    CMP SI, 100  ; Max 100 chars for security question answer
    JNE SECURITY_LOOP

    ; For now, assume the answer is always correct
    ; Check for correctness and handle attempt count
    MOV AL, sec_attempts
    INC AL
    MOV sec_attempts, AL

    ; Lock system after 2 incorrect attempts
    CMP sec_attempts, 2
    JAE LOCK_DOOR

    ; Show success message for security question
    MOV AH, 9
    LEA DX, msg_hint_success
    INT 21H
    JMP START

EXIT:
    MOV AX, 4C00H
    INT 21H
MAIN ENDP
END MAIN
