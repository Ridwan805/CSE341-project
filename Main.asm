.MODEL SMALL
.STACK 100H
.DATA
    correct_pass       DB '1234$'          ; 4-digit PIN + '$'
    user_input         DB 4 DUP('$')      ; buffer for entered PIN
    new_pass           DB 4 DUP('$')      ; buffer for new PIN
    password_hint      DB 'Default hint$' ; initialize with default hint
    attempts           DB 0               ; wrong-PIN counter
    
    ; Security Question System
    security_question  DB 'What is your pet name?$'  ; default question
    security_answer    DB 'fluffy$'       ; default answer
    temp_answer        DB 20 DUP('$')     ; temporary buffer for answer verification
    user_answer        DB 20 DUP('$')     ; buffer for user's answer
    question_set       DB 1               ; flag (1=question is set by default)
    
    ; History Logging System
    history_log        DB 100 DUP('$')    ; buffer for history (100 bytes)
    history_ptr        DW 0               ; pointer to current position in history
    
    ; Messages
    msg_prompt         DB 'Enter 4-digit PIN: $'
    msg_success        DB 13,10,'Access Granted!$'
    msg_fail           DB 13,10,'Wrong PIN. Try again.$'
    msg_alarm          DB 13,10,'*** ALARM ACTIVATED ***$'
    msg_forgot_prompt  DB 13,10,'Forgot your PIN? (Y/N): $'
    msg_reset_prompt   DB 13,10,'Enter new PIN: $'
    msg_invalid_input  DB 13,10,'Invalid input or same as old PIN.$'
    msg_reset_success  DB 13,10,'PIN successfully changed!$'
    msg_hint_prompt    DB 13,10,'Enter a hint for your PIN (max 20 chars): $'
    msg_hint_success   DB 13,10,'Hint saved!$'
    msg_view_hint      DB 13,10,'Would you like to see your password hint? (Y/N): $'
    msg_show_hint      DB 13,10,'Your password hint is: $'
    msg_question_prompt DB 13,10,'Would you like to set up a security question? (Y/N): $'
    msg_enter_question  DB 13,10,'Enter your security question (max 50 chars): $'
    msg_enter_answer    DB 13,10,'Enter the answer (max 20 chars): $'
    msg_verify_answer   DB 13,10,'Verify your answer: $'
    msg_question_saved  DB 13,10,'Security question and answer saved!$'
    msg_answer_prompt   DB 13,10,'Answer your security question to reset PIN: $'
    msg_answer_correct  DB 13,10,'Correct answer! You may now reset your PIN.$'
    msg_answer_wrong    DB 13,10,'Wrong answer. Access denied.$'
    msg_answer_mismatch DB 13,10,'Answers did not match. Please try again.$'
    msg_menu           DB 13,10,'Options:',13,10,'1. Change PIN',13,10,'2. Set security question',13,10,'3. View history',13,10,'4. Exit',13,10,'Choice: $'
    msg_history        DB 13,10,'--- Activity History ---$'
    newline            DB 13,10,'$'

.CODE
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX
    MOV ES,AX         ; for string operations

    ; Initialize history log
    LEA DI, history_log
    MOV history_ptr, DI
    LEA SI, msg_prompt+2  ; Skip CR,LF in message
    
    ; Copy the initialization message to history log
INIT_HISTORY:
    MOV AL, [SI]
    CMP AL, '$'
    JE START_PROGRAM
    MOV [DI], AL
    INC SI
    INC DI
    JMP INIT_HISTORY

START_PROGRAM:
    MOV history_ptr, DI  ; Update history pointer

START:
    ; Log login attempt
    LEA SI, msg_prompt+2  ; Skip CR,LF
    MOV DI, history_ptr
    
    ; Add newline if not at start
    CMP DI, OFFSET history_log
    JE LOG_MSG
    MOV AL, 13
    MOV [DI], AL
    INC DI
    MOV AL, 10
    MOV [DI], AL
    INC DI
    
LOG_MSG:
    ; Copy message to history
    MOV AL, [SI]
LOG_COPY:
    CMP AL, '$'
    JE LOG_DONE
    MOV [DI], AL
    INC SI
    INC DI
    MOV AL, [SI]
    JMP LOG_COPY
LOG_DONE:
    MOV history_ptr, DI

    ; Prompt for PIN
    MOV AH,9
    LEA DX,msg_prompt
    INT 21h

    ; Read 4 keystrokes, echo backspace + '*'
    MOV SI,0
