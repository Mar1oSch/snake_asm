; ! ######################################################## ! ;
; ! #     In the beginning of the project I tested the     # ! ;
; ! #      constructor cascade here. But many things       # ! ;
; ! #     changed since then. So this test should be       # ! ;
; ! #               rewritten in some time.                # ! ;
; ! ######################################################## ! ;











; global constructor_test

; %include "./include/strucs/position_struc.inc"
; %include "./include/strucs/interface_table_struc.inc"
; %include "./include/strucs/game/board_struc.inc"
; %include "./include/strucs/game/game_struc.inc"
; %include "./include/strucs/game/player_struc.inc"
; %include "./include/strucs/food/food_struc.inc"
; %include "./include/strucs/snake/snake_struc.inc"
; %include "./include/strucs/snake/unit_struc.inc"
; %include "./include/strucs/organizer/console_manager_struc.inc"

; ;;;; THIS TEST IS IMPLEMENTED TO TEST THE CONSTRUCTOR CHAIN FROM:

; ;;;;                           GAME
; ;;;;                            ^                              
; ;;;;          BOARD                          PLAYER 
; ;;;;            ^
; ;;;;  SNAKE   FOOD    CONSOLE-MANAGER
; ;;;;    |
; ;;;;   UNIT
; ;;;;    |
; ;;;;  TABLE
; ;;;;    |
; ;;;; POSITION

; section .data
;     game_pointer db "game_pointer: %p", 13, 10, 0
;     game_lvl db "game_lvl: %1d", 13, 10, 0
;     game_board db "game_board: %p", 13, 10, 0
;     game_player db "game_player: %p", 13, 10, 13, 10, 0

;     player_pointer db "player_pointer: %p", 13, 10, 0
;     player_points db "player_points: %d", 13, 10, 0
;     player_name db "player_name: %s", 13, 10, 0

;     board_pointer db "board_pointer: %p",13, 10, 0
;     board_width db "board_width: %d", 13, 10, 0
;     board_height db "board_height: %d", 13, 10, 0
;     board_snake db "board_snake: %p", 13, 10, 0
;     board_food db "board_food: %p", 13, 10, 0
;     board_console_manager db "board_console_manager: %p", 13, 10, 13, 10, 0

;     console_manager_pointer db "console_manager_pointer: %p", 13, 10, 0
;     console_manager_output_handle db "console_manager_output_handle: %u", 13, 10, 13, 10, 0

;     food_pointer db "food_pointer: %p", 13, 10, 0
;     food_interface_table db "food_table: %p", 13, 10, 0
;     food_points db "food_points: %d", 13, 10, 0
;     food_char db "food_char: '%c'", 13, 10, 0
;     food_position db "food_position: %p", 13, 10, 13, 10, 0

;     snake_pointer db "snake_pointer: %p", 13, 10, 0
;     snake_length db "snake_length: %d", 13, 10, 0
;     snake_head db "snake_head: %p", 13, 10, 0
;     snake_tail db "snake_tail: %p", 13, 10, 13, 10, 0

;     unit_pointer db "unit_pointer: %p", 13, 10, 0
;     unit_interface_table db "unit_table: %p", 13, 10, 0
;     unit_position db "unit_position: %p", 13, 10, 0
;     unit_char db "unit_char: '%c'", 13, 10, 0
;     unit_direction db "unit_direction: %d", 13, 10, 0
;     unit_next db "unit_next: %p", 13, 10, 13, 10, 0

;     table_pointer db "table_pointer: %p", 13, 10, 0
;     table_drawable db "table_drawable: %p", 13, 10, 13, 10, 0

;     position_pointer db "position_pointer: %p", 13, 10, 0
;     position_x db "position_x: %d", 13, 10, 0
;     position_y db "position_y: %d", 13, 10, 13, 10, 0


; section .text
;     global main
;     extern game_new
;     extern printf

; constructor_test:
;     push rbp
;     mov rbp, rsp
;     sub rsp, 48

;     xor rcx, rcx
;     mov cx, 100                  ; Moving width into CX  (So: ECX = 0, width)
;     shl rcx, 16                 ; Shifting rcx 16 bits left (So : ECX = width, 0)
;     mov cx, 20  
;     mov rdx, 5
;     call game_new

;     ;###################################################;
;     ;#                    Test GAME                    #;
;     ;###################################################;
;     mov [rbp - 8], rax
;     lea rcx, [rel game_pointer]
;     mov rdx, rax
;     call printf

;     mov rax, [rbp - 8]
;     lea rcx, [rel game_lvl]
;     movzx rdx, byte [rax + game.lvl]
;     call printf

;     mov rax, [rbp - 8]
;     lea rcx, [rel game_board]
;     mov rdx, [rax + game.board_ptr]
;     call printf

;     mov rax, [rbp - 8]
;     lea rcx, [rel game_player]
;     mov rdx, [rax + options.player_ptr]
;     call printf

;     ;###################################################;
;     ;#                    Test PLAYER                  #;
;     ;###################################################;
;     mov rax, [rbp - 8]
;     mov rax, [rax + options.player_ptr]
;     mov [rbp - 16], rax

;     lea rcx, [rel player_pointer]
;     mov rdx, rax
;     call printf

;     mov rax, [rbp - 16]
;     lea rcx, [rel player_points]
;     mov rdx, [rax + player.points]
;     call printf

;     mov rax, [rbp - 16]
;     lea rcx, [rel player_name]
;     mov rdx, [rax + player.name]
;     call printf

;     ;###################################################;
;     ;#                    Test BOARD                   #;
;     ;###################################################;
;     mov rax, [rbp - 8]
;     mov rax, [rax + game.board_ptr]
;     mov [rbp - 8], rax

;     lea rcx, [rel board_pointer]
;     mov rdx, rax
;     call printf

;     mov rax, [rbp - 8]
;     lea rcx, [rel board_width]
;     movzx rdx, word [rax + board.width] 
;     call printf
    
;     mov rax, [rbp - 8]
;     lea rcx, [rel board_height]
;     movzx rdx, word [rax + board.height]             
;     call printf
    
;     mov rax, [rbp - 8]
;     lea rcx, [rel board_snake]
;     mov rdx, [rax + board.snake_ptr]          
;     call printf
    
;     mov rax, [rbp - 8]
;     lea rcx, [rel board_food]
;     mov rdx, [rax + board.food_ptr]          
;     call printf

;     ;###################################################;
;     ;#              Test CONSOLE MANAGER               #;
;     ;###################################################;

;     mov rax, [rbp - 8]
;     mov rax, [rax + board.console_manager_ptr]
;     mov [rbp - 16], rax

;     lea rcx, [rel console_manager_pointer]
;     mov rdx, rax
;     call printf

;     mov rax, [rbp - 16]
;     lea rcx, [rel console_manager_output_handle]
;     mov rdx, [rax + console_manager.output_handle]
;     call printf

;     ;###################################################;
;     ;#                    Test Food                    #;
;     ;###################################################;

;     mov rax, [rbp - 8]
;     mov rax, [rax + board.food_ptr]
;     mov [rbp - 16], rax

;     lea rcx, [rel food_pointer]
;     mov rdx, rax
;     call printf

;     mov rax, [rbp - 16]
;     lea rcx, [rel food_interface_table]
;     mov rdx, [rax + food.interface_table_ptr]
;     call printf

;     mov rax, [rbp - 16]
;     lea rcx, [rel food_points]
;     mov rdx, [rax + food.points]
;     call printf

;     mov rax, [rbp - 16]
;     lea rcx, [rel food_char]
;     movzx rdx, byte [rax + food.char]
;     call printf

;     mov rax, [rbp - 16]
;     lea rcx, [rel food_position]
;     mov rdx, [rax + food.position_ptr]
;     call printf

;     ;###################################################;
;     ;#                    Test SNAKE                   #;
;     ;###################################################;

;     mov rax, [rbp - 8]
;     mov rax, [rax + board.snake_ptr]
;     mov [rbp - 8], rax

;     lea rcx, [rel snake_pointer]
;     mov rdx, rax
;     call printf

;     mov rax, [rbp - 8]
;     lea rcx, [rel snake_length]
;     mov rdx, [rax + snake.length]
;     call printf

;     mov rax, [rbp - 8]
;     lea rcx, [rel snake_head]
;     mov rdx, [rax + snake.head_ptr]
;     call printf

;     mov rax, [rbp - 8]
;     lea rcx, [rel snake_tail]
;     mov rdx, [rax + snake.tail_ptr]
;     call printf

;     ;###################################################;
;     ;#                    Test UNIT                    #;
;     ;###################################################;

;     mov rax, [rbp - 8]
;     mov rax, [rax + snake.head_ptr]
;     mov [rbp - 8], rax

;     lea rcx, [rel unit_pointer]
;     mov rdx, rax
;     call printf

;     mov rax, [rbp - 8]
;     lea rcx, [rel unit_interface_table]
;     mov rdx, [rax + unit.interface_table_ptr]
;     call printf

;     mov rax, [rbp - 8]
;     lea rcx, [rel unit_position]
;     mov rdx, [rax + unit.position_ptr]
;     call printf

;     mov rax, [rbp - 8]
;     lea rcx, [rel unit_char]
;     movzx rdx, byte [rax + unit.char]
;     call printf

;     mov rax, [rbp - 8]
;     lea rcx, [rel unit_direction]
;     movzx rdx, byte [rax + unit.direction]
;     call printf

;     mov rax, [rbp - 8]
;     lea rcx, [rel unit_next]
;     mov rdx, [rax + unit.next_unit_ptr]
;     call printf

;     ;###################################################;
;     ;#                    Test TABLE                   #;
;     ;###################################################;

;     mov rax, [rbp - 8]
;     mov rax, [rax + unit.interface_table_ptr]
;     mov [rbp - 16], rax

;     lea rcx, [rel table_pointer]
;     mov rdx, rax
;     call printf

;     mov rax, [rbp - 16]
;     lea rcx, [rel table_drawable]
;     mov rdx, [rax + interface_table.vtable_drawable_ptr]
;     call printf

;     ;###################################################;
;     ;#                  Test POSITION                  #;
;     ;###################################################;

;     mov rax, [rbp - 8]
;     mov rax, [rax + unit.position_ptr]
;     mov [rbp - 8], rax

;     lea rcx, [rel position_pointer]
;     mov rdx, rax
;     call printf

;     mov rax, [rbp - 8]
;     lea rcx, [rel position_x]
;     movzx rdx, word [rax + position.x]
;     call printf

;     mov rax, [rbp - 8]
;     lea rcx, [rel position_y]
;     movzx rdx, word [rax + position.y]
;     call printf

;     mov rax, 0
;     mov rsp, rbp
;     pop rbp
;     ret