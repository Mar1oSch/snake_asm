%include "../include/interface_table_struc.inc"
%include "../include/position_struc.inc"
%include "../include/game/board_struc.inc"
%include "../include/food/food_struc.inc"
%include "../include/snake/snake_struc.inc"
%include "../include/snake/unit_struc.inc"

global board_new, board_destroy, board_draw, board_setup, board_move_snake, get_board, board_create_new_food

section .rodata
    constructor_name db "board_new", 0
    fence_char db "#"

section .data
    filetime_struct dd 0, 0

section .bss
    BOARD_PTR resq 1

section .text
    extern malloc
    extern free
    extern Sleep
    extern GetSystemTimeAsFileTime

    extern snake_new, snake_update, snake_get_tail_position
    extern console_manager_new, console_manager_setup, console_manager_write, console_manager_move_cursor, console_manager_erase
    extern food_new, food_destroy
    extern malloc_failed, object_not_created
    extern DRAWABLE_VTABLE_X_POSITION_OFFSET, DRAWABLE_VTABLE_Y_POSITION_OFFSET, DRAWABLE_VTABLE_CHAR_PTR_OFFSET

;;;;;; PUBLIC FUNCTIONS ;;;;;;
board_new:
    ; Expect width and height in ECX
    push rbp
    mov rbp, rsp
    sub rsp, 72

    cmp qword [rel BOARD_PTR], 0
    jne .complete

    mov word [rbp - 8], cx            ; Move height onto stack. (ECX = width, height)
    add word [rbp - 8], 2
    shr rcx, 16                       ; Shifting ECX right by 16 bits. (ECX = 0, width)
    mov word [rbp - 16], cx           ; Move width onto stack. (ECX = 0, width)
    add word [rbp - 16], 2

    xor rcx, rcx
    mov ax, word [rbp - 16]
    mul word [rbp - 8]
    mov cx, ax
    add cx, board_size
    call malloc
    test rax, rax
    jz _b_malloc_failed
    mov [rel BOARD_PTR], rax

    xor rcx, rcx
    mov cx, word [rbp - 16]
    mov [rax + board.width], cx
    shl rcx, 16
    mov cx, word [rbp - 8]
    mov [rax + board.height], cx

    mov cx, 10
    shl rcx, 16
    mov cx, word [rax + board.height]
    shr cx, 1
    mov rdx, 2
    call snake_new

    mov rcx, [rel BOARD_PTR]
    mov [rcx + board.snake_ptr], rax
    mov qword [rcx + board.food_ptr], 0

    call console_manager_new
    mov r8, [rel BOARD_PTR]
    mov [r8 + board.console_manager_ptr], rax

    movzx rcx, word [r8 + board.width]
    sub rcx, 10
    shl rcx, 16
    mov cx, word [r8 + board.height]
    sub cx, 10
    call food_new

    mov rcx, [rel BOARD_PTR]
    mov [rcx + board.food_ptr], rax

.complete:
    mov rax, qword [rel BOARD_PTR]
    mov rsp, rbp
    pop rbp
    ret

board_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel BOARD_PTR], 0
    je _b_object_failed

    call free

    mov rsp, rbp
    pop rbp
    ret

board_setup:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov r8, [rel BOARD_PTR]
    mov cx, [r8 + board.height]
    shl rcx, 16
    mov cx, [r8 + board.width]
    call console_manager_setup

    mov r8, [rel BOARD_PTR]
    mov cx, [r8 + board.height]
    shl rcx, 16
    mov cx, [r8 + board.width]
    call _draw_fence

    call _draw_food

    mov rsp, rbp
    pop rbp
    ret

board_move_snake:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call _draw_snake
    call _erase_last_snake_unit
    call _move_cursor_to_end

    mov rsp, rbp
    pop rbp
    ret

board_create_new_food:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel BOARD_PTR], 0
    je _b_object_failed

    mov rcx, [rel BOARD_PTR]
    mov rcx, [rcx + board.food_ptr]
    call food_destroy
.loop:
    call _create_random_position
    mov [rbp - 8], rax
    mov rcx, rax
    call _check_position_with_snake
    cmp rax, 0
    je .loop

    mov rcx, [rbp - 8]
    call food_new

    mov rcx, [rel BOARD_PTR]
    mov [rcx + board.food_ptr], rax

    call _draw_food

    mov rsp, rbp
    pop rbp
    ret

get_board:
    cmp qword [rel BOARD_PTR], 0
    je _b_object_failed

    mov rax, [rel BOARD_PTR]
    ret




;;;;;; PRIVATE FUNCTIONS ;;;;;;
_board_draw_content:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel BOARD_PTR], 0
    je _b_object_failed


    call _draw_snake
    mov qword [rbp - 8], 50
    call _move_cursor_to_end

    mov rsp, rbp
    pop rbp
    ret

_draw_snake:
    push rbp
    mov rbp, rsp
    sub rsp, 70

    cmp qword [rel BOARD_PTR], 0
    je _b_object_failed

    mov r9, [rel BOARD_PTR]
    mov r9, [r9 + board.snake_ptr]                          ; Get snake_ptr into R9.

    mov r10, [r9 + snake.head_ptr]
    mov [rbp - 8], r10                                      ; Save head of snake.

    mov r9, [r9 + snake.tail_ptr]                           
    mov [rbp - 16], r9                                      ; Save tail of snake.

    mov r11, [r10 + unit.interface_table_ptr]
    mov r11, [r11 + interface_table.vtable_drawable_ptr]    ; Get the drawable-interface into R11
    mov [rbp - 24], r11                                     ; Save interface relation.

.loop:
    mov rcx, r10                                            ; Move pointer to unit to RCX.
    call [r11 + DRAWABLE_VTABLE_X_POSITION_OFFSET]
    mov word [rbp - 32], ax                                 ; Save X-Position.
    mov rcx, r10                                            ; Move pointer to unit to RCX.
    call [r11 + DRAWABLE_VTABLE_Y_POSITION_OFFSET]
    mov word [rbp - 40], ax                                 ; Save Y-Position.
    mov rcx, r10                                            ; Move pointer to unit to RCX.
    call [r11 + DRAWABLE_VTABLE_CHAR_PTR_OFFSET]
    mov rdx, rax                                            ; Load pointer to char into RDX.
    mov cx, [rbp - 32]                                      ; Move X-Position into CX (ECX = 0, X)
    shl rcx, 16                                             ; Shift ECX 16 bits to the left. (ECX = X, 0)
    mov cx, [rbp - 40]                                      ; Move Y-Position into CX (ECX = X, Y)
    call console_manager_write
    mov r10, [rbp - 8]
    cmp r10, [rbp - 16]
    je .complete
    mov r10, [r10 + unit.next_unit_ptr]
    mov r11, [rbp - 24]
    mov [rbp - 8], r10
    jmp .loop

.complete:
    mov rsp, rbp
    pop rbp
    ret

_draw_fence:
    push rbp
    mov rbp, rsp
    sub rsp, 80

    cmp qword [rel BOARD_PTR], 0
    je _b_object_failed

    ; Expect Width and Height of Board in RCX
    mov word [rbp - 8], cx                      ; Save height.
    shr rcx, 16
    mov word [rbp - 16], cx    

    ; Save non-volatile regs.
    mov [rbp - 24], r15
    mov [rbp - 32], r14

    xor r15, r15        ; Zero Height counter
.loop:
    cmp r15, 0
    je .draw_whole_line
    cmp r15w, word [rbp - 8]
    je .draw_whole_line

.draw_single_chars:
    mov cx, r15w
    shl rcx, 16
    mov cx, 0
    lea rdx, [rel fence_char] 
    call console_manager_write
    mov cx, r15w
    shl rcx, 16
    mov cx, word [rbp - 16]
    lea rdx, [rel fence_char] 
    call console_manager_write
    jmp .loop_handle

.draw_whole_line:
    xor r14, r14        ; Zero Width counter
    .inner_loop:
        mov cx, r15w
        shl rcx, 16
        mov cx, r14w
        lea rdx, [rel fence_char]
        call console_manager_write
    .inner_loop_handle:
        cmp r14w, [rbp - 16]
        je .loop_handle
        inc r14w
        jmp .inner_loop

.loop_handle:
    cmp r15w, [rbp - 8]
    je .complete
    inc r15
    jmp .loop

.complete:
    mov [rbp - 32], r14
    mov [rbp - 24], r15
    mov rsp, rbp
    pop rbp
    ret

