%include "../include/food/food_struc.inc"
%include "../include/position_struc.inc"
global food_new, food_destroy, food_get_char_ptr, food_get_points, food_get_x_position, food_get_y_position, food_draw

section .rodata
    FOOD_POINTS equ 100
    FOOD_CHAR equ "*"

section .text
    extern malloc
    extern free
    extern position_new
    extern interface_table_new
    extern food_vtable_food
    extern drawable_vtable_food

food_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40
    
    ; Expect X- and Y-Coordinates in ECX
    call position_new
    mov qword [rbp - 8], rax

    lea rcx, [rel drawable_vtable_food]
    lea rdx, [rel food_vtable_food]
    call interface_table_new
    mov qword [rbp - 16], rax

    mov rcx, food_size
    call malloc
    mov qword [rbp - 24], rax

    mov rcx, [rbp - 16]
    mov qword [rax + food.interface_table_ptr], rcx
    
    mov qword [rax + food.char], FOOD_CHAR 

    mov qword [rax + food.points], FOOD_POINTS

    mov rcx, [rbp - 8]
    mov qword [rax + food.position_ptr], rcx

    mov rsp, rbp
    pop rbp
    ret

food_get_char_ptr:
    ; Expect pointer to food object in RCX
    lea rax, [rcx + food.char]
    ret

food_get_x_position:
    ; Expect pointer to food object in RCX
    mov rax, [rcx + food.position_ptr]
    movzx rax, word [rax + position.x]
    ret

food_get_y_position:
    ; Expect pointer to food object in RCX
    mov rax, [rcx + food.position_ptr]
    movzx rax, word [rax + position.y]
    ret

food_get_points:
    mov rax, FOOD_POINTS
    ret

food_draw:
    ret

food_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call free

    mov rsp, rbp
    pop rbp
    ret