section .data
    hello db "Worked! Pointer: %p", 13, 10, 0
    position db "Lets see where we are: cx: %d, dx: %d.", 13, 10, 0
section .text
    global main
    extern position_new
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 48

    mov cx, 12
    mov dx, 5
    call position_new
    mov rax, [rbp - 8]
    lea rcx, [rel hello]
    mov rdx, rax
    call printf

    lea rcx, [rel position]
    mov rax, [rbp - 8]
    mov rdx, [rax]
    mov r8, [rax + 2]
    call printf

    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret