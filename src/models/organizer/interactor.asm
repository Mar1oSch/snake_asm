%include "../include/organizer/interactor_struc.inc"
%include "../include/organizer/file_manager_struc.inc"

global interactor_new, interactor_setup, interactor_destroy

section .rodata
;;;;;; INTRODUCTION ;;;;;;
introduction:
    .string1 db "Hello, fellow friend! Welcome to your snake adventure."
    .new_line1 db 13, 10
    .string2 db "Is this the first time you are entering this dangerous territory?"
    .new_line2 db 13, 10
    .new_line3 db 13, 10
    .string3 db "[Y]es / [N]o"
introduction_end:
introduction_size equ introduction_end - introduction

intro_table:
    dq introduction.string1, (introduction.new_line1 - introduction.string1)       ; pointer + length (auto calc)
    dq introduction.new_line1, (introduction.string2 - introduction.new_line1)
    dq introduction.string2, (introduction.new_line2 - introduction.string2)
    dq introduction.new_line2, (introduction.new_line3 - introduction.new_line1)
    dq introduction.new_line3, (introduction.string3 - introduction.new_line3)
    dq introduction.string3, (introduction_end - introduction.string3)
intro_table_end:
intro_table_size equ intro_table_end - intro_table

section .bss
    INTERACTOR_PTR resq 1

section .text
    extern malloc
    extern free
    extern printf
    extern Sleep

    extern designer_new, designer_start_screen, designer_clear, designer_type_sequence
    extern file_manager_new

interactor_new:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel INTERACTOR_PTR], 0
    jne .complete

    ; Save non-volatile regs.
    mov [rbp - 8], r15

    mov rcx, interactor_size
    call malloc
    mov [rel INTERACTOR_PTR], rax

    call designer_new
    mov r15, [rel INTERACTOR_PTR]
    mov [r15 + interactor.designer_ptr], rax

    call file_manager_new
    mov [r15 + interactor.file_manager_ptr], rax

.complete:
    mov rax, [rel INTERACTOR_PTR]
    mov rsp, rbp
    pop rbp
    ret

interactor_destroy:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov rcx, [rel INTERACTOR_PTR]
    call free

    mov rsp, rbp
    pop rbp
    ret

interactor_setup:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call designer_start_screen
    mov rcx, 1000
    call Sleep
    call designer_clear
    call _introduction

    mov rsp, rbp
    pop rbp
    ret



;;;;;; PRIVATE FUNCTIONS ;;;;;;
_introduction:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    lea rcx, [rel intro_table]
    mov rcx, [rcx]
    mov rdx, intro_table_size
    call designer_type_sequence

    mov rsp, rbp
    pop rbp
    ret