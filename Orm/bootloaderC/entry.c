
char* const textVideoMemory = (char* const)0xb8000;

void C_entry(void)
{
    char* cursorLocation = textVideoMemory + (160*19);
    *(cursorLocation) = '?';
    *(cursorLocation+1) = 0x0C; // light red.

}   




// maybe this is the kernel?