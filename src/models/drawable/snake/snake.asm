; Constants:
%include "./include/data/snake/snake_constants.inc"
%include "./include/data/snake/unit/unit_constants.inc"

; Strucs:
%include "./include/strucs/interface_table_struc.inc"
%include "./include/strucs/position_struc.inc"
%include "./include/strucs/snake/snake_struc.inc"
%include "./include/strucs/snake/unit_struc.inc"

; This is the snake object the player is maneuvering in the board.
; It is the primary instance of the game.
; It is not moving by itself, since the game logic manages the update of each units position, depending on the direction of each unit.
; The board then draws the snake.
; The snake itself is managing the addition of a new unit after consuming a food object. That's why I decided to let the snake know, which unit its head is and which unit its tail is. So adding a unit just means: Make new unit the snakes tail, and let the old tail point to the new unit.
; The snake as whole has no direction, since every unit has it's own direction. I am passing down the direction each update through the units in the list. 
; The length of the snake is then used to check, if the player finished the game: If length of snake = board.width * board.height, player gets 100 bonus points.

global snake_static_vtable

section .rodata
    ;;;;;; DEBUGGING ;;;;;;
    constructor_name db "snake_new", 0

    ;;;;;; VTABLES ;;;;;;
    snake_static_vtable:
        dq snake_new

    snake_methods_vtable:
        dq snake_reset
        dq snake_add_unit

section .bss
    ; Memory space for the created snake pointer.
    ; Since there is always just one snake on the board, I decided to create a kind of a singleton.
    ; If this lcl_snake_ptr is 0, the constructor will create a new snake object.
    ; If it is not 0, it simply is going to return this pointer.
    ; This pointer is also used, to reference the object in the destructor and other functions.
    ; So it is not needed to pass a pointer to the object itself as function parameter.
    lcl_snake_ptr resq 1

section .text
    extern malloc, free

    extern unit_static_vtable

    extern malloc_failed, object_not_created


;;;;;; PUBLIC METHODS ;;;;;;

; The constructor for the snake object.
; It handles the creation of a new snake object.
; It needs to know the X- and Y- coordinates, the first unit of the snake is initially located on the board.
; The Y-Coordinate is stored in the lower 16 bits of ECX (EX).
; The X-Coordinate is stored in the higher 16 bits of ECX.
; It also needs to know, which direction the first unit will move at start.
snake_new:
    ; * Expect X- and Y-Coordinates in ECX.
    ; * Expect direction in DL.
    .set_up:
        ; Set up  stack frame:
        ; * 16 bytes for local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 16


        ; Check if snake already is created. If it is, return the pointer to the created snake.
        cmp qword [rel lcl_snake_ptr], 0
        jne .complete

        ; Save non-volatile regs.
        ; First local variable.
        mov [rbp - 8], r12

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

    .create_dependend_objects:
        ; ECX already contains the position.
        ; DL already contains the direction.
        ; Set R8 to 1, so the unit knows it is the head.
        mov r8, 1
        lea r10, [rel unit_static_vtable]
        call [r10 + UNIT_STATIC_CONSTRUCTOR_OFFSET]
        ; Second local variable: 
        ; * Unit pointer.
        mov qword [rbp - 16], rax

    .create_object:
        ; Creating the snake itself, containing space for:
        ; * - Methods vtable pointer. (8 bytes)
        ; * - Length of snake. (8 bytes)
        ; * - A pointer to the head unit. (8 bytes)
        ; * - A pointer to the tail unit. (8 bytes)
        mov rcx, snake_size
        call malloc
        ; Pointer to snake object is stored in RAX now.
        ; Check if return of malloc is 0 (if it is, it failed).
        ; If it failed, it will get printed into the console.
        test rax, rax
        jz _s_malloc_failed

        ; Save pointer to initially reserved space. Object is "officially" created now.
        mov [rel lcl_snake_ptr], rax

    .set_up_object:
        ; Load unit pointer into RCX.
        mov rcx, [rbp - 16]
        ; Save it as head and tail now, since the unit just created is the first of the snake.
        mov [rax + snake.head_ptr], rcx
        mov [rax + snake.tail_ptr], rcx

        ; Save vtable into its preserved memory space.
        lea rcx, [rel snake_methods_vtable]
        mov [rax + snake.methods_vtable_ptr], rcx

        ; Initial snake length is one.
        mov qword [rax + snake.length], 1

    .set_up_list:
        ; Use the R12 register as counter for the loop:
        ; It is initialized as STARTING_LENGTH - 1, because one unit already was created.
        mov r12, STARTING_LENGTH - 1

    .loop:
        ; Check if 0 is reached. If it is, the creation is completed.
        test r12, r12
        jz .complete

        ; If 0 is not yet reached, add a new unit to the snake.
        call snake_add_unit

        ; Decrement the counter by one and loop again.
        dec r12
        jmp .loop

    .complete:
        ; Restore non-volatile regs.
        mov r12, [rbp - 8]

        ; Use the pointer to the snake object as return value of this constructor.
        mov rax, qword [rel lcl_snake_ptr]

        ; Restore the old stack frame and leave the constructor.
        mov rsp, rbp
        pop rbp
        ret

