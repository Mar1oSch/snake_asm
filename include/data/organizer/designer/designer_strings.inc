;;;;;; START SCREEN ;;;;;;
headline:
    .line1 db "  SSSSSS    NNN     NNN    AAAAAAA    KKK    KKK   EEEEEEEEE",13,10, 0
    .line2 db "SSSSSSSSSS  NNNN    NNN   AAAAAAAAA   KKK   KKK    EEEEEEEEE",13,10, 0
    .line3 db "SSSS        NNNNN   NNN   AAA   AAA   KKK  KKK     EEE      ",13,10, 0
    .line4 db " SSSSS      NNN NN  NNN   AAAAAAAAA   KKKKKK       EEEEEEEE ",13,10, 0
    .line5 db "  SSSSS     NNN  NN NNN   AAAAAAAAA   KKK KKK      EEEEEEEE ",13,10, 0
    .line6 db "     SSSS   NNN   NNNNN   AAA   AAA   KKK  KKK     EEE      ",13,10, 0
    .line7 db "SSSSSSSSS   NNN    NNNN   AAA   AAA   KKK   KKK    EEEEEEEEE",13,10, 0
    .line8 db "  SSSSS     NNN     NNN   AAA   AAA   KKK    KKK   EEEEEEEEE",13,10, 0
headline_end:

headline_table:
    dq headline.line1, (headline.line2 - headline.line1)
    dq headline.line2, (headline.line3 - headline.line2)
    dq headline.line3, (headline.line4 - headline.line3)
    dq headline.line4, (headline.line5 - headline.line4)
    dq headline.line5, (headline.line6 - headline.line5)
    dq headline.line6, (headline.line7 - headline.line6)
    dq headline.line7, (headline.line8 - headline.line7)
    dq headline.line8, (headline_end - headline.line8)
headline_table_end:

HEADLINE_TABLE_SIZE equ (headline_table_end - headline_table) / 16

author:
db "by Mario Schanzenbach", 0
author_end:

AUTHOR_LENGTH equ author_end - author

;;;;;; LEADERBOARD SCREEN ;;;;;;
leaderboard:
    db "LEADERBOARD", 0
leaderboard_end:

LEADERBOARD_SIZE equ leaderboard_end - leaderboard