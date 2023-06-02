.intel_syntax noprefix

.section .data

board_string: 
.STRING " * | * | * \n---+---+---\n * | * | * \n---+---+---\n * | * | * \n" # 60

make_move_string:
.STRING "\nMake a move (1-9)\n9 8 7\n6 5 4\n3 2 1\n>>_" # 40

restart_string:
.STRING "restart? (y/n)\n>>_" # 18

wins:
.BYTE 128, 128, 128, 128, 128, 128, 128, 255
.BYTE 128, 170, 240, 250, 128, 170, 240, 255
.BYTE 128, 128, 204, 204, 128, 128, 204, 255
.BYTE 128, 170, 252, 254, 128, 170, 252, 255
.BYTE 128, 128, 170, 170, 240, 240, 250, 255
.BYTE 128, 170, 250, 250, 240, 250, 250, 255
.BYTE 128, 128, 238, 238, 240, 240, 254, 255
.BYTE 255, 255, 255, 255, 255, 255, 255, 255

.section .text
.global main

#############################

main:
    push rbx
    sub rsp, 32

    # r9 is the board
    mov r9, 0
    
    inner_loop:

    call print_board

    lea rdi, [rip+make_move_string]
    mov rsi, 40
    call write

    mov rdi, rsp
    mov rsi, 32
    call read

    mov al, BYTE PTR [rsp]
    sub al, '1'

    cmp al, 0
    jl inner_loop
    cmp al, 8
    jg inner_loop

    mov rdi, 1
    mov sil, al

    call freeSquare
    test ax, ax
    jnz inner_loop

    call setBoardSquare

    call getFullBoard
    cmp ax, 0x01FF
    je inner_out

    mov rdi, 1
    mov rsi, 0
    mov cl, -127
    mov dl, 127

    call negamax

    mov rdi, 0
    xchg al, ah
    mov sil, al
    call setBoardSquare

    mov rdi, 0
    call hasVictory
    test al, al
    jz inner_loop

    inner_out:

    call print_board

    mov r9, 0

    lea rdi, [rip+restart_string]
    mov rsi, 18
    call write

    mov rdi, rsp
    mov rsi, 32
    call read

    cmp BYTE PTR [rsp], 'y'
    je inner_loop

    add rsp, 32
    pop rbx
    mov rax, 0
    
    ret

#############################

getBoard: 
    # (alliance rdi) -> rax

    push rcx

    mov rcx, rdi
    shl rcx, 4
    mov rax, r9
    shr eax, cl
    and rax, 0x01FF

    pop rcx

    ret

#############################

setBoardSquare: 
    # (alliance rdi, square rsi) -> rax

    push rbx
    push rcx

    mov rcx, rdi
    shl rcx, 4
    mov rbx, 0x0100
    shl ebx, cl
    mov rcx, rsi
    shr ebx, cl
    xor r9d, ebx

    pop rcx
    pop rbx

    ret

#############################

freeSquare:

    push rbx

    mov eax, r9d
    shr eax, 16 
    or ax, r9w

    mov rbx, 0x0100
    xchg rsi, rcx
    shr rbx, cl
    xchg rsi, rcx
    and ax, bx 

    pop rbx

    ret

#############################

getFullBoard: # () -> rax

    mov eax, r9d
    shr eax, 16 
    or ax, r9w

    ret

#############################

legalMoves: # () -> rax

    mov eax, r9d
    shr eax, 16 
    or ax, r9w
    not ax
    and ax, 0x01FF

    ret

#############################

hasVictory:
    # (alliance rdi) -> rax

    push rcx
    push rbx

    # Probe the magic win
    # table

    call getBoard
    mov cx, ax
    mov bx, 1
    and cx, 7
    shl bl, cl
    shr ax, 3
    lea rcx, [rip+wins]
    mov al, BYTE PTR [rcx+rax] 
    and al, bl
    mov ah, 0

    pop rbx
    pop rcx

    ret

#############################

print_board:

    sub rsp, 86
    mov QWORD PTR [rsp+70], rbx
    mov QWORD PTR [rsp+78], rcx

    mov BYTE PTR [rsp+0], ' '
    mov BYTE PTR [rsp+1], ' '
    mov BYTE PTR [rsp+2], ' '
    mov BYTE PTR [rsp+3], ' '
    mov BYTE PTR [rsp+4], ' '
    mov BYTE PTR [rsp+5], ' '
    mov BYTE PTR [rsp+6], ' '
    mov BYTE PTR [rsp+7], ' '
    mov BYTE PTR [rsp+8], ' '
    mov BYTE PTR [rsp+9], ' '

    #---------------------------

    mov rdi, 0
    call getBoard
    mov bx, ax

    mov dil, 'x'

    ploop:
    test bx, bx
    jz pbreak

    xor rax, rax
    bsf ax, bx
    mov BYTE PTR [rsp+rax], dil
    mov ax, bx
    sub ax, 1
    and bx, ax

    jmp ploop
    pbreak:

    cmp dil, 'x'
    jne continue

    mov rdi, 1
    call getBoard
    mov bx, ax

    mov dil, 'o'

    jmp ploop
    continue:

    #---------------------------

    lea rbx, [rip+board_string]
    mov cl, BYTE PTR [rsp+0]
    mov BYTE PTR [rbx+1], cl

    mov cl, BYTE PTR [rsp+1]
    mov BYTE PTR [rbx+5], cl

    mov cl, BYTE PTR [rsp+2]
    mov BYTE PTR [rbx+9], cl

    mov cl, BYTE PTR [rsp+3]
    mov BYTE PTR [rbx+25], cl

    mov cl, BYTE PTR [rsp+4]
    mov BYTE PTR [rbx+29], cl

    mov cl, BYTE PTR [rsp+5]
    mov BYTE PTR [rbx+33], cl

    mov cl, BYTE PTR [rsp+6]
    mov BYTE PTR [rbx+49], cl

    mov cl, BYTE PTR [rsp+7]
    mov BYTE PTR [rbx+53], cl

    mov cl, BYTE PTR [rsp+8]
    mov BYTE PTR [rbx+57], cl

    #---------------------------

    mov rdi, rbx
    mov rsi, 60
    call write

    #---------------------------

    mov rcx, QWORD PTR [rsp+78]
    mov rbx, QWORD PTR [rsp+70]
    add rsp, 86

    ret

