section .text
    global main
    extern board_new, board_setup, board_draw_content
    extern printf

main:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    xor rcx, rcx
    mov cx, 100                 ; Moving width into CX  (So: ECX = 0, width)
    shl rcx, 16                 ; Shifting rcx 16 bits left (So : ECX = width, 0)
    mov cx, 20                  ; Moving height into CX (So: ECX = width, height)
    call board_new

    call board_setup

    call board_draw_content

    mov rax, 0
    mov rsp, rbp
    pop rbp
    ret