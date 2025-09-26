section .text
    global main
    extern game_new, game_setup
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    xor rcx, rcx
    mov cx, 20                  ; Moving width into CX  (So: ECX = 0, width)
    shl rcx, 16                 ; Shifting rcx 16 bits left (So : ECX = width, 0)
    mov cx, 11                  ; Moving height into CX (So: ECX = width, height)
    call game_new

    call game_setup

    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret