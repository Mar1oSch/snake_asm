; Strucs:
%include "../include/strucs/food/food_struc.inc"
%include "../include/strucs/position_struc.inc"

; This is the simple food-object the snake is consuming.
; It is purely passive and its usage is getting handled by the board and the game.
; That's why it needs to get to know its position when it is constructed.

global food_new, food_destroy, food_get_char_ptr, food_get_x_position, food_get_y_position, food_draw

section .rodata
    ;;;;;; CONSTANTS ;;;;;;
    FOOD_CHAR equ "*"

    ;;;;;; DEBUGGING ;;;;;;
    constructor_name db "food_new", 0

section .text
    extern malloc, free

    extern position_new, position_destroy
    extern interface_table_new, interface_table_destroy
    extern drawable_vtable_food

    extern malloc_failed

;;;;;;PUBLIC METHODS ;;;;;;

; The constructor for the food object.
; It handles the creation of a new food object.
; It needs to know the X- and Y- coordinates, the food is located on the board.
; The Y-Coordinate is stored in the lower 16 bits of ECX (EX).
; The X-Coordinate is stored in the higher 16 bits of ECX.
food_new:
.set_up:
    ; Setting up the stack frame:
    ; 16 bytes space for local variables.
    push rbp
    mov rbp, rsp
    sub rsp, 16                                              

    ; Expect X- and Y-Coordinates in ECX

    ; Setting up 32 bytes shadow space for called functions.
    sub rsp, 32

.create_dependend_objects:
    ; Creating the position object, a food object is pointing to.
    call position_new
    ; First local variable: 
    ; Position pointer.
    mov [rbp - 8], rax                    

    ; Creating an interface table. 
    ; The food object is a drawable. 
    lea rcx, [rel drawable_vtable_food]
    call interface_table_new
    ; Second local variable:
    ; Interface table pointer.
    mov [rbp - 16], rax

.create_object:
    ; Creating the food itself, containing space for:
    ; - A pointer to the position object created earlier. (8 bytes)
    ; - A pointer to the interface table object created earlier. (8 bytes)
    ; - The char it is represented by on the board. (1 byte)
    mov rcx, food_size
    call malloc
    ; Pointer to food object is stored in RAX now.
    ; Check if return of malloc is 0 (if it is, it failed).
    ; If it failed, it will get printed into the console.
    test rax, rax
    jz _f_malloc_failed

.set_up_object:
    ; Getting pointer to interface table into RCX and move it into the reserved memory space of created food object.
    mov rcx, [rbp - 16]
    mov qword [rax + food.interface_table_ptr], rcx

    ; Same as above with position pointer.
    mov rcx, [rbp - 8]
    mov qword [rax + food.position_ptr], rcx

    ; Save defined FOOD_CHAR into reserved memory space.
    mov byte [rax + food.char], FOOD_CHAR 

.complete:
    ; Restore old stack frame and leave the constructor.
    mov rsp, rbp
    pop rbp
    ret

food_destroy:
.set_up:
    ; Setting up the stack frame:
    ; 8 bytes for local variables.
    ; 8 bytes to keep stack 16 byte algined.
    push rbp
    mov rbp, rsp
    sub rsp, 16

    ; Expect pointer to the food object in RCX.
    ; Save first argument into shadow space (RBP + 16).
    mov [rbp + 16], rcx

.destroy_dependend_objects:
    ; Free the space of the position object owned by the food object which is going to be destroyed.
    mov rcx, [rcx + food.position_ptr]
    call position_destroy

    ; Also free the space of the interface table.
    mov rcx, [rbp + 16]
    mov rcx, [rcx + food.interface_table_ptr]
    call interface_table_destroy

.destroy_object:
    ; Finally free the food object itself.
    mov rcx, [rbp + 16]
    call free

.complete:
    ; Restore old stack frame and leave the function.
    mov rsp, rbp
    pop rbp
    ret




;;;;;; DRAWABLE  INTERFACE ;;;;;;

; Here I wrote three getters belonging to the drawable interface:
; 1. : Get the pointer to the Character, representing the drawable on the board.
; 2. : Get the X-Coordinate of the Drawable.
; 3. : Get the Y-Coordinate of the Drawable.

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




;;;;;; ERROR HANDLING ;;;;;;
_f_malloc_failed:
.set_up:
    ; Setting up stack frame without local variables.
    push rbp
    mov rbp, rsp

.debug:
    lea rcx, [rel constructor_name]
    mov rdx, rax
    ; Reserve shadow space for function call:
    sub rsp, 32
    call malloc_failed

.complete:
    mov rsp, rbp
    pop rbp
    ret