%include "../include/position_struc.inc"
%include "../include/interface_table_struc.inc"
%include "../include/game/board_struc.inc"
%include "../include/snake/snake_struc.inc"
%include "../include/snake/unit_struc.inc"


section .data
    board_width db "board_width: %d", 13, 10, 0
    board_height db "board_height: %d", 13, 10, 0
    board_snake db "board_snake: %p", 13, 10, 0
    board_food db "board_food: %p", 13, 10, 0
    board_first_buffer db "board_buffer: %d", 13, 10, 0

    snake_length db "snake_length: %d", 13, 10, 0
    snake_head db "snake_head: %p", 13, 10, 0
    snake_tail db "snake_tail: %p", 13, 10, 0

    unit_interface_table db "unit_table: %p", 13, 10, 0
    unit_position db "unit_position: %p", 13, 10, 0
    unit_char db "unit_char: %c", 13, 10, 0
    unit_direction db "unit_direction: %d", 13, 10, 0
    unit_next db "unit_next: %p", 13, 10, 0

    table_drawable db "table_drawable: %p", 13, 10, 0
    table_food db "table_food: %p", 13, 10, 0

    position_x db "position_x: %d", 13, 10, 0
    position_y db "position_y: %d", 13, 10, 0

section .text
    global main
    extern board_new
    extern board_setup
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    mov rcx, 50
    mov rdx, 50
    call board_new

    mov [rbp - 8], rax
    ; Access width (at offset 0)
    lea rcx, [rel board_width]
    movzx rdx, word [rax + board.width] 
    call printf
    
    mov rax, [rbp - 8]
    lea rcx, [rel board_height]
    movzx rdx, word [rax + board.height]               ; rax + 0 -> width (2 bytes)
    call printf
    
    mov rax, [rbp - 8]
    lea rcx, [rel board_snake]
    mov rdx, [rax + board.snake_ptr]          ; rax + 4 -> console_handle (8 bytes)
    call printf
    
    mov rax, [rbp - 8]
    lea rcx, [rel board_food]
    mov rdx, [rax + board.food_ptr]          ; rax + 4 -> console_handle (8 bytes)
    call printf
    
    mov rax, [rbp - 8]
    lea rcx, [rel board_first_buffer]
    movzx rdx, byte [rax + board.buffer_start]          ; rax + 4 -> console_handle (8 bytes)
    call printf

    mov rax, [rbp - 8]
    mov rax, [rax + board.snake_ptr]
    mov [rbp - 8], rax

    lea rcx, [rel snake_length]
    mov rdx, [rax + snake.length]
    call printf

    mov rax, [rbp - 8]
    lea rcx, [rel snake_head]
    mov rdx, [rax + snake.head_ptr]
    call printf

    mov rax, [rbp - 8]
    lea rcx, [rel snake_tail]
    mov rdx, [rax + snake.tail_ptr]
    call printf

    mov rax, [rbp - 8]
    mov rax, [rax + snake.head_ptr]
    mov [rbp - 8], rax

    lea rcx, [rel unit_interface_table]
    mov rdx, [rax + unit.interface_table_ptr]
    call printf

    mov rax, [rbp - 8]
    lea rcx, [rel unit_position]
    mov rdx, [rax + unit.position_ptr]
    call printf

    mov rax, [rbp - 8]
    lea rcx, [rel unit_char]
    movzx rdx, byte [rax + unit.char]
    call printf

    mov rax, [rbp - 8]
    lea rcx, [rel unit_direction]
    mov rdx, [rax + unit.direction]
    call printf

    mov rax, [rbp - 8]
    lea rcx, [rel unit_next]
    mov rdx, [rax + unit.next_unit_ptr]
    call printf

    mov rax, [rbp - 8]
    mov rax, [rax + unit.interface_table_ptr]
    mov [rbp - 16], rax

    lea rcx, [rel table_drawable]
    mov rdx, [rax + interface_table.vtable_drawable_ptr]
    call printf

    mov rax, [rbp - 16]
    lea rcx, [rel table_food]
    mov rdx, [rax + interface_table.vtable_food_ptr]
    call printf

    mov rax, [rbp - 8]
    mov rax, [rax + unit.position_ptr]
    mov [rbp - 8], rax

    lea rcx, [rel position_x]
    movzx rdx, word [rax + position.x]
    call printf

    mov rax, [rbp - 8]
    lea rcx, [rel position_y]
    movzx rdx, word [rax + position.y]
    call printf

    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret