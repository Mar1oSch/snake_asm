section .text
    global main
    extern console_manager_new
    extern game_new, game_setup, game_start
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    xor rcx, rcx
    mov cx, 20                  ; Moving width into CX  (So: ECX = 0, width)
    shl rcx, 16                 ; Shifting rcx 16 bits left (So : ECX = width, 0)
    mov cx, 11                  ; Moving height into CX (So: ECX = width, height)
    mov dl, 8
    call game_new

    call game_setup

    call game_start
    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret