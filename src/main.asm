section .text
    global main
    extern game_new

main:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    call game_new

    mov rsp, rbp
    pop rbp
    ret