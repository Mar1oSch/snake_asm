; Strucs:
%include "../include/strucs/interface_table_struc.inc"
%include "../include/strucs/position_struc.inc"
%include "../include/strucs/game/board_struc.inc"
%include "../include/strucs/food/food_struc.inc"
%include "../include/strucs/snake/snake_struc.inc"
%include "../include/strucs/snake/unit_struc.inc"

; The board is both: active and passive. 
; Active in case of drawing the content: Drawing food, creating new food and position it inside the board, drawing the snake.
; Passive in that way, that it is getting told by the game, when it should draw the snake, when it should create new food, when the old food gets destroyed and so on.

global board_new, board_setup, board_move_snake, board_create_new_food, board_draw_food, board_reset, get_board_x_offset, get_board_y_offset

;;;;;; CONSTANTS ;;;;;;
STARTING_DIRECTION equ 2

section .rodata
    fence_char db "#"

    ;;;;;; DEBUGGING ;;;;;;
    constructor_name db "board_new", 0

section .data
    ; FILETIME structure to capture information from "GetSystemTimeAsFileTime", which collects the system time as nano seconds and saves it into the structure.
    ; I use it to create pseudoe random positions for the food creation.
    filetime_struct dd 0, 0

section .bss
    ; Memory space for the created board pointer.
    ; Since there is always just one board in the game, I decided to create a kind of a singleton.
    ; If this lcl_board_ptr is 0, the constructor will create a new board object.
    ; If it is not 0, it simply is going to return this pointer.
    ; This pointer is also used, to reference the object in the destructor and other functions.
    ; So it is not needed to pass a pointer to the object itself as function parameter.
    lcl_board_ptr resq 1

section .text
    extern malloc, free
    extern Sleep
    extern GetSystemTimeAsFileTime

    extern snake_new, snake_update, snake_get_tail_position, snake_reset
    extern console_manager_write_char, console_manager_set_cursor_to_end, console_manager_erase, console_manager_get_height_to_center_offset, console_manager_get_width_to_center_offset
    extern food_new, food_destroy
    extern designer_clear

    extern malloc_failed, object_not_created
    extern DRAWABLE_VTABLE_X_POSITION_OFFSET, DRAWABLE_VTABLE_Y_POSITION_OFFSET, DRAWABLE_VTABLE_CHAR_PTR_OFFSET

;;;;;; PUBLIC METHODS ;;;;;;

; The constructor of the board. It needs to know the width and height the game wants it to be (I wanted the user to be able to create a personalized board by input, but I decided to stay with the default size. That's why I wanted the board to get its width and height from outside itself) and it needs a pointer to the console manager object. 
board_new:
    .set_up:
        ; Set up stack frame:
        ; 8 bytes local variables.
        ; 8 bytes to keep stack 16 byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; Check if a board already exists. If yes, return the pointer to it.
        cmp qword [rel lcl_board_ptr], 0
        jne .complete

        ; Save non volatile regs.
        mov [rbp - 8], rbx

        ; Expect width and height in ECX
        ; Expect pointer to console_manager in RDX
        mov [rbp + 16], ecx
        mov [rbp + 24], rdx

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .create_object:
        ; Creating the board, containing space for:
        ; * - Snake pointer. (8 bytes)
        ; * - Food pointer. (8 bytes)
        ; * - Console manager pointer. (8 bytes)
        ; * - Width. (2 bytes)
        ; * - Height. (2 bytes)
        mov cx, board_size
        call malloc
        ; Pointer to board object is stored in RAX now.
        ; Check if return of malloc is 0 (if it is, it failed).
        ; If it failed, it will get printed into the console.
        test rax, rax
        jz _b_malloc_failed

        ; Save pointer to initially reserved space. Object is "officially" created now.
        mov [rel lcl_board_ptr], rax

        ; Make RBX containing lcl_board_ptr to set object up.
        mov rbx, rax

    .set_up_object:
        ; Use the second parameter and save the console manager pointer into the preserved memory space.
        mov rcx, [rbp + 24]
        mov [rbx + board.console_manager_ptr], rcx

        ; Use the first parameter to define size of created board.
        mov ecx, [rbp + 16]
        mov [rbx + board.height], cx
        add word [rbx + board.height], 2
        ror ecx, 16
        mov [rbx + board.width], cx
        add word [rbx + board.width], 2

    .create_snake:
        ; Create snake and let its head start in the center of the board.
        ; CX already contains the board.width from above.
        shr cx, 1                           ; Bit shift one to the right: Div CX, 2
        rol ecx, 16                         ; Move the vale 16 bits to the left, to put them into the upper part of ECX and
                                            ; make space in CX.
        ; Now CX contains the board.height from above.
        shr cx, 1                           ; Bit shift one to the right: Div CX, 2
        mov dl, STARTING_DIRECTION
        call snake_new
        ; Make created snake belong to the board.
        mov [rbx + board.snake_ptr], rax

    .create_food:
        ; Create the first food on the board and store it in the bottom left quarter of the board.
        mov cx, [rbx + board.width]
        shr cx, 2                           ; Bit shift two to the right: Div CX, 4
        shl ecx, 16
        mov cx, [rbx + board.height]
        shr cx, 2                           ; Bit shift one to the right: Div CX, 2
        call food_new
        ; Make created food belong to the board.
        mov [rbx + board.food_ptr], rax

    .complete:
        ; Restore non volatile regs.
        mov rbx, [rbp - 8]

        ; Use the pointer to the board object as return value of this constructor.
        mov rax, qword [rel lcl_board_ptr]

        ; Restore the old stack frame and leave the constructor.
        mov rsp, rbp
        pop rbp
        ret

; This is some kind of a wrapper function, which is responsible for preparing the board for a new game.
board_setup:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

        ; If board is not created yet, print a debug message.
        cmp qword [rel lcl_board_ptr], 0
        je _b_object_failed

    .clear_screen:
        ; Let the designer clear the console screen.
        call designer_clear

    .draw_board:
        ; Calling all three draw functions to prepare the board:
        ; * - Draw the fence to mark the border of the board.
        ; * - Draw the snake by using the unit positions.
        ; * - Draw the initially created food using its position.
        call _draw_fence
        call _draw_food
        call _draw_snake

    .erase_first_tail:
        ; The first tail part has to get erased, since it would stay if the snake is moving.
        call _erase_last_snake_unit

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; The board is getting restarted here.
; It:
; * 1.) Saves the values which stay the same to hand it over to the new board.
; * 2.) Destroys all the objects belonging to itself.
; * 3.) Recreates itself.
board_reset:
    .set_up:
        ; Set up stack frame:
        ; 24 bytes for local variables.
        ; 8 bytes to keep the stack 16 byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 32

        ; If board is not created yet, print a debug message.
        cmp qword [rel lcl_board_ptr], 0
        je _b_object_failed

        ; Save non volatile regs.
        mov [rbp - 8], rbx

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

        ; Make RBX the base (containing lcl_board_ptr).
        mov rbx, [rel lcl_board_ptr]

    .save_solid_values:
        ; Prepare to save the width and height of board.
        ; ! Here is an annoying problem:
        ; ! I do have to sub 2 of width and height, because it is getting added in the constructor again. My consideration was: Initially I just have to pass the playable width and height. Then add two rows in the height for the fence and two columns in width for the fence. Here it would be nice (and also not as difficult - just annoying atm) to find a better solution: The fence should be drawn at width(-1 & width + 1) and height(-1 & height + 1). Also the collission check should be like that.
        ; TODO: Find better way to handle board borders.
        mov cx, [rbx + board.width]
        sub cx, 2
        shl ecx, 16
        mov cx, [rbx + board.height]
        sub cx, 2
        ; Second local variable:
        ; * Board dimensions
        mov [rbp - 16], ecx

        ; Save console manager pointer
        mov rdx, [rbx + board.console_manager_ptr]
        ; Third local variable:
        ; * Console manager pointer
        mov [rbp - 24], rdx

    .destroy_old_objects:
        ; At first: Get the pointer of the food still existing and destroy it.
        mov rcx, [rbx + board.food_ptr]
        call food_destroy
        ; Then: Make the snake destroy all its constituting objects.
        call snake_reset
        ; Finally destroy the board itself.
        call _board_destroy

    .create_new_board:
        ; Use former saved values to create the new board.
        mov ecx, [rbp - 16]
        mov rdx, [rbp - 24]
        call board_new

    .complete:
        ; Return pointer to the new board in RAX.
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; As soon as the game updated the snake depending on the game logic, it calls the board to mov the snake. Therefore the board needs to draw it and also erase the last unit, because it would just simply stay on the board and the snake would get longer and longer and longer (even without consuming food;). 
board_move_snake:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; If board is not created yet, print a debug message.
        cmp qword [rel lcl_board_ptr], 0
        je _b_object_failed

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .move_snake:
        ; Here the snake gets drawn, the last unit deleted and the console cursor gets moved to the end, because otherwise the snake would trail it the whole time.
        call _draw_snake
        call _erase_last_snake_unit
        call console_manager_set_cursor_to_end

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; As soon as the snake consumes a piece of food, the game calls the board to create new food. I decided to make it the boards responsibility to do so, because where it is placed should just belong to the board itself. The game manages the points mechanic and addition of new snake units if food is consumed.
board_create_new_food:
    .set_up:
        ; Set up stack frame:
        ; 16 bytes local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; If board is not created yet, print a debug message.
        cmp qword [rel lcl_board_ptr], 0
        je _b_object_failed

        ; Save non volatile regs.
        mov [rbp - 8], rbx

        ; Reserve 32 bytes shado space for function calls.
        sub rsp, 32

        ; Make RBX the base by using it as lcl_board_ptr.
        mov rbx, [rel lcl_board_ptr]

    .destroy_old_food:
        ; On the surface, the old food is consumed and erased. But the memory space is still reserved for it. Since the program won't ever use it again, it is now time to set it free. Therefore I load the pointer to the old food object, which is still saved in the board struc, into RCX and let it get set free.
        mov rcx, [rbx + board.food_ptr]
        call food_destroy

    .randomize_new_position_loop:
        ; Here a position object with randomized X- and Y-coordinates is created.
        call _create_random_position
        ; Second local variable:
        ; * Position pointer
        mov [rbp - 16], rax

        ; Check if food would be placed on the snake. If yes, loop again.
        ; ! Here I also would like to find a better solution. The bigger the snake gets and the less possible fields on the board are free, the chance to create a valid random position decreases a lot. There must be a better way. For example: create a list of possible positions and let the board randomly choose one. If the snake is updated, the position it moved to disapperas from the list, while the just freed position gets into the list again. 
        ; TODO: Find different randomization algorithm.
        mov rcx, rax
        call _control_food_and_snake_position
        test rax, rax
        jz .randomize_new_position_loop

    .create_new_food:
        ; Use the position to create the food object.
        mov rcx, [rbp - 16]
        call food_new

    .set_up_board:
        ; Make the board own the created food object.
        mov [rbx + board.food_ptr], rax

    .draw_food:
        ; finally: Make the food appear on the drawn board.
        call _draw_food

    .complete:
        ; Restore non volatile regs.
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; I wanted to place the board in the center of the console. That's why there is a getter for the starting X-Coordinate and a getter for the starting Y-Coordinate, to draw the board from there. 
get_board_x_offset:
    .set_up:
        ; Set up stack frame:
        ; 8 bytes for local variables.
        ; 8 bytes to keep stack 16 byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; Save non volatile regs.
        mov [rbp - 8], rbx

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .get_half_board_width:
        ; Loading the width of the board into BX and divide it by two.
        mov rbx, [rel lcl_board_ptr]
        mov bx,  [rbx + board.width]
        shr bx, 1
    
    .get_center_x_of_console:
        ; Get the central X-point of the console window.
        call console_manager_get_width_to_center_offset
    
    .calculate_final_offset:
        ; To get the starting X value of the board, we need to subtract the half width of the board from the central point. 
        sub ax, bx

    .complete:
        ; Restore non volatile regs.
        mov rbx, [rbp - 8]

        ; Return the value as quadword.
        movzx rax, ax

        mov rsp, rbp
        pop rbp
        ret

