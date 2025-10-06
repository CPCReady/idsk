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
	bool IsBasic = true;
	//cout << "Entre Ici\n";
	// cerr << "File size: " << TailleFic << endl;
	Basic(BufFile, Listing, IsBasic, AddCrLf);
	//cout << Listing << endl;
	return Listing;
}

string ViewAscii()
{
	// cerr << "File size: " << TailleFic << endl;
	Ascii(BufFile, Listing, TailleFic);
	//cout << Listing << endl;
	return Listing;
}
