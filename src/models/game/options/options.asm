; Strucs:
%include "./include/strucs/game/options_struc.inc"

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
        ; Set up stack frame:
        ; * 8 bytes local variables.
        ; * 8 bytes to keep stack 16-byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 16

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
        ; * First local variable: options pointer.
        mov [rbp - 8], rax

    .set_up_object:
        ; Use the first parameter and save it into reserved space for player pointer.
        mov rcx, [rbp + 16]
        mov [rax + options.player_ptr], rcx

        ; Use the second parameter and save it into reserved space for level.
        mov ecx, [rbp + 24]
        mov [rax + options.lvl], ecx

        ; Get delay and save it into reserved space for delay.
        call _get_delay
        mov rcx, [rbp - 8]
        mov [rcx + options.delay], ax

    .complete:
        ; Return pointer to options object in RAX.
        mov rax, rcx

        ; Restore old stack frame and return from constructor.
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
        ; * Expectpointer to options object in RCX
        call free

    .complete:
        ; Restore old stack frame and return from destructor.
        mov rsp, rbp
        pop rbp
        ret




;;;;;; PRIVATE METHODS ;;;;;;
_get_delay:
    ; * Expect level in ECX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If ecx is above 9 or below 1 it is invalid.
        cmp ecx, 1
        jb .invalid
        cmp ecx, 9
        ja .invalid

        ; Setting up table and jmp to desired address.
        lea rdx, [rel .delay_table]
        dec rcx
        mov rax, [rdx + rcx*8]
        jmp rax

    ; Get the delay by level.
    .invalid:
        mov ax, 270
        jmp .complete

    .delay_table:
        dq .first_level
        dq .second_level
        dq .third_level
        dq .fourth_level
        dq .fifth_level
        dq .sixth_level
        dq .seventh_level
        dq .eighth_level
        dq .nineth_level

    .first_level:  
        mov ax, 270
        jmp .complete
    .second_level: 
        mov ax, 240
        jmp .complete
    .third_level:  
        mov ax, 210
        jmp .complete
    .fourth_level: 
        mov ax, 180
        jmp .complete
    .fifth_level:  
        mov ax, 150
        jmp .complete
    .sixth_level:  
        mov ax, 120
        jmp .complete
    .seventh_level:
        mov ax, 90
        jmp .complete
    .eighth_level: 
        mov ax, 60
        jmp .complete
    .nineth_level: 
        mov ax, 30

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

;;;;;; DEBUGGING ;;;;;;
_o_malloc_failed:
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