get_board_y_offset:
    .set_up:
        ; Set up stack frame:
        ; 8 bytes for local variables.
        ; 8 bytes to keep stack 16 byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; Save non volatile regs.
        mov [rbp - 8], rbx

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .get_half_board_height:
        ; Loading the height of the board into BX and divide it by two.
        mov rbx, [rel lcl_board_ptr]
        mov bx,  [rbx + board.height]
        shr bx, 1
    
    .get_center_y_of_console:
        ; Get the central Y-point of the console window.
        call console_manager_get_height_to_center_offset
    
    .calculate_final_offset:
        ; To get the starting Y value of the board, we need to subtract the half width of the board from the central point. 
        sub ax, bx

    .complete:
        ; Restore non volatile regs.
        mov rbx, [rbp - 8]

        ; Return the value as quadword.
        movzx rax, ax

        mov rsp, rbp
        pop rbp
        ret

; Simple wrapper function to keep the public space clear and small. The _draw_food function contains the more complicated 
board_draw_food:
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

    .draw:
        call _draw_food

    .complete:
        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret




;;;;;; PRIVATE METHODS ;;;;;;

; Private destructor. The board_reset method is the public method to handle the board release.
_board_destroy:
.set_up:
    ; Setting up the stack frame without local variables.
    push rbp
    mov rbp, rsp

    ; Reserve 32 bytes shadow space for called functions.
    sub rsp, 32

    ; If board is not created yet, print a debug message.
    cmp qword [rel lcl_board_ptr], 0
    je _b_object_failed

