#include "dsk.h"
#include <cstring>
#include <cstdio>
#include <cstdlib>
#include <cctype>
#include <algorithm>
#include <string>

using namespace std;

// Check if system is big endian
bool isBigEndian() {
    union {
        uint32_t i;
        char c[4];
    } test = {0x01020304};
    return test.c[0] == 1;
}

// Swap endianness of AMSDOS header
StAmsdos* StAmsdosEndian(StAmsdos* pEntete) {
    static StAmsdos ret;
    memcpy(&ret, pEntete, sizeof(StAmsdos));
    
    WORD* p = (WORD*)&ret.Adress;
    *p = (*p >> 8) | (*p << 8);
    
    p = (WORD*)&ret.Length;
    *p = (*p >> 8) | (*p << 8);
    
    p = (WORD*)&ret.EntryAdress;
    *p = (*p >> 8) | (*p << 8);
    
    p = (WORD*)&ret.LengthForTAPE;
    *p = (*p >> 8) | (*p << 8);
    
    p = (WORD*)&ret.AdressForTAPE;
    *p = (*p >> 8) | (*p << 8);
    
    p = (WORD*)&ret.Checksum;
    *p = (*p >> 8) | (*p << 8);
    
    return &ret;
}

// Check if buffer has valid AMSDOS header
bool CheckAmsdos(unsigned char* Buf) {
    if (!Buf) return false;
    
    int Checksum = 0;
    unsigned short CheckSumFile;
    
    // Read checksum from file (bytes 0x43 and 0x44)
    CheckSumFile = Buf[0x43] + Buf[0x44] * 256;
    
    // Calculate checksum (first 67 bytes = 0x43 bytes)
    for (int i = 0; i < 67; i++)
        Checksum += Buf[i];
    
    return (CheckSumFile == (unsigned short)Checksum) && Checksum != 0;
}

DSK::DSK() {
    memset(ImgDsk, 0, sizeof(ImgDsk));
}

DSK::~DSK() {}

// Get minimum sector number
int DSK::GetMinSect() {
    CPCEMUTrack* pTrack = (CPCEMUTrack*)&ImgDsk[sizeof(CPCEMUEnt)];
    return pTrack->Sect[0].R;
}

// Get position of data in DSK image
int DSK::GetPosData(int track, int sect, bool SectPhysique) {
    int Pos = sizeof(CPCEMUEnt);
    CPCEMUTrack* tr = (CPCEMUTrack*)&ImgDsk[Pos];
    short SizeByte;
    
    for (int t = 0; t <= track; t++) {
        Pos += sizeof(CPCEMUTrack);
        for (int s = 0; s < tr->NbSect; s++) {
            if (t == track) {
                if (((tr->Sect[s].R == sect) && SectPhysique) ||
                    ((s == sect) && !SectPhysique))
                    break;
            }
            SizeByte = tr->Sect[s].SizeByte;
            if (SizeByte)
                Pos += SizeByte;
            else
                Pos += (128 << tr->Sect[s].N);
        }
    }
    return Pos;
}

// Get directory entry
StDirEntry* DSK::GetInfoDirEntry(int NumDir) {
    static StDirEntry Dir;
    int MinSect = GetMinSect();
    int s = (NumDir >> 4) + MinSect;
    int t = (MinSect == 0x41 ? 2 : 0);
    if (MinSect == 1)
        t = 1;
    
    memcpy(&Dir, &ImgDsk[((NumDir & 15) << 5) + GetPosData(t, s, true)], sizeof(StDirEntry));
    return &Dir;
}

// Read a block from disk (1 block = 2 sectors = 1024 bytes)
unsigned char* DSK::ReadBloc(int bloc) {
    static unsigned char BlocBuf[1024];
    
    if (bloc < 0 || bloc > 255) {
        memset(BlocBuf, 0, sizeof(BlocBuf));
        return BlocBuf;
    }
    
    int track = (bloc << 1) / 9;
    int sect = (bloc << 1) % 9;
    int MinSect = GetMinSect();
    
    if (MinSect == 0x41)
        track += 2;
    else if (MinSect == 0x01)
        track++;
    
    int Pos = GetPosData(track, sect + MinSect, true);
    if (Pos >= 0 && Pos + 512 <= 0x80000) {
        memcpy(BlocBuf, &ImgDsk[Pos], 512);
    } else {
        memset(BlocBuf, 0, 512);
    }
    
    if (++sect > 8) {
        track++;
        sect = 0;
    }
    
    Pos = GetPosData(track, sect + MinSect, true);
    if (Pos >= 0 && Pos + 512 <= 0x80000) {
        memcpy(&BlocBuf[512], &ImgDsk[Pos], 512);
    } else {
        memset(&BlocBuf[512], 0, 512);
    }
    
    return BlocBuf;
}

// Fill bitmap to calculate used space
int DSK::FillBitmap() {
    unsigned char Bitmap[256];
    memset(Bitmap, 0, sizeof(Bitmap));
    
    int usedKB = 0;
    for (int i = 0; i < 64; i++) {
        StDirEntry* Dir = GetInfoDirEntry(i);
        if (Dir->User != USER_DELETED) {
            int NbBlocs = (Dir->NbPages + 7) >> 3;
            for (int j = 0; j < NbBlocs; j++) {
                int bloc = Dir->Blocks[j];
                if (bloc < 256 && !Bitmap[bloc]) {
                    Bitmap[bloc] = 1;
                    usedKB++;
                }
            }
        }
    }
    
    return usedKB;
}

// Get free space in KB
int DSK::GetFreeSpace() {
    int usedKB = FillBitmap();
    return 178 - usedKB;
}

// Read DSK file
bool DSK::ReadDsk(const string& filename) {
    FILE* f = fopen(filename.c_str(), "rb");
    if (!f) return false;
    
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);
    
    if (size > 0x80000) {
        fclose(f);
        return false;
    }
    
    size_t read = fread(ImgDsk, 1, size, f);
    fclose(f);
    
    return (read == size);
}

// Check if DSK is valid
bool DSK::CheckDsk() {
    return (!strncmp((char*)ImgDsk, "MV - CPC", 8) ||
            !strncmp((char*)ImgDsk, "EXTENDED", 8));
}

// Get file size string
static string GetTaille(int t) {
    char buf[16];
    snprintf(buf, sizeof(buf), "%d K", t);
    return string(buf);
}

// Professional table format listing
string DSK::ReadDskDir() {
    StDirEntry TabDir[64];
    string catalogue;
    
    auto formatCell = [](const string& content, int width, char align = 'l') -> string {
        string result = content;
        if (result.length() > width) {
            result = result.substr(0, width);
        }
        
        int padding = width - result.length();
        if (align == 'c') {
            int leftPad = padding / 2;
            int rightPad = padding - leftPad;
            result = string(leftPad, ' ') + result + string(rightPad, ' ');
        } else if (align == 'r') {
            result = string(padding, ' ') + result;
        } else {
            result = result + string(padding, ' ');
        }
        return result;
    };
    
    catalogue += "┌──────────────┬────────┬──────────┬──────────┬────────┐\n";
    catalogue += "│     File     │  Size  │   Load   │   Exec   │  User  │\n";
    catalogue += "├──────────────┼────────┼──────────┼──────────┼────────┤\n";
    
    for (int i = 0; i < 64; i++) {
        memcpy(&TabDir[i], GetInfoDirEntry(i), sizeof(StDirEntry));
    }
    
    for (int i = 0; i < 64; i++) {
        if (TabDir[i].User != USER_DELETED && !TabDir[i].NumPage) {
            char Nom[13];
            memcpy(Nom, TabDir[i].Nom, 8);
            memcpy(&Nom[9], TabDir[i].Ext, 3);
            Nom[8] = '.';
            Nom[12] = 0;
            
            for (int j = 0; j < 12; j++) {
                Nom[j] &= 0x7F;
                if (!isprint(Nom[j]))
                    Nom[j] = '?';
            }
            
            int p = 0, t = 0;
            do {
                if (TabDir[p + i].User == TabDir[i].User)
                    t += TabDir[p + i].NbPages;
                p++;
            } while (TabDir[p + i].NumPage && (p + i) < 64);
            
            string size = GetTaille((t + 7) >> 3);
            
            string loadAddr = "-";
            string execAddr = "-";
            if (TabDir[i].Blocks[0] != 0) {
                unsigned char* firstBlock = ReadBloc(TabDir[i].Blocks[0]);
                if (firstBlock && CheckAmsdos(firstBlock)) {
                    StAmsdos* header = (StAmsdos*)firstBlock;
                    if (isBigEndian()) {
                        header = StAmsdosEndian(header);
                    }
                    char loadBuf[10], execBuf[10];
                    snprintf(loadBuf, 10, "&%04X", header->Adress);
                    snprintf(execBuf, 10, "&%04X", header->EntryAdress);
                    loadAddr = loadBuf;
                    execAddr = execBuf;
                }
            }
            
            string fileCol = formatCell(Nom, 12, 'l');
            string sizeCol = formatCell(size, 6, 'r');
            string loadCol = formatCell(loadAddr, 8, 'c');
            string execCol = formatCell(execAddr, 8, 'c');
            string userCol = formatCell(to_string(TabDir[i].User), 6, 'c');
            
            catalogue += "│ " + fileCol + " │ " + sizeCol + " │ " + loadCol + " │ " + execCol + " │ " + userCol + " │\n";
        }
    }
    
    catalogue += "├──────────────────────────────────────────────────────┤\n";
    catalogue += "│" + formatCell(to_string(GetFreeSpace()) + "K free", 54, 'c') + "│\n";
    catalogue += "└──────────────────────────────────────────────────────┘\n";
    
    return catalogue;
}

// Simple column format listing
string DSK::ReadDskDirSimple() {
    StDirEntry TabDir[64];
    string catalogue;
    
    for (int i = 0; i < 64; i++) {
        memcpy(&TabDir[i], GetInfoDirEntry(i), sizeof(StDirEntry));
    }
    
    for (int i = 0; i < 64; i++) {
        if (TabDir[i].User != USER_DELETED && !TabDir[i].NumPage) {
            char Nom[13];
            memcpy(Nom, TabDir[i].Nom, 8);
            memcpy(&Nom[9], TabDir[i].Ext, 3);
            Nom[8] = '.';
            Nom[12] = 0;
            
            for (int j = 0; j < 12; j++) {
                Nom[j] &= 0x7F;
                if (!isprint(Nom[j]))
                    Nom[j] = '?';
            }
            
            int p = 0, t = 0;
            do {
                if (TabDir[p + i].User == TabDir[i].User)
                    t += TabDir[p + i].NbPages;
                p++;
            } while (TabDir[p + i].NumPage && (p + i) < 64);
            
            string size = GetTaille((t + 7) >> 3);
            
            string loadAddr = "-";
            string execAddr = "-";
            if (TabDir[i].Blocks[0] != 0) {
                unsigned char* firstBlock = ReadBloc(TabDir[i].Blocks[0]);
                if (firstBlock && CheckAmsdos(firstBlock)) {
                    StAmsdos* header = (StAmsdos*)firstBlock;
                    if (isBigEndian()) {
                        header = StAmsdosEndian(header);
                    }
                    char loadBuf[10], execBuf[10];
                    snprintf(loadBuf, 10, "&%04X", header->Adress);
                    snprintf(execBuf, 10, "&%04X", header->EntryAdress);
                    loadAddr = loadBuf;
                    execAddr = execBuf;
                }
            }
            
            char line[100];
            snprintf(line, 100, "%-12s %6s  %-8s %-8s User %d\n", 
                     Nom, size.c_str(), loadAddr.c_str(), execAddr.c_str(), TabDir[i].User);
            catalogue += line;
        }
    }
    
    catalogue += "\n" + to_string(GetFreeSpace()) + "K free\n";
    return catalogue;
}
