[BITS 16]       ;запускаем код в 16 битном режиме
[ORG 0x7c00]    ;код должен быть запущен, начиная с адреса 7с00 (первый сектор запуска bios)

start:
    xor ax,ax   ; инициализируем все сегементные регистры нулями
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov sp,0x7c00   ; код будет начинаться с 7с00, а стек будет меньше 7с00 (на 2 байта будет уменьшаться в этом режиме)

TeskDiskExtension:
    mov [DriveId],dl ; dl - driveId
    mov ah,0x41       ;
    mov bx,0x55aa
    int 0x13        ; если сервис не поддерживается, возводится CF
    jc NotSupport
    cmp bx,0xaa55   ; если не равны, означает, что DiskExtension не поддерживается
    jne NotSupport              
                    
LoadLoader:
    mov si,ReadPacket   ; offset    field
                        ;    0       size
                        ;    2       number of sectors
                        ;    4       offset
                        ;    6       segment
                        ;    8       address lo
                        ;    12      address hi
    mov word[si],0x10   ; так как размер у нас 16 байт
    mov word[si+2],5    ; количество секторов, которое хотим прочитать, этого достаточно для загрузчика
    mov word[si+4],0x7e00 ; следующие 2 слова - адрес памяти, куда хотим считать наш файл, у нас это будет 7e00
    mov word[si+6],0    ; сегмент нам не нужен, чтобы в сумме получилось 0*16 + 0x7e00 = 0x7e00
    mov dword[si+8],1   ; 64-битный LBA (logical block address), файл загрузчика будет записан во второй сектор диска, поэтому lba = 1 (т.к. 0,1...)
    mov dword[si+0xc],0

    mov dl,[DriveId] ; сохраняем DriveId
                    ; в качестве параметра для этого сервиса используется структура, ReadPacket размера 16 байт
    mov ah,0x42     ; function code = 42h
    int 0x13
    jc ReadError    ; если не удастся считать сектор cf=1

    mov dl,[DriveId]
    jmp 0x7e00      ; адрес, по которому мы загрузили наш загрузчик с диска

ReadError:
NotSupport:
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


DriveId: db 0
Message: db "We have an error in boot process"
MessageLen: equ $-Message
ReadPacket: times 16 db 0

times (0x1be-($-$$)) db 0       ; повторяем (0x1be-($-$$)) раз. $$ - адрес текущей секции, у нас здесь только одна (начало кода), тут от нач кода до кон сообщения
                                ; то есть мы заполним место от конца сообщения до 0x1be нулями
                                ; по этому адресу запись о разделах. всего 4записи размером по 16 байт
                                ; мы определяем только первую запись, остальные обнуляем. формат записи ниже:
    db 80h                      ; первый байт - индикатор загрузки, 80 - означает, что загрузочный раздел
    db 0,2,0                    ; байты задают CHS значения (cylinder, head, sector), перый байт - головка
                                ; второй байт разделен на 2 части: 0-5 - сектор, 6-7 - цилиндр
                                ; последний байт содержит 8 бит - значение цилиндра. значения головки и цилиндра начинаются с 0,  0 цилиндр - это первый цилиндр
                                ; значения сектора начинаются с 1, 1 сектор - первый сектор
    db 0f0h                     ; 4-й байт - тип раздела, ставим f0h
    db 0ffh,0ffh,0ffh           ; эти три бита задают конечные значения для CHS, ставим максимум
    dd 1                        ; двойное слово, LBA (logical block address) адрес начального сектора, тогически мы используем его, а не CHS значение
    dd (20*16*63-1)             ; количество секторов у раздела, здесь устанавливаем размер 10 Mb
                                ; на самом деле ничего страшного, если не очень понятно, 
                                ; это на самом деле не реальные значения разделов, просто хотим, 
                                ; чтобы bios воспринял флешку как диск, а не как дискету, например
    times (16*3) db 0

    db 0x55                     ; signature 55aa
    db 0xaa                     
                                ; всего 512 байт