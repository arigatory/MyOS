[BITS 16]
[ORG 0x7e00]


start:
    mov [DriveId],dl    ; в dl у нас хранился DriveId перед тем как мы прыгнули в загрузчик
    
    mov eax,0x80000000 ; проверим, можем ли подать 0x80000001 на вход
    cpuid
    cmp eax,0x80000001 ; если не можем, то значение будет меньше 0x80000001
    jb NotSupport   
    ; ПРОВЕРКА Long Mode
    mov eax,0x8000001 ; подается на вход cpuid, чтобы получить фичи процессора, информация о поддержки long mode хранится в edx
    cpuid   ; возвращает id процессора и его фичи
    test edx,(1<<29) ; проверяем 29-й бит, именно он отвечает за поддержку long mode
    jz NotSupport
    test edx,(1<<26) ; проверям 26 бит, чтобы понять поддерживается ли 1гб режим
    js NotSupport
       ; будем использовать прерывания биоса для печати. Здесь 0x10
    mov ah,0x13     ; код функции 0x13 - print_string
    mov al,1        ; write mode = 1, курсор будет помещаться в конец строки
    mov bx,0xa      ; bh - page number, bl - info about character attribute, 0xa означает, что будет печататься ярким зеленым цветом
    xor dx,dx       ; dh - rows, dl - columns
    mov bp,Message  ; bp - адрес сообщения для печати
    mov cx,MessageLen
    int 0x10      ; print 

NotSupport:
End:
    hlt
    jmp End


DriveId: db 0
Message: db "Welcome to your new OS! Loader starts... Long mode is supported"
MessageLen: equ $-Message