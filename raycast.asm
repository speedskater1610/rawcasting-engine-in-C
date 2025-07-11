; extern declarations for linking with C library & Windows API
extern GetStdHandle
extern SetConsoleCursorPosition
extern printf
extern sprintf       ; from C stdlib
extern system, scanf, getchar
extern map



extern malloc
extern free
extern srand
extern rand
extern time
extern sinf
extern cosf
extern fabsf
extern sqrtf
extern _kbhit
extern _getch


extern SetConsoleScreenBufferSize
extern SetConsoleActiveScreenBuffer
extern Sleep
extern WriteConsoleOutputCharacterW

section .bss
    linebuf resb 16
    setting         resb 1
    whichBullet     resd 1
    x               resd 1
    y               resd 1
    tile            resb 1
    changeHardness  resd 1
    holdingChar     resb 1


section .data

; Constants
STD_OUTPUT_HANDLE    equ -11
SCREEN_WIDTH        equ 209
SCREEN_HEIGHT       equ 51
MAP_WIDTH           equ 32
MAP_HEIGHT          equ 16
DEPTH               dd 16.0
FOV                 dd 1.0471976       ; 60 degrees in radians approx

; Strings
prompt              db "Are you ready to start? Y/n - ", 0
str_caret           db "^", 0
str_line1_bow       db "____|____", 0
str_line2_bow       db "/    |    \", 0
str_line3_bow       db "/_____|_____\", 0
str_pipe            db "|", 0
str_slash_pipe      db "/|\", 0
str_line1_justbow   db "____ ____", 0
str_line2_justbow   db "/         \", 0
str_line3_justbow   db "/_____ _____\", 0
str_space           db " ", 0
str_spaces3         db "   ", 0
clsStr              db "cls", 0

titleText           db "SETTING", 0
bullet1             db "- 1) change input type", 0
bullet2             db "- 2) change hardness", 0
bullet3             db "- 3) edit map", 0
bullet4             db "- 4) leave setting", 0

promptInput         db "%i", 0
promptX             db "enter x (0-%d): ", 10, 0
promptY             db "enter y (0-%d): ", 10, 0
promptTile          db "enter tile char (e.g. 0 or 1): ", 10, 0
updateText          db "map updated at %d,%d", 10, 0
invalidCoords       db "invalid coords", 10, 0
pressEnter          db "press enter to continue...", 10, 0
hardnessPrompt      db "change hardness to [easy (1-10) hard] - ", 0
changePrompt        db "What do you want to change it to? - ", 0

format_char         db "%c", 0

; Map (32x16 chars)
map db \
"11111111111111111111111111111111",\
"10000000001100000000000000000001",\
"10110000011100000020000000000001",\
"10010000000000000000000000000001",\
"11111111101100000111000000000001",\
"10000000001100000111011111111111",\
"10110000011100000111011111111111",\
"10110000000000000000000000000001",\
"10000000000000000000000000000001",\
"10000000000000000000000000000001",\
"10000000000000000000000000000001",\
"10000000000000000000000000000001",\
"10000000000000000000000000000001",\
"10000000000000000000000000000001",\
"10000000000000000000000000000001",\
"11111111111111111111111111111111"

; Floating-point constants
float_0_1           dd 0x3dcccccd    ; 0.1f
float_0_25          dd 0.25
float_0_5           dd 0x3f000000    ; 0.5f
float_0_75          dd 0.75
float_0_9           dd 0.9
float_1_0           dd 0x3f800000    ; 1.0f
float_2_0           dd 0x40000000    ; 2.0f
float_SCREEN_WIDTH  dd SCREEN_WIDTH
float_SCREEN_HEIGHT dd SCREEN_HEIGHT
float_SCREEN_HEIGHT_half dd 25.5
half_FOV            dd 0.5235987756  ; FOV/2 = 30 degrees in radians approx
FOV_float           dd FOV
float_depth         dd DEPTH
float_depth_div_4   dd 4.0
float_depth_div_3   dd 5.3333333
float_depth_div_2   dd 8.0

; Buffers and vars
buffer_coord        dw 0,0

; Format strings for sprintf in drawWeapon_norm
fmt1                db "[%c%c|%c%c]", 0
fmt2                db "%c|%c", 0
fmt3                db "[%c%c %c%c]", 0
fmt4                db "%c %c", 0

; Console variables
screen_ptr          dq 0
hConsole            dq 0
bufferSize          dw SCREEN_WIDTH, SCREEN_HEIGHT
dwBytesWritten      dq 0

; Player position and movement
playerX             dd 14.7
playerY             dd 5.09
playerA             dd 0.0
moveSpeed           dd 0.5
rotSpeed            dd 0.1


section .text
global _start

_start:

    ; --- print prompt ---
    sub rsp, 40
    lea rcx, [rel prompt]
    xor rax, rax
    call printf
    add rsp, 40

    ; --- scanf " %c" into startLetter ---
    sub rsp, 40
    lea rcx, [rel format_char]
    lea rdx, [rel startLetter]
    xor rax, rax
    call scanf
    add rsp, 40

    ; check if startLetter == 'Y' or 'y'
    mov al, [startLetter]
    cmp al, 'Y'
    je .start_game
    cmp al, 'y'
    je .start_game
    ; else exit
    mov ecx, 0
    call exit_process

.start_game:
    ; srand(time(NULL))
    sub rsp, 40
    xor rcx, rcx
    call time
    mov rcx, rax
    call srand
    add rsp, 40

    ; allocate screen buffer: sizeof(wchar_t)*SCREEN_WIDTH*SCREEN_HEIGHT = 2*209*51 = 21318 bytes
    mov edi, SCREEN_WIDTH
    imul edi, SCREEN_HEIGHT
    imul edi, 2
    mov rcx, rdi
    sub rsp, 40
    call malloc
    add rsp, 40
    mov [screen_ptr], rax

    ; zero the screen buffer
    mov rcx, SCREEN_WIDTH
    imul rcx, SCREEN_HEIGHT
    mov rdi, [screen_ptr]
    xor eax, eax
    mov rdx, rcx

.zero_loop:
    mov word [rdi], ax
    add rdi, 2
    dec rdx
    jnz .zero_loop

    ; Get console handle (STD_OUTPUT_HANDLE = -11)
    sub rsp, 40
    mov ecx, -11
    call GetStdHandle
    add rsp, 40
    mov [hConsole], rax

    ; SetConsoleScreenBufferSize(hConsole, bufferSize)
    sub rsp, 40
    mov rcx, [hConsole]
    lea rdx, [rel bufferSize]
    call SetConsoleScreenBufferSize
    add rsp, 40

    ; SetConsoleActiveScreenBuffer(hConsole)
    sub rsp, 40
    mov rcx, [hConsole]
    call SetConsoleActiveScreenBuffer
    add rsp, 40

; -------- Main game loop --------
.game_loop:

    ; --- Handle keyboard input ---
    sub rsp, 40
    call _kbhit
    add rsp, 40
    test eax, eax
    jz .skip_input

    sub rsp, 40
    call _getch
    add rsp, 40
    mov bl, al

    ; check keys:
    ; 'a' = turn left (playerA -= rotSpeed)
    cmp bl, 'a'
    jne .check_d
    ; xmm0 = playerA, xmm1 = rotSpeed, playerA -= rotSpeed
    movss xmm0, [playerA]
    movss xmm1, [rotSpeed]
    subss xmm0, xmm1
    movss [playerA], xmm0
    jmp .skip_input

.check_d:
    cmp bl, 'd'
    jne .check_w
    ; playerA += rotSpeed
    movss xmm0, [playerA]
    movss xmm1, [rotSpeed]
    addss xmm0, xmm1
    movss [playerA], xmm0
    jmp .skip_input

.check_w:
    cmp bl, 'w'
    jne .check_s
    ; Move forward
    ; newX = playerX + sin(playerA)*moveSpeed
    movss xmm0, [playerA]
    sub rsp, 40
    movss xmm1, xmm0
    movss xmm2, xmm0
    call sinf               ; sin(playerA) in xmm0
    movss xmm3, xmm0       ; save sin(playerA)
    movss xmm0, [moveSpeed]
    mulss xmm3, xmm0       ; sin(playerA)*moveSpeed
    movss xmm4, xmm3       ; x increment

    movss xmm0, [playerX]
    addss xmm0, xmm4
    movss xmm5, xmm0       ; newX

    ; newY = playerY + cos(playerA)*moveSpeed
    movss xmm0, [playerA]
    call cosf
    movss xmm3, xmm0       ; cos(playerA)
    movss xmm0, [moveSpeed]
    mulss xmm3, xmm0       ; cos(playerA)*moveSpeed
    movss xmm0, [playerY]
    addss xmm0, xmm3
    movss xmm6, xmm0       ; newY

    ; check if map[(int)newY*MAP_WIDTH + (int)newX] == '1'
    ; integer cast by truncation:
    cvttss2si rax, xmm6    ; int newY
    mov rcx, rax
    imul rcx, MAP_WIDTH
    cvttss2si rdx, xmm5    ; int newX
    add rcx, rdx           ; index in map
    lea rbx, [rel map]
    movzx eax, byte [rbx + rcx]

    cmp al, '1'
    je .no_move_w          ; blocked by wall

    ; update playerX and playerY
    movss [playerX], xmm5
    movss [playerY], xmm6
    jmp .skip_input

.no_move_w:
    ; do nothing, no move

.skip_input:
    ; --- Raycasting per column ---
    xor r8d, r8d           ; x = 0

.ray_loop:
    cmp r8d, SCREEN_WIDTH
    jge .ray_done

    ; rayAngle = playerA - (FOV/2) + (x/SCREEN_WIDTH)*FOV
    movss xmm0, [playerA]

    movss xmm1, [float_1_0]
    movss xmm2, [float_1_0]

    ; FOV/2 (float)
    movss xmm3, dword [rel half_FOV]
    subss xmm0, xmm3        ; playerA - FOV/2

    ; (x / SCREEN_WIDTH) * FOV
    cvtsi2ss xmm4, r8d      ; float(x)
    movss xmm5, dword [rel float_SCREEN_WIDTH]
    divss xmm4, xmm5        ; x / SCREEN_WIDTH
    movss xmm5, dword [rel FOV_float]
    mulss xmm4, xmm5        ; (x/SCREEN_WIDTH)*FOV

    addss xmm0, xmm4        ; rayAngle

    movss xmm7, xmm0        ; save rayAngle

    ; distanceToWall = 0.0f
    xorps xmm1, xmm1        ; zero xmm1

    ; hitWall = 0 (int)
    xor r9d, r9d

    ; eyeX = sin(rayAngle)
    movss xmm0, xmm7
    call sinf
    movss xmm2, xmm0       ; eyeX

    ; eyeY = cos(rayAngle)
    movss xmm0, xmm7
    call cosf
    movss xmm3, xmm0       ; eyeY

    ; Start ray distance loop
.ray_distance_loop:
    cmp r9d, 1
    jne .continue_ray

    jmp .ray_after_loop

.continue_ray:
    ; distanceToWall += 0.1
    movss xmm4, xmm1       ; distanceToWall
    movss xmm5, [float_0_1]
    addss xmm4, xmm5
    movss xmm1, xmm4       ; update distanceToWall

    ; testX = int(playerX + eyeX * distanceToWall)
    movss xmm0, [playerX]
    mulss xmm2, xmm1       ; eyeX*distanceToWall in xmm2
    addss xmm0, xmm2       ; playerX + eyeX*distanceToWall
    cvttss2si rax, xmm0

    ; testY = int(playerY + eyeY * distanceToWall)
    movss xmm0, [playerY]
    mulss xmm3, xmm1       ; eyeY*distanceToWall in xmm3
    addss xmm0, xmm3
    cvttss2si rdx, xmm0

    ; Check bounds
    cmp rax, 0
    jl .hit_wall
    cmp rax, MAP_WIDTH - 1
    jg .hit_wall

    cmp rdx, 0
    jl .hit_wall
    cmp rdx, MAP_HEIGHT - 1
    jg .hit_wall

    ; Check map char
    mov rcx, rdx
    imul rcx, MAP_WIDTH
    add rcx, rax
    movzx eax, byte [rel map + rcx]
    cmp al, '1'
    jne .ray_distance_loop_continue

.hit_wall:
    mov r9d, 1            ; hitWall = 1
    jmp .ray_after_loop

.ray_distance_loop_continue:
    jmp .ray_distance_loop

.ray_after_loop:

    ; ceiling = (SCREEN_HEIGHT / 2) - SCREEN_HEIGHT / distanceToWall
    movss xmm0, dword [float_SCREEN_HEIGHT_half]
    movss xmm1, dword [float_SCREEN_HEIGHT]
    divss xmm1, xmm4        ; SCREEN_HEIGHT / distanceToWall
    subss xmm0, xmm1        ; ceiling

    cvttss2si esi, xmm0    ; int ceiling

    ; floor = SCREEN_HEIGHT - ceiling
    mov edi, SCREEN_HEIGHT
    sub edi, esi           ; floor

    ; Draw vertical column for this x (r8d)
    mov ecx, 0             ; y = 0

.draw_column_loop:
    cmp ecx, SCREEN_HEIGHT
    jge .draw_column_done

    ; idx = y * SCREEN_WIDTH + x
    mov eax, ecx
    imul eax, SCREEN_WIDTH
    add eax, r8d

    ; if y < ceiling: screen[idx] = ' '
    cmp ecx, esi
    jl .draw_ceiling

    ; if y >= ceiling && y <= floor
    cmp ecx, edi
    jg .draw_floor

    ; wall shading depending on distanceToWall
    ; Use Unicode blocks:
    ; distanceToWall <= DEPTH/4 -> 0x2588 (█)
    ; else if distanceToWall < DEPTH/3 -> 0x2593 (▓)
    ; else if distanceToWall < DEPTH/2 -> 0x2592 (▒)
    ; else if distanceToWall < DEPTH -> 0x2591 (░)
    ; else ' '

    movss xmm0, xmm4          ; distanceToWall

    movss xmm1, dword [float_depth]
    movss xmm2, dword [float_depth_div_4]
    movss xmm3, dword [float_depth_div_3]
    movss xmm5, dword [float_depth_div_2]

    ucomiss xmm0, xmm2
    ja .check_depth_3
    ; <= depth/4
    mov word [screen_ptr + eax*2], 0x2588
    jmp .next_y

.check_depth_3:
    ucomiss xmm0, xmm3
    ja .check_depth_2
    mov word [screen_ptr + eax*2], 0x2593
    jmp .next_y

.check_depth_2:
    ucomiss xmm0, xmm5
    ja .check_depth_1
    mov word [screen_ptr + eax*2], 0x2592
    jmp .next_y

.check_depth_1:
    ucomiss xmm0, xmm1
    ja .draw_empty_space
    mov word [screen_ptr + eax*2], 0x2591
    jmp .next_y

.draw_empty_space:
    mov word [screen_ptr + eax*2], ' '

    jmp .next_y

.draw_ceiling:
    mov word [screen_ptr + eax*2], ' '
    jmp .next_y

.draw_floor:
    ; floor shading - calculate b = 1.0 - ((y - SCREEN_HEIGHT/2) / (SCREEN_HEIGHT/2))
    movss xmm0, dword [float_1_0]
    movss xmm1, ecx
    cvtsi2ss xmm1, ecx
    movss xmm2, dword [float_SCREEN_HEIGHT_half]
    subss xmm1, xmm2           ; y - SCREEN_HEIGHT/2
    divss xmm1, xmm2           ; / (SCREEN_HEIGHT/2)
    subss xmm0, xmm1           ; b = 1 - ...

    ; if b < 0.25 -> '#'
    movss xmm3, dword [float_0_25]
    ucomiss xmm0, xmm3
    jb .floor_hash

    ; else if b < 0.5 -> 'x'
    movss xmm3, dword [float_0_5]
    ucomiss xmm0, xmm3
    jb .floor_x

    ; else if b < 0.75 -> '.'
    movss xmm3, dword [float_0_75]
    ucomiss xmm0, xmm3
    jb .floor_dot

    ; else if b < 0.9 -> '-'
    movss xmm3, dword [float_0_9]
    ucomiss xmm0, xmm3
    jb .floor_dash

    ; else ' '
    mov word [screen_ptr + eax*2], ' '
    jmp .next_y

