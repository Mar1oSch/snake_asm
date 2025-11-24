; Strucs:
%include "../include/strucs/game/options_struc.inc"

; The board is a simple options object.
; It defines the player and the level of the game.
; I decided to work with an options object, because it made 

global options_new, options_destroy

section .rodata
    ;;;;;; DEBUGGING ;;;;;;
    constructor_name db "object_new", 0

section .text
    extern malloc, free

    extern malloc_failed




;;;;;; PUBLIC METHODS ;;;;;;

; The constructor of the options object.
; It needs to know, which player is playing and which level is going to be played.
options_new:
    ; * Expect player pointer in RCX.
    ; * Expect lvl in EDX.
    .set_up:
        ; Setting up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Save params into shadow space.
        mov [rbp + 16], rcx
        mov [rbp + 24], edx

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .create_object:
        ; Creating the options, containing space for:
        ; * - Player pointer. (8 bytes)
        ; * - Lvl. (2 bytes)
        mov rcx, options_size
        call malloc
        ; Pointer to options object is stored in RAX now.
        ; Check if return of malloc is 0 (if it is, it failed).
        ; If it failed, it will get printed into the console.
        test rax, rax
        jz _o_malloc_failed

    .set_up_object:
        ; Use the first parameter and save it inot reserved space for player pointer.
        mov rcx, [rbp + 16]
        mov [rax + options.player_ptr], rcx

        ; Use the second parameter and save it inot reserved space for level.
        mov ecx, [rbp + 24]
        mov [rax + options.lvl], ecx

    .complete:
        ; Restore old stack frame and return from constructor.
        ; Return pointer to options object in RAX.
        mov rsp, rbp
        pop rbp
        ret


options_destroy:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .destroy_object:
        ; Expect pointer to options object in RCX
        call free

    .complete:
        ; Restore old stack frame and return from destructor.
        mov rsp, rbp
        pop rbp
        ret


;;;;;; DEBUGGING ;;;;;;
_o_malloc_failed:
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
        ; Restore old stack frame and leave debugging function.
        mov rsp, rbp
        pop rbp
        ret