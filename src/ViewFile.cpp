#include <iostream>
using namespace std;
#include "GestDsk.h"
#include "Outils.h"
#include "Basic.h"
#include "Desass.h"
#include "Dams.h"
#include "endianPPC.h"
#include "ViewFile.h"
#include "Ascii.h"

string ViewDams()
{
	// cerr << "File size: " << TailleFic << endl;
	Dams(BufFile, TailleFic, Listing);
	return Listing;
	//cout << Listing << endl;
}

string ViewDesass()
{
	// cerr << "File size: " << TailleFic << endl;
	Desass(BufFile, Listing, TailleFic, AdresseCharg);
	return Listing;
	//cout << Listing << endl;
}

string ViewBasic(bool AddCrLf)
{
	// Auto-detect if file is tokenized BASIC or ASCII
	// Tokenized BASIC starts with: [2-byte length][2-byte line number][tokens]
	// ASCII BASIC contains readable text with line numbers like "10 PRINT..."
	bool IsBasic = true;  // Default to tokenized
	
	if (TailleFic >= 4) {
		// Get first 4 bytes
		int length = BufFile[0] | (BufFile[1] << 8);
		int lineNum = BufFile[2] | (BufFile[3] << 8);
		
		// Check if it looks like tokenized format:
		// - Length should be reasonable (< file size, > 4)
		// - Line number should be reasonable (< 65000)
		// - First content byte after line number should be a valid token or printable char
		bool looksTokenized = (length > 4 && length < TailleFic && 
		                       lineNum > 0 && lineNum < 65000);
		
		// If first bytes look like ASCII text (line number as text), it's ASCII
		if (BufFile[0] >= '0' && BufFile[0] <= '9') {
			IsBasic = false;  // ASCII format
		} else if (!looksTokenized) {
			// Doesn't look tokenized, treat as ASCII
			IsBasic = false;
		}
	}
	
	// Process accordingly
	if (IsBasic) {
		Basic(BufFile, Listing, IsBasic, AddCrLf);
	} else {
		Ascii(BufFile, Listing, TailleFic);
	}
	
	return Listing;
}

string ViewAscii()
{
	// cerr << "File size: " << TailleFic << endl;
	Ascii(BufFile, Listing, TailleFic);
	//cout << Listing << endl;
	return Listing;
}