.floor_hash:
    mov word [screen_ptr + eax*2], '#'
    jmp .next_y
.floor_x:
    mov word [screen_ptr + eax*2], 'x'
    jmp .next_y
.floor_dot:
    mov word [screen_ptr + eax*2], '.'
    jmp .next_y
.floor_dash:
    mov word [screen_ptr + eax*2], '-'
    jmp .next_y

.next_y:
    inc ecx
    jmp .draw_column_loop

.draw_column_done:

    inc r8d
    jmp .ray_loop

.ray_done:

    ; WriteConsoleOutputCharacterW(hConsole, screen, SCREEN_WIDTH*SCREEN_HEIGHT, (COORD){0,0}, &dwBytesWritten);
    sub rsp, 40
    mov rcx, [hConsole]
    mov rdx, [screen_ptr]
    mov r8d, SCREEN_WIDTH*SCREEN_HEIGHT
    lea r9, [rel buffer_coord]
    lea r10, [rel dwBytesWritten]
    call WriteConsoleOutputCharacterW
    add rsp, 40

    ; Sleep(60)
    sub rsp, 40
    mov ecx, 60
    call Sleep
    add rsp, 40

    jmp .game_loop

exit_process:
    mov ecx, edi
    extern ExitProcess
    call ExitProcess







openMenu:
    push rbp
    mov rbp, rsp

    ; system("cls")
    mov rcx, clsStr
    call system

    mov byte [setting], 1

.done:
    cmp byte [setting], 0
    je .end

    ; Clear screen again
    mov rcx, clsStr
    call system

    ; Print border
    mov ecx, SCREEN_WIDTH
.print_border:
    push rcx
    mov rdi, '='
    call putchar_wrapper
    pop rcx
    dec ecx
    jnz .print_border

    ; Print padding spaces
    mov ecx, SCREEN_WIDTH / 2
.print_spaces:
    push rcx
    mov rdi, ' '
    call putchar_wrapper
    pop rcx
    dec ecx
    jnz .print_spaces

    ; Print title
    mov rcx, titleText
    call printf
    call newline

    ; Print bullets
    call halfwaybullets
    mov rcx, bullet1
    call printf
    call newline

    call halfwaybullets
    mov rcx, bullet2
    call printf
    call newline

    call halfwaybullets
    mov rcx, bullet3
    call printf
    call newline

    call halfwaybullets
    mov rcx, bullet4
    call printf
    call newline

    ; Read option
    call halfwaybullets
    mov rcx, promptInput
    mov rdx, whichBullet
    call scanf

    ; Check input
    mov eax, [whichBullet]
    cmp eax, 1
    je .change_input
    cmp eax, 2
    je .change_hardness
    cmp eax, 3
    je .edit_map
    cmp eax, 4
    je .leave
    jmp .done

.change_input:
    ; Simplified - just clears and exits
    mov rcx, clsStr
    call system
    jmp .done

.change_hardness:
    mov rcx, clsStr
    call system

    ; Print prompt
    call halfwaybullets
    mov rcx, hardnessPrompt
    call printf

    mov rcx, promptInput
    mov rdx, changeHardness
    call scanf

    ; Assign
    mov eax, [changeHardness]
    mov [hardness], eax
    jmp .done

.edit_map:
    mov rcx, clsStr
    call system

    ; Prompt x
    mov rcx, promptX
    mov edx, MAP_WIDTH-1
    call printf

    mov rcx, promptInput
    mov rdx, x
    call scanf

    ; Prompt y
    mov rcx, promptY
    mov edx, MAP_HEIGHT-1
    call printf

    mov rcx, promptInput
    mov rdx, y
    call scanf

    ; Prompt tile
    mov rcx, promptTile
    call printf
    mov rcx, tileFmt
    mov rdx, tile
    call scanf

    ; Bounds check
    mov eax, [x]
    cmp eax, MAP_WIDTH
    jae .invalid
    mov eax, [y]
    cmp eax, MAP_HEIGHT
    jae .invalid

    ; Write to map[y * MAP_WIDTH + x] = tile
    mov eax, [y]
    imul eax, MAP_WIDTH
    add eax, [x]
    movzx edx, byte [tile]
    mov [map + rax], dl

    ; Print success
    mov rcx, updateText
    mov eax, [x]
    mov edx, [y]
    call printf
    jmp .wait

