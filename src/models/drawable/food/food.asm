; Constants:
%include "./include/data/food/food_constants.inc"
%include "./include/data/interface_table_constants.inc"
%include "./include/data/position_constants.inc"

; Strucs:
%include "./include/strucs/food/food_struc.inc"
%include "./include/strucs/position_struc.inc"
%include "./include/strucs/interface_table_struc.inc"

; This is the simple food-object the snake is consuming.
; It is purely passive and its usage is getting handled by the board and the game.
; That's why it needs to get to know its position when it is constructed.

global food_static_vtable

section .rodata
    ;;;;;; DEBUGGING ;;;;;;
    constructor_name db "food_new", 0

    ;;;;;; VTABLES ;;;;;;
    food_static_vtable:
        dq food_new

    food_methods_vtable:
        dq food_destroy

    food_drawable_vtable:
        dq food_get_char_ptr 
        dq food_get_x_position
        dq food_get_y_position

section .text
    extern malloc, free

    extern position_static_vtable
    extern interface_table_static_vtable

    extern malloc_failed



;;;;;;PUBLIC METHODS ;;;;;;

; The constructor for the food object.
; It handles the creation of a new food object.
; It needs to know the X- and Y- coordinates, the food is located on the board.
; The Y-Coordinate is stored in the lower 16 bits of ECX (EX).
; The X-Coordinate is stored in the higher 16 bits of ECX.
food_new:
    ; * Expect X- and Y-Coordinates in ECX
    .set_up:
        ; Set up stack frame:
        ; * 16 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 16                                              

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .create_dependend_objects:
        ; Creating the position object, a food object is pointing to.
        lea r10, [rel position_static_vtable]
        call [r10 + POSITION_STATIC_CONSTRUCTOR_OFFSET]
        ; * First local variable: Position pointer.
        mov [rbp - 8], rax                    

        ; Creating an interface table. 
        ; The food object is a drawable. 
        lea rcx, [rel food_drawable_vtable]
        lea r10, [rel interface_table_static_vtable]
        call [r10 + INTERFACE_TABLE_STATIC_CONSTRUCTOR_OFFSET]
        ; * Second local variable: Interface table pointer.
        mov [rbp - 16], rax

    .create_object:
        ; Creating the food itself, containing space for:
        ; * A pointer to the methods vtable. (8 bytes)
        ; * A pointer to the position object created earlier. (8 bytes)
        ; * A pointer to the interface table object created earlier. (8 bytes)
        ; * The char it is represented by on the board. (1 byte)
        mov rcx, food_size
        call malloc
        ; Pointer to food object is stored in RAX now.
        ; Check if return of malloc is 0 (if it is, it failed).
        ; If it failed, it will get printed into the console.
        test rax, rax
        jz _f_malloc_failed

    .set_up_object:
        ; Save pointer to methods vtable in its preserved memory space.
        lea rcx, [rel food_methods_vtable]
        mov [rax + food.methods_vtable_ptr], rcx

        ; Getting pointer to interface table into RCX and move it into the reserved memory space of created food object.
        mov rcx, [rbp - 16]
        mov [rax + food.interface_table_ptr], rcx

        ; Same as above with position pointer.
        mov rcx, [rbp - 8]
        mov [rax + food.position_ptr], rcx

        ; Save defined FOOD_CHAR into reserved memory space.
        mov byte [rax + food.char], FOOD_CHAR 

    .complete:
        ; Restore old stack frame and leave the constructor.
        ; Return the food pointer in RAX.
        mov rsp, rbp
        pop rbp
        ret

food_destroy:
    ; * Expect pointer to the food object in RCX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

        ; Save params into shadow space.
        mov [rbp + 16], rcx

    .destroy_dependend_objects:
        ; Free the space of the position object owned by the food object which is going to be destroyed.
        mov rcx, [rcx + food.position_ptr]
        mov r10, [rcx + position.methods_vtable_ptr]
        call [r10 + POSITION_METHODS_DESTRUCTOR_OFFSET]

        ; Also free the space of the interface table.
        mov rcx, [rbp + 16]
        mov rcx, [rcx + food.interface_table_ptr]
        mov r10, [rcx + interface_table.methods_vtable_ptr]
        call [r10 + INTERFACE_TABLE_METHODS_DESTRUCTOR_OFFSET]

    .destroy_object:
        ; Finally free the food object itself.
        mov rcx, [rbp + 16]
        call free

    .complete:
        ; Restore old stack frame and leave the destructor.
        mov rsp, rbp
        pop rbp
        ret




;;;;;; DRAWABLE  INTERFACE ;;;;;;

; Here I wrote three getters belonging to the drawable interface:
; * 1. : Get the pointer to the Character, representing the drawable on the board.
; * 2. : Get the X-Coordinate of the Drawable.
; * 3. : Get the Y-Coordinate of the Drawable.

food_get_char_ptr:
    ; * Expect pointer to food object in RCX.
    ; Return pointer to food char in RAX.
    lea rax, [rcx + food.char]
    ret

food_get_x_position:
    ; * Expect pointer to food object in RCX.
    ; Return X-Position in RAX.
    mov rax, [rcx + food.position_ptr]
    movzx rax, word [rax + position.x]
    ret

food_get_y_position:
    ; * Expect pointer to food object in RCX.
    ; Return Y-Position in RAX.
    mov rax, [rcx + food.position_ptr]
    movzx rax, word [rax + position.y]
    ret




;;;;;; ERROR HANDLING ;;;;;;
_f_malloc_failed:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Reserve shadow space for function call:
        sub rsp, 32

    .debug:
        lea rcx, [rel constructor_name]
        mov rdx, rax
        call malloc_failed

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret