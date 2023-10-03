#pragma once

#include <stdint.h>
#include <stddef.h>

enum Color
{
    ColorBlack        = 0,
    ColorBlue         = 1,
    ColorGreen        = 2,
    ColorCyan         = 3,
    ColorRed          = 4,
    ColorMagenta      = 5,
    ColorBrown        = 6,
    ColorLightGray    = 7,
    ColorDarkGray     = 8,
    ColorLightBlue    = 9,
    ColorLightGreen   = 10,
    ColorLightCyan    = 11,
    ColorLightRed     = 12,
    ColorLightMegenta = 13,
    ColorYellow       = 14,
    ColorWhite        = 15,
};

void Clear();
void SetColor(uint8_t ForegroundColor, uint8_t BackgroundColor);
void PrintChar(char C);
void PrintString(const char* S);