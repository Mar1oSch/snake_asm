;;;;;; INTRODUCTION ;;;;;;
introduction:
    .string1 db "Hello, fellow friend! Welcome to your snake adventure."    
    .string2 db "Is this the first time you are entering this dangerous territory?"
    .string3 db "[Y]es / [N]o"
    .string4 db 0
introduction_end:

intro_table:
    dq introduction.string1, (introduction.string2 - introduction.string1)
    dq introduction.string2, (introduction.string3 - introduction.string2)
    dq introduction.string3, (introduction.string4 - introduction.string3)
    dq introduction.string4, (introduction_end - introduction.string4)
intro_table_end:
intro_table_size equ (intro_table_end - intro_table) /16

;;;;;; PLAYER CREATION ;;;;;;
new_player:
    .string1 db "A Very well welcome from my side."
    .string2 db "What is your name, adventurer?"
    .string3 db "(Max 15 signs)"
    .string4 db 0
new_player_end:

new_player_table:
    dq new_player.string1, (new_player.string2 - new_player.string1)
    dq new_player.string2, (new_player.string3 - new_player.string2)
    dq new_player.string3, (new_player.string4 - new_player.string3)
    dq new_player.string4, (new_player_end - new_player.string4)
new_player_table_end:
new_player_table_size equ (new_player_table_end - new_player_table) /16

;;;;;; FILE PLAYER CREATION ;;;;;;
file_player:
    .string1 db "Welcome back then."
    .string2 db "What is your name?"
    .string3 db "(Max 15 signs)"
    .string4 db 0
file_player_end:

file_player_table:
    dq file_player.string1, (file_player.string2 - file_player.string1)
    dq file_player.string2, (file_player.string3 - file_player.string2)
    dq file_player.string3, (file_player.string4 - file_player.string3)
    dq file_player.string4, (file_player_end - file_player.string4)
file_player_table_end:
file_player_table_size equ (file_player_table_end - file_player_table) /16

file_player_headline:
    db "Who are you?"
file_player_headline_end:
file_player_headline_length equ file_player_headline_end - file_player_headline

;;;;;; LEVEL CREATION ;;;;;;
level_creation:
    .string1 db "Nice to meet you, brave person."
    .string2 db "How brave are you?"
    .string3 db "Which level do you want to play?"
    .string4 db "The ride is going to be harder on higher stages, but the rewards are rich."
    .string5 db 0
    .string6 db "[1] [2] [3] [4] [5] [6] [7] [8] [9]"
    .string7 db 0
level_creation_end:

level_creation_table:
    dq level_creation.string1, (level_creation.string2 - level_creation.string1)
    dq level_creation.string2, (level_creation.string3 - level_creation.string2)
    dq level_creation.string3, (level_creation.string4 - level_creation.string3)
    dq level_creation.string4, (level_creation.string5 - level_creation.string4)
    dq level_creation.string5, (level_creation.string6 - level_creation.string5)
    dq level_creation.string6, (level_creation.string7 - level_creation.string6)
    dq level_creation.string7, (level_creation_end - level_creation.string7)
level_creation_table_end:
level_creation_table_size equ (level_creation_table_end - level_creation_table) /16

;;;;;; GAME OVER ;;;;;;
after_game:
    .string1 db "The ride was too bumpy for you I guess.."    
    .string2 db "But you played well!"
    .string3 db "What do you want to do next? These are your options:"
    .string4 db 0
    .string5 db "[1]: Replay Game     "
    .string6 db "[2]: Change Player   "
    .string7 db "[3]: Change Level    "
    .string8 db "[4]: Change Both     "
    .string9 db "[5]: Show Leaderboard"
    .string10 db "[6]: Exit Game       "
    .string11 db 0
    .string12 db 0
after_game_end:

after_game_table:
    dq after_game.string1, (after_game.string2 - after_game.string1)
    dq after_game.string2, (after_game.string3 - after_game.string2)
    dq after_game.string3, (after_game.string4 - after_game.string3)
    dq after_game.string4, (after_game.string5 - after_game.string4)
    dq after_game.string5, (after_game.string6 - after_game.string5)
    dq after_game.string6, (after_game.string7 - after_game.string6)
    dq after_game.string7, (after_game.string8 - after_game.string7)
    dq after_game.string8, (after_game.string9 - after_game.string8)
    dq after_game.string9, (after_game.string10 - after_game.string9)
    dq after_game.string10, (after_game.string11 - after_game.string10)
    dq after_game.string11, (after_game.string12 - after_game.string11)
    dq after_game.string12, (after_game_end - after_game.string12)
after_game_table_end:
after_game_table_size equ (after_game_table_end - after_game_table) /16
