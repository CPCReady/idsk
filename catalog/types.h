#ifndef TYPES_H_
#define TYPES_H_

typedef unsigned char  BYTE;
typedef unsigned short WORD;
typedef unsigned long  DWORD;

#define TRUE 1
#define FALSE 0
#define USER_DELETED 0xE5
#define SECTSIZE 512

// DSK structures
#pragma pack(push, 1)

// DSK header
typedef struct {
    char debut[0x30];
    unsigned char NbTracks;
    unsigned char NbHeads;
    unsigned short DataSize;
    unsigned char Unused[0xCC];
} CPCEMUEnt;

// Sector information
typedef struct {
    unsigned char C;  // track
    unsigned char H;  // head
    unsigned char R;  // sector
    unsigned char N;  // size
    short Un1;
    short SizeByte;  // Sector size in bytes
} CPCEMUSect;

// Track information
typedef struct {
    char ID[0x10];
    unsigned char Track;
    unsigned char Head;
    short Unused;
    unsigned char SectSize;
    unsigned char NbSect;
    unsigned char Gap3;
    unsigned char OctRemp;
    CPCEMUSect Sect[29];
} CPCEMUTrack;

// Directory entry structure
typedef struct {
    unsigned char User;
    char Nom[8];
    char Ext[3];
    unsigned char NumPage;
    unsigned char Unused[2];
    unsigned char NbPages;
    unsigned char Blocks[16];
} StDirEntry;

// AMSDOS header structure
typedef struct {
    BYTE User;
    char Nom[8];
    char Ext[3];
    BYTE Pad1[6];
    BYTE FileType;
    WORD Adress;
    BYTE Pad2;
    WORD Length;
    WORD EntryAdress;
    BYTE Pad3[36];
    WORD LengthForTAPE;
    WORD AdressForTAPE;
    BYTE Pad4[2];
    WORD Checksum;
    BYTE Pad5[59];
} StAmsdos;

#pragma pack(pop)

#endif
