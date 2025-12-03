global object_not_created

section .rodata
    error_message db "The object you wanted to access was not created yet. Please call %s first."

section .text
    extern printf

object_not_created:
    ; * Expectpointer to constructor_name in RCX.
    push rbp
    mov rbp, rsp
    sub rsp, 40

    mov [rbp - 8], rcx
    lea rcx, [rel error_message]
    mov rdx, [rbp - 8]
    call printf

    mov rsp, rbp
    pop rbp
    ret