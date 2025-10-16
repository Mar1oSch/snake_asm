game_over:
    .string1 db "GAME OVER"
game_over_end:

game_over_table:
    dq game_over.string1, (game_over_end - game_over.string1)
game_over_table_end:

game_over_table_size equ (game_over_table_end - game_over_table) /16

paused:
    .string1 db "P A U S E D"
paused_end:

paused_table:
    dq paused.string1, (paused_end - paused.string1)
paused_table_end:

paused_table_size equ (paused_table_end - paused_table) /16

empty:
    .string1 db "              "
empty_end:

empty_table:
    dq empty.string1, (empty_end - empty.string1)
empty_table_end:

empty_table_size equ (empty_table_end - empty_table) /16