; This function cascades down the unit objects and releases their memory spaces. Afterwards it destroys itself.It is used by the board to reset itself.
snake_reset:
    .set_up:
        ; Set up stack frame:
        ; * 16 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; If snake is not created, let the user know.
        cmp qword [rel lcl_snake_ptr], 0
        je _s_object_failed

        ; Save non-volatile regs.
        mov [rbp - 8], rbx

        ; Reserve 32 bytes shadow space for called functions. 
        sub rsp, 32

        ; Using the tail pointer as termination signal.
        mov rbx, [rel lcl_snake_ptr]
        mov rcx, [rbx + snake.tail_ptr]
        ; Second local variable:
        ; * Tail pointer.
        mov [rbp - 16], rcx

    .destroy_list:
        ; Using head pointer as starting point of the freeing process.
        mov rbx, [rbx + snake.head_ptr]

    .loop:
        ; Destroy unit by unit.
        mov rcx, rbx
        mov rbx, [rbx + unit.next_unit_ptr]
        mov r10, [rcx + unit.methods_vtable_ptr]
        call [r10 + UNIT_METHODS_DESTRUCTOR_OFFSET]

    .loop_handle:
        ; Check if unit is tail. If it is, the process is done.
        cmp rbx, [rbp - 16]
        je .complete

        jmp .loop

    .complete:
        ; All units are released. Release snake itself now.
        call _snake_destroy

        ; Restore non-volatile regs.
        mov rbx, [rbp - 8]

        ; Restore old stack frame and leave destructor.
        mov rsp, rbp
        pop rbp
        ret

; The function which handles the addition of a new unit into the linked list. 
snake_add_unit:
    .set_up:
        ; Set up stack frame:
        ; * 32 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 32

        ; If snake is not created, let the user know.
        cmp qword [rel lcl_snake_ptr], 0
        je _s_object_failed

        ; Save non-volatile regs.
        mov [rbp - 8], rbx
        mov [rbp - 16], r12

        ; Set the tail pointer of the snake as base for this function.
        mov rbx, [rel lcl_snake_ptr]
        mov r12, [rbx + snake.tail_ptr]

        ; Get position of active tail.
        mov rcx, [r12 + unit.position_ptr]

        movzx rax, word [rcx + position.x]
        ; Second local variable:
        ; * X-Position of tail.
        mov [rbp - 24], ax

        mov ax, [rcx + position.y]
        ; Third local variable:
        ; * Y-Position of tail.
        mov [rbp - 32], ax

    ; At this point, I am setting up to the position of the new unit.
    ; The .position_table works as reference table for the calculation of the new position. It is accessed by index and leads to the suiting label, handling the position of the new unit.
    .set_up_position:
        movzx rdx, byte [r12 + unit.direction]
        lea r8, [rel .position_table]
        mov r8, [r8 + rdx * 8]
        jmp r8

    .position_table:
        dq ._left
        dq ._up
        dq ._right
        dq ._down

    ; Depending on the moving direction of the tail, the new unit must be placed on the right spot. For example, if the tail is moving downwards, the new unit is placed Y+1, since it needs to be one on top of the old tail.
    ._left:
        inc word [rbp - 24]
        jmp .create_unit
    ._up:
        inc word [rbp - 32]
        jmp .create_unit
    ._right:
        dec word [rbp - 24]
        jmp .create_unit
    ._down:
        dec word [rbp - 32]

    ; Now the position is set up and can be used to create the new unit.
    .create_unit:
        ; ECX will contain the coordinates for the position.
        movzx rcx, word [rbp - 24]
        shl rcx, 16
        mov cx, [rbp - 32]
        ; DL already containts the direction from above (new unit must have the same direction as old tail had).
        ; R8 is 0, because the new unit is definitely not the head.
        xor r8, r8
        lea r10, [rel unit_static_vtable]
        call [r10 + UNIT_STATIC_CONSTRUCTOR_OFFSET]
        ; Since I don't need the saved position anymore, I replace the old third local variable with the unit pointer.
        mov [rbp - 32], rax

    .add_unit_to_list:
        ; R12 is the unit object, which was the tail of the snake before. This tail unit now needs to point to the unit just created as next_unit.
        mov [r12 + unit.next_unit_ptr], rax

        ; RBX still holds the snake object as whole. The newly created object is the snakes tail now.
        mov [rbx + snake.tail_ptr], rax

        ; Length of snake grew by one.
        inc qword [rbx + snake.length]

    .complete:
        ; Restore non-volatile regs.
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret




;;;;;; PRIVATE METHODS ;;;;;;
_snake_destroy:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

        ; If unit is not created yet, print a debug message.
        cmp qword [rel lcl_snake_ptr], 0
        je _s_object_failed

    .destroy_object:
        ; Use the local lcl_snake_ptr to free the memory space and set it back to 0.
        mov rcx, [rel lcl_snake_ptr]
        call free
        mov qword [rel lcl_snake_ptr], 0

    .complete:
        ; Restore old stack frame and leave the destructor.
        mov rsp, rbp
        pop rbp
        ret




;;;;;; ERROR HANDLING ;;;;;;

_s_malloc_failed:
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

_s_object_failed:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .debug:
        lea rcx, [rel constructor_name]
        call object_not_created

    .complete:
        ; Restore old stack frame and leave debugging function.
        mov rsp, rbp
        pop rbp
        ret