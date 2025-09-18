section .data

section .text
    global main
    extern constructor_test
main:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    call constructor_test

    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret