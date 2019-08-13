.data
# syscall constants
PRINT_STRING            = 4
PRINT_CHAR              = 11
PRINT_INT               = 1

# memory-mapped I/O
VELOCITY                = 0xffff0010
ANGLE                   = 0xffff0014
ANGLE_CONTROL           = 0xffff0018

BOT_X                   = 0xffff0020
BOT_Y                   = 0xffff0024

TIMER                   = 0xffff001c

SUBMIT_ORDER            = 0xffff00b0
DROPOFF                 = 0xffff00c0
PICKUP                  = 0xffff00e0
GET_TILE_INFO           = 0xffff0050
SET_TILE                = 0xffff0058

REQUEST_PUZZLE          = 0xffff00d0
SUBMIT_SOLUTION         = 0xffff00d4

BONK_INT_MASK           = 0x1000
BONK_ACK                = 0xffff0060

TIMER_INT_MASK          = 0x8000
TIMER_ACK               = 0xffff006c

REQUEST_PUZZLE_INT_MASK = 0x800
REQUEST_PUZZLE_ACK      = 0xffff00d8

GET_MONEY               = 0xffff00e4
GET_LAYOUT              = 0xffff00ec
SET_REQUEST             = 0xffff00f0
GET_REQUEST             = 0xffff00f4

GET_INVENTORY           = 0xffff0040
GET_TURNIN_ORDER        = 0xffff0044
GET_TURNIN_USERS        = 0xffff0048
GET_SHARED              = 0xffff004c

GET_BOOST               = 0xffff0070
GET_INGREDIENT_INSTANT  = 0xffff0074
FINISH_APPLIANCE_INSTANT = 0xffff0078

# arctan constants
three:  .float  3.0
five:   .float  5.0
seven:  .float  7.0
nine:   .float  9.0
eleven: .float  11.0
thirteen: .float 13.0
fifteen:  .float 15.0
seventeen:.float 17.0
PI:     .float  3.141592
F180: .float 180.0


#Estimated puzzle solve cycles is used when waiting
ESTIMATED_PUZZLE_SOLVE_CYCLES = 30000000
############## puzzle #################################################
#puzzle
PUZZLE_SIZE = 452
PUZZLE_SIZE_BYTES = 1808
#a single puzzle size is 452
puzzle_list:      .word 0:7232
#2 bits: LSB--0 ready, 1 done; MSB--0 slot 0, 1 slot 1;
puzzle_state: .word 3 #11 in binary
#plan 2
puzzle_request: .word 0
puzzle_ready: .word 0
puzzle_done: .word 0

layout: .byte 0:226
block: .byte 0:6
foodid: .word 0:3
keypoint: .byte 0:10
direction: .byte 0:2
avil: .byte 0:12
order: .word 0:12
counter: .word 0:12
request_arr: .word 0:12
turnin_order: .word 0:10
request_order: .word 0:4
request_our: .word 0:4
share_counter: .word 0:4
inventory: .word 0:4
current_order_arr: .word 0:13

layout_map: .byte 0:10
side: .byte 0

get_turnin_orders: .word 0:1

cmd_queue: .word 0:4095 #upper 16 bits: angle; lower 16 bits: blocks
cmd_queue_head: .word 0 #head is inclusive but tail is not
cmd_queue_tail: .word 0

last_cycles: .word 0:3

.text
main:
    # Construct interrupt mask
    li      $t4, 0
    or      $t4, $t4, TIMER_INT_MASK
    or      $t4, $t4, BONK_INT_MASK # request bonk
    or      $t4, $t4, REQUEST_PUZZLE_INT_MASK  # puzzle interrupt bit
    or      $t4, $t4, 1 # global enable
    mtc0    $t4, $12

############################# Initialize ###############################################
    #State machine
    #t9 is used to store the bot move cmd with the first 2 bits as cmd state
    li $t9, 0x80000000   #t9's first 2 bits: 0 unreached; 1 not adjusted; 2 complete
    #set puzzle state to the second slot is done and request puzzle
    li $t0, 3
    la $t1, puzzle_state
    sw $t0, 0($t1)
    li $t0, 1
    la $t1, puzzle_request
    sw $t0, 0($t1)
    la $t0, puzzle_list
    li $t1, PUZZLE_SIZE_BYTES
	  add $t0, $t0, $t1
    sw $t0, REQUEST_PUZZLE

############################  ###########################################


    lw $t0, BOT_X
    bgt $t0, 150, right
left:

    la $a0, layout
    sw $a0, GET_LAYOUT
    lw $a1, BOT_X
    lw $a2, BOT_Y
    la $a3, block
    jal check_layout

    la $a0, block
    la $a1, avil
    la $a2, order
    la $a3, request_arr
    jal check_avil


    la $a0, request_arr
    sub $0, $0, 1


    la $a0, order
    jal request_decode

    lw $a0, BOT_X
    la $a1, current_order_arr
    jal get_current_order


    la $a0, block
    la $a1, foodid
    jal check_foodid
    #key point
    la $t0, keypoint
    li $t1, 0x00000013
    sb $t1, 0($t0)
    li $t1, 0x00000017
    sb $t1, 1($t0)
    li $t1, 0x0000001b
    sb $t1, 2($t0)
    li $t1, 0x00000023
    sb $t1, 3($t0)
    li $t1, 0x00000053
    sb $t1, 4($t0)
    li $t1, 0x00000063
    sb $t1, 5($t0)
    li $t1, 0x00000067
    sb $t1, 6($t0)
    li $t1, 0x0000006b
    sb $t1, 7($t0)
    li $t1, 0x0000006d
    sb $t1, 8($t0)


    la $t0, direction
    li $t1, 180
    sb $t1, 0($t0)
    sb $0, 1($t0)


    li $a0, 0x00000002
    jal add_cmd_move
    li $a0, 0x00000012
    jal add_cmd_move
    j main_start_to_walk

right:

    la $a0, layout
    sw $a0, GET_LAYOUT
    lw $a1, BOT_X
    lw $a2, BOT_Y
    la $a3, block
    jal check_layout

    la $a0, block
    la $a1, avil
    la $a2, order
    la $a3, request_arr
    jal check_avil

    lw $a0, BOT_X
    la $a1, current_order_arr
    jal get_current_order


    la $a0, order
    jal request_decode

    la $a0, block
    la $a1, foodid
    jal check_foodid


    la $t0, keypoint
    li $t1, 0x000000d3
    sb $t1, 0($t0)
    li $t1, 0x000000d7
    sb $t1, 1($t0)
    li $t1, 0x000000db
    sb $t1, 2($t0)
    li $t1, 0x000000c3
    sb $t1, 3($t0)
    li $t1, 0x00000093
    sb $t1, 4($t0)
    li $t1, 0x00000083
    sb $t1, 5($t0)
    li $t1, 0x00000087
    sb $t1, 6($t0)
    li $t1, 0x0000008b
    sb $t1, 7($t0)
    li $t1, 0x0000008d
    sb $t1, 8($t0)

    la $t0, direction
    li $t1, 180
    sb $t1, 1($t0)
    sb $0, 0($t0)

    li $a0, 0x000000E2
    jal add_cmd_move

    li $a0, 0x000000D2
    jal add_cmd_move


main_start_to_walk:
    la $t0, keypoint
    lbu $a0, 0($t0)
    jal add_cmd_move

    la $t0, direction
    lbu $a0, 0($t0)
    jal add_cmd_turn

    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick

    la $t0, keypoint
    lbu $a0, 5($t0)
    jal add_cmd_move

    la $t0, direction
    lbu $a0, 1($t0)
    jal add_cmd_turn

    la $t0, foodid
    lw $a0, 0($t0)
    jal add_cmd_drop

    jal add_cmd_drop

    jal add_cmd_drop

    jal add_cmd_drop


    la $t0, block
    lbu $a0, 0($t0)
    la $a1, order
    jal take_ingre_times
    move $t4, $v0
  ingre_from_bin1_loop:
    ble    $t4, $0, ingre_from_bin2  # if  <  then
    la $t0, keypoint
    lbu $a0, 0($t0)
    jal add_cmd_move

    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick

    la $t0, keypoint
    lbu $a0, 5($t0)
    jal add_cmd_move

    la $t0, direction
    lbu $a0, 1($t0)
    jal add_cmd_turn
    la $t0, foodid
    lw $a0, 0($t0)
    jal add_cmd_drop
    jal add_cmd_drop
    jal add_cmd_drop
    jal add_cmd_drop
    sub $t4, $t4, 1
    j ingre_from_bin1_loop
  ingre_from_bin2:
    la $t0, keypoint
    lbu $a0, 1($t0)
    jal add_cmd_move

    la $t0, direction
    lbu $a0, 0($t0)
    jal add_cmd_turn

    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick

    la $t0, keypoint
    lbu $a0, 6($t0)
    jal add_cmd_move

    la $t0, direction
    lbu $a0, 1($t0)
    jal add_cmd_turn

    la $t0, foodid
    lw $a0, 4($t0)
    jal add_cmd_drop

    jal add_cmd_drop

    jal add_cmd_drop

    jal add_cmd_drop

    la $t0, block
    lbu $a0, 1($t0)
    la $a1, order
    jal take_ingre_times
    move $t4, $v0
  ingre_from_bin2_loop:
    ble    $t4, $0, ingre_from_bin3  # if  <  then

    la $t0, keypoint
    lbu $a0, 1($t0)
    jal add_cmd_move

    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick

    la $t0, keypoint
    lbu $a0, 6($t0)
    jal add_cmd_move

    la $t0, direction
    lbu $a0, 1($t0)
    jal add_cmd_turn

    la $t0, foodid
    lw $a0, 4($t0)
    jal add_cmd_drop
    jal add_cmd_drop
    jal add_cmd_drop
    jal add_cmd_drop
    sub $t4, $t4, 1
    j ingre_from_bin2_loop


  ingre_from_bin3:
    la $t0, keypoint
    lbu $a0, 2($t0)
    jal add_cmd_move

    la $t0, direction
    lbu $a0, 0($t0)
    jal add_cmd_turn

    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick

    la $t0, keypoint
    lbu $a0, 7($t0)
    jal add_cmd_move

    la $t0, direction
    lbu $a0, 1($t0)
    jal add_cmd_turn

    la $t0, foodid
    lw $a0, 8($t0)
    jal add_cmd_drop

    jal add_cmd_drop

    jal add_cmd_drop

    jal add_cmd_drop

    la $t0, block
    lbu $a0, 2($t0)
    la $a1, order
    jal take_ingre_times
    move $t4, $v0
  ingre_from_bin3_loop:
    ble    $t4, $0, processing  # if  <  then

    la $t0, keypoint
    lbu $a0, 2($t0)
    jal add_cmd_move

    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick

    la $t0, keypoint
    lbu $a0, 7($t0)
    jal add_cmd_move

    la $t0, direction
    lbu $a0, 1($t0)
    jal add_cmd_turn

    la $t0, foodid
    lw $a0, 8($t0)
    jal add_cmd_drop
    jal add_cmd_drop
    jal add_cmd_drop
    jal add_cmd_drop
    sub $t4, $t4, 1
    j ingre_from_bin3_loop
processing:
    la $t0, keypoint
    lbu $a0, 5($t0)
    jal add_cmd_move

    la $t0, direction
    lbu $a0, 1($t0)
    jal add_cmd_turn

    la $a0, counter
    jal counter_decode

    la $t0, direction
    lbu $a0, 1($t0)
    jal add_cmd_turn

    la $t0, block
    lbu $t1, 3($t0) # t1: block[3]
    lbu $t2, 4($t0) # t1: block[4]


    ## turn in order
    #jal add_cmd_batch_turnin


#########################################################################################

move_thread:





############################# Main Thread ##############################################3

main_thread:  #Endless loop
    jal cmd_thread
    jal puzzle_thread
    jal decision_thread
    j main_thread

############################## Decision Thread ############################################
decision_thread:
    sub $sp, $sp, 8
    sw $ra, 0($sp)
    sw $t0, 4($sp)
    srl $t0, $t9, 30

    bne $t0, 2, decision_thread_return #exit if the robot is moving
    #Is robot near counter 120<bot_x<180
    lw $t0, BOT_X
    ble $t0, 120, decision_thread_next_loop
    bge $t0, 180, decision_thread_next_loop
    lw $t0, BOT_Y
    bge $t0, 250, decision_thread_try_turn_in



    la $a0, counter
    jal counter_decode
    j decision_thread_process
decision_thread_next_loop: #pick up from bin and all over again
    jal add_cmd_batch_take_ingrediants
    j decision_thread_return
decision_thread_process:
# meat
    la $t0, counter
    lw $t0, 36($t0)
    ble $t0, 4, decision_thread_process_meat
    li $t0, 4
decision_thread_process_meat:
    ble $t0, 0, decision_thread_process_meat_end
    li $a0, 0x00020000
    move $a1, $t0
    jal add_cmd_batch_process
    #j decision_thread_return
decision_thread_process_meat_end:
# tomato
    la $t0, counter
    lw $t0, 24($t0)
    ble $t0, 4, decision_thread_process_tomato
    li $t0, 4
decision_thread_process_tomato:
    ble $t0, 0, decision_thread_process_tomato_end
    li $a0, 0x00030000
    move $a1, $t0
    jal add_cmd_batch_process
    #j decision_thread_return
decision_thread_process_tomato_end:
# wash lettuce
    la $t0, counter
    lw $t0, 8($t0)
    ble $t0, 4, decision_thread_process_lettuce_wash
    li $t0, 4
decision_thread_process_lettuce_wash:
    ble $t0, 0, decision_thread_process_lettuce_wash_end
    li $a0, 0x00050000
    move $a1, $t0
    jal add_cmd_batch_process
    #j decision_thread_return
decision_thread_process_lettuce_wash_end:
# onion
    la $t0, counter
    lw $t0, 16($t0)
    ble $t0, 4, decision_thread_process_onion
    li $t0, 4
decision_thread_process_onion:
    ble $t0, 0, decision_thread_process_onion_end
    li $a0, 0x00040000
    move $a1, $t0
    jal add_cmd_batch_process
    #j decision_thread_return
decision_thread_process_onion_end:

# cut lettuce
    la $t0, counter
    lw $t0, 4($t0)
    ble $t0, 4, decision_thread_process_lettuce_cut
    li $t0, 4
decision_thread_process_lettuce_cut:
    ble $t0, 0, decision_thread_process_lettuce_cut_end
    li $a0, 0x00050001
    move $a1, $t0
    jal add_cmd_batch_process
decision_thread_process_lettuce_cut_end:

    la $t0, cmd_queue_head
    la $t1, cmd_queue_tail
    lw $t0, 0($t0)
    lw $t1, 0($t1)
    bne $t0, $t1, decision_thread_return
decision_process_finish:
    #if cannot process then go to turn in keypoint
    jal add_cmd_batch_take_ingrediants
    j decision_thread_return

decision_thread_try_turn_in:
    jal add_cmd_batch_turnin

decision_thread_return:
    lw $ra, 0($sp)
    lw $t0, 4($sp)
    add $sp, $sp, 8
    jr $ra




################# Helper Function #########################################

turnin_all: ## turn in lettuce onions tomato meat cheese bread
  sub $sp, $sp, 32
  sw $ra, 0($sp)
  sw $t0, 4($sp)
  sw $t1, 8($sp)
  sw $t2, 12($sp)
  sw $t3, 16($sp)
  sw $t4, 20($sp)
  sw $t5, 24($sp)
  sw $t6, 28($sp)
  # a0: one_order
  lw $t0, 0($a0) #lettuce to take
  lw $t1, 12($a0) #onion to take
  lw $t2, 20($a0) #tomato to take
  lw $t3, 32($a0) #meat to take
  lw $t4, 40($a0) #cheese to take
  lw $t5, 44($a0) # bread to take

turnin_lettuce_loop:
  ble $t0, 0, turnin_lettuce_complete
  bge $t0, 4, turnin_lettuce_4_times
turnin_lettuce_less_than_4_loop:
  la $a0, direction
  lbu $a0, 1($a0)
  jal exec_cmd_turn
  ble $t0, 0, turnin_lettuce_complete
  li  $a0, 0x00050002
  jal exec_cmd_pick
  la $a0, 90
  jal exec_cmd_turn
  li $a0, 0x00050002
  jal exec_cmd_drop
  sub $t0, $t0, 1
  j turnin_lettuce_less_than_4_loop
turnin_lettuce_less_than_4_loop_end:
  j turnin_lettuce_loop
turnin_lettuce_4_times:
  la $a0, direction
  lbu $a0, 1($a0)
  jal exec_cmd_turn
  li $a0, 0x00050002
  jal exec_cmd_pick
  jal exec_cmd_pick
  jal exec_cmd_pick
  jal exec_cmd_pick
  la $a0, 90
  jal exec_cmd_turn
  li $a0, 0x00050002
  jal exec_cmd_drop
  jal exec_cmd_drop
  jal exec_cmd_drop
  jal exec_cmd_drop
  sub $t0, $t0, 4
  j turnin_lettuce_loop
turnin_lettuce_complete:


turnin_onion_loop:
  ble $t1, 0, turnin_onion_complete
  bge $t1, 4, turnin_onion_4_times
turnin_onion_less_than_4_loop:
  ble $t1, 0, turnin_onion_less_than_4_loop_end
  la $a0, direction
  lbu $a0, 1($a0)
  jal exec_cmd_turn
  li  $a0, 0x00040001
  jal exec_cmd_pick
  la $a0, 90
  jal exec_cmd_turn
  li $a0, 0x00040001
  jal exec_cmd_drop
  sub $t1, $t1, 1
  j turnin_onion_less_than_4_loop
turnin_onion_less_than_4_loop_end:
  j turnin_onion_loop
turnin_onion_4_times:
  la $a0, direction
  lbu $a0, 1($a0)
  jal exec_cmd_turn
  li $a0, 0x00040001
  jal exec_cmd_pick
  jal exec_cmd_pick
  jal exec_cmd_pick
  jal exec_cmd_pick
  la $a0, 90
  jal exec_cmd_turn
  li $a0, 0x00040001
  jal exec_cmd_drop
  jal exec_cmd_drop
  jal exec_cmd_drop
  jal exec_cmd_drop

  sub $t1, $t1, 4
  j turnin_onion_loop
turnin_onion_complete:


turnin_tomato_loop:
  ble $t2, 0, turnin_tomato_complete
  bge $t2, 4, turnin_tomato_4_times
turnin_tomato_less_than_4_loop:
  ble $t2, 0, turnin_tomato_complete
  la $a0, direction
  lbu $a0, 1($a0)
  jal exec_cmd_turn
  li  $a0, 0x00030001
  jal exec_cmd_pick
  la $a0, 90
  jal exec_cmd_turn
  li $a0, 0x00030001
  jal exec_cmd_drop
  sub $t2, $t2, 1
  j turnin_tomato_less_than_4_loop
turnin_tomato_less_than_4_loop_end:
  j turnin_tomato_loop
turnin_tomato_4_times:
  la $a0, direction
  lbu $a0, 1($a0)
  jal exec_cmd_turn
  li $a0, 0x00030001
  jal exec_cmd_pick
  jal exec_cmd_pick
  jal exec_cmd_pick
  jal exec_cmd_pick
  la $a0, 90
  jal exec_cmd_turn
  li $a0, 0x00030001
  jal exec_cmd_drop
  jal exec_cmd_drop
  jal exec_cmd_drop
  jal exec_cmd_drop
  sub $t2, $t2, 4
  j turnin_tomato_loop
turnin_tomato_complete:


turnin_meat_loop:
  ble $t3, 0, turnin_meat_complete
  bge $t3, 4, turnin_meat_4_times
turnin_meat_less_than_4_loop:
  ble $t3, 0, turnin_meat_complete
  la $a0, direction
  lbu $a0, 1($a0)
  jal exec_cmd_turn
  li  $a0, 0x00020001
  jal exec_cmd_pick
  la $a0, 90
  jal exec_cmd_turn
  li $a0, 0x00020001
  jal exec_cmd_drop

  sub $t3, $t3, 1
  j turnin_meat_less_than_4_loop
turnin_meat_less_than_4_loop_end:
  j turnin_meat_loop
turnin_meat_4_times:
  la $a0, direction
  lbu $a0, 1($a0)
  jal exec_cmd_turn
  li $a0, 0x00020001
  jal exec_cmd_pick
  jal exec_cmd_pick
  jal exec_cmd_pick
  jal exec_cmd_pick
  la $a0, 90
  jal exec_cmd_turn
  li $a0, 0x00020001
  jal exec_cmd_drop
  jal exec_cmd_drop
  jal exec_cmd_drop
  jal exec_cmd_drop

  sub $t3, $t3, 4
  j turnin_meat_loop
turnin_meat_complete:

turnin_cheese_loop:
  ble $t4, 0, turnin_cheese_complete
  bge $t4, 4, turnin_cheese_4_times
turnin_cheese_less_than_4_loop:
  ble $t4, 0, turnin_cheese_complete
  la $a0, direction
  lbu $a0, 1($a0)
  jal exec_cmd_turn
  li  $a0, 0x00010000
  jal exec_cmd_pick
  la $a0, 90
  jal exec_cmd_turn
  li $a0, 0x00010000
  jal exec_cmd_drop
  sub $t4, $t4, 1
  j turnin_cheese_less_than_4_loop
turnin_cheese_less_than_4_loop_end:
  j turnin_cheese_loop
turnin_cheese_4_times:
  la $a0, direction
  lbu $a0, 1($a0)
  jal exec_cmd_turn
  li $a0, 0x00010000
  jal exec_cmd_pick
  jal exec_cmd_pick
  jal exec_cmd_pick
  jal exec_cmd_pick
  la $a0, 90
  jal exec_cmd_turn
  li $a0, 0x00010000
  jal exec_cmd_drop
  jal exec_cmd_drop
  jal exec_cmd_drop
  jal exec_cmd_drop
  sub $t4, $t4, 4
  j turnin_cheese_loop
turnin_cheese_complete:

turnin_bread_loop:
  ble $t5, 0, turnin_bread_complete
  bge $t5, 4, turnin_bread_4_times
turnin_bread_less_than_4_loop:
  ble $t5, 0, turnin_bread_less_than_4_loop_end
  la $a0, direction
  lbu $a0, 1($a0)
  jal exec_cmd_turn
  li  $a0, 0x00000000
  jal exec_cmd_pick
  la $a0, 90
  jal exec_cmd_turn
  li $a0, 0x00000000
  jal exec_cmd_drop

  sub $t5, $t5, 1
  j turnin_bread_less_than_4_loop
turnin_bread_less_than_4_loop_end:
  j turnin_bread_loop
turnin_bread_4_times:
  la $a0, direction
  lbu $a0, 1($a0)
  jal exec_cmd_turn
  li $a0, 0x00000000
  jal exec_cmd_pick
  jal exec_cmd_pick
  jal exec_cmd_pick
  jal exec_cmd_pick
  la $a0, 90
  jal exec_cmd_turn
  li $a0, 0x00000000
  jal exec_cmd_drop
  jal exec_cmd_drop
  jal exec_cmd_drop
  jal exec_cmd_drop

  sub $t5, $t5, 4
  j turnin_bread_loop
turnin_bread_complete:

  lw $ra, 0($sp)
  lw $t0, 4($sp)
  lw $t1, 8($sp)
  lw $t2, 12($sp)
  lw $t3, 16($sp)
  lw $t4, 20($sp)
  lw $t5, 24($sp)
  lw $t6, 28($sp)
  add $sp, $sp, 32
  jr $ra