.destroy_object:
    ; Use the local lcl_board_ptr to free the memory space and set it back to 0.
    mov rcx, [rel lcl_board_ptr]
    call free
    mov qword [rel lcl_board_ptr], 0

.complete:
    ; Restore old stack frame and leave the destructor.
    mov rsp, rbp
    pop rbp
    ret

; The actual function to draw the snake on the board. It loops down from head to tail and uses the DRAWABLE getters to finally draw the snake on the board.
_draw_snake:
    .set_up:
        ; Set up stack frame:
        ; 40 bytes local variables.
        ; 8 bytes to keep stack 16 byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 48

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32
        
        ; If board is not created yet, print a debug message.
        cmp qword [rel lcl_board_ptr], 0
        je _b_object_failed

        ; Save non volatile regs.
        mov [rbp - 8], rbx
        mov [rbp - 16], r12
        mov [rbp - 24], r13
        mov [rbp - 32], r14
        mov [rbp - 40], r15

    .set_up_loop_base:
        ; I am setting up the base for the drawing loop:
        ; * - RBX is going to be the tail pointer. After every iteration, I will check, if the tail is reached.
        ; * - R12 is the active unit getting drawn.
        ; * - R13 will hold the X- and Y-positions of the DRAWABLE.
        ; * - R14 will hold the X- and Y-offsets of the board.
        ; * - R15 will hold the pointer to the DRAWABLE interface vtable.

        ; Setting up RBX as base. First it will store the snake pointer.
        mov rbx, [rel lcl_board_ptr]
        mov rbx, [rbx + board.snake_ptr]                          

        ; Load the first unit (snakes head) into R12.
        mov r12, [rbx + snake.head_ptr]

        ; Moving the last unit (snakes tail) into RBX now.
        mov rbx, [rbx + snake.tail_ptr]                           

        ; Saving the X- and Y-offsets into R14.
        ; R14D looks like that: 
        ; * [X-offset, Y-offset]
        call get_board_x_offset
        mov r14w, ax
        shl r14d, 16
        call get_board_y_offset
        mov r14w, ax

        ; R15 holds DRAWABLE interface vtable now.
        mov r15, [r12 + unit.interface_table_ptr]
        mov r15, [r15 + interface_table.vtable_drawable_ptr]

    .draw_snake_loop:
        .get_x:
            ; Getting the X-position of the DRAWABLE, add the X-offset and move it into R13W.
            mov rcx, r12                                           
            call [r15 + DRAWABLE_VTABLE_X_POSITION_OFFSET]
            ror r14d, 16
            add ax, r14w
            mov r13w, ax

        .get_y:
            ; Getting the Y-position of the DRAWABLE, add the Y-offset, and move it into R13W, after R13 has been shifted to the left 16 bits.
            mov rcx, r12                                            ; Move pointer to unit to RCX.
            call [r15 + DRAWABLE_VTABLE_Y_POSITION_OFFSET]
            rol r14d, 16
            add ax, r14w
            shl r13d, 16
            mov r13w, ax 
        
        .get_char:
            ; Now it's time to get the pointer to the character representing the DRAWABLE on the board. 
            mov rcx, r12                                           
            call [r15 + DRAWABLE_VTABLE_CHAR_PTR_OFFSET]

        .draw_char: 
            ; Finally the character is get drawn into the board.
            ; * - ECX holds the X- and Y-position.
            ; * - RDX holds the pointer to the char.
            mov ecx, r13d                                    
            mov rdx, rax  
            call console_manager_write_char
        
    .draw_snake_loop_handle:
        ; At first it gets checked, if R12 ist the tail now.
        ; If it is, the function is done.
        ; If not, R12 is the next unit in the list now and the next iteration starts.
        cmp r12, rbx
        je .complete
        mov r12, [r12 + unit.next_unit_ptr]
        jmp .draw_snake_loop

    .complete:
        ; Restore non volateile regs.
        mov r15, [rbp - 40]
        mov r14, [rbp - 32]
        mov r13, [rbp - 24]
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

