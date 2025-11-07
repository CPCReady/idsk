#include <iostream>
#include <cstdlib>
#include "dsk.h"

using namespace std;

void printUsage(const char* progName) {
    cout << "Usage: " << progName << " <disk.dsk> [--simple]" << endl;
    cout << endl;
    cout << "Options:" << endl;
    cout << "  --simple    Use simple column format instead of table" << endl;
    cout << endl;
    cout << "Examples:" << endl;
    cout << "  " << progName << " game.dsk" << endl;
    cout << "  " << progName << " game.dsk --simple" << endl;
}

int main(int argc, char** argv) {
    if (argc < 2) {
        printUsage(argv[0]);
        return EXIT_FAILURE;
    }
    
    string dskFile = argv[1];
    bool simpleMode = false;
    
    // Check for --simple flag
    for (int i = 2; i < argc; i++) {
        if (string(argv[i]) == "--simple") {
            simpleMode = true;
        }
    }
    
    // Create DSK object
    DSK disk;
    
    // Read the DSK file
    if (!disk.ReadDsk(dskFile)) {
        cerr << "Error: Cannot read file " << dskFile << endl;
        return EXIT_FAILURE;
    }
    
    // Check if it's a valid DSK
    if (!disk.CheckDsk()) {
        cerr << "Error: Unsupported image file (" << dskFile << ")" << endl;
        return EXIT_FAILURE;
    }
    
    // Display catalog
    if (simpleMode) {
        cout << disk.ReadDskDirSimple();
    } else {
        cout << disk.ReadDskDir();
    }
    
    return EXIT_SUCCESS;
}
