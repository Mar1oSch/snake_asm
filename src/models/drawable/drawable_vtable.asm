global DRAWABLE_VTABLE_CHAR_OFFSET, DRAWABLE_VTABLE_X_POSITION_OFFSET, DRAWABLE_VTABLE_Y_POSITION_OFFSET, DRAWABLE_VTABLE_DRAW_OFFSET
global drawable_vtable_food, drawable_vtable_super_food, drawable_vtable_unit

section .rodata
    DRAWABLE_VTABLE_CHAR_OFFSET equ 0
    DRAWABLE_VTABLE_X_POSITION_OFFSET equ 8
    DRAWABLE_VTABLE_Y_POSITION_OFFSET equ 16
    DRAWABLE_VTABLE_DRAW_OFFSET equ 24

section .text
    extern food_get_char, food_get_x_position, food_get_y_position, food_draw
    extern super_food_get_char, super_food_get_x_position, super_food_get_y_position, super_food_draw
    extern unit_get_char, unit_get_x_position, unit_get_y_position, unit_draw

drawable_vtable_food:
    dq food_get_char 
    dq food_get_x_position
    dq food_get_y_position
    dq food_draw

drawable_vtable_super_food:
    dq super_food_get_char
    dq super_food_get_x_position
    dq super_food_get_y_position
    dq super_food_draw

drawable_vtable_unit:
    dq unit_get_char
    dq unit_get_x_position
    dq unit_get_y_position
    dq unit_draw