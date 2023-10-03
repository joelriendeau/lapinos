#include "print.h"

static const size_t NumColumns = 80;
static const size_t NumRows    = 25;

struct ColoredCharacter
{
    uint8_t Char;
    uint8_t Color;
};

struct ColoredCharacter* Buffer = (struct ColoredCharacter*) 0xb8000;
size_t CurrentColumn = 0;
size_t CurrentRow = 0;
uint8_t CurrentColor = ColorBlack + (ColorWhite << 4);

void ClearRow(size_t Row)
{
    struct ColoredCharacter Void = (struct ColoredCharacter)
    {
        Char: ' ',
        Color: CurrentColor,
    };

    for (size_t C = 0; C < NumColumns; ++C)
        Buffer[C + NumColumns * Row] = Void;
}

void Clear()
{
    for (size_t R = 0; R < NumRows; ++R)
        ClearRow(R);
}

void SetColor(uint8_t ForegroundColor, uint8_t BackgroundColor)
{
    CurrentColor = ForegroundColor + (BackgroundColor << 4);
}

void PrintNewline()
{
    CurrentColumn = 0;
    if (CurrentRow < NumRows - 1)
    {
        ++CurrentRow;
        return;
    }

    for (size_t R = 0; R < NumRows; ++R)
        for (size_t C = 0; C < NumColumns; ++C)
        {
            struct ColoredCharacter ColChar = Buffer[C + NumColumns * R];
            Buffer[C + NumColumns * (R - 1)] = ColChar;
        }
    
    ClearRow(NumRows - 1);
}

void PrintCharacter(char C)
{
    if (C == '\n')
    {
        PrintNewline();
        return;
    }

    if (CurrentColumn >= NumColumns)
        PrintNewline();

    Buffer[CurrentColumn + NumColumns * CurrentRow] = (struct ColoredCharacter)
    {
        Char: C,
        Color: CurrentColor,
    };

    ++CurrentColumn;
}

void PrintString(const char* S)
{
    if (S == 0)
        return;

    for (char C = *S; C != '\0'; C = *++S)
    {
        PrintCharacter(C);
    }
}