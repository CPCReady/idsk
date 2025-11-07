#ifndef DSK_H_
#define DSK_H_

#include "types.h"
#include <string>

class DSK {
private:
    unsigned char ImgDsk[0x80000];
    
    int GetPosData(int track, int sect, bool SectPhysique);
    int GetMinSect();
    StDirEntry* GetInfoDirEntry(int NumDir);
    int FillBitmap();
    
public:
    unsigned char* ReadBloc(int bloc);  // Made public for testing
    
private:
    
public:
    DSK();
    ~DSK();
    
    bool ReadDsk(const std::string& filename);
    bool CheckDsk();
    std::string ReadDskDir();
    std::string ReadDskDirSimple();
    int GetFreeSpace();
};

bool CheckAmsdos(unsigned char* Buf);
bool isBigEndian();
StAmsdos* StAmsdosEndian(StAmsdos* pEntete);

#endif