READ_LOOP:
    MOV AH,1
    INT 21h
    MOV user_input[SI],AL

    MOV DL,08h        ; backspace
    MOV AH,2
    INT 21h
    MOV DL,'*'
    MOV AH,2
    INT 21h

    INC SI
    CMP SI,4
    JNE READ_LOOP

    ; Compare entered PIN vs correct_pass
    MOV SI,0
    MOV DI,0
    MOV CX,4
    MOV BX,0         ; match count

CHECK_LOOP:
    MOV AL,user_input[SI]
    CMP AL,correct_pass[DI]
    JNE FAIL
    INC BX
    INC SI
    INC DI
    LOOP CHECK_LOOP

    CMP BX,4
    JNE FAIL

    ; Correct PIN!
    MOV AH,9
    LEA DX,msg_success
    INT 21h
    MOV attempts,0    ; reset counter

    ; Log successful login
    LEA SI, msg_success+2
    MOV DI, history_ptr
    
    ; Add newline
    MOV AL, 13
    MOV [DI], AL
    INC DI
    MOV AL, 10
    MOV [DI], AL
    INC DI
    
    ; Copy message to history
    MOV AL, [SI]
LOG_SUCCESS:
    CMP AL, '$'
    JE SUCCESS_LOGGED
    MOV [DI], AL
    INC SI
    INC DI
    MOV AL, [SI]
    JMP LOG_SUCCESS
SUCCESS_LOGGED:
    MOV history_ptr, DI

    ; Show menu after successful login
SHOW_MENU:
    MOV AH,9
    LEA DX,msg_menu
    INT 21h

    ; Get user choice
    MOV AH,1
    INT 21h

    ; Process menu choice
    CMP AL,'1'
    JE CHANGE_PIN
    CMP AL,'2'
    JE SETUP_SECURITY_QUESTION
    CMP AL,'3'
    JE VIEW_HISTORY
    CMP AL,'4'
    JE EXIT
    JMP SHOW_MENU     ; Invalid choice, show menu again

CHANGE_PIN:
    ; Reset flow
    MOV AH,9
    LEA DX,msg_reset_prompt
    INT 21h

    ; Read new 4-digit PIN
    MOV SI,0
NEW_PIN_LOOP:
    MOV AH,1
    INT 21h
    MOV new_pass[SI],AL

    MOV DL,08h
    MOV AH,2
    INT 21h
    MOV DL,'*'
    MOV AH,2
    INT 21h

    INC SI
    CMP SI,4
    JNE NEW_PIN_LOOP

    ; Compare new_pass vs correct_pass to prevent reuse
    MOV SI,0
    MOV DI,0
    MOV CX,4

CHECK_SAME:
    MOV AL,new_pass[SI]
    CMP AL,correct_pass[DI]
    JNE  UPDATE_OK    ; if any byte differs, it's new
    INC SI
    INC DI
    LOOP CHECK_SAME

    ; If all 4 matched, show invalid input & retry
    MOV AH,9
    LEA DX,msg_invalid_input
    INT 21h
    JMP CHANGE_PIN

UPDATE_OK:
    ; Copy new_pass to correct_pass
    MOV SI,0
    MOV DI,0
    MOV CX,4
COPY_LOOP:
    MOV AL,new_pass[SI]
    MOV correct_pass[DI],AL
    INC SI
    INC DI
    LOOP COPY_LOOP

    ; Log password change
    LEA SI, msg_reset_success+2
    MOV DI, history_ptr
    
    ; Add newline
    MOV AL, 13
    MOV [DI], AL
    INC DI
    MOV AL, 10
    MOV [DI], AL
    INC DI
    
    ; Copy message to history
    MOV AL, [SI]
LOG_RESET:
    CMP AL, '$'
    JE RESET_LOGGED
    MOV [DI], AL
    INC SI
    INC DI
    MOV AL, [SI]
    JMP LOG_RESET
RESET_LOGGED:
    MOV history_ptr, DI

    ; Prompt for hint update after PIN reset
    MOV AH,9
    LEA DX,msg_hint_prompt
    INT 21h

    MOV SI,0
HINT_LOOP:
    MOV AH,1
    INT 21h
    CMP AL,13        ; Enter key
    JE HINT_DONE
    MOV password_hint[SI],AL

    

    INC SI
    CMP SI,20
    JNE HINT_LOOP
    
