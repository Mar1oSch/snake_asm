; Strucs:
%include "../include/strucs/position_struc.inc"

; The position object each drawable holds. 
; It defines the X-coordinate and Y-coordinate of the drawable.

global position_new, position_destroy

section .rodata
    ;;;;;; DEBUGGING ;;;;;;
    constructor_name db "position_new", 0

section .text
    extern malloc, free

    extern malloc_failed

;;;;;; PUBLIC METHODS ;;;;;;

; The position is getting created. 
; The constructor just needs to know, which X- and Y-coordinates the position is constituted of. 
position_new:
    ; * Expect X- and Y-coordinates in ECX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Save ECX into the shadow space.
        mov [rbp + 16], ecx             

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .create_object:
        ; Creating the position, containing space for:
        ; * - X-coordinate. (2 bytes)
        ; * - Y-coordinate. (2 bytes)
        mov rcx, position_size
        call malloc
        ; Pointer to position object is stored in RAX now.
        ; Check if return of malloc is 0 (if it is, it failed).
        ; If it failed, it will get printed into the console.
        test rax, rax
        jz _pos_malloc_failed

    .set_up_object:
        ; Load the X- and Y-coordinates from the shadow space.
        mov ecx, [rbp + 16]
        ; Save them into the X- and Y-fields of the object.
        mov word [rax + position.y], cx
        shr ecx, 16
        mov word [rax + position.x], cx

    .complete:
        ; Restore old stack frame and return from constructor.
        ; Return pointer to position object in RAX.
        mov rsp, rbp
        pop rbp
        ret

position_destroy:
    ; * Expect pointer to position object in RCX
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .destroy_object:
        call free

    .complete:
        ; Restore old stack frame and return from destructor.
        mov rsp, rbp
        pop rbp
        ret




;;;;;; DEBUGGING ;;;;;;

_pos_malloc_failed:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .debug:
        lea rcx, [rel constructor_name]
        mov rdx, rax
        call malloc_failed

    .complete:
        ; Restore old stack frame and leave debugging function.
        mov rsp, rbp
        pop rbp
        ret