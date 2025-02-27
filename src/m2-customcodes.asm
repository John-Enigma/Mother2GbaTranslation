//==============================================================================
// void parse(int code, char* parserAddress, WINDOW* window)
// In:
//    r0: code
//    r1: parser address
//    r2: window
// Out:
//    r0: control code length (0 if not matched)
//==============================================================================

customcodes_parse:

push    {r1-r5,lr}
mov     r3,0
mov     r4,r0

//--------------------------------
// 60 FF XX: Add XX pixels to the renderer
cmp     r4,0x60
bne     @@next

// 60 FF should be treated as a renderable code
push    {r0-r3}
mov     r0,r2
bl      handle_first_window
pop     {r0-r3}

mov     r3,3

// Get the current X offset
ldrh    r4,[r2,2]

// Get the current X tile
ldrh    r5,[r2,0x2A]

lsl     r5,r5,3
add     r4,r4,r5             // Current X location (in pixels)

// Get the value to add
ldrb    r5,[r1,2]           // Control code parameter
add     r4,r4,r5             // New X location

// Store the pixel offset of the new location
@@store_x:
lsl     r5,r4,29
lsr     r5,r5,29
strh    r5,[r2,2]

// Store the X tile of the new location
lsr     r4,r4,3
strh    r4,[r2,0x2A]
b       @@end

@@next:

//--------------------------------
// 5F FF XX: Set the X value of the renderer
cmp     r4,0x5F
bne     @@next2

// 5F FF should be treated as a renderable code
push    {r0-r3}
mov     r0,r2
bl      handle_first_window
pop     {r0-r3}

mov     r3,3

// Get the new X value
ldrb    r4,[r1,2]
b       @@store_x

@@next2:

//--------------------------------
// 5E FF XX: Load value into memory
cmp     r4,0x5E
bne     @@next3
mov     r3,3

// Get the argument
ldrb    r4,[r1,2]
cmp     r4,1
bne     @@end

// 01: load enemy plurality
ldr     r1,=0x2025038
ldrb    r1,[r1] // number of enemies at start of battle
cmp     r1,4
blt     @@small
mov     r1,3
@@small:
mov     r0,r1 // the jump table is 1-indexed
mov     r4,r3
bl      0x80A334C // store to window memory
mov     r3,r4
b @@end

@@next3:

//--------------------------------
// 5D FF: Print give text
cmp     r4,0x5D
bne     @@end

// 5D FF should be treated as a renderable code
push    {r0-r3}
mov     r0,r2
bl      handle_first_window
pop     {r0-r3}

ldr     r3,=#0x30009FB
ldrb    r3,[r3,#0] //Source
ldr     r2,=#m2_active_window_pc //Target
ldrb    r2,[r2,#0]
ldr     r1,=#0x3005230
ldr     r1,[r1,#0x10] //Inventory Window
ldrh    r4,[r1,#0x36] //Cursor Y
ldrh    r1,[r1,#0x34] //Cursor X
lsl     r4,r4,#1
cmp     r1,#0
beq     @@continue
add     r4,r4,#1 //Selected Item number in inventory
@@continue:
lsl     r4,r4,#1
ldr     r0,=#0x3005200
ldr     r0,[r0,#0]
push    {r0} //String address
ldr     r0,=#0x3001D40
mov     r1,#0x6C
mul     r1,r3
add     r0,#0x14
add     r0,r0,r1 //Inventory of source
add     r0,r0,r4 //Item address
ldrh    r0,[r0,#0] //Item
cmp     r0,#0
beq     @@EndOf5D
mov     r1,r2
mov     r2,r3
ldr     r3,=#0x3005230
ldr     r3,[r3,#0x08] //Dialogue Window
bl      give_print

@@EndOf5D:
pop     {r0}
mov     r3,#0
sub     r3,r3,#1 //r3 is now -1

//--------------------------------
@@end:
mov     r0,r3
pop     {r1-r5,pc}
.pool