## $a0 one_order   return 1: can complete 0: cant complete
CanComplete:
  sub $sp, $sp,20
  sw $ra, 0($sp)
  sw $t0, 4($sp)
  sw $t1, 8($sp)
  sw $t2, 12($sp)
  sw $t3, 16($sp)

  li $v0, 1 # can Complete
  la $t1, counter

  ## lettuce
  lw $t2, 0($t1) # lettuce on counter
  lw $t3, 0($a0) # lettuce required
  ble $t3, $t2, CanComplete_lettuce_ok
  li $v0, 0 # cant Complete
CanComplete_lettuce_ok:
  ## onions
  lw $t2, 12($t1) # onion on counter
  lw $t3, 12($a0) # onion required
  ble $t3, $t2, CanComplete_onion_ok
  li $v0, 0 # cant Complete
CanComplete_onion_ok:
  ## tomato
  lw $t2, 20($t1) # tomato on counter
  lw $t3, 20($a0) # tomato required
  ble $t3, $t2, CanComplete_tomato_ok
  li $v0, 0 # cant Complete
CanComplete_tomato_ok:
  ## meat
  lw $t2, 32($t1) # meat on counter
  lw $t3, 32($a0) # meat required
  ble $t3, $t2, CanComplete_meat_ok
  li $v0, 0 # cant Complete
CanComplete_meat_ok:
  ## cheese
  lw $t2, 40($t1) # cheese on counter
  lw $t3, 40($a0) # cheese required
  ble $t3, $t2, CanComplete_cheese_ok
  li $v0, 0 # cant Complete
CanComplete_cheese_ok:
  ## bread
  lw $t2, 44($t1) # bread on counter
  lw $t3, 44($a0) # bread required
  ble $t3, $t2, CanComplete_bread_ok
  li $v0, 0 # cant Complete
CanComplete_bread_ok:

  lw $ra, 0($sp)
  lw $t0, 4($sp)
  lw $t1, 8($sp)
  lw $t2, 12($sp)
  lw $t3, 16($sp)
  add $sp, $sp, 20
  jr $ra

  get_current_order:
        sub $sp, $sp, 40
        sw $ra, 0($sp)
        sw $a0, 4($sp)
        sw $a1, 8($sp)
        sw $t0, 12($sp)
        sw $t1, 16($sp)
        sw $t2, 20($sp)
        sw $t3, 24($sp)
        sw $t4, 28($sp)
        sw $t5, 32($sp)
        sw $t6, 36($sp)

        bge     $a1, 150, get_current_order_right    # if $a1 !=  then
        la $t0 turnin_order
        sw $t0, GET_TURNIN_ORDER
        lw $t1, 20($t0) # hi
        lw $t2, 16($t0) # lo
        li $t0, 0 # i
    loop_lo_encode_current_left:
        bge     $t0, 6, middle_bit_encode_current_left   # if  >=  then
        and $t4, $t2, 0x0000001f #lo & 0x0000001f
        sll $t5, $t0, 2
        add $t5, $t5, $a1 # order[]
        sw $t4, 0($t5)
    lo_count_encode_current_left:
        srl $t2, $t2, 5
        add $t0, $t0, 1
        j loop_lo_encode_current_left
    middle_bit_encode_current_left:     # could start to reuse t0, t3-t8
        sll $t3, $t1, 2
        and $t3, $t3, 0x0000001f # $t3 is upper_three_bits cannot be rewritten!!!
        or $t4, $t3, $t2
        sw $t4, 24($a1)
    shift_hi_current_left:
        srl $t1, $t1, 3
        li $t0, 7
    loop_hi_encode_current_left:      # could start to reuse t4-8
        bgt     $t0, 11, get_current_order_right   # if  >=  then
        and $t4, $t1, 0x0000001f # hi & 0x0000001f
        sll $t6, $t0, 2
        add $t6, $t6, $a1 # order[i] address
        sw $t4, 0($t6)
    hi_count_encode_current_left:
        srl $t1, $t1, 5
        add $t0, $t0, 1
        j loop_hi_encode_current_left
    get_current_order_right:
        la $t0 turnin_order
        sw $t0, GET_TURNIN_ORDER
        lw $t1, 4($t0) # hi
        lw $t2, 0($t0) # lo
        li $t0, 0 # i
    loop_lo_encode_current_right:
        bge     $t0, 6, middle_bit_encode_current_right   # if  >=  then
        and $t4, $t2, 0x0000001f #lo & 0x0000001f
        sll $t5, $t0, 2
        add $t5, $t5, $a1 # order[]
        sw $t4, 0($t5)
    lo_count_encode_current_right:
        srl $t2, $t2, 5
        add $t0, $t0, 1
        j loop_lo_encode_current_right
    middle_bit_encode_current_right:     # could start to reuse t0, t3-t8
        sll $t3, $t1, 2
        and $t3, $t3, 0x0000001f # $t3 is upper_three_bits cannot be rewritten!!!
        or $t4, $t3, $t2
        sw $t4, 24($a1)
    shift_hi_current_right:
        srl $t1, $t1, 3
        li $t0, 7
    loop_hi_encode_current_right:      # could start to reuse t4-8
        bgt     $t0, 11, get_current_order_done   # if  >=  then
        and $t4, $t1, 0x0000001f # hi & 0x0000001f
        sll $t6, $t0, 2
        add $t6, $t6, $a1 # order[i] address
        sw $t4, 0($t6)
    hi_count_encode_current_right:
        srl $t1, $t1, 5
        add $t0, $t0, 1
        j loop_hi_encode_current_right
    get_current_order_done:
        lw $ra, 0($sp)
        lw $a0, 4($sp)
        lw $a1, 8($sp)
        lw $t0, 12($sp)
        lw $t1, 16($sp)
        lw $t2, 20($sp)
        lw $t3, 24($sp)
        lw $t4, 28($sp)
        lw $t5, 32($sp)
        lw $t6, 36($sp)
        add $sp, $sp, 40
        jr $ra

add_cmd_batch_take_ingrediants:
    sub $sp, $sp, 28
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $t0, 8($sp)
    sw $t1, 12($sp)
    sw $t2, 16($sp)
    sw $t3, 20($sp)
    sw $t4, 24($sp)
add_cmd_batch_take_ingrediants_main_start_to_walk:
    la $t0, keypoint
    lbu $a0, 0($t0)
    jal add_cmd_move

    la $t0, direction
    lbu $a0, 0($t0)
    jal add_cmd_turn
    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick

    la $t0, keypoint
    lbu $a0, 5($t0)
    jal add_cmd_move

    la $t0, direction
    lbu $a0, 1($t0)
    jal add_cmd_turn

    la $t0, foodid
    lw $a0, 0($t0)
    jal add_cmd_drop
    jal add_cmd_drop
    jal add_cmd_drop
    jal add_cmd_drop

    la $t0, block
    lbu $a0, 0($t0)
    la $a1, order
    jal take_ingre_times
    move $t4, $v0

    la $t1, block
    lbu $t1, 0($t1)
    bne $t1, 7, add_cmd_batch_take_ingrediants_ingre_from_bin1_loop
    add $t4, $t4, 1

  add_cmd_batch_take_ingrediants_ingre_from_bin1_loop:
    ble    $t4, $0, add_cmd_batch_take_ingrediants_ingre_from_bin2  # if  <  then
    la $t0, keypoint
    lbu $a0, 0($t0)
    jal add_cmd_move

    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick

    la $t0, keypoint
    lbu $a0, 5($t0)
    jal add_cmd_move

    la $t0, direction
    lbu $a0, 1($t0)
    jal add_cmd_turn
    la $t0, foodid
    lw $a0, 0($t0)
    jal add_cmd_drop
    jal add_cmd_drop
    jal add_cmd_drop
    jal add_cmd_drop
    sub $t4, $t4, 1
    j add_cmd_batch_take_ingrediants_ingre_from_bin1_loop


  add_cmd_batch_take_ingrediants_ingre_from_bin2:
    la $t0, keypoint
    lbu $a0, 1($t0)
    jal add_cmd_move

    la $t0, direction
    lbu $a0, 0($t0)
    jal add_cmd_turn

    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick

    la $t0, keypoint
    lbu $a0, 6($t0)
    jal add_cmd_move

    la $t0, direction
    lbu $a0, 1($t0)
    jal add_cmd_turn
# add_cmd_batch_take_ingrediants:
    la $t0, foodid
    lw $a0, 4($t0)
    jal add_cmd_drop

    jal add_cmd_drop

    jal add_cmd_drop

    jal add_cmd_drop

    la $t0, block
    lbu $a0, 1($t0)
    la $a1, order
    jal take_ingre_times
    move $t4, $v0

    la $t1, block
    lbu $t1, 1($t1)
    bne $t1, 7, add_cmd_batch_take_ingrediants_ingre_from_bin2_loop
    add $t4, $t4, 1

  add_cmd_batch_take_ingrediants_ingre_from_bin2_loop:
    ble    $t4, $0, add_cmd_batch_take_ingrediants_ingre_from_bin3  # if  <  then

    la $t0, keypoint
    lbu $a0, 1($t0)
    jal add_cmd_move

    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick

    la $t0, keypoint
    lbu $a0, 6($t0)
    jal add_cmd_move

    la $t0, direction
    lbu $a0, 1($t0)
    jal add_cmd_turn

    la $t0, foodid
    lw $a0, 4($t0)
    jal add_cmd_drop
    jal add_cmd_drop
    jal add_cmd_drop
    jal add_cmd_drop
    sub $t4, $t4, 1
    j add_cmd_batch_take_ingrediants_ingre_from_bin2_loop


  add_cmd_batch_take_ingrediants_ingre_from_bin3:
    la $t0, keypoint
    lbu $a0, 2($t0)
    jal add_cmd_move

    la $t0, direction
    lbu $a0, 0($t0)
    jal add_cmd_turn

    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick

    la $t0, keypoint
    lbu $a0, 7($t0)
    jal add_cmd_move

    la $t0, direction
    lbu $a0, 1($t0)
    jal add_cmd_turn

    la $t0, foodid
    lw $a0, 8($t0)
    jal add_cmd_drop

    jal add_cmd_drop

    jal add_cmd_drop

    jal add_cmd_drop

    la $t0, block
    lbu $a0, 2($t0)
    la $a1, order
    jal take_ingre_times
    move $t4, $v0

    la $t1, block
    lbu $t1, 2($t1)
    bne $t1, 7, add_cmd_batch_take_ingrediants_ingre_from_bin3_loop
    add $t4, $t4, 1
  add_cmd_batch_take_ingrediants_ingre_from_bin3_loop:
    ble    $t4, $0, add_cmd_batch_take_ingrediants_processing  # if  <  then

    la $t0, keypoint
    lbu $a0, 2($t0)
    jal add_cmd_move

    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick
    jal add_cmd_pick

    la $t0, keypoint
    lbu $a0, 7($t0)
    jal add_cmd_move

    la $t0, direction
    lbu $a0, 1($t0)
    jal add_cmd_turn

    la $t0, foodid
    lw $a0, 8($t0)
    jal add_cmd_drop
    jal add_cmd_drop
    jal add_cmd_drop
    jal add_cmd_drop
    sub $t4, $t4, 1
    j add_cmd_batch_take_ingrediants_ingre_from_bin3_loop
add_cmd_batch_take_ingrediants_processing:
    la $t0, keypoint
    lbu $a0, 5($t0)
    jal add_cmd_move

    la $t0, direction
    lbu $a0, 1($t0)
    jal add_cmd_turn

    la $a0, counter
    jal counter_decode

    la $t0, direction
    lbu $a0, 1($t0)
    jal add_cmd_turn

    lw $ra, 0($sp)
    lw $a0, 4($sp)
    lw $t0, 8($sp)
    lw $t1, 12($sp)
    lw $t2, 16($sp)
    lw $t3, 20($sp)
    lw $t4, 24($sp)
    add $sp, $sp, 28

    jr $ra
#################################################
#oven: 4; sink: 5; chopping board: 6
#a0: foodid+preparationLevel; a1: num of times
add_cmd_batch_process:
    sub $sp, $sp, 20
    sw $ra, 0($sp)
    sw $t0, 4($sp)
    sw $t1, 8($sp)
    sw $t2, 12($sp)
    sw $t3, 16($sp)

    #Find position of appliance
    #Find The debug id of appliance
    srl $t0, $a0, 16 #food id
    and $t1, $a0, 0x0000FFFF #preparation level
    #t2 is debug id; $t3 is process time
#check tomato
    bne $t0, 3, add_cmd_batch_process_check_lettuce
    bne $t1, $0, add_cmd_batch_process_return
    li $t2, 5
    li $t3, 40000
    j add_cmd_batch_process_check_appliance
#check lettuce
add_cmd_batch_process_check_lettuce:
    bne $t0, 5, add_cmd_batch_process_check_onion
    bne $t1, $0, add_cmd_batch_process_check_lettuce_level_1
    li $t2, 5
    li $t3, 40000
    j add_cmd_batch_process_check_appliance
add_cmd_batch_process_check_lettuce_level_1:
    bne $t1, 1, add_cmd_batch_process_return
    li $t2, 6
    li $t3, 40000
    j add_cmd_batch_process_check_appliance
#check onion
add_cmd_batch_process_check_onion:
    bne $t0, 4, add_cmd_batch_process_check_meat
    bne $t1, 0, add_cmd_batch_process_return
    li $t2, 6
    li $t3, 40000
    j add_cmd_batch_process_check_appliance
#check meat
add_cmd_batch_process_check_meat:
    bne $t0, 2, add_cmd_batch_process_return
    bne $t1, 0, add_cmd_batch_process_return
    li $t2, 4
    li $t3, 100000
add_cmd_batch_process_check_appliance:
    la $t0, block
    lbu $t1, 3($t0)
#check block 3
    bne $t2, $t1, add_cmd_batch_process_check_block_4
    li $t1, 3
    j add_cmd_batch_process_add_pick_cmd
#check block 4
add_cmd_batch_process_check_block_4:
    lbu $t1, 4($t0)
    bne $t2, $t1, add_cmd_batch_process_return
    move $t0, $a0
    li $t1, 4
add_cmd_batch_process_add_pick_cmd:
    li $t0, 0
    move $t2, $a1
add_cmd_batch_process_add_pick_cmd_loop:
    bge $t0, $t2, add_cmd_batch_process_add_move_cmd
    jal add_cmd_pick
    add $t0, $t0, 1
    j add_cmd_batch_process_add_pick_cmd_loop
add_cmd_batch_process_add_move_cmd:
    move $t0, $a0
    la $a0, keypoint
    add $a0, $t1, $a0
    lbu $a0, 0($a0)
    jal add_cmd_move
    move $a0, $t0
add_cmd_batch_process_add_turn_cmd:
#Add turn north cmd
    move $t0, $a0
    li $a0, 270
    jal add_cmd_turn
    move $a0, $t0
#In a loop, add cmd of drop and wait_and_pick
    li $t0, 0
add_cmd_batch_process_loop:
    bge $t0, $t2, add_cmd_batch_process_go_back
    jal add_cmd_drop
    move $t1, $a0
    move $a0, $t3
    jal add_cmd_wait_and_pick
    move $a0, $t1
    add $t0, $t0, 1
    j add_cmd_batch_process_loop
add_cmd_batch_process_go_back:
    move $t3, $a0
    la $a0, keypoint
    lbu $a0, 5($a0)
    jal add_cmd_move
    lw $a0, ANGLE
    jal add_cmd_turn
    li $t0, 0
    move $a0, $t3 #a0 is the original a0: foodid+level
    add $a0, $a0, 1
add_cmd_batch_process_drop_loop:
    bge $t0, $t2, add_cmd_batch_process_return
    jal add_cmd_drop
    add $t0, $t0, 1
    j add_cmd_batch_process_drop_loop

add_cmd_batch_process_return:
    lw $ra, 0($sp)
    lw $t0, 4($sp)
    lw $t1, 8($sp)
    lw $t2, 12($sp)
    lw $t3, 16($sp)
    add $sp, $sp, 20
    jr $ra


add_cmd_batch_turnin:
    sub $sp, $sp, 16
    sw $ra, 0($sp)
    sw $a0, 4($sp)
    sw $a1, 8($sp)
    sw $v0, 12($sp)




    la $a0, counter
    jal counter_decode

    lw $a0, BOT_X
    la $a1, current_order_arr
    jal get_current_order

    la $a0, current_order_arr
    jal CanComplete

    # li $v0, 1   # for debug
    #
    beq $v0, $0, add_cmd_batch_turnin_get_back_to_bin_1
greedy_turnin:
    la $a0, current_order_arr
    jal turnin_all

    li $a0, 90
    jal exec_cmd_turn
    sw $0, SUBMIT_ORDER

    la $a0, counter
    jal counter_decode

    lw $a0, BOT_X
    la $a1, current_order_arr
    jal get_current_order

    la $a0, current_order_arr
    jal CanComplete

    beq $v0, 1, greedy_turnin


add_cmd_batch_turnin_get_back_to_bin_1:


      lw $ra, 0($sp)
      lw $a0, 4($sp)
      lw $a1, 8($sp)
      lw $v0, 12($sp)
      add $sp, $sp, 16
      jr $ra




  ##########################

check_foodid:
			sub $sp, $sp, 24
			sw $ra, 0($sp)
			sw $t0, 4($sp)
			sw $t1, 8($sp)
			sw $t2, 12($sp)
			sw $s0, 16($sp)
			sw $s1, 20($sp)

			li $s0, 0 # i
		foodid_loop:
			bge $s0, 3, foodid_end
			add $t0, $a0, $s0
			lbu $t0, 0($t0) 					#t0 : block[i]
      sll $t2, $s0, 2
			add $t1, $a1, $t2 			#t1: &block_to_foodid[i]

		foodid_7:
			bne $t0, 7, foodid_9
			sw $0, 0($t1)
		foodid_9:
			bne $t0, 9, foodid_8
			li $t2, 0x00050000
			sw $t2, 0($t1)
		foodid_8:
			bne $t0, 8, foodid_11
			li $t2, 0x00020000
			sw $t2, 0($t1)
		foodid_11:
			bne $t0, 11, foodid_10
			li $t2, 0x00010000
			sw $t2, 0($t1)
		foodid_10:
			bne $t0, 10, foodid_12
			li $t2, 0x00030000
			sw $t2, 0($t1)
		foodid_12:
			bne $t0, 12, foodid_loop_end
			li $t2, 0x00040000
      sw $t2, 0($t1)
		foodid_loop_end:
			add $s0, $s0, 1
			j	foodid_loop
		foodid_end:

			lw $ra, 0($sp)
			lw $t0, 4($sp)
			lw $t1, 8($sp)
			lw $t2, 12($sp)
			lw $s0, 16($sp)
			lw $s1, 20($sp)
			add $sp, $sp, 24
			jr $ra


layout_cord:
    bne    $a0, 0, layout_right  # if $a0 !=  then
    sw $0, 0($a1)
    li $t0, 3
    sw $t0, 1($a1)
    sw $0, 2($a1)
    li $t0, 7
    sw $t0, 3($a1)
    sw $0, 4($a1)
    li $t0, 11
    sw $t0, 5($a1)
    li $t0, 2
    sw $t0, 6($a1)
    sw $t0, 7($a1)
    li $t1, 5
    sw $t1, 8($a1)
    sw $t0, 9($a1)
    j layout_cord_end
layout_right:
    li $t0, 14
    sw $t0, 0($a1)
    li $t1, 3
    sw $t1, 1($a1)
    sw $t0, 2($a1)
    li $t1, 7
    sw $t1, 3($a1)
    sw $t0, 4($a1)
    li $t1, 11
    sw $t1, 5($a1)
    li $t1, 9
    li $t2, 2
    sw $t1, 6($a1)
    sw $t2, 7($a1)
    li $t1, 12
    sw $t2, 9($a1)
    sw $t1, 8($a1)
layout_cord_end:
    jr $ra

# char[] check_layout(char[][] map, int bot_x, int bot_y, *block)
check_layout:
    sub $sp, $sp, 8
    sw $ra, 0($sp)
    sw $s0, 4($sp)


    bge     $a1, 150, layout_else    # if $a1 !=  then
    lbu $s0, 45($a0)        # write in blocks
    sb $s0, 0($a3)        # write in blocks
    lbu $s0, 105($a0)        # write in blocks
    sb $s0, 1($a3)        # write in blocks
    lbu $s0, 165($a0)        # write in blocks
    sb $s0, 2($a3)        # write in blocks
    lbu $s0, 32($a0)        # write in blocks
    sb $s0, 3($a3)        # write in blocks
    lbu $s0, 35($a0)        # write in blocks
    sb $s0, 4($a3)        # write in blocks


    j layout_done
layout_else:
    lbu $s0, 59($a0)        # write in blocks
    sb $s0, 0($a3)        # write in blocks
    lbu $s0, 119($a0)        # write in blocks
    sb $s0, 1($a3)        # write in blocks
    lbu $s0, 179($a0)        # write in blocks
    sb $s0, 2($a3)        # write in blocks
    lbu $s0, 42($a0)        # write in blocks
    sb $s0, 3($a3)        # write in blocks
    lbu $s0, 39($a0)        # write in blocks
    sb $s0, 4($a3)        # write in blocks
layout_done:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    add $sp, $sp, 8
    jr $ra

# void check_avil(char* block, char* avil, int* order)
check_avil:
    sub $sp, $sp, 64
    sw $ra, 0($sp)
    sw $s0, 4($sp) # request_lo
    sw $s1, 8($sp) # request_hi
    sw $t0, 12($sp)
    sw $t1, 16($sp)
    sw $t2, 20($sp)
    sw $t3, 24($sp)
    sw $t4, 28($sp)
    sw $t5, 32($sp)
    sw $t6, 36($sp)
    sw $t7, 40($sp)
    sw $s2, 44($sp)
    sw $s3, 48($sp)
    sw $s4, 52($sp)
    sw $s5, 56($sp)
    sw $t8, 60($sp)

    sb $0, 0($a1)    # initialize avil
  sb $0, 1($a1)    # initialize avil
  sb $0, 2($a1)    # initialize avil
  sb $0, 3($a1)    # initialize avil
  sb $0, 4($a1)    # initialize avil
  sb $0, 5($a1)    # initialize avil
  sb $0, 6($a1)    # initialize avil
  sb $0, 7($a1)    # initialize avil
  sb $0, 8($a1)    # initialize avil
  sb $0, 9($a1)    # initialize avil
  sb $0, 10($a1)    # initialize avil
  sb $0, 11($a1)    # initialize avil
  li $t1, 1
  li $t0, 0 #i
loop_avil_ingre:
  bge    $t0, 3, check_appliance  # if $t6 >=  then
  add $t2, $t0, $a0
  lbu $t2, 0($t2)
  bne    $t2, 7, check_meat  # if  !=  then
  sb $t1, 11($a1)
check_meat:
  bne    $t2, 8, check_lettuce  # if $t2 !=  then
  sb $t1, 9($a1)
check_lettuce:
  bne    $t2, 9, check_tomato  # if $t2 !9then
  sb $t1, 2($a1)
check_tomato:
  bne    $t2, 10, check_cheese  # if $t2 !10then
  sb $t1, 6($a1)
check_cheese:
  bne    $t2, 11, check_onion  # if $t2 !11then
  sb $t1, 10($a1)
check_onion:
  bne    $t2, 12, check_ingre_count  # if $t2 !12then
  sb $t1, 4($a1)  ## should be avil not block
check_ingre_count:
  add $t0, $t0, 1
  j loop_avil_ingre
check_appliance:
  li $t0, 3 # i
loop_avil_appliance:
  bgt    $t0, 4, check_avial_done  # if  >  then
  add $t2, $t0, $a0
  lbu $t2, 0($t2)
  bne    $t2, 4, check_sink  # if $t2 !4then
  sb $t1, 8($a1)
check_sink:
  bne    $t2, 5, check_cut  # if $t2 !5then
  sb $t1, 0($a1)
  sb $t1, 5($a1)
check_cut:
  bne    $t2, 6, check_appliance_count  # if $t2 !6then
  sb $t1, 1($a1)
  sb $t1, 3($a1)
check_appliance_count:
  add $t0, $t0, 1
  j loop_avil_appliance
check_avial_done:

    lw $t0, BOT_X
    bge    $t0, 150, order_encode_right  # if  >=  then

    la $t0 turnin_order
    sw $t0, GET_TURNIN_ORDER
    lw $t1, 20($t0) # hi
    lw $t2, 16($t0) # lo
    li $t0, 0 # i
loop_lo_encode:
    bge     $t0, 6, middle_bit_encode   # if  >=  then
    and $t4, $t2, 0x0000001f #lo & 0x0000001f
    sll $t5, $t0, 2
    add $t5, $t5, $a2 # order[]
    sw $t4, 0($t5)

lo_count_encode:
    srl $t2, $t2, 5
    add $t0, $t0, 1
    j loop_lo_encode
middle_bit_encode:     # could start to reuse t0, t3-t8
    sll $t3, $t1, 2
    and $t3, $t3, 0x0000001f # $t3 is upper_three_bits cannot be rewritten!!!
    or $t4, $t3, $t2
    sw $t4, 24($a2)

shift_hi:
    srl $t1, $t1, 3
    li $t0, 7
loop_hi_encode:      # could start to reuse t4-8
    bgt     $t0, 11, order_encode_right   # if  >=  then
    and $t4, $t1, 0x0000001f # hi & 0x0000001f
    sll $t6, $t0, 2
    add $t6, $t6, $a2 # order[i] address
    sw $t4, 0($t6)
hi_count_encode:
    srl $t1, $t1, 5
    add $t0, $t0, 1
    j loop_hi_encode

# encode_last_step:
#     beq     $t8, 0, last_step_else  # if $t8 ==  then
#     sll $s1, $s1, 3
order_encode_right:
    la $t0 turnin_order
    sw $t0, GET_TURNIN_ORDER
    lw $t1, 4($t0) # hi
    lw $t2, 0($t0) # lo
    li $t0, 0 # i

loop_lo_encode_right:
    bge     $t0, 6, middle_bit_encode_right   # if  >=  then
    and $t4, $t2, 0x0000001f #lo & 0x0000001f
    sll $t5, $t0, 2
    add $t5, $t5, $a2 # order[]
    sw $t4, 0($t5)

lo_count_encode_right:
    srl $t2, $t2, 5
    add $t0, $t0, 1
    j loop_lo_encode_right
middle_bit_encode_right:     # could start to reuse t0, t3-t8
    sll $t3, $t1, 2
    and $t3, $t3, 0x0000001f # $t3 is upper_three_bits cannot be rewritten!!!
    or $t4, $t3, $t2
    sw $t4, 24($a2)

shift_hi_right:
    srl $t1, $t1, 3
    li $t0, 7
loop_hi_encode_right:      # could start to reuse t4-8
    bgt     $t0, 11, order_encode_done   # if  >=  then
    and $t4, $t1, 0x0000001f # hi & 0x0000001f
    sll $t6, $t0, 2
    add $t6, $t6, $a2 # order[i] address
    sw $t4, 0($t6)
hi_count_encode_right:
    srl $t1, $t1, 5
    add $t0, $t0, 1
    j loop_hi_encode_right
order_encode_done:








    # completing missing elements of order
    lw $t0, 0($a2)
    sw $t0, 4($a2)
    sw $t0, 8($a2)
    lw $t0, 12($a2)
    sw $t0, 16($a2)
    lw $t0, 20($a2)
    sw $t0, 24($a2)
    lw $t0, 32($a2)
    sw $t0, 36($a2)

    li $t0, 0 #i
loop_order_to_request:
    bge    $t0, 12, done_order_to_request  # if  >=12hen
    add $t1, $t0, $a1
    lbu $t1, 0($t1)
    sll $t2, $t0, 2
    add $t2, $t2, $a3
    sll $t4, $t0, 2
    add $t4, $t4, $a2
    bne    $t1, $0, order_to_request_count  # if $t1 !=0then
    lw $t3, 0($t4)
    sw $t3, 0($t2)
order_to_request_count:
    add $t0, $t0, 1
    j loop_order_to_request
done_order_to_request:
li $t0, 11 #i

loop_encode_request_hi:
ble    $t0, 6, loop_encode_request_middle  # if  <  then
sll $t1, $t0, 2
add $t2, $t1, $a3
lw $t2, 0($t2)
sll $s1, $s1, 5
add $s1, $s1, $t2
sub $t0, $t0, 1
j    loop_encode_request_hi        # jump to loop_encode_request_hi
loop_encode_request_middle:
sll $s1, $s1, 3
lw $t2, 24($a3)
srl $t2, $t2, 2
add $s1, $s1, $t2
li $t0, 5
loop_encode_request_lo:
blt    $t0, 0, loop_encode_done  # if  <  then
sll $t1, $t0, 2
add $t2, $t1, $a3
lw $t2, 0($t2)
sll $s0, $s0, 5
add $s0, $s0, $t2
sub $t0, $t0, 1
j    loop_encode_request_lo
loop_encode_done:


and $s0, $s0, 0x3fffffff
lw $t0, 24($a3)
and $t0, $t0, 0xc0000000
add $s0, $s0, $t0

    la $t0, request_our
    sw $s0, 0($t0) # SET_REQUEST
    sw $s1, 4($t0) # SET_REQUEST
    sw $t0, SET_REQUEST # SET_REQUEST

    lw $ra, 0($sp)
    lw $s0, 4($sp) # request_lo
    lw $s1, 8($sp) # request_hi
    lw $t0, 12($sp)
    lw $t1, 16($sp)
    lw $t2, 20($sp)
    lw $t3, 24($sp)
    lw $t4, 28($sp)
    lw $t5, 32($sp)
    lw $t6, 36($sp)
    lw $t7, 40($sp)
    lw $s2, 44($sp)
    lw $s3, 48($sp)
    lw $s4, 52($sp)
    lw $s5, 56($sp)
    lw $t8, 60($sp)
    add $sp, $sp, 64
    jr $ra




    # decode their request
request_decode:
    la $t0, request_order
    sw $t0, GET_REQUEST
    lw $t1, 4($t0) # their_hi
    lw $t2, 0($t0) # their_lo
    li $t0, 0
loop_lo_decode:
    bge     $t0, 6, middle_bit_decode   # if  >=  then
    and $t3, $t2, 0x0000001f # their_lo & 0x0000001f
    sll $t4, $t0, 2
    add $t4, $t4, $a0 # order[i] address
    lw $t5, 0($t4)
    add $t5, $t5, $t3
    sw $t5, 0($t4)
    srl $t2, $t2, 5
    add $t0, $t0, 1
    j loop_lo_decode
middle_bit_decode:
    sll $t0, $t1, 2
    and $t0, $t0, 0x0000001f
    or $t0, $t0, $t2 #their_upper_three_bits | their_lo;
    lw $t3, 24($a0)
    add $t3, $t3, $t0
    sw $t3, 24($a0)
    srl $t1, $t1, 3
    li $t0, 7
loop_hi_decode:
    bgt     $t0, 11, decode_done    # if  >=  then
    and $t3, $t1, 0x0000001f # their_lo & 0x0000001f
    sll $t4, $t0, 2
    add $t4, $t4, $a0 # order[i] address
    lw $t5, 0($t4)
    add $t5, $t5, $t3
    sw $t5, 0($t4)
    srl $t1, $t1, 5
    add $t0, $t0, 1
    j loop_hi_decode
decode_done:
    jr $ra




counter_decode:
    la $t0, share_counter
    sw $t0, GET_SHARED
    lw $t1, 4($t0) # their_hi
    lw $t2, 0($t0) # their_lo
    li $t0, 0
loop_lo_counter_decode:
    bge     $t0, 6, middle_bit_counter_decode   # if  >=  then
    and $t3, $t2, 0x0000001f # their_lo & 0x0000001f
    sll $t4, $t0, 2
    add $t4, $t4, $a0 # order[i] address
    sw $t3, 0($t4)
    srl $t2, $t2, 5
    add $t0, $t0, 1
    j loop_lo_counter_decode
middle_bit_counter_decode:
    sll $t0, $t1, 2
    and $t0, $t0, 0x0000001f
    or $t0, $t0, $t2 #their_upper_three_bits | their_lo;
    # lw $t3, 24($a0)
    # add $t3, $t3, $t0
    sw $t0, 24($a0)
    srl $t1, $t1, 3
    li $t0, 7
loop_hi_counter_decode:
    bgt     $t0, 11, decode_counter_done    # if  >=  then
    and $t3, $t1, 0x0000001f # their_lo & 0x0000001f
    sll $t4, $t0, 2
    add $t4, $t4, $a0 # order[i] address
    # lw $t5, 0($t4)
    # add $t5, $t5, $t3
    sw $t3, 0($t4)
    srl $t1, $t1, 5
    add $t0, $t0, 1
    j loop_hi_counter_decode
decode_counter_done:
    jr $ra



take_ingre_times:
    li $v0, 0
    bne     $a0, 7, case_9  # if $a0 !=  then
    lw $t0, 44($a1)
    srl $t0, $t0, 2
    move $v0, $t0
    j ingre_done
case_9:
    bne     $a0, 9, case_8  # if $a0 !=  then
    lw $t0, 8($a1)
    # lw $t1, 4($a1)
    # lw $t2, 8($a1)
    # add $t0, $t0, $t1
    # add $t0, $t0, $t2
    srl $t0, $t0, 1
    move $v0, $t0
    j ingre_done
case_8:
    bne     $a0, 8, case_10 # if $a0 !=  then
    lw $t0, 36($a1)
    # lw $t1, 32($a1)
    # lw $t2, 36($a1)
    # add $t0, $t0, $t1
    # add $t0, $t0, $t2
    srl $t0, $t0, 2
    move $v0, $t0
    j ingre_done
case_10:
    bne     $a0, 10, case_11    # if $a0 !=  then
    lw $t0, 24($a1)
    # add $t0, $t0, $t1
    add $0, $0, 2
    srl $t0, $t0, 2
    move $v0, $t0
    j ingre_done
case_11:
    bne     $a0, 11, case_12    # if $a0 !=  then
    lw $t0, 40($a1)
    srl $t0, $t0, 2
    move $v0, $t0
    j ingre_done
case_12:
    bne     $a0, 12, ingre_done # if $a0 !=  then
    lw $t0, 16($a1)
    # lw $t1, 16($a1)
    # add $t0, $t0, $t1
    srl $t0, $t0, 2
    move $v0, $t0
ingre_done:
    jr $ra

