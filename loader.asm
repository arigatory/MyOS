[BITS 16]
[ORG 0x7e00]


start:
    mov [DriveId],dl    ; в dl у нас хранился DriveId перед тем как мы прыгнули в загрузчик
    
    mov eax,0x80000000 ; проверим, можем ли подать 0x80000001 на вход
    cpuid
    cmp eax,0x80000001 ; если не можем, то значение будет меньше 0x80000001
    jb NotSupport   
    ; ПРОВЕРКА Long Mode
    mov eax,0x80000001 ; подается на вход cpuid, чтобы получить фичи процессора, информация о поддержки long mode хранится в edx
    cpuid   ; возвращает id процессора и его фичи
    test edx,(1<<29) ; проверяем 29-й бит, именно он отвечает за поддержку long mode
    jz NotSupport
    test edx,(1<<26) ; проверям 26 бит, чтобы понять поддерживается ли 1гб режим
    jz NotSupport

LoadKernel:
    mov si,ReadPacket   ; offset    field
                        ;    0       size
                        ;    2       number of sectors
                        ;    4       offset
                        ;    6       segment
                        ;    8       address lo
                        ;    12      address hi
    mov word[si],0x10   ; так как размер у нас 16 байт
    mov word[si+2],100    ; количество секторов, которое хотим прочитать, этого достаточно для загрузчика
    mov word[si+4],0        ; следующие 2 слова - адрес памяти, куда хотим считать наш файл, у нас это будет 10 000h
    mov word[si+6],0x1000    ; сегмент нужен, так как в оффсет не поместится 1000, а тут  1000*16 + 0x0 = 0x10000
    mov dword[si+8],6   ; 64-битный LBA (logical block address), файл ядра будет записан в седьмой сектор диска, тк lba = 1 (т.к. 0,1...)
    mov dword[si+0xc],0

    mov dl,[DriveId] ; сохраняем DriveId
                    ; в качестве параметра для этого сервиса используется структура, ReadPacket размера 16 байт
    mov ah,0x42     ; function code = 42h
    int 0x13
    jc ReadError    ; если не удастся считать сектор cf=1


       ; будем использовать прерывания биоса для печати. Здесь 0x10
    mov ah,0x13     ; код функции 0x13 - print_string
    mov al,1        ; write mode = 1, курсор будет помещаться в конец строки
    mov bx,0xa      ; bh - page number, bl - info about character attribute, 0xa означает, что будет печататься ярким зеленым цветом
    xor dx,dx       ; dh - rows, dl - columns
    mov bp,Message  ; bp - адрес сообщения для печати
    mov cx,MessageLen
    int 0x10      ; print 


ReadError:
NotSupport:
End:
    hlt
    jmp End


DriveId: db 0
Message: db "Welcome to your new OS! Loader starts...",10,13,"Long mode is supported...",10,13,"Kernel is loaded...",10,13
MessageLen: equ $-Message
ReadPacket: times 16 db 0