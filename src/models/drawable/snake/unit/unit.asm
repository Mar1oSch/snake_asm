; Strucs:
%include "../include/strucs/interface_table_struc.inc"
%include "../include/strucs/position_struc.inc"
%include "../include/strucs/snake/unit_struc.inc"

; This is the unit object a snake is built of.
; The unit is an object part of a singly linked list. It always points to the next unit.
; It is also passive, and it is handled especially by the board and the snake itself.
; Because it is moving (in difference to food), it needs to know the direction it is moving.
; Since it also is a drawable object, it gets told, where on the board it is positioned at the moment.

global unit_new, unit_destroy, unit_get_char_ptr, unit_get_x_position, unit_get_y_position

;;;;;; CONSTANTS ;;;;;;
UNIT_CHAR equ "O"
HEAD_CHAR equ "@"

section .rodata
    ;;;;;; DEBUGGING ;;;;;;
    constructor_name db "unit_new", 0

section .text
    extern malloc, free

    extern position_new, position_destroy
    extern interface_table_new, interface_table_destroy
    extern drawable_vtable_unit

    extern malloc_failed

;;;;;; PUBLIC METHODS ;;;;;;

; The constructor for the unit object.
; It handles the creation of a new unit object.
; It needs to know the X- and Y- coordinates, the unit is initially located on the board.
; The Y-Coordinate is stored in the lower 16 bits of ECX (EX).
; The X-Coordinate is stored in the higher 16 bits of ECX.
; It also needs to know, which direction it will move next. This is important for the update algorithm the game is handling.
; Finally the unit is also represented by a character on the board. I wanted to differentiate between the head and the rest. That's why the snake needs to tell the unit, if it is the head of the snake or it isn't. The unit uses that information to choose, which character is used to represent it.
unit_new:
    .set_up:
        ; Setting up the stack frame:
        ; * 24 bytes space for local variables. 
        ; * 8 bytes to keep the stack 16 byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 32

        ; Expect X- and Y-Coordinates in ECX.
        ; Expect direction in DL.
        ; Expect 1 if char is the head or 0 if not in R8.
        ; Save DL and R8 into shadow space.
        mov [rbp + 16], dl
        mov [rbp + 24], r8

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .create_dependend_objects:
        ; Create the position object, the unit object will later point at.
        call position_new
        ; First local variable: 
        ; * Position pointer.
        mov [rbp - 8], rax

        ; Creating the interface table.
        ; The unit is a drawable.
        lea rcx, [rel drawable_vtable_unit]
        call interface_table_new
        ; Second local variable:
        ; * Interface table pointer.
        mov [rbp - 16], rax

    .get_character:
        ; Now the representing character will get called:
        mov rcx, [rbp + 24]
        call _handle_char
        ; Third local variable:
        ; Char of unit.
        mov [rbp - 24], al

    .create_object:
        ; Creating the unit itself, containing space for:
        ; * - A pointer to the position object created earlier. (8 bytes)
        ; * - A pointer to the interface table object created earlier. (8 bytes)
        ; * - A pointer to the next unit in the list. (Singly linked list) (8 bytes)
        ; * - The direction it is moving to. (1 = left, 2 = up, 3 = right, 4 = down) (1 byte)
        ; * - The char it is represented by on the board. (1 byte)
        mov rcx, unit_size
        call malloc
        ; Pointer to unit object is stored in RAX now.
        ; Check if return of malloc is 0 (if it is, it failed).
        ; If it failed, it will get printed into the console.
        test rax, rax
        jz _u_malloc_failed

    .set_up_object:
        ; Getting pointer to interface table into RCX and move it into the reserved memory space of created food object.
        mov rcx, [rbp - 16]
        mov qword [rax + unit.interface_table_ptr], rcx

        ; Same as above with position pointer.
        mov rcx, [rbp - 8]
        mov qword [rax + unit.position_ptr], rcx
        
        ; Save the direction into its preserved space.
        mov cl, [rbp + 16]
        mov [rax + unit.direction], cl

        ; Handle the unit as it would be the last element in the list.
        ; It will get updated by the game, if it gets a follow up.
        mov qword [rax + unit.next_unit_ptr], 0

        ; Now the char is getting loaded into CL and moved into the preserved space for it. 
        mov cl, [rbp - 24]
        mov byte [rax + unit.char], cl

    .complete:
        ; Restore old stack frame and leave the constructor.
        ; Return the unit pointer in RAX.
        mov rsp, rbp
        pop rbp
        ret

unit_destroy:
    .set_up:
        ; Setting up the stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Expect unit-pointer in RCX.
        mov [rbp + 16], rcx

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .destroy_dependend_objects:
        ; Free memory space of linked position object.
        mov rcx, [rcx + unit.position_ptr]
        call position_destroy

        ; Free memory space of linked interface table object.
        mov rcx, [rbp + 16]
        mov rcx, [rcx + unit.interface_table_ptr]
        call interface_table_destroy

    .destroy_object:
        ; Free unit object itself.
        mov rcx, [rbp + 16]
        call free

    .complete:
        ; Restore old stack frame and leave the destructor.
        mov rsp, rbp
        pop rbp
        ret




;;;;;; DRAWABLE INTERFACE ;;;;;;

; Here I wrote three getters belonging to the drawable interface:
; * 1. : Get the pointer to the Character, representing the drawable on the board.
; * 2. : Get the X-Coordinate of the Drawable.
; * 3. : Get the Y-Coordinate of the Drawable.

unit_get_char_ptr:
    ; Expect pointer to unit-object in RCX.
    ; Return pointer to unit char in RAX.
    lea rax, [rcx + unit.char]
    ret

unit_get_x_position:
    ; Expect pointer to unit-object in RCX.
    ; Return X-Position in RAX.
    mov rax, [rcx + unit.position_ptr]
    movzx rax, word [rax + position.x]
    ret

unit_get_y_position:
    ; Expect pointer to unit-object in RCX.
    ; Return Y-Position in RAX.
    mov rax, [rcx + unit.position_ptr]
    movzx rax, word [rax + position.y]
    ret




;;;;;; PRIVATE METHODS ;;;;;;

_handle_char:
    ; Expect: 
    ; - 1 if unit is head
    ; - 0 if it isn't the head
    ; in RCX.
    test rcx, rcx
    jz .normal

    .head:
        mov al, HEAD_CHAR
        ret

    .normal:
        mov al, UNIT_CHAR
        ret




;;;;;; ERROR HANDLING ;;;;;;
_u_malloc_failed:
    .set_up:
        ; Setting up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Reserve 32 bytes shadow space for called functions.
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