; Constants:
%include "./include/data/drawable_vtable/drawable_vtable_constants.inc"

; The DRAWABLE interface.
; It handles the operation with objects, which are drawn into the board.

; ! That interface simply was a small try to implement some object oriented pattern into an assembly project. Neither was it really necessary, nor is it doing anything, the objects wouldn't be able to handle by themselves. I am not referencing to a kind of list, which just holds drawable elements but handling drawing the snake and drawing the food seperately. So, the use of this interface is for practice and trial.

global DRAWABLE_VTABLE_CHAR_PTR_OFFSET, DRAWABLE_VTABLE_X_POSITION_OFFSET, DRAWABLE_VTABLE_Y_POSITION_OFFSET
global drawable_vtable_food, drawable_vtable_unit

section .text
    extern food_get_char_ptr, food_get_x_position, food_get_y_position
    extern unit_get_char_ptr, unit_get_x_position, unit_get_y_position

; Here are the tables for food and units.
; It holds the pointers to the getters of each object.
drawable_vtable_food:
    dq food_get_char_ptr 
    dq food_get_x_position
    dq food_get_y_position

drawable_vtable_unit:
    dq unit_get_char_ptr
    dq unit_get_x_position
    dq unit_get_y_position