#
# take_process_times:
#     # int take_process_numbers (int curr_block, int* counter, int foodID, char* order)
#     li $v0, 0
#     bne     $a0, 4, take_process_times_case_5    # if $a0 !=  then
#     lw $t0, 9($a1)
#     lw $t1, 8($a3)
#     ble $t0,$t1,take_process_times_case_4_else # counter[9] > order[8]
#     move $v0, $t1
# take_process_times_case_4_else:
#     move $v0, $t0
#     j process_done
# take_process_times_case_5:
#     bne     $a0, 5, take_process_times_case_6    # if $a0 !=  then
#     bne     $a2, 1, take_process_times_case_5_else   # if $a2 !=  then
#     lw $t0, 1($a1)  # counter[1]
#     lw $t1, 0($a3)  # order[0]
#     ble $t0, $t1, take_process_times_case_5_if_else
#     move $v0, $t1
# take_process_times_case_5_if_else:
#     move $v0, $t0
#     j process_done
# take_process_times_case_5_else:
#     lw $t0, 6($a1)
#     lw $t1, 5($a3)
#     ble $t0, $t1, take_process_times_case_5_else_else
#     move $v0, $t1
# take_process_times_case_5_else_else:
#     move $v0, $t0
#     j process_done
# take_process_times_case_6:
#     bne     $a0, 6, process_done    # if $a0 !=  then
#     bne     $a2, 2, take_process_times_case_6_else   # if $a2 !=  then
#     lw $t0, 2($a1)
#     lw $t1, 0($a3)
#     ble $t0, $t1, take_process_times_case_6_if_else
#     move $v0, $t1
# take_process_times_case_6_if_else:
#     move $v0, $t0
#     j process_done
# take_process_times_case_6_else:
#     lw $t0, 4($a1)
#     lw $t1, 3($a3)
#     ble $t0, $t1, take_process_times_case_6_else_else
#     move $v0, $t1
# take_process_times_case_6_else_else:
#     move $v0, $t0
#     j process_done
# process_done:
#     jr $ra
#
#


    ################# Cmd Thread ###############################################################
    cmd_thread:
        sub $sp, $sp, 24
        sw $ra, 0($sp)
        sw $t0, 4($sp)
        sw $t1, 8($sp)
        sw $t2, 12($sp)
        sw $t3, 16($sp)
        sw $t4, 20($sp)
        ######FIRST priority: if close to end, go to hand in
        lw $t0, TIMER
        blt $t0, 9300000, cmd_thread_normal_procedure
        la $t0, last_cycles
        lw $t0, 0($t0)
        bne $t0, $0, cmd_thread_normal_procedure
        # sao cao zuo
        #drop all inventory
        li $t0, 0
        sw $t0, DROPOFF
        li $t0, 1
        sw $t0, DROPOFF
        li $t0, 2
        sw $t0, DROPOFF
        li $t0, 3
        sw $t0, DROPOFF
        li $t9, 0x80000000
        #clear cmd queue
        la $t0, cmd_queue_head
        la $t1, cmd_queue_tail
        sw $0, 0($t0)
        sw $0, 0($t1)
        la $t0, keypoint
        lbu $a0, 8($t0)
        jal add_cmd_move
        li $t1, 1
        la $t0, last_cycles
        sw $t1, 0($t0)

    cmd_thread_normal_procedure:
        srl $t0, $t9, 30
        bne $t0, $0, cmd_thread_continue_thread
        #if moving
        lw $t1, GET_MONEY
        ble $t1, 14, cmd_thread_return_directly
        sw $t1, GET_BOOST

        j cmd_thread_return_directly
    cmd_thread_continue_thread:
        li $t1, 1
        bne $t0, $t1, cmd_thread_exec_cmd
        jal exec_cmd_move_adjust
    cmd_thread_exec_cmd:
        # while t9's msb == 2 and !cmd_queue.empty exec cmd
        # in the loop we ensure t0 is head and t1 is tail
        la $t0,cmd_queue_head
        la $t1, cmd_queue_tail
        lw $t0, 0($t0)
        lw $t1, 0($t1)
    cmd_thread_exec_cmd_while_loop:
        bge $t0, $t1, cmd_thread_return_and_save_cmd_queue_head
        srl $t2, $t9, 30
        li $t3, 2
        bne $t2, $t3, cmd_thread_return_and_save_cmd_queue_head
        #start decode and exec
        sll $t2, $t0, 2
        la $t3, cmd_queue
        add $t2, $t2, $t3
        lw $t2, 0($t2) #t2 is cmd
        srl $t3, $t2, 30 #t3 is 2 MSB of cmd (for decoding)
        li $t4, 0
        bne $t3, $t4, cmd_thread_decode_01
        #This is a move cmd (including turn)
        srl $t3, $t2, 29
        bne $t3, $0, cmd_thread_decode_turn
        move $a0, $t2
        jal exec_cmd_move
        add $t0, $t0, 1 #cmd_queue.head++
        j cmd_thread_exec_cmd_while_loop
    cmd_thread_decode_turn:
        move $a0, $t2
        jal exec_cmd_turn
        add $t0, $t0, 1 #cmd_queue.head++
        j cmd_thread_exec_cmd_while_loop
    cmd_thread_decode_01:
        li $t4, 1
        bne $t3, $t4, cmd_thread_decode_10
        #This is a wait and pick cmd
        move $a0, $t2
        jal exec_cmd_wait_and_pick
        add $t0, $t0, 1 #cmd_queue.head++
        j cmd_thread_exec_cmd_while_loop
    cmd_thread_decode_10:
        li $t4, 2
        bne $t3, $t4, cmd_thread_decode_11
        #This is a pick cmd
        move $a0, $t2
        jal exec_cmd_pick
        add $t0, $t0, 1 #cmd_queue.head++
        j cmd_thread_exec_cmd_while_loop
    cmd_thread_decode_11:
        #This can only be a drop cmd
        move $a0, $t2
        jal exec_cmd_drop
        add $t0, $t0, 1 #cmd_queue.head++
        j cmd_thread_exec_cmd_while_loop
    cmd_thread_return_and_save_cmd_queue_head:
        la $t2, cmd_queue_head
        sw $t0, 0($t2)
    cmd_thread_return_directly:
        lw $ra, 0($sp)
        lw $t0, 4($sp)
        lw $t1, 8($sp)
        lw $t2, 12($sp)
        lw $t3, 16($sp)
        lw $t4, 20($sp)
        add $sp, $sp, 24
        jr $ra

    # a0: 5-8 LSB:x; 1-4 LSB: y
    add_cmd_move:
        sub $sp, $sp, 20
        sw $ra, 0($sp)
        sw $t0, 4($sp)
        sw $t1, 8($sp)
        sw $t2, 12($sp)
        sw $t3, 16($sp)

        la $t0, cmd_queue_tail
        lw $t1, 0($t0)
        sll $t2, $t1, 2
        la $t3, cmd_queue
        add $t2, $t2, $t3   #address of cmd
        and $a1, $a0, 0x0000000F
        srl $a0, $a0, 4
        mul $a0, $a0, 20
        mul $a1, $a1, 20
        add $a0, $a0, 10
        add $a1, $a1, 10
        sll $a0, $a0, 10
        or $t3, $a0, $a1

        sw $t3, 0($t2)

        add $t1, $t1, 1 #cmd_queue_tail++
        sw $t1, 0($t0)

        lw $ra, 0($sp)
        lw $t0, 4($sp)
        lw $t1, 8($sp)
        lw $t2, 12($sp)
        lw $t3, 16($sp)
        add $sp, $sp, 20
        jr $ra

    #a0 : angle
    add_cmd_turn:
        sub $sp, $sp, 20
        sw $ra, 0($sp)
        sw $t0, 4($sp)
        sw $t1, 8($sp)
        sw $t2, 12($sp)
        sw $t3, 16($sp)

        la $t0, cmd_queue_tail
        lw $t1, 0($t0)
        sll $t2, $t1, 2
        la $t3, cmd_queue
        add $t2, $t2, $t3   #address of cmd
        or $t3, $a0, 0x20000000
        sw $t3, 0($t2)
        add $t1, $t1, 1
        sw $t1, 0($t0)

        lw $ra, 0($sp)
        lw $t0, 4($sp)
        lw $t1, 8($sp)
        lw $t2, 12($sp)
        lw $t3, 16($sp)
        add $sp, $sp, 20
        jr $ra

    add_cmd_pick:
        sub $sp, $sp, 20
        sw $ra, 0($sp)
        sw $t0, 4($sp)
        sw $t1, 8($sp)
        sw $t2, 12($sp)
        sw $t3, 16($sp)

        la $t0, cmd_queue_tail
        lw $t1, 0($t0)
        sll $t2, $t1, 2
        la $t3, cmd_queue
        add $t2, $t2, $t3   #address of cmd
        or $t3, $a0, 0x80000000
        sw $t3, 0($t2)
        add $t1, $t1, 1
        sw $t1, 0($t0)

        lw $ra, 0($sp)
        lw $t0, 4($sp)
        lw $t1, 8($sp)
        lw $t2, 12($sp)
        lw $t3, 16($sp)
        add $sp, $sp, 20
        jr $ra

    add_cmd_drop:
        sub $sp, $sp, 20
        sw $ra, 0($sp)
        sw $t0, 4($sp)
        sw $t1, 8($sp)
        sw $t2, 12($sp)
        sw $t3, 16($sp)

        la $t0, cmd_queue_tail
        lw $t1, 0($t0)
        sll $t2, $t1, 2
        la $t3, cmd_queue
        add $t2, $t2, $t3   #address of cmd
        or $t3, $a0, 0xC0000000
        sw $t3, 0($t2)
        add $t1, $t1, 1
        sw $t1, 0($t0)

        lw $ra, 0($sp)
        lw $t0, 4($sp)
        lw $t1, 8($sp)
        lw $t2, 12($sp)
        lw $t3, 16($sp)
        add $sp, $sp, 20
        jr $ra

    add_cmd_wait_and_pick:
        sub $sp, $sp, 20
        sw $ra, 0($sp)
        sw $t0, 4($sp)
        sw $t1, 8($sp)
        sw $t2, 12($sp)
        sw $t3, 16($sp)

        la $t0, cmd_queue_tail
        lw $t1, 0($t0)
        sll $t2, $t1, 2
        la $t3, cmd_queue
        add $t2, $t2, $t3   #address of cmd
        or $t3, $a0, 0x40000000
        sw $t3, 0($t2)
        add $t1, $t1, 1
        sw $t1, 0($t0)

        lw $ra, 0($sp)
        lw $t0, 4($sp)
        lw $t1, 8($sp)
        lw $t2, 12($sp)
        lw $t3, 16($sp)
        add $sp, $sp, 20
        jr $ra

    #a0: turn cmd
    exec_cmd_turn:
        sub $sp, $sp, 8
        sw $ra, 0($sp)
        sw $t0, 4($sp)
        and $t0, $a0, 0x0FFFFFFF
        sw $t0, ANGLE
        li $t0, 1
        sw $t0, ANGLE_CONTROL
        lw $ra, 0($sp)
        lw $t0, 4($sp)
        add $sp, $sp, 8
        jr $ra

    # a0 : move cmd (32 bits, starting with 000)
    exec_cmd_move:
        sub $sp, $sp, 28
        sw $ra, 0($sp)
        sw $t0, 4($sp)
        sw $t1, 8($sp)
        sw $t2, 12($sp)
        sw $t3, 16($sp)
        sw $t4, 20($sp)
        sw $v0, 24($sp)
        move $t9, $a0   #save the cmd to t9, 2 MSB do not need to be modified
        lw $t0, BOT_X
        lw $t1, BOT_Y
        and $t2, $t9, 0x000FFC00
        srl $t2, $t2, 10 #target x
        and $t3, $t9, 0x000003FF #target y
        bne $t0, $t2, exec_cmd_move_find_angle
        bne $t1, $t3, exec_cmd_move_find_angle
        and $t9, $t9, 0x3FFFFFFF
        or $t9, $t9,  0x80000000
        j exec_cmd_move_return
    exec_cmd_move_find_angle:
        sub $t0, $t2, $t0   #delta x
        sub $t1, $t3, $t1   #delta y
        move $a0, $t0
        move $a1, $t1
        jal arctan
        sw $v0, ANGLE
        li $v0, 1
        sw $v0, ANGLE_CONTROL
        #find cycles, assume speed is 10
        mul $t0, $t0, $t0
        mul $t1, $t1, $t1
        add $t2, $t0, $t1   #sum of square
        mul $t2, $t2, 10000 # times 100 cycles
        #search for smallest number t3 whose square t4 > t2, use (t3-1)*10 as final cycle
        li $t0, 0
        li $t1, 30000
        #repeat until t0>=t1-1
    exec_cmd_move_repeat:
        add $t3, $t0, $t1
        srl $t3, $t3, 1
        mul $t4, $t3, $t3
        ble $t4, $t2, exec_cmd_move_binary_search_right
        #exec_cmd_move_binary_search_left
        move $t1, $t3
        j exec_cmd_move_binary_search_not_right
    exec_cmd_move_binary_search_right:
        move $t0, $t3
    exec_cmd_move_binary_search_not_right:
        add $t4, $t0, 1
        blt $t4, $t1, exec_cmd_move_repeat
        add $t3, $t0, $t1
        srl $t3, $t3, 1
        mul $t4, $t3, $t3
        ble $t4, $t2, exec_cmd_move_binary_search_end #If (t3*t3>t2) t3--;
        sub $t3, $t3, 1
    exec_cmd_move_binary_search_end:
        mul $t3, $t3, 10
        lw      $v0, TIMER
        add     $v0, $v0, $t3
        sw      $v0, TIMER
        li      $t0, 10
        sw      $t0, VELOCITY
    exec_cmd_move_return:
        lw $ra, 0($sp)
        lw $t0, 4($sp)
        lw $t1, 8($sp)
        lw $t2, 12($sp)
        lw $t3, 16($sp)
        lw $t4, 20($sp)
        lw $v0, 24($sp)
        add $sp, $sp, 28
        jr      $ra

    exec_cmd_move_adjust:
        #boost begin
        li $t9, 0x80000000 #Set cmd move state to 2 (complete)
        jr $ra
        #boost end
        sub $sp, $sp, 16
        sw $ra, 0($sp)
        sw $t0, 4($sp)
        sw $t1, 8($sp)
        sw $t2, 12($sp)
        #adjust y
        and $t1, $t9, 0x000003FF #target y
        lw $t0, BOT_Y
        beq $t0, $t1, exec_cmd_move_adjust_x
        slt $t2, $t1, $t0
        mul $t2, $t2, 180
        add $t2, $t2, 90
        sw $t2, ANGLE
        li $t2, 1
        sw $t2, ANGLE_CONTROL
        li $t2, 10
        sw $t2, VELOCITY
    exec_cmd_move_adjust_y_loop:
        lw $t0, BOT_Y
        bne $t0, $t1, exec_cmd_move_adjust_y_loop
    exec_cmd_move_adjust_x:
        sw $0, VELOCITY
        and $t1, $t9, 0x000FFC00
        srl $t1, $t1, 10 #target x
        lw $t0, BOT_X
        beq $t0, $t1, exec_cmd_move_adjust_complete
        slt $t2, $t1, $t0
        mul $t2, $t2, 180
        sw $t2, ANGLE
        li $t2, 1
        sw $t2, ANGLE_CONTROL
        li $t2, 10
        sw $t2, VELOCITY
    exec_cmd_move_adjust_x_loop:
        lw $t0, BOT_X
        bne $t0, $t1, exec_cmd_move_adjust_x_loop
    exec_cmd_move_adjust_complete:
        sw $0, VELOCITY
        li $t9, 0x80000000 #Set cmd move state to 2 (complete)
        lw $ra, 0($sp)
        lw $t0, 4($sp)
        lw $t1, 8($sp)
        lw $t2, 12($sp)
        add $sp, $sp, 16
        jr $ra

    #wait for at least a0 cycles
    #if more than estimated puzzle solve cycles remaining, solve puzzle
    exec_cmd_wait_and_pick:
        sub $sp, $sp, 16
        sw $t0, 0($sp)
        sw $t1, 4($sp)
        sw $t2, 8($sp)
        sw $ra, 12($sp)
        and $a0, $a0, 0x3fffffff
        lw $t0, TIMER #Time stamp at which we start waiting
        add $t1, $t0, $a0 #Time stamp to stop waiting
        sw $t1, TIMER
    exec_cmd_wait_and_pick_check_return:  #while now<t1
        lw $t0, TIMER
        bgeu $t0, $t1, exec_cmd_wait_and_pick_return
        #jal puzzle_thread
        j exec_cmd_wait_and_pick_check_return
    exec_cmd_wait_and_pick_return:
        lw $t0, 0($sp)
        lw $t1, 4($sp)
        lw $t2, 8($sp)
        lw $ra, 12($sp)
        add $sp, $sp, 16
        jr $ra

    exec_cmd_pick:
        sub $sp, $sp, 4
        sw $ra, 0($sp)
        lw $a1, GET_MONEY
        bgt $a1, $0, exec_cmd_pick_pick
        jal puzzle_thread
        j exec_cmd_pick
    exec_cmd_pick_pick:
        and $a0, $a0, 0x3fffffff
        sw $a0, PICKUP
        lw $ra, 0($sp)
        add $sp, $sp, 4
        jr $ra

    # a0: food type
    exec_cmd_drop:
        sub $sp, $sp, 12
        sw $t0, 0($sp)
        sw $t1, 4($sp)
        sw $ra, 8($sp)
    exec_cmd_drop_wait_loop:
        lw $a1, GET_MONEY
        bgt $a1, $0, exec_cmd_drop_drop
        jal puzzle_thread
        j exec_cmd_drop_wait_loop
    exec_cmd_drop_drop:
        and $a0, $a0, 0x3fffffff
        la $t0, inventory
        sw $t0, GET_INVENTORY
        lw $t1, 0($t0)  #inventory 1
        bne $t1, $a0, exec_cmd_drop_inventory_2
        li $t1, 0
        sw $t1, DROPOFF
        j exec_cmd_drop_return
    exec_cmd_drop_inventory_2:
        lw $t1, 4($t0)  #inventory 2
        bne $t1, $a0, exec_cmd_drop_inventory_3
        li $t1, 1
        sw $t1, DROPOFF
        j exec_cmd_drop_return
    exec_cmd_drop_inventory_3:
        lw $t1, 8($t0)  #inventory 3
        bne $t1, $a0, exec_cmd_drop_inventory_4
        li $t1, 2
        sw $t1, DROPOFF
        j exec_cmd_drop_return
    exec_cmd_drop_inventory_4:
        lw $t1, 12($t0)  #inventory 4
        bne $t1, $a0, exec_cmd_drop_return
        li $t1, 3
        sw $t1, DROPOFF
    exec_cmd_drop_return:
        lw $t0, 0($sp)
        lw $t1, 4($sp)
        lw $ra, 8($sp)
        add $sp, $sp, 12
        jr $ra

    ################## Puzzle Thread  #######################################################
    puzzle_thread:
        sub $sp, $sp, 20
        sw $ra, 0($sp)
        sw $t0, 4($sp)
        sw $t1, 8($sp)
        sw $t2, 12($sp)
    	sw $t3, 16($sp)
    	la $t0, puzzle_request
    	la $t1, puzzle_ready
    	la $t2, puzzle_done
    	lw $t0, 0($t0)
    	lw $t1, 0($t1)
    	lw $t2, 0($t2)
    	#request
    	bgt $t0, $t1, puzzle_thread_solve
    	#puzzle_request++
    	add $t0, $t0, 1
    	la $t3, puzzle_request
    	sw $t0, 0($t3)
    	and $t0, $t0, 0x0000000F
    	mul $t0, $t0, PUZZLE_SIZE_BYTES
    	la $t3, puzzle_list
    	add $t3, $t3, $t0
    	sw $t3, REQUEST_PUZZLE
    puzzle_thread_solve:
    	ble $t1, $t2, puzzle_thread_return
    	#puzzle_done ++
    	add $t2, $t2, 1
    	la $t3, puzzle_done
    	sw $t2, 0($t3)
    	#solve
    	and $t2, $t2, 0x0000000F
    	mul $t2, $t2, PUZZLE_SIZE_BYTES
    	la $t3, puzzle_list
    	add $a0, $t2, $t3
    	jal solve_puzzle
    	sw $a0, SUBMIT_SOLUTION
    puzzle_thread_return:
        lw $ra, 0($sp)
        lw $t0, 4($sp)
        lw $t1, 8($sp)
        lw $t2, 12($sp)
    	lw $t3, 16($sp)
        add $sp, $sp, 20
        jr $ra

    #a0: puzzle address in the list
    solve_puzzle:
        sub     $sp, $sp, 48
        sw      $ra, 0($sp) # save $ra on stack
        sw      $a0, 4($sp)
    	sw		$v1, 8($sp)
    	sw		$t0, 12($sp)
        sw      $s0, 16($sp)
        sw      $s1, 20($sp)
        sw      $s2, 24($sp)
        sw      $s3, 28($sp)
    	sw		$s4, 32($sp)
    	sw		$s5, 36($sp)
    	sw		$s6, 40($sp)
    	sw		$s7, 44($sp)
        li      $s0, 0      # row
        li      $v1, 'A'
        lw      $s2, 0($a0) # NUM_ROWS
        lw      $s3, 4($a0) # NUM_COLS
    	#todo: save s4
    	mul $s4,$s2,$s3
    	add $s4, $s4, 8
    	add $s4, $s4, $a0 #s4: address of bitmap
    	#s5: col num of bitmap
    	and $s5, $s3, 7
    	slt $s5, $0, $s5
    	srl $s6, $s2, 3
    	add $s5, $s5, $s6
    solve_puzzle_outer_loop:
        bge     $s0, $s2, solve_puzzle_end_outer
        li      $s1, 0
    	#s6 and s7 are bitmap of the row
    	lbu		$s6, 0($s4)
    	lbu		$t0, 1($s4)
    	sll $s6, $s6, 8
    	or $s6, $s6, $t0
    	lbu		$t0, 2($s4)
    	sll $s6, $s6, 8
    	or $s6, $s6, $t0
    	lbu		$t0, 3($s4)
    	sll $s6, $s6, 8
    	or $s6, $s6, $t0
    	blt $s5, 5, solve_puzzle_inner_loop
    	lbu $s7, 4($s4)
    	sll $s7, $s7, 24
    solve_puzzle_inner_loop:
        bge     $s1, $s3, solve_puzzle_end_inner
        move    $a1, $v1
        move    $a2, $s0
        move    $a3, $s1
        jal     floodfill           # Test floodfill
    	#find next s1
    	bge $s1, 30, solve_puzzle_inner_loop_bigger_than_31
    	#solve_puzzle_inner_loop_smaller_than_32:

    	#if current is not #
    	li $t0, 31
    	sub $t0, $t0, $s1
    	srlv $t0, $s6, $t0
    	and $t0, $t0, 1
    	beq $t0, $0, solve_puzzle_inner_loop_bigger_than_31

    	add $s1, $s1, 1
    	move $t0, $a0	#caller save a0
    	sllv $a0, $s6, $s1
    	not $a0, $a0
    	jal find_first_one
    	add $s1, $v0, $s1
    	not $a0, $a0
    	sllv $a0, $a0, $v0
    	jal find_first_one
    	add $s1, $s1, $v0
    	move $a0, $t0	#caller save a0
    	j solve_puzzle_inner_loop_continue
    solve_puzzle_inner_loop_bigger_than_31:
    	add $s1, $s1, 1
    solve_puzzle_inner_loop_continue:
        j       solve_puzzle_inner_loop
    solve_puzzle_end_inner:
        add     $s0, $s0, 1
    	add 	$s4, $s4, $s5
        j       solve_puzzle_outer_loop
    solve_puzzle_end_outer:
        lw      $ra, 0($sp) # save $ra on stack
        lw      $a0, 4($sp)
    	lw		$v1, 8($sp)
    	lw		$t0, 12($sp)
        lw      $s0, 16($sp)
        lw      $s1, 20($sp)
        lw      $s2, 24($sp)
        lw      $s3, 28($sp)
    	lw		$s4, 32($sp)
    	lw		$s5, 36($sp)
    	lw		$s6, 40($sp)
    	lw		$s7, 44($sp)
        add     $sp, $sp, 48
        jr      $ra


    find_first_one:
    	sub $sp, $sp, 12
    	sw $ra, 0($sp)
    	sw $t0, 4($sp)
    	sw $a0, 8($sp)
    	move $v0, $0    	# pos = 0
    	bne $a0, $0, find_first_one_iszero
    	li $v0, 32
    	j find_first_one_1bits
    find_first_one_iszero:
    	li $t0, 0xFFFF0000
    	and $t0, $t0, $a0
    	bne $t0, $0, find_first_one_16bits
    	sll $a0, $a0, 16
    	add $v0, $v0, 16
    find_first_one_16bits:
    	li $t0, 0xFF000000
    	and $t0, $t0, $a0
    	bne $t0, $0, find_first_one_8bits
    	sll $a0, $a0, 8
    	add $v0, $v0, 8
    find_first_one_8bits:
    	li $t0, 0xF0000000
    	and $t0, $t0, $a0
    	bne $t0, $0, find_first_one_4bits
    	sll $a0, $a0, 4
    	add $v0, $v0, 4
    find_first_one_4bits:
    	li $t0, 0xC0000000
    	and $t0, $t0, $a0
    	bne $t0, $0, find_first_one_2bits
    	sll $a0, $a0, 2
    	add $v0, $v0, 2
    find_first_one_2bits:
    	li $t0, 0x80000000
    	and $t0, $t0, $a0
    	bne $t0, $0, find_first_one_1bits
    	sll $a0, $a0, 1
    	add $v0, $v0, 1
    find_first_one_1bits:
    	lw $ra, 0($sp)
    	lw $t0, 4($sp)
    	lw $a0, 8($sp)
    	add $sp, $sp, 12
    	jr $ra


    #char floodfill (Puzzle* puzzle, char marker, int row, int col)
    floodfill:
    #       if (row < 0 || col < 0) {
    #             return marker;
    #       }
    #       if (row >= puzzle->NUM_ROWS || col >= puzzle->NUM_COLS) {
    #               return marker;
    #       }
            slt     $t0, $a2, 0
            slt     $t1, $a3, 0
            or      $t0, $t1, $t0
            beq     $t0, 0, f_end_if1
            move    $v1, $a1
            jr      $ra
    f_end_if1:
    		#s2 and s3 are rowNum and colNum
            sge     $t0, $a2, $s2
            sge     $t1, $a3, $s3
            or      $t0, $t1, $t0
            beq     $t0, 0, f_end_if2
            move    $v1, $a1
            jr      $ra
    f_end_if2:
    #       char board[][] = puzzle->board;
    #       if (board[row][col] != \u2019#\u2019) {
    #               return marker;
    #       }
            mul     $t2, $a2, $s3
            add     $t2, $t2, $a3
            add     $t2, $t2, $a0
            add     $t2, $t2, 8
            lb      $t3, 0($t2)
            beq     $t3, '#', f_recur
            move    $v1, $a1
            jr      $ra
    f_recur:
            sub     $sp, $sp, 4
            sw      $ra, 0($sp)
    #       board[row][col] = marker;
            sb      $a1, 0($t2)
    #       floodfill(puzzle, marker, row, col + 1);
            add     $a3, $a3, 1
            jal     floodfill
    #       floodfill(puzzle, marker, row, col - 1);
            add     $a3, $a3, -2
            jal     floodfill

    		add     $a2, $a2, 1
    #       floodfill(puzzle, marker, row + 1, col - 1);
            jal     floodfill
    #       floodfill(puzzle, marker, row + 1, col + 0);
            add     $a3, $a3, 1
            jal     floodfill
    #       floodfill(puzzle, marker, row + 1, col + 1);
            add     $a3, $a3, 1
            jal     floodfill

    		add $a2, $a2, -2
    #       floodfill(puzzle, marker, row - 1, col + 1);
            jal     floodfill
    #       floodfill(puzzle, marker, row - 1, col + 0);
            add     $a3, $a3, -1
            jal     floodfill
    #       floodfill(puzzle, marker, row - 1, col - 1);
            add     $a3, $a3, -1
            jal     floodfill
    #		make a1 and a2 and a3 return to normal
    		add		$a2, $a2, 1
    		add		$a3, $a3, 1
    #       return marker + 1;
            add     $v1, $a1, 1
    f_done:
            lw      $ra, 0($sp)
            add     $sp, $sp, 4
            jr      $ra





    #####################  Utils  #############################################
    # -----------------------------------------------------------------------
    # sb_arctan - computes the arctangent of y / x
    # $a0 - x
    # $a1 - y
    # returns the arctangent in $v0
    # -----------------------------------------------------------------------
    # f, a, ra are not saved
    arctan:
        sub $sp, $sp, 8
        sw $t0, 0($sp)
        sw $t1, 4($sp)
        li      $v0, 0           # angle = 0;
        abs     $t0, $a0         # get absolute values
        abs     $t1, $a1
        ble     $t1, $t0, arctan_no_TURN_90
        ## if (abs(y) > abs(x)) { rotate 90 degrees }
        move    $t0, $a1         # int temp = y;
        neg     $a1, $a0         # y = -x;
        move    $a0, $t0         # x = temp;
        li      $v0, 90          # angle = 90;
    arctan_no_TURN_90:
        bgez    $a0, arctan_pos_x       # skip if (x >= 0)
        ## if (x < 0)
        add     $v0, $v0, 180    # angle += 180;
    arctan_pos_x:
        mtc1    $a0, $f0
        mtc1    $a1, $f1
        cvt.s.w $f0, $f0         # convert from ints to floats
        cvt.s.w $f1, $f1
        div.s   $f0, $f1, $f0    # float v = (float) y / (float) x;
        mul.s   $f1, $f0, $f0    # v^^2
        mul.s   $f2, $f1, $f0    # v^^3
        l.s     $f3, three       # load 3.0
        div.s   $f3, $f2, $f3    # v^^3/3
        sub.s   $f6, $f0, $f3    # v - v^^3/3
        mul.s   $f4, $f1, $f2    # v^^5
        l.s     $f5, five        # load 5.0
        div.s   $f5, $f4, $f5    # v^^5/5
        add.s   $f6, $f6, $f5    # value = v - v^^3/3 + v^^5/5
        #Extended Accuracy Begin
        mul.s   $f7, $f1, $f4    #v^^7
        l.s     $f8, seven
        div.s   $f8, $f7, $f8    #v^^7/7
        sub.s   $f6, $f6, $f8
        mul.s   $f7, $f1, $f7    #f7 = v^^9
        l.s     $f8, nine
        div.s   $f8, $f7, $f8    #v^^9/9
        add.s   $f6, $f6, $f8
        mul.s   $f7, $f1, $f7    #v^^11
        l.s     $f8, eleven
        div.s   $f8, $f7, $f8    #v^^11/11
        sub.s   $f6, $f6, $f8
        mul.s   $f7, $f1, $f7    #v^^13
        l.s     $f8, thirteen
        div.s   $f8, $f7, $f8    #v^^13/13
        add.s   $f6, $f6, $f8
        mul.s   $f7, $f1, $f7    #v^^15
        l.s     $f8, fifteen
        div.s   $f8, $f7, $f8    #v^^15/15
        sub.s   $f6, $f6, $f8
        mul.s   $f7, $f1, $f7    #v^^17
        l.s     $f8, seventeen
        div.s   $f8, $f7, $f8    #v^^17/17
        add.s   $f6, $f6, $f8
        #Extended Accuracy End
        l.s     $f8, PI          # load PI
        div.s   $f6, $f6, $f8    # value / PI
        l.s     $f7, F180        # load 180.0
        mul.s   $f6, $f6, $f7    # 180.0 * value / PI
        cvt.w.s $f6, $f6         # convert "delta" back to integer
        mfc1    $t0, $f6
        add     $v0, $v0, $t0    # angle += delta
        bge     $v0, 0, arctan_end
        # negative value received.
        li      $t0, 360
        add     $v0, $t0, $v0
        slt     $t0, $v0, $0
        mul     $t0, $t0, 360
        add     $v0, $t0, $v0
    arctan_end:
        lw $t0, 0($sp)
        lw $t1, 4($sp)
        add $sp, $sp, 8
        jr      $ra



    #   KERNEL      #############################################
    .kdata
    chunkIH:    .space 32
    non_intrpt_str:    .asciiz "Non-interrupt exception\n"
    unhandled_str:    .asciiz "Unhandled interrupt type\n"
    .ktext 0x80000180
    interrupt_handler:
    .set noat
            move      $k1, $at        # Save $at
    .set at
            la        $k0, chunkIH
            sw        $a0, 0($k0)        # Get some free registers
            sw        $v0, 4($k0)        # by storing them to a global variable
            sw        $t0, 8($k0)
            sw        $t1, 12($k0)
            sw        $t2, 16($k0)
            sw        $t3, 20($k0)
            sw $t4, 24($k0)
            sw $t5, 28($k0)

            mfc0      $k0, $13             # Get Cause register
            srl       $a0, $k0, 2
            and       $a0, $a0, 0xf        # ExcCode field
            bne       $a0, 0, non_intrpt



    interrupt_dispatch:            # Interrupt:
        mfc0       $k0, $13        # Get Cause register, again
        beq        $k0, 0, done        # handled all outstanding interrupts

        and        $a0, $k0, BONK_INT_MASK    # is there a bonk interrupt?
        bne        $a0, 0, bonk_interrupt

        and        $a0, $k0, TIMER_INT_MASK    # is there a timer interrupt?
        bne        $a0, 0, timer_interrupt

        and        $a0, $k0, REQUEST_PUZZLE_INT_MASK
        bne        $a0, 0, request_puzzle_interrupt

        li         $v0, PRINT_STRING    # Unhandled interrupt types
        la         $a0, unhandled_str
        syscall
        j          done

    bonk_interrupt:
        sw      $0, BONK_ACK
        #Fill in your code here
        sw      $0, VELOCITY
        and $t9, $t9, 0x3FFFFFFF
        or $t9, $t9,  0x40000000 #the robot needs to be adjusted
        j       interrupt_dispatch    # see if other interrupts are waiting

    request_puzzle_interrupt:
        sw      $0, REQUEST_PUZZLE_ACK
        #Fill in your code here
        la      $t0, puzzle_state
        lw      $t1, 0($t0)
        not     $t1, $t1
        sw      $t1, 0($t0)
        #puzzle ready ++
        la $t0, puzzle_ready
        lw $t1, 0($t0)
        add $t1, $t1, 1
        sw $t1, 0($t0)
        j   interrupt_dispatch

    timer_interrupt:
        sw      $0, TIMER_ACK
        #Fill in your code here
        sw      $0, VELOCITY
        #if 2 MSB of t9 is 00 then make it to 01
        srl $t0, $t9, 30
        bne $t0, $0, timer_interrupt_pick_up
        and $t9, $t9, 0x3FFFFFFF
        or $t9, $t9,  0x40000000 #the robot needs to be adjusted
        j		timer_interrupt_dispatch
        #else if 2 MSB of t9 is 10 then pick up
    timer_interrupt_pick_up:
        sw $0, PICKUP
    timer_interrupt_dispatch:
        j        interrupt_dispatch    # see if other interrupts are waiting
    non_intrpt:                # was some non-interrupt
        li        $v0, PRINT_STRING
        la        $a0, non_intrpt_str
        syscall                # print out an error message
        # fall through to done
    done:
        la      $k0, chunkIH
        lw      $a0, 0($k0)        # Restore saved registers
        lw      $v0, 4($k0)
        lw      $t0, 8($k0)
        lw      $t1, 12($k0)
        lw      $t2, 16($k0)
        lw      $t3, 20($k0)
        lw $t4, 24($k0)
        lw $t5, 28($k0)
    .set noat
        move    $at, $k1        # Restore $at
    .set at
        eret