.invalid:
    mov rcx, invalidCoords
    call printf

.wait:
    mov rcx, pressEnter
    call printf
    call getchar
    call getchar
    jmp .done

.leave:
    mov byte [setting], 0
    jmp .done

.end:
    pop rbp
    ret

; Helper functions
putchar_wrapper:
    ; input char in rdi
    push rcx
    push rdx
    push rsi
    sub rsp, 32
    mov rcx, rdi
    call putchar
    add rsp, 32
    pop rsi
    pop rdx
    pop rcx
    ret

newline:
    mov rdi, 10
    call putchar_wrapper
    ret






halfwaybullets:
    push rbp
    mov rbp, rsp

    mov ecx, 94          ; loop counter (i = 94)
.loop:
    cmp ecx, 0
    jl .done             ; if i < 0, exit loop

    mov rcx, str_space   ; printf(" ")
    call printf

    dec ecx              ; i--
    jmp .loop

.done:
    pop rbp
    ret




moveXY:
    ; Parameters:
    ; RCX = x (int)
    ; RDX = y (int)
    ; R8  = print (char*)

    push rbp
    mov rbp, rsp

    ; allocate space for COORD on stack (4 bytes)
    sub rsp, 8           ; align stack to 16 bytes for calls, 8 bytes reserved

    ; COORD has two SHORT (2 bytes each) fields: X and Y
    ; We'll store x and y as 16-bit values on the stack at [rsp] and [rsp+2]

    mov ax, cx           ; move lower 16 bits of RCX (x) to ax
    mov [rsp], ax        ; store x at [rsp]
    mov ax, dx           ; move lower 16 bits of RDX (y) to ax
    mov [rsp+2], ax      ; store y at [rsp+2]

    ; Call GetStdHandle(STD_OUTPUT_HANDLE)
    mov ecx, STD_OUTPUT_HANDLE  ; parameter for GetStdHandle
    call GetStdHandle           ; returns HANDLE in RAX

    ; Call SetConsoleCursorPosition(handle, coord)
    mov rcx, rax               ; HANDLE in RCX
    lea rdx, [rsp]             ; pointer to COORD struct in RDX
    call SetConsoleCursorPosition

    ; Call printf(print)
    mov rcx, r8                ; print pointer in RCX
    call printf

    ; cleanup stack
    add rsp, 8

    pop rbp
    ret

drawWeapon_norm:
    ; Parameters:
    ; RCX = bow_fired (bool)
    ; RDX = bow_ready (bool)

    push rbp
    mov rbp, rsp

    ; We'll ignore bow_fired here since your original code does nothing with it

    ; Compare bow_ready
    cmp dl, 0
    je .justbow

.bowandarrow:
    ; moveXY(centerX, centerY+2, "^")
    mov ecx, centerX
    mov edx, centerY
    add edx, 2
    mov r8, str_caret
    call moveXY

    ; moveXY(centerX-4, centerY+3, "____|____")
    mov ecx, centerX
    sub ecx, 4
    mov edx, centerY
    add edx, 3
    mov r8, str_line1_bow
    call moveXY

    ; moveXY(centerX-5, centerY+4, "/    |    \\")
    mov ecx, centerX
    sub ecx, 5
    mov edx, centerY
    add edx, 4
    mov r8, str_line2_bow
    call moveXY

    ; moveXY(centerX-6, centerY+5, "/_____|_____\\")
    mov ecx, centerX
    sub ecx, 6
    mov edx, centerY
    add edx, 5
    mov r8, str_line3_bow
    call moveXY

    ; Build line like: "[██|██]" using sprintf(linebuf, "[%c%c|%c%c]", 219, 219, 219, 219);
    ; ASCII 219 decimal is 0xDB
    lea rcx, [linebuf]
    mov rdx, fmt1         ; format string "[%c%c|%c%c]"
    mov r8b, 219          ; first %c
    mov r9b, 219          ; second %c

    ; For more than 4 parameters, need to push on stack
    ; Parameters for sprintf:
    ; RCX = buffer
    ; RDX = format string
    ; R8 = 1st char
    ; R9 = 2nd char
    ; others pushed

    ; So 3rd char and 4th char must be pushed in reverse order:
    sub rsp, 16
    mov byte [rsp + 8], 219
    mov byte [rsp + 9], 219

    call sprintf
    add rsp, 16

    ; moveXY(centerX-3, centerY+6, linebuf)
    mov ecx, centerX
    sub ecx, 3
    mov edx, centerY
    add edx, 6
    lea r8, [linebuf]
    call moveXY

    ; Build line "[219|219]" but just two chars separated by '|'
    ; sprintf(linebuf, "%c|%c", 219, 219);
    lea rcx, [linebuf]
    mov rdx, fmt2         ; "%c|%c"
    mov r8b, 219
    mov r9b, 219
    ; No extra args, just 4 max

    call sprintf

    ; moveXY(centerX-1, centerY+7, linebuf)
    mov ecx, centerX
    sub ecx, 1
    mov edx, centerY
    add edx, 7
    lea r8, [linebuf]
    call moveXY

    ; moveXY(centerX, centerY+8, "|")
    mov ecx, centerX
    mov edx, centerY
    add edx, 8
    mov r8, str_pipe
    call moveXY

    ; moveXY(centerX, centerY+9, "|")
    mov ecx, centerX
    mov edx, centerY
    add edx, 9
    mov r8, str_pipe
    call moveXY

    ; moveXY(centerX-1, centerY+10, "/|\\")
    mov ecx, centerX
    sub ecx, 1
    mov edx, centerY
    add edx, 10
    mov r8, str_slash_pipe
    call moveXY

    jmp .done

.justbow:
    ; moveXY(centerX, centerY+2, " ")
    mov ecx, centerX
    mov edx, centerY
    add edx, 2
    mov r8, str_space
    call moveXY

    ; moveXY(centerX-4, centerY+3, "____ ____")
    mov ecx, centerX
    sub ecx, 4
    mov edx, centerY
    add edx, 3
    mov r8, str_line1_justbow
    call moveXY

    ; moveXY(centerX-5, centerY+4, "/         \\")
    mov ecx, centerX
    sub ecx, 5
    mov edx, centerY
    add edx, 4
    mov r8, str_line2_justbow
    call moveXY

    ; moveXY(centerX-6, centerY+5, "/_____ _____\\")
    mov ecx, centerX
    sub ecx, 6
    mov edx, centerY
    add edx, 5
    mov r8, str_line3_justbow
    call moveXY

    ; sprintf(linebuf, "[%c%c %c%c]", 219, 219, 219, 219);
    lea rcx, [linebuf]
    mov rdx, fmt3  ; "[%c%c %c%c]"
    mov r8b, 219
    mov r9b, 219
    sub rsp, 16
    mov byte [rsp + 8], 219
    mov byte [rsp + 9], 219
    call sprintf
    add rsp, 16

    ; moveXY(centerX-3, centerY+6, linebuf)
    mov ecx, centerX
    sub ecx, 3
    mov edx, centerY
    add edx, 6
    lea r8, [linebuf]
    call moveXY

    ; sprintf(linebuf, "%c %c", 219, 219);
    lea rcx, [linebuf]
    mov rdx, fmt4  ; "%c %c"
    mov r8b, 219
    mov r9b, 219
    call sprintf

    ; moveXY(centerX-1, centerY+7, linebuf)
    mov ecx, centerX
    sub ecx, 1
    mov edx, centerY
    add edx, 7
    lea r8, [linebuf]
    call moveXY

    ; moveXY(centerX, centerY+8, " ")
    mov ecx, centerX
    mov edx, centerY
    add edx, 8
    mov r8, str_space
    call moveXY

    ; moveXY(centerX, centerY+9, " ")
    mov ecx, centerX
    mov edx, centerY
    add edx, 9
    mov r8, str_space
    call moveXY

    ; moveXY(centerX-1, centerY+10, "   ")
    mov ecx, centerX
    sub ecx, 1
    mov edx, centerY
    add edx, 10
    mov r8, str_spaces3
    call moveXY

.done:
    pop rbp
    ret