_draw_food:
    push rbp
    mov rbp, rsp
    sub rsp, 72

    cmp qword [rel BOARD_PTR], 0
    je _b_object_failed

    mov rcx, [rel BOARD_PTR]
    mov rcx, [rcx + board.food_ptr]
    mov [rbp - 8], rcx

    mov rdx, [rcx + food.interface_table_ptr]
    mov rdx, [rdx + interface_table.vtable_drawable_ptr]
    mov [rbp - 16], rdx

    call [rdx + DRAWABLE_VTABLE_X_POSITION_OFFSET]
    mov word [rbp - 24], ax

    mov rcx, [rbp - 8]
    mov rdx, [rbp - 16]
    call [rdx + DRAWABLE_VTABLE_Y_POSITION_OFFSET]
    mov word [rbp - 32], ax

    mov rcx, [rbp - 8]
    mov rdx, [rbp - 16]
    call [rdx + DRAWABLE_VTABLE_CHAR_PTR_OFFSET]

    mov rdx, rax
    mov cx, word [rbp - 24]
    shl rcx, 16
    mov cx, word [rbp - 32]
    call console_manager_write

    mov rsp, rbp
    pop rbp
    ret

_erase_last_snake_unit:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel BOARD_PTR], 0
    je _b_object_failed

    call snake_get_tail_position

    mov ecx, eax
    call console_manager_erase

.complete:
    mov rsp, rbp
    pop rbp
    ret

_move_cursor_to_end:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel BOARD_PTR], 0
    je _b_object_failed

    xor rcx, rcx
    mov r8, [rel BOARD_PTR]
    mov cx, [r8 + board.width]
    shl rcx, 16
    mov cx, [r8 + board.height]
    add cx, 1
    call console_manager_move_cursor

    mov rsp, rbp
    pop rbp
    ret

_create_random_position:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel BOARD_PTR], 0
    je _b_object_failed


    lea rcx, [rel filetime_struct]
    call GetSystemTimeAsFileTime

    xor rax, rax
    mov rax, [rel filetime_struct]
    ror rax, 32
    mov rcx, [rel BOARD_PTR]

.calculate_x:
    movzx r8, word [rcx + board.width]
    xor rdx, rdx
    div r8

    cmp dx, 0
    je .increment_x
    cmp dx, word [rcx + board.width]
    je .decrement_x
    jmp .calculate_y
.increment_x:
    inc dx
    jmp .calculate_y
.decrement_x:
    dec dx

.calculate_y:
    mov word [rbp - 8], dx
    xor rax, rax
    mov rax, [rel filetime_struct]
    rol rax, 32
    movzx r8, word [rcx + board.height]
    xor rdx, rdx
    div r8

    cmp dx, 0
    je .increment_y
    cmp dx, word [rcx + board.height]
    je .decrement_y
    jmp .complete
.increment_y:
    inc dx
    jmp .complete
.decrement_y:
    dec dx

.complete:
    mov word [rbp - 16], dx

    movzx rax, word [rbp - 8]
    shl rax, 16
    mov ax, word [rbp - 16]

    mov rsp, rbp
    pop rbp
    ret

_check_position_with_snake:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect X- and Y-Coordinates in ECX.
    mov [rbp - 8], cx               ; Save Y-Coordinates
    shr rcx, 16
    mov [rbp - 16], cx              ; Save X-Coordinates

    cmp qword [rel BOARD_PTR], 0
    je _b_object_failed

    mov rcx, [rel BOARD_PTR]
    mov rcx, [rcx + board.snake_ptr]
    mov r8, [rcx + snake.tail_ptr]
    mov [rbp - 24], r8
    mov r8, [rcx + snake.head_ptr]

.loop:
    mov r9, [r8 + unit.position_ptr]
    mov r10w, word [r9 + position.x]
    cmp r10w, word [rbp - 16]
    jne .loop_handle
    mov r10w, word [r9 + position.y]
    cmp r10w, word [rbp - 8]
    je .failed
.loop_handle:
    cmp r8, [rbp - 24]
    je .worked
    mov r8, [r8 + unit.next_unit_ptr]
    jmp .loop

.failed:
    mov rax, 0
    jmp .complete

.worked:
    mov rax, 1

.complete:
    mov rsp, rbp
    pop rbp
    ret




;;;;;; ERROR HANDLING ;;;;;;
_b_object_failed:
    lea rcx, [rel constructor_name]
    call object_not_created

    mov rsp, rbp
    pop rbp
    ret

_b_malloc_failed:
    lea rcx, [rel constructor_name]
    mov rdx, rax
    call malloc_failed

    mov rsp, rbp
    pop rbp
    ret