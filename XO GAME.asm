data segment       
    game_draw db "_|_|_", 13, 10
              db "_|_|_", 13, 10
              db "_|_|_", 13, 10, "$"    
    game_pointer db 9 DUP(?)  
    win_flag db 0 
    player db "0$"
    game_over_message db "GAME OVER", 13, 10, "$"    
    game_start_message db "XO GAME", 13, 10, "$"
    player_message db "PLAYER $"   
    win_message db " IS THE WINNER!$"   
    position_input_message db "ENTER THE POSITION: $"
ends 


stack segment
    dw   128  dup(?)
ends  


code segment
start:
    ; set segment registers
    mov     ax, data
    mov     ds, ax

    ; game start   
    call    set_game_pointer    
            
main_loop:
    ; clear screen every turn  
    call    clear_screen   
    ; print the title of the game
    lea     dx, game_start_message 
    call    print
    call    new_line                      
    ; print the player that should take turn
    lea     dx, player_message
    call    print
    lea     dx, player
    call    print  
    call    new_line    
    ; print the grid 
    lea     dx, game_draw
    call    print    
    call    new_line    
    ; print input message
    lea     dx, position_input_message    
    call    print                              
    ; read draw position                   
    call    read_keyboard              
    ; calculate draw position                   
    sub     al, 49                
    mov     bh, 0
    mov     bl, al                                  
    ; update the grid in the memory                              
    call    update_draw                                    
    ; check the win condtions starting from line, column ending with diagonals                                         
    call    check_line 
                       
    ; check if game ends                   
    cmp     win_flag, 1  
    je      game_over  
    
    call    change_player 
            
    jmp     main_loop

game_over:        
    call    clear_screen   
    lea     dx, game_start_message 
    call    print
    call    new_line                          
    lea     dx, game_draw
    call    print    
    call    new_line
    lea     dx, game_over_message
    call    print  
    lea     dx, player_message
    call    print
    lea     dx, player
    call    print
    lea     dx, win_message
    call    print 
    jmp     end_game 
    
      
end_game:
    mov ax, 4c00h ; exit to operating system.
    int 21h       


;______________________________________________________________________
change_player proc   
    lea     si, player    
    xor     [si], 1 
    ret
change_player endp
      
 
update_draw proc
    mov     bl, game_pointer[bx]
    mov     bh, 0
    
    lea     si, player
    
    cmp     ds:[si], "0"
    je      draw_x     
                  
    cmp     ds:[si], "1"
    je      draw_o              
                  
    draw_x:
    mov     cl, "x"
    jmp     update

    draw_o:          
    mov     cl, "o"  
    jmp     update    
          
    update:         
    mov     ds:[bx], cl
      
    ret
update_draw endp 
       
       
check_line proc
    mov     cx, 0
    
    check_line_loop:     
    cmp     cx, 0
    je      first_line
    
    cmp     cx, 1
    je      second_line
    
    cmp     cx, 2
    je      third_line  
    
    call    check_column
    ret    
        
    first_line:    
    mov     si, 0   
    jmp     do_check_line   

    second_line:    
    mov     si, 3
    jmp     do_check_line
    
    third_line:    
    mov     si, 6
    jmp     do_check_line        

    do_check_line:
    inc     cx
  
    mov     bh, 0
    mov     bl, game_pointer[si] ; Sets BL to point to the first cell in the current line.
    mov     al, ds:[bx] ; Loads the symbol in the current cell into AL.
    cmp     al, "_"
    je      check_line_loop
    
    inc     si
    mov     bl, game_pointer[si]    
    cmp     al, ds:[bx]
    jne     check_line_loop 
      
    inc     si
    mov     bl, game_pointer[si]  
    cmp     al, ds:[bx]
    jne     check_line_loop
                 
                         
    mov     win_flag, 1
    ret         
check_line endp       
       
       
check_column proc
    mov     cx, 0
    
    check_column_loop:     
    cmp     cx, 0
    je      first_column
    
    cmp     cx, 1
    je      second_column
    
    cmp     cx, 2
    je      third_column  
    
    call    check_diagonal
    ret    
        
    first_column:    
    mov     si, 0   
    jmp     do_check_column   

    second_column:    
    mov     si, 1
    jmp     do_check_column
    
    third_column:    
    mov     si, 2
    jmp     do_check_column        

    do_check_column:
    inc     cx
  
    mov     bh, 0
    mov     bl, game_pointer[si]
    mov     al, ds:[bx]
    cmp     al, "_"
    je      check_column_loop
    
    add     si, 3
    mov     bl, game_pointer[si]    
    cmp     al, ds:[bx]
    jne     check_column_loop 
      
    add     si, 3
    mov     bl, game_pointer[si]  
    cmp     al, ds:[bx]
    jne     check_column_loop
                 
                         
    mov     win_flag, 1
    ret
check_column endp        


check_diagonal proc
    mov     cx, 0
    
    check_diagonal_loop:     
    cmp     cx, 0
    je      first_diagonal
    
    cmp     cx, 1
    je      second_diagonal                         
    
    ret    
        
    first_diagonal:    
    mov     si, 0                
    mov     dx, 4 
    jmp     do_check_diagonal   

    second_diagonal:    
    mov     si, 2
    mov     dx, 2
    jmp     do_check_diagonal       

    do_check_diagonal:
    inc     cx
  
    mov     bh, 0
    mov     bl, game_pointer[si]
    mov     al, ds:[bx]
    cmp     al, "_"
    je      check_diagonal_loop
    
    add     si, dx
    mov     bl, game_pointer[si]    
    cmp     al, ds:[bx]
    jne     check_diagonal_loop 
      
    add     si, dx
    mov     bl, game_pointer[si]  
    cmp     al, ds:[bx]
    jne     check_diagonal_loop
                 
                         
    mov     win_flag, 1
    ret
check_diagonal endp 

     
set_game_pointer proc
    lea     si, game_draw
    lea     bx, game_pointer          
    mov     cx, 9   

    loop_1:
    cmp     cx, 6
    je      add_1                
    
    cmp     cx, 3
    je      add_1
    
    jmp     add_2 
    
    add_1:
    add     si, 1
    jmp     add_2     
      
    add_2:                                
    mov     ds:[bx], si 
    add     si, 2
                        
    inc     bx               
    loop    loop_1 
 
    ret
set_game_pointer endp  
         
       
print proc     ; print dx content  
    mov     ah, 9
    int     21h   
    ret
print endp 
    

clear_screen proc       ; get and set video mode
    mov     ah, 0fh
    int     10h   
    mov     ah, 0
    int     10h
    ret
clear_screen endp
       
    
read_keyboard proc  ; read character from user
    mov     ah, 1       
    int     21h  
    ret      
read_keyboard endp   
          
          
new_line proc
    mov ah, 2
    mov dl, 0ah
    int 21h
    mov ah, 2
    mov dl, 0dh
    int 21h 
    ret
new_line endp

;____________________________________________________________________________
      
code ends

end start