#############################

write:

    mov rdx, rsi
    mov rsi, rdi
    mov rax, 1
    mov rdi, 1
    syscall

    ret

#############################

read:

    mov rdx, rsi
    mov rsi, rdi
    mov rax, 0
    mov rdi, 1
    syscall

    ret

#############################

negamax:
                                    # args:
                                    # (1) rdi - alliance 
                                    # (2) rsi - depth 
                                    # (3) rcx - alpha
                                    # (4) rdx - beta

    call hasVictory                 # if(hasVictory(Alliance)) {
    test al, al                     
    jz cont1

    mov al, sil                     # return depth - 10;
    sub al, 10 

    ret

    cont1:                          # }



    call getFullBoard               # if(board.isFull()) {
    cmp ax, 0x01FF
    jne cont2

    xor rax, rax                    # return 0;

    ret

    cont2:                          # }

    xor rdi, 1                      # alliance = swapAlliance(alliance);

                                    #------------------------
                                    # Free Registers:
                                    # (1) rax - return value
                                    # (2) rbx - legal move board
                                    # (3) r11 - best move
                                    # (4) r12 - high score
                                    # (5) r13 - current move
                                    # (6) r14 - temp
                                    # (7) r15 - temp

    sub rsp, 40
    mov QWORD PTR  [rsp+0], rbx     # spill rbx
    mov QWORD PTR  [rsp+8], r11     # spill r11
    mov QWORD PTR [rsp+16], r12     # spill r12
    mov QWORD PTR [rsp+24], r13     # spill r13
    xor r11, r11                    # bestMove = 0;

    call legalMoves                 # legalMoves = board.legalMoves();
    mov rbx, rax                    
    mov r12b, 0x80                  # highScore = INT8_MIN;

    mov QWORD PTR [rsp+32], rdx     # spill beta

    moveloop1:                      # while(legalMoves) {
    test bx, bx
    jz return
    
    mov r13, rsi                    # temp = depth;
    bsf r8, rbx                     # temp2 = bitScanForward(legalMoves);
    mov rsi, 8                      # temp3 = 8;
    sub rsi, r8                     # temp3 -= temp2;
    call setBoardSquare             # board.setSquare(temp3);
    xchg rsi, r13                   # depth = temp; move = temp3;

    xchg cl, dl                     # temp = alpha; alpha = -beta; beta = -temp;
    neg cl
    neg dl
    inc rsi                         # ++depth;

    call negamax                    # score = negamax(alliance, depth, alpha, beta)

    mov cl, dl                      # alpha = -beta;
    neg cl

    dec rsi                         # --depth;

    mov rdx, QWORD PTR [rsp+32]     # restore beta

    xchg rsi, r13                   # board.setSquare(move);
    call setBoardSquare
    xchg rsi, r13

    neg al                          # score = -score;

    cmp al, r12b                    # if(score > highscore) {
    jle skipper

    mov r12b, al                    # highScore = score;
    mov r11b, r13b                  # bestMove = move;

    cmp al, cl                      # if(score > alpha) {
    jle skipper

    cmp al, dl                      # if(score >= beta) {
    jge return                      # goto returnLabel;
                                    # }

    mov cl, al                      # alpha = score;

    skipper:                        # }
                                    # }

    mov r8w, bx                    # moveBoard &= moveBoard - 1; // pop lsb
    sub bx, 1
    and bx, r8w

    jmp moveloop1                   # }

    return:                         # return label:

    mov al, r11b                    # value = (bestMove << 8) | highScore;
    xchg al, ah
    mov al, r12b

    mov r13, QWORD PTR [rsp+24]     # restore r13
    mov r12, QWORD PTR [rsp+16]     # restore r12
    mov r11, QWORD PTR  [rsp+8]     # restore r11
    mov rbx, QWORD PTR  [rsp+0]     # restore rbx

    add rsp, 40                     

    xor rdi, 1                      # alliance = swapAlliance(alliance);

    ret                             # return value;

#############################