_draw_fence:
    push rbp
    mov rbp, rsp
    sub rsp, 104

    cmp qword [rel lcl_board_ptr], 0
    je _b_object_failed

    mov r8, [rel lcl_board_ptr]
    mov cx, [r8 + board.width]
    mov [rbp - 8], cx                     
    mov cx, [r8 + board.height]                  ; Save height.
    mov [rbp - 16], cx    

    call get_board_x_offset
    mov [rbp - 24], ax
    call get_board_y_offset
    mov [rbp - 32], ax

    ; Save non-volatile regs.
    mov [rbp - 40], r15
    mov [rbp - 48], r14

    xor r15, r15        ; Zero Height counter
.loop:
    cmp r15, 0
    je .draw_whole_line
    cmp r15w, [rbp - 16]
    je .draw_whole_line

.draw_single_chars:
    mov cx, [rbp - 24]
    shl rcx, 16
    mov cx, r15w
    add cx, [rbp - 32]
    lea rdx, [rel fence_char] 
    call console_manager_write_char
    mov cx, word [rbp - 8]
    add cx, [rbp - 24]
    shl rcx, 16
    mov cx, r15w
    add cx, [rbp - 32]
    lea rdx, [rel fence_char] 
    call console_manager_write_char
    jmp .loop_handle

.draw_whole_line:
    xor r14, r14        ; Zero Width counter
    .inner_loop:
        mov cx, r14w
        add cx, [rbp - 24]
        shl rcx, 16
        mov cx, r15w
        add cx, [rbp - 32]
        lea rdx, [rel fence_char]
        call console_manager_write_char
    .inner_loop_handle:
        cmp r14w, [rbp - 8]
        je .loop_handle
        inc r14w
        jmp .inner_loop

.loop_handle:
    cmp r15w, word [rbp - 16]
    je .complete
    inc r15
    jmp .loop

.complete:
    mov [rbp - 48], r14
    mov [rbp - 40], r15
    mov rsp, rbp
    pop rbp
    ret

_draw_food:
    push rbp
    mov rbp, rsp
    sub rsp, 80

    cmp qword [rel lcl_board_ptr], 0
    je _b_object_failed

    mov rcx, [rel lcl_board_ptr]
    mov rcx, [rcx + board.food_ptr]
    mov [rbp - 8], rcx

    mov rdx, [rcx + food.interface_table_ptr]
    mov rdx, [rdx + interface_table.vtable_drawable_ptr]
    mov [rbp - 16], rdx

    call [rdx + DRAWABLE_VTABLE_X_POSITION_OFFSET]
    mov word [rbp - 24], ax
    call get_board_x_offset
    add word [rbp - 24], ax 

    mov rcx, [rbp - 8]
    mov rdx, [rbp - 16]
    call [rdx + DRAWABLE_VTABLE_Y_POSITION_OFFSET]
    mov word [rbp - 32], ax
    call get_board_y_offset
    add word [rbp - 32], ax

    mov rcx, [rbp - 8]
    mov rdx, [rbp - 16]
    call [rdx + DRAWABLE_VTABLE_CHAR_PTR_OFFSET]

    mov rdx, rax
    mov cx, word [rbp - 24]
    shl rcx, 16
    mov cx, word [rbp - 32]
    call console_manager_write_char

    mov rsp, rbp
    pop rbp
    ret

_erase_last_snake_unit:
    push rbp
    mov rbp, rsp
    sub rsp, 56

    cmp qword [rel lcl_board_ptr], 0
    je _b_object_failed

    call get_board_x_offset
    mov [rbp - 8], ax

    call get_board_y_offset
    mov [rbp - 16], ax

    call snake_get_tail_position
    mov ecx, eax
    ror ecx, 16
    add cx, [rbp - 8]
    rol ecx, 16
    add cx, [rbp - 16]
    mov rdx, 1
    call console_manager_erase

.complete:
    mov rsp, rbp
    pop rbp
    ret

_create_random_position:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    cmp qword [rel lcl_board_ptr], 0
    je _b_object_failed


    lea rcx, [rel filetime_struct]
    call GetSystemTimeAsFileTime

    xor rax, rax
    mov rax, [rel filetime_struct]
    ror rax, 32
    mov rcx, [rel lcl_board_ptr]

.calculate_x:
    movzx r8, word [rcx + board.width]
    xor rdx, rdx
    div r8

    cmp dx, 0
    je .increment_x
    cmp dx, word [rcx + board.width]
    je .decrement_x
    jmp .calculate_y
.increment_x:
    inc dx
    jmp .calculate_y
.decrement_x:
    dec dx

.calculate_y:
    mov word [rbp - 8], dx
    xor rax, rax
    mov rax, [rel filetime_struct]
    rol rax, 32
    movzx r8, word [rcx + board.height]
    xor rdx, rdx
    div r8

    cmp dx, 0
    je .increment_y
    cmp dx, word [rcx + board.height]
    je .decrement_y
    jmp .complete
.increment_y:
    inc dx
    jmp .complete
.decrement_y:
    dec dx

.complete:
    mov word [rbp - 16], dx

    movzx rax, word [rbp - 8]
    shl rax, 16
    mov ax, word [rbp - 16]

    mov rsp, rbp
    pop rbp
    ret

_control_food_and_snake_position:
    push rbp
    mov rbp, rsp
    sub rsp, 40

    ; Expect X- and Y-Coordinates in ECX.
    mov [rbp - 8], cx               ; Save Y-Coordinates
    shr rcx, 16
    mov [rbp - 16], cx              ; Save X-Coordinates

    cmp qword [rel lcl_board_ptr], 0
    je _b_object_failed

    mov rcx, [rel lcl_board_ptr]
    mov rcx, [rcx + board.snake_ptr]
    mov r8, [rcx + snake.tail_ptr]
    mov [rbp - 24], r8
    mov r8, [rcx + snake.head_ptr]

.loop:
    mov r9, [r8 + unit.position_ptr]
    mov r10w, word [r9 + position.x]
    cmp r10w, word [rbp - 16]
    jne .loop_handle
    mov r10w, word [r9 + position.y]
    cmp r10w, word [rbp - 8]
    je .failed
.loop_handle:
    cmp r8, [rbp - 24]
    je .worked
    mov r8, [r8 + unit.next_unit_ptr]
    jmp .loop

.failed:
    mov rax, 0
    jmp .complete

.worked:
    mov rax, 1

.complete:
    mov rsp, rbp
    pop rbp
    ret




;;;;;; ERROR HANDLING ;;;;;;

_b_object_failed:
    lea rcx, [rel constructor_name]
    call object_not_created

    mov rsp, rbp
    pop rbp
    ret

_b_malloc_failed:
    lea rcx, [rel constructor_name]
    mov rdx, rax
    call malloc_failed

    mov rsp, rbp
    pop rbp
    ret