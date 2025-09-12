global DRAWABLE_VTABLE_CHAR_OFFSET, DRAWABLE_VTABLE_X_POSITION_OFFSET, DRAWABLE_VTABLE_Y_POSITION_OFFSET, DRAWABLE_VTABLE_DRAW_OFFSET
global drawable_vtable_food, drawable_vtable_super_food, drawable_vtable_segment

section .rodata
    DRAWABLE_VTABLE_CHAR_OFFSET equ 0
    DRAWABLE_VTABLE_X_POSITION_OFFSET equ 8
    DRAWABLE_VTABLE_Y_POSITION_OFFSET equ 16
    DRAWABLE_VTABLE_DRAW_OFFSET equ 24

section .text
    extern food_get_char, food_get_x_position, food_get_y_position, food_draw
    extern super_food_get_char, super_food_get_x_position, super_food_get_y_position, super_food_draw
    extern segment_get_char, segment_get_x_position, segment_get_y_position, segment_draw

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

drawable_vtable_segment:
    dq segment_get_char
    dq segment_get_x_position
    dq segment_get_y_position
    dq segment_draw