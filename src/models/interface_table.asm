%include "./include/strucs/interface_table_struc.inc"

; The object for each class participating in an interface. It is referencing all the different interfaces (Actually.. in this case just one).
; The idea behind it was, to say: Alright. I have classes which are participating in more interfaces. Some are participating in less interfaces. And all are participating in different ones.
; So every class has a interface_vtable attribute, keepint an pointer to its own table, where it either has a pointer to a specific interface table (like the DRAWABLE), or a 0.
; From there I can navigate further to the specific interface methods.

global interface_table_static_vtable

section .rodata
    ;;;;;; DEBUGGING ;;;;;;
    constructor_name db "interface_table_new", 0

    ;;;;;; VTABLES ;;;;;;
    interface_table_static_vtable:
        dq interface_table_new

    interface_table_methods_vtable:
        dq interface_table_destroy

section .text
    extern malloc, free

    extern malloc_failed

;;;;;; PUBLIC METHODS ;;;;;;

; In the very beginning I wanted to have a food interface as well, since I thought: Let's have two different kinds of food, but both are handled the same, just different points.
; I decided against it, so that interface table is a bit useless. But still here. Maybe for reasons of expansion.
interface_table_new:
    ; * Expect pointer to vtable_drawable in RCX (0 if there is none).
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Save params into shadow space.
        mov [rbp + 16], rcx

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .create_object:
        ; Creating the interface_table, containing space for:
        ; * - DRAWABLE interface pointer (8 bytes).
        mov rcx, interface_table_size
        call malloc
        ; Pointer to interface_table object is stored in RAX now.
        ; Check if return of malloc is 0 (if it is, it failed).
        ; If it failed, it will get printed into the console.
        test rax, rax
        jz _it_malloc_failed

    .set_up_object:
        lea rcx, [rel interface_table_methods_vtable]
        mov [rax + interface_table.methods_vtable_ptr], rcx

        mov rcx, [rbp + 16]
        mov [rax + interface_table.vtable_drawable_ptr], rcx

    .complete:
        ; Return pointer to interface table in RAX.

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret


interface_table_destroy:
    ; * Expect pointer to interface table object in RCX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .destroy_object:
        call free

    .complete:
        ; Restore old stack frame and leave the destructor.
        mov rsp, rbp
        pop rbp
        ret


;;;;;; ERROR HANDLING ;;;;;;
_it_malloc_failed:
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