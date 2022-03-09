[BITS 16]
[ORG 0x7e00]


start:
       ; будем использовать прерывания биоса для печати. Здесь 0x10
    mov ah,0x13     ; код функции 0x13 - print_string
    mov al,1        ; write mode = 1, курсор будет помещаться в конец строки
    mov bx,0xa      ; bh - page number, bl - info about character attribute, 0xa означает, что будет печататься ярким зеленым цветом
    xor dx,dx       ; dh - rows, dl - columns
    mov bp,Message  ; bp - адрес сообщения для печати
    mov cx,MessageLen
    int 0x10      ; print 




End:
    hlt
    jmp End


Message: db "Welcome to your new OS! Loader starts..."
MessageLen: equ $-Message