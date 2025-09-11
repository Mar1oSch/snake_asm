global food_new, food_destroy, food_get_char, food_get_points

section .rodata
food:
    FOOD_INTERFACE_TABLE_OFFSET equ 0
    FOOD_CHAR_OFFSET equ 8
    FOOD_POINTS_OFFSET equ 16
    FOOD_POSITION_PTR_OFFSET equ 24
food_end:
    FOOD_SIZE equ food_end - food
    FOOD_POINTS equ 100
    FOOD_CHAR equ "~"

section .text
    extern malloc
    extern free
    extern position_new
    extern interface_table_new
    extern food_vtable_food
    extern food_vtable_drawable

food_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40
    
    ; Expect X-Coordinates in RCX
    ; Expect Y_Coordinates in RDX
    call position_new
    mov qword [rbp - 8], rax

    lea rcx, [rel food_vtable_drawable]
    lea rdx, [rel food_vtable_food]
    call interface_table_new
    mov qword [rbp - 16], rax

    mov rcx, FOOD_SIZE
    call malloc
    mov qword [rbp - 24], rax

    mov rcx, [rbp - 16]
    mov qword [rax + FOOD_INTERFACE_TABLE_OFFSET], rcx
    
    mov qword [rax + FOOD_CHAR_OFFSET], FOOD_CHAR 

    mov qword [rax + FOOD_POINTS_OFFSET], FOOD_POINTS

    mov rcx, [rbp - 8]
    mov qword [rax + FOOD_POSITION_PTR_OFFSET], rcx

    mov rsp, rbp
    pop rbp
    ret

food_get_points:
    mov rax, FOOD_POINTS
    ret

food_get_char:
    mov rax, FOOD_CHAR
    ret

food_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call free

    mov rsp, rbp
    pop rbp
    ret