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
    lcl_filetime_struc dd 0, 0

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

    extern snake_new, snake_update, snake_reset
    extern console_manager_write_char,  console_manager_erase, console_manager_repeat_char, console_manager_get_height_to_center_offset, console_manager_get_width_to_center_offset
    extern food_new, food_destroy
    extern designer_clear
    extern DRAWABLE_VTABLE_X_POSITION_OFFSET, DRAWABLE_VTABLE_Y_POSITION_OFFSET, DRAWABLE_VTABLE_CHAR_PTR_OFFSET

    extern malloc_failed, object_not_created

;;;;;; PUBLIC METHODS ;;;;;;

; The constructor of the board. It needs to know the width and height the game wants it to be (I wanted the user to be able to create a personalized board by input, but I decided to stay with the default size. That's why I wanted the board to get its width and height from outside itself) and it needs a pointer to the console manager object. 
board_new:
    ; * 1. param: Expect width and height in ECX. [width, height]
    ; * 2. param: Expect pointer to console_manager in RDX.
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

        ; Save params into shadow space.
        mov [rbp + 16], ecx
        mov [rbp + 24], rdx

        ; Save non-volatile regs.
        mov [rbp - 8], rbx

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
        ror ecx, 16
        mov [rbx + board.width], cx

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
        ; Restore non-volatile regs.
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

        ; Save non-volatile regs.
        mov [rbp - 8], rbx

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32

        ; Make RBX the base (containing lcl_board_ptr).
        mov rbx, [rel lcl_board_ptr]

    .save_solid_values:
        ; Prepare to save the width and height of board.
        mov cx, [rbx + board.width]
        shl ecx, 16
        mov cx, [rbx + board.height]
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
    ; * 1. param: Expect X- and Y-coordinates of old tail in ECX.
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
        ; Tell the eraser, which position the old tail was and let it do its job.
        call _erase_snake_unit

        ; Here the snake gets drawn, the last unit deleted and the console cursor gets moved to the end, because otherwise the snake would trail it the whole time.
        call _draw_snake


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

        ; Save non-volatile regs.
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
        ; * Position
        mov [rbp - 16], eax

        ; Check if food would be placed on the snake. If yes, loop again.
        ; ! Here I would like to find a better solution. The bigger the snake gets and the less possible fields on the board are free, the chance to create a valid random position decreases a lot. There must be a better way. For example: create a list of possible positions and let the board randomly choose one. If the snake is updated, the position it moved to disapperas from the list, while the just freed position gets into the list again. 
        ; TODO: Find different randomization algorithm.
        mov ecx, eax
        call _is_food_position_free
        test rax, rax
        jz .randomize_new_position_loop

    .create_new_food:
        ; Use the position to create the food object.
        mov ecx, [rbp - 16]
        call food_new

    .set_up_board:
        ; Make the board own the created food object.
        mov [rbx + board.food_ptr], rax

    .draw_food:
        ; finally: Make the food appear on the drawn board.
        call _draw_food

    .complete:
        ; Restore non-volatile regs.
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

        ; Save non-volatile regs.
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
        ; Restore non-volatile regs.
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

        ; Save non-volatile regs.
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
        ; Restore non-volatile regs.
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



;;;;;; DRAWING METHODS ;;;;;;

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

        ; Save non-volatile regs.
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

    .draw_loop:
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
        
    .draw_loop_handle:
        ; At first it gets checked, if R12 ist the tail now.
        ; If it is, the function is done.
        ; If not, R12 is the next unit in the list now and the next iteration starts.
        cmp r12, rbx
        je .complete
        mov r12, [r12 + unit.next_unit_ptr]
        jmp .draw_loop

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

; Drawing the border of the board. The function loops through the Y-axis of the board. Before it starts with Y = 0, it draws the top fence at board.y - 1. As soon as the Y-counter exceeds the board.height, it draws the bottom fence.
_draw_fence:
    .set_up:
        ; Setting up stack frame:
        ; 24 bytes local variables.
        ; 8 bytes to keep stack 16 byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 32

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32
        
        ; If board is not created yet, print a debug message.
        cmp qword [rel lcl_board_ptr], 0
        je _b_object_failed

        ; Save non-volatile regs.
        mov [rbp - 8], rbx
        mov [rbp - 16], r12
        mov [rbp - 24], r13

    .set_up_loop_base:
        ; I am setting up the base for the drawing loop:
        ; * - EBX will hold the width and the height of the board [width, height].
        ; * - R12 will be the height counter for the loop [X-offset, Y-offset].
        ; * - R13 will hold the X- and Y-offsets of the board.
        mov rcx, [rel lcl_board_ptr]
        ; Setting up EBX containing the width and height of board.
        mov bx, [rcx + board.width]
        shl ebx, 16                   
        mov bx, [rcx + board.height]                  ; Save height.   

        ; Setting up R13D containing X- and Y-offsets. 
        call get_board_x_offset
        mov r13w, ax
        shl r13d, 16
        call get_board_y_offset
        mov r13w, ax

        ; Set height counter to 0.
        xor r12w, r12w

    .draw_top_fence:
        ; The Fence at board(Y - 1).
        ; Setting up the params for "console_manager_repeat_char":
        ; * - CL contains the char to repeat.
        mov cl, [rel fence_char]

        ; * - EDX contains the number of repetitions.
        ror ebx, 16
        movzx edx, bx
        add edx, 3
        rol ebx, 16

        ; * - R8D contains the starting coordinates. (In this case: [board.width_offset - 1, board.height_offset - 1])
        ror r13d, 16
        mov r8w, r13w
        dec r8w
        shl r8d, 16
        rol r13d, 16
        mov r8w, r13w
        dec r8w
        call console_manager_repeat_char

    .draw_side_fence_loop:
        ; Preparing coordinates of the left fence piece. 
        ; The X-coordinate is board.x-offset - 1
        ror r13d, 16
        mov cx, r13w
        dec cx

        ; Now the Y-coordinate is board.y-offset + R12W.
        shl ecx, 16
        rol r13d, 16
        mov cx, r13w
        add cx, r12w

        ; Finally the pointer to the fence char get's loaded into RDX.
        ; Parameters are set up.
        lea rdx, [rel fence_char] 
        call console_manager_write_char

        ; Preparing coordinates of the right fence piece.
        ; The X-coordinate is board.x-offset + board.width + 1
        ror r13d, 16
        mov cx, r13w
        ror ebx, 16
        add cx, bx
        inc cx

        ; The Y- coordinate is board.y-offset + R12W
        shl ecx, 16
        rol r13d, 16
        mov cx, r13w
        add cx, r12w

        ; Loading again the pointer to the fence char into RDX.
        ; Parameters are set up.
        lea rdx, [rel fence_char] 
        call console_manager_write_char

    .draw_side_fence_loop_handle:
        ; The loop handles sets EBX back into set up [width, height] and increments the height counter.
        rol ebx, 16
        inc r12w

        ; Then it is checking, if R12W exceeded the board height.
        ; If it didn't exceed it, it loops again.
        cmp r12w, bx
        jbe .draw_side_fence_loop

    .draw_bottom_fence:
        ; The Fence at board(height + 1).
        ; Setting up the params for "console_manager_repeat_char":
        ; * - CL contains the char to repeat.
        mov cl, [rel fence_char]

        ; * - EDX contains the number of repetitions.
        ror ebx, 16
        movzx edx, bx
        add edx, 3

        ; * - R8D contains the starting coordinates. (In this case: [board.width_offset - 1, board.height_offset + R12W])
        ror r13d, 16
        mov r8w, r13w
        dec r8w
        shl r8d, 16
        rol r13d, 16
        mov r8w, r13w
        add r8w, r12w
        call console_manager_repeat_char

    .complete:
        ; Restore non-volatile regs.
        mov r15, [rbp - 40]
        mov r14, [rbp - 32]
        mov r13, [rbp - 24]
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; Here the food (another DRAWABLE) is getting printed into the board. 
_draw_food:
    .set_up:
        ; Set up stack frame:
        ; 24 bytes local variables.
        ; 8 bytes to keep stack 16 byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 32

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32
        
        ; If board is not created yet, print a debug message.
        cmp qword [rel lcl_board_ptr], 0
        je _b_object_failed

        ; Save non-volatile regs.
        mov [rbp - 8], rbx
        mov [rbp - 16], r12
        mov [rbp - 24], r13

        ; RBX becomes food pointer.
        mov rbx, [rel lcl_board_ptr]
        mov rbx, [rbx + board.food_ptr]

        ; R12 becomes pointer to DRAWABLE vtable.
        mov r12, [rbx + food.interface_table_ptr]
        mov r12, [r12 + interface_table.vtable_drawable_ptr]

        ; R13 will hold final position [X-position, Y-position].
    .get_x:
        ; Get X-position of DRAWABLE.
        mov rcx, rbx
        call [r12 + DRAWABLE_VTABLE_X_POSITION_OFFSET]
        mov r13w, ax

        ; Add board.x_offset.
        call get_board_x_offset
        add r13w, ax 

    .get_y:
        ; Get Y-position of DRAWABLE.
        mov rcx, rbx
        call [r12 + DRAWABLE_VTABLE_Y_POSITION_OFFSET]
        shl r13d, 16
        mov r13w, ax

        ; Add board.y_offset.
        call get_board_y_offset
        add r13w, ax
    
    .get_char_ptr:
        ; Finally get char pointer of DRAWABLE object.
        mov rcx, rbx
        call [r12 + DRAWABLE_VTABLE_CHAR_PTR_OFFSET]

        ; Set up parameter for "console_manager_write_char":
        ; * - ECX contains the position of char.
        ror r13d, 16
        mov cx, r13w
        rol r13d, 16
        shl rcx, 16
        mov cx, r13w

        ; * - RDX contains pointer to char.
        mov rdx, rax
        call console_manager_write_char

    .complete:
        ; Restore non-volatile regs.
        mov [rbp - 24], r13
        mov [rbp - 16], r12
        mov [rbp - 8], rbx

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; If the snake is moving, the former tail has to be erased, since it would stay there the whole time. This function is responsible for that.
_erase_snake_unit:
    ; * 1. param: Expect position of old tail in ECX.
    .set_up:
        ; Set up stack frame:
        ; 8 bytes for local variables.
        ; 8 bytes to keep stack 16 byte aligned.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32
        
        ; If board is not created yet, print a debug message.
        cmp qword [rel lcl_board_ptr], 0
        je _b_object_failed

        ; Save param into shadow space.
        mov [rbp + 16], ecx

        ; Save non-volatile regs.
        mov [rbp - 8], rbx

    .get_x_offset:
        ; Getting the board.x_offset to add it to the position of the X-coordinate passed in ECX.
        call get_board_x_offset
        mov bx, ax

    .get_y_offset:
        ; Getting the board.y_offset to add it to the position of the Y-coordinate passed in ECX.
        call get_board_y_offset
        shl ebx, 16
        mov bx, ax

    .erase_old_tail:
        ; Now I am preparing the coordinates to pass them into the "console_manager_erase" method.
        ; At first the Y-coordinate is handled, and the board.y_offset is added to the Y-coordinate in CX.
        mov ecx, [rbp + 16]
        add cx, bx

        ; Moving the bits of the regs into the right place for next operation.
        rol ecx, 16
        shr ebx, 16

        ; Adding the board.x_offset to the X-coordinate.
        add cx, bx

        ; Moving the bits into the right place for passing the parameter.
        ror ecx, 16

        ; Letting the function erase exactly one char.
        mov rdx, 1
        call console_manager_erase

    .complete:
        ; Restore non-volatile regs.
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; The idea was to create a PRNG to let the board create new food on random positions. Therefore I am getting the SystemTime as FileTime, store it in lcl_filetime_struc and use these values to create x- and y-coordinates of the food.
; ! To get a valid food-position, it needs to be checked, that the food is not placed on a position already occupied by the snake itself. Therefore I am creating that position, checking it with the snake, and if it is colliding with the snake, I do it all over again. 
; ! That is far off being efficient. Especially if the snake is really big, and not many empty positions on the board are left anymore. Want to find a better solution for that.
_create_random_position:
    .set_up:
        ; Set up stack frame:
        ; 16 bytes for local variables.
        push rbp
        mov rbp, rsp
        sub rsp, 16

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32
        
        ; If board is not created yet, print a debug message.
        cmp qword [rel lcl_board_ptr], 0
        je _b_object_failed

        ; Save non-volatile regs.
        mov [rbp - 8], rbx
        mov [rbp - 16], r12

        ; Make RBX pointing to board object.
        mov rbx, [rel lcl_board_ptr]

    .get_system_time_as_file_time:
        lea rcx, [rel lcl_filetime_struc]
        call GetSystemTimeAsFileTime

        ; Prepare RAX for calculating value.
        mov rax, [rel lcl_filetime_struc]
        ror rax, 16

    .calculate_x:
        ; Div RAX by board.width and save remainder in R12W.
        xor rdx, rdx
        movzx r8, word [rbx + board.width]
        div r8
        mov r12w, dx

    .calculate_y:
        ; Prepare RAX for calculation.
        mov rax, [rel lcl_filetime_struc]
        rol rax, 32

        ; Div RAX by board.height and save remainder in R12W (after preparing the reg).
        xor rdx, rdx
        movzx r8, word [rbx + board.height]
        div r8
        shl r12d, 16
        mov r12w, dx

    .complete:
        ; Return calculated position in EAX.
        mov eax, r12d

        ; Restore non-volatile regs.
        mov r12, [rbp - 16]
        mov rbx, [rbp - 8]

        ; Restore old stack frame and return to caller.
        mov rsp, rbp
        pop rbp
        ret

; Here the newly created position gets controlled with snake positions. If it is on a snake position, the function returns FALSE. If not, the function returns TRUE.
_is_food_position_free:
    ; * 1. param: Expect X- and Y-Coordinates of position in ECX.
    .set_up:
        ; Set up stack frame without local variables.
        push rbp
        mov rbp, rsp

        ; Reserve 32 bytes shadow space for called functions.
        sub rsp, 32
        
        ; If board is not created yet, print a debug message.
        cmp qword [rel lcl_board_ptr], 0
        je _b_object_failed

    .set_up_loop_base:
        ; I am setting up the base for the controlling loop:
        ; * - ECX is already holding the X- and Y-position of the checked position.
        ; * - RDX will hold the tail.
        ; * - R8 will hold the active snake unit.
        ; * - R9 gets the position information of the active unit from R8.

        ; Make RDX pointing to snake object first.
        mov rdx, [rel lcl_board_ptr]
        mov rdx, [rdx + board.snake_ptr]

        ; R8 will store head first.
        mov r8, [rdx + snake.head_ptr]

        ; Now RDX can hold the tail.
        mov rdx, [rdx + snake.tail_ptr]

    .check_loop:
        ; Compare unit.y_position with check.y_position.
        ; If it is not equal, preparing x coordinates can already be skipped.
        mov r9, [r8 + unit.position_ptr]
        mov r10w, [r9 + position.y]
        cmp r10w, cx
        jne .check_loop_handle

        ; Compare unit.x_position with check.x_position.
        ; If it is also equal, the position is blocked and needs to be recreated.
        ror ecx, 16
        mov r10w, word [r9 + position.x]
        cmp r10w, cx
        je .position_blocked

    .check_loop_handle:
        ; If R8 was the tail, the check is done and the position is free.
        cmp r8, rdx
        je .position_free

        ; Move on to next unit in the linked list and reset ECX.
        mov r8, [r8 + unit.next_unit_ptr]
        rol ecx, 16
        jmp .check_loop

    .position_blocked:
        ; Set return value to FALSE.
        mov rax, 0
        jmp .complete

    .position_free:
        ; Set return value to TRUE.
        mov rax, 1

    .complete:
        ; Restore old stack frame and return to caller.
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