HINT_DONE:
    ; Properly terminate the hint string
    MOV password_hint[SI], '$'
    
    MOV AH,9
    LEA DX,msg_hint_success
    INT 21h
    
    ; Log hint update
    LEA SI, msg_hint_success+2
    MOV DI, history_ptr
    
    ; Add newline
    MOV AL, 13
    MOV [DI], AL
    INC DI
    MOV AL, 10
    MOV [DI], AL
    INC DI
    
    ; Copy message to history
    MOV AL, [SI]
    JE EXIT
LOG_HINT:
    CMP AL, '$'
    JE HINT_LOGGED
    MOV [DI], AL
    INC SI
    INC DI
    MOV AL, [SI]
    JMP LOG_HINT
HINT_LOGGED:
    MOV history_ptr, DI

    JMP SHOW_MENU

SETUP_SECURITY_QUESTION:
    ; Prompt for security question
    MOV AH,9
    LEA DX,msg_enter_question
    INT 21h
    
    ; Read security question
    MOV SI,0
QUESTION_LOOP:
    MOV AH,1
    INT 21h
    CMP AL,13          ; Check for Enter key
    JE QUESTION_DONE
    MOV security_question[SI],AL
    INC SI
    CMP SI,50
    JNE QUESTION_LOOP
QUESTION_DONE:
    MOV security_question[SI], '$'  ; Null-terminate
    
    ; Prompt for answer
    MOV AH,9
    LEA DX,msg_enter_answer
    INT 21h
    
    ; Read security answer
    MOV SI,0
ANSWER_LOOP:
    MOV AH,1
    INT 21h
    CMP AL,13          ; Check for Enter key
    JE ANSWER_DONE
    MOV security_answer[SI],AL
    INC SI
    CMP SI,20
    JNE ANSWER_LOOP
ANSWER_DONE:
    MOV security_answer[SI], '$'    ; Null-terminate
    
    ; Verify answer by asking to enter it again
    MOV AH,9
    LEA DX,msg_verify_answer
    INT 21h
    
    ; Read verification answer
    MOV SI,0
VERIFY_LOOP:
    MOV AH,1
    INT 21h
    CMP AL,13          ; Check for Enter key
    JE VERIFY_DONE
    MOV temp_answer[SI],AL
    INC SI
    CMP SI,20
    JNE VERIFY_LOOP
VERIFY_DONE:
    MOV temp_answer[SI], '$'    ; Null-terminate
    
    ; Compare both answers during setup
    MOV SI,0
COMPARE_SETUP_ANSWERS:
    MOV AL,security_answer[SI]
    CMP AL,temp_answer[SI]
    JNE ANSWERS_MISMATCH
    CMP AL,'$'         ; Check if we've reached end of string
    JE ANSWERS_MATCH
    INC SI
    JMP COMPARE_SETUP_ANSWERS
    
ANSWERS_MISMATCH:
    MOV AH,9
    LEA DX,msg_answer_mismatch
    INT 21h
    JMP SETUP_SECURITY_QUESTION ; Start over
    
ANSWERS_MATCH:
    MOV question_set, 1             ; Mark question as set
    MOV AH,9
    LEA DX,msg_question_saved
    INT 21h
    
    ; Log security question setup
    LEA SI, msg_question_saved+2
    MOV DI, history_ptr
    
    ; Add newline
    MOV AL, 13
    MOV [DI], AL
    INC DI
    MOV AL, 10
    MOV [DI], AL
    INC DI
    
    ; Copy message to history
    MOV AL, [SI]
LOG_QUESTION:
    CMP AL, '$'
    JE QUESTION_LOGGED
    MOV [DI], AL
    INC SI
    INC DI
    MOV AL, [SI]
    JMP LOG_QUESTION
QUESTION_LOGGED:
    MOV history_ptr, DI
    
    JMP SHOW_MENU

VIEW_HISTORY:
    ; Display history
    MOV AH,9
    LEA DX,newline
    INT 21h
    LEA DX,msg_history
    INT 21h
    LEA DX,newline
    INT 21h
    LEA DX,history_log
    INT 21h
    LEA DX,newline
    INT 21h
    
    ; Wait for any key to continue
    MOV AH,1
    INT 21h
    
    JMP SHOW_MENU

FAIL:
    ; Increment attempt count on wrong PIN
    INC attempts
    MOV AL, attempts
    
    ; Trigger alarm immediately if 3rd wrong attempt
    CMP AL, 3
    JE TRIGGER_ALARM

    ; On 2nd attempt, clearly prompt forgot PIN
    CMP AL, 2
    JE ASK_RESET
    
    ; 1st failed attempt only shows retry message
    MOV AH, 9
    LEA DX, msg_fail
    INT 21h
    JMP START


SHOW_FAIL:
    MOV AH,9
    LEA DX,msg_fail
    INT 21h
    
    ; Log failed attempt
    LEA SI, msg_fail+2
    MOV DI, history_ptr
    
    ; Add newline
    MOV AL, 13
    MOV [DI], AL
    INC DI
    MOV AL, 10
    MOV [DI], AL
    INC DI
    
    ; Copy message to history
    MOV AL, [SI]
LOG_FAIL:
    CMP AL, '$'
    JE FAIL_LOGGED
    MOV [DI], AL
    INC SI
    INC DI
    MOV AL, [SI]
    JMP LOG_FAIL
FAIL_LOGGED:
    MOV history_ptr, DI
    
    JMP START

TRIGGER_ALARM:
    ; Show alarm message
    MOV AH,9
    LEA DX,msg_alarm
    INT 21h
    
    ; Log alarm trigger
    LEA SI, msg_alarm+2
    MOV DI, history_ptr
    
    ; Add newline
    MOV AL, 13
    MOV [DI], AL
    INC DI
    MOV AL, 10
    MOV [DI], AL
    INC DI
    
    ; Copy message to history
    MOV AL, [SI]
LOG_ALARM:
    CMP AL, '$'
    JE ALARM_LOGGED
    MOV [DI], AL
    INC SI
    INC DI
    MOV AL, [SI]
    JMP LOG_ALARM
ALARM_LOGGED:
    MOV history_ptr, DI

ASK_RESET:
    ; "Forgot your PIN? (Y/N)"
    MOV AH,9
    LEA DX,msg_forgot_prompt
    INT 21h

    MOV AH,1
    INT 21h          ; read AL
    CMP AL,'Y'
    JE  CHECK_SECURITY_QUESTION
    CMP AL,'y'
    JE  CHECK_SECURITY_QUESTION
    CMP AL,'N'
    JE  SOUND_LOOP
    CMP AL,'n'
    JE  SOUND_LOOP

    ; invalid input -> re-prompt
    MOV AH,9
    LEA DX,msg_invalid_input
    INT 21h
    JMP ASK_RESET

CHECK_SECURITY_QUESTION:
    ; Check if security question is set
    CMP question_set, 1
    JNE RESET_PIN      ; If not set, go directly to reset
    
    ; Ask security question
    ; Display security question prompt
    MOV AH,9
    LEA DX,msg_answer_prompt
    INT 21h
    
    ; Display the security question
    MOV AH,9
    LEA DX,security_question
    INT 21h
    
    ; Add colon and space after question
    MOV DL, ':'
    MOV AH, 2
    INT 21h
    MOV DL, ' '
    INT 21h
    
    ; Read user's answer
    MOV SI,0
READ_ANSWER:
    MOV AH,1
    INT 21h
    CMP AL,13        ; Enter key
    JE CHECK_USER_ANSWER
    MOV user_answer[SI],AL
    INC SI
    CMP SI,20
    JB READ_ANSWER
    
CHECK_USER_ANSWER:
    ; Null terminate the answer
    MOV user_answer[SI], '$'
    
    ; Compare user's answer with stored answer
    MOV SI,0
COMPARE_USER_ANSWER:
    MOV AL,security_answer[SI]
    CMP AL,user_answer[SI]
    JNE WRONG_ANSWER
    CMP AL,'$'       ; Check for end of string
    JE CORRECT_ANSWER
    INC SI
    JMP COMPARE_USER_ANSWER

WRONG_ANSWER:
    MOV AH,9
    LEA DX,msg_answer_wrong
    INT 21h
    JMP SOUND_LOOP

CORRECT_ANSWER:
    MOV AH,9
    LEA DX,msg_answer_correct
    INT 21h
    
    ; Log correct answer
    LEA SI, msg_answer_correct+2
    MOV DI, history_ptr
    
    ; Add newline
    MOV AL, 13
    MOV [DI], AL
    INC DI
    MOV AL, 10
    MOV [DI], AL
    INC DI
    
    ; Copy message to history
    MOV AL, [SI]
LOG_CORRECT_ANSWER:
    CMP AL, '$'
    JE ANSWER_LOGGED
    MOV [DI], AL
    INC SI
    INC DI
    MOV AL, [SI]
    JMP LOG_CORRECT_ANSWER
ANSWER_LOGGED:
    MOV history_ptr, DI
    
    ; Allow password reset
    JMP RESET_PIN

RESET_PIN:
    ; Reset flow
    MOV attempts,0
    MOV AH,9
    LEA DX,msg_reset_prompt
    INT 21h

    ; Read new 4-digit PIN
    MOV SI,0
NEW_PIN_LOOP2:
    MOV AH,1
    INT 21h
    MOV new_pass[SI],AL

    MOV DL,08h
    MOV AH,2
    INT 21h
    MOV DL,'*'
    MOV AH,2
    INT 21h

    INC SI
    CMP SI,4
    JNE NEW_PIN_LOOP2

    ; Compare new_pass vs correct_pass to prevent reuse
    MOV SI,0
    MOV DI,0
    MOV CX,4

CHECK_SAME2:
    MOV AL,new_pass[SI]
    CMP AL,correct_pass[DI]
    JNE  UPDATE_OK2    ; if any byte differs, it's new
    INC SI
    INC DI
    LOOP CHECK_SAME2

    ; If all 4 matched, show invalid input & retry
    MOV AH,9
    LEA DX,msg_invalid_input
    INT 21h
    JMP RESET_PIN

UPDATE_OK2:
    ; Copy new_pass to correct_pass
    MOV SI,0
    MOV DI,0
    MOV CX,4
COPY_LOOP2:
    MOV AL,new_pass[SI]
    MOV correct_pass[DI],AL
    INC SI
    INC DI
    LOOP COPY_LOOP2

    ; Log password change
    LEA SI, msg_reset_success+2
    MOV DI, history_ptr
    
    ; Add newline
    MOV AL, 13
    MOV [DI], AL
    INC DI
    MOV AL, 10
    MOV [DI], AL
    INC DI
    
    ; Copy message to history
    MOV AL, [SI]
LOG_RESET2:
    CMP AL, '$'
    JE RESET_LOGGED2
    MOV [DI], AL
    INC SI
    INC DI
    MOV AL, [SI]
    JMP LOG_RESET2
RESET_LOGGED2:
    MOV history_ptr, DI

    ; Prompt for hint update after PIN reset
    MOV AH,9
    LEA DX,msg_hint_prompt
    INT 21h

    MOV SI,0
HINT_LOOP2:
    MOV AH,1
    INT 21h
    CMP AL,13        ; Enter key
    JE HINT_DONE2
    MOV password_hint[SI],AL

    MOV DL,08h
    MOV AH,2
    INT 21h
    MOV DL,'*'
    MOV AH,2
    INT 21h

    INC SI
    CMP SI,20
    JNE HINT_LOOP2
    
HINT_DONE2:
    ; Properly terminate the hint string
    MOV password_hint[SI], '$'
    
    MOV AH,9
    LEA DX,msg_hint_success
    INT 21h
    
    ; Log hint update
    LEA SI, msg_hint_success+2
    MOV DI, history_ptr
    
    ; Add newline
    MOV AL, 13
    MOV [DI], AL
    INC DI
    MOV AL, 10
    MOV [DI], AL
    INC DI
    
    ; Copy message to history
    MOV AL, [SI]
    JE Exit
LOG_HINT2:
    CMP AL, '$'
    JE HINT_LOGGED2
    MOV [DI], AL
    INC SI
    INC DI
    MOV AL, [SI]
    JMP LOG_HINT2
HINT_LOGGED2:
    MOV history_ptr, DI

    JMP START

SOUND_LOOP:
    ; Continuous buzzer
    CMP attempts, 2
    JE Fail
    
    MOV AH,2
    MOV DL,07h
    INT 21h
    JMP SOUND_LOOP

EXIT:
    ; Show history before exiting
    MOV AH,9
    LEA DX,newline
    INT 21h
    LEA DX,msg_history
    INT 21h
    LEA DX,newline
    INT 21h
    LEA DX,history_log
    INT 21h 
    MOV attempts, 0
      
    
    MOV AX,4C00h
    INT 21h 
    
CLEAR_USER_INPUT:
    MOV user_input[SI], '$'
    INC SI
    CMP SI, 4
    JB CLEAR_USER_INPUT

    JMP START 

MAIN ENDP
END MAIN
