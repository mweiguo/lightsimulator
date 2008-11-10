// gs2Extractor.cpp : Defines the entry point for the DLL application.
//

#include "stdafx.h"
#include <tcl.h>
#include <fstream>
#include <list>
#include <string>
#include <iostream>
#ifdef _MANAGED
#pragma managed(push, off)
#endif

BOOL APIENTRY DllMain( HMODULE hModule,
					  DWORD  ul_reason_for_call,
					  LPVOID lpReserved
					  )
{
	return TRUE;
}

#ifdef _MANAGED
#pragma managed(pop)
#endif


using namespace std;

int get_chnames ( ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[] )
{
	if ( 2 != objc ){
		Tcl_WrongNumArgs ( interp, 1, objv, "GS2_filename");
		return TCL_ERROR;
	}

	int len;
	char *gs2File = Tcl_GetStringFromObj ( objv[1], &len );
	list<string> names;

	try {
		ifstream in;
		in.open ( gs2File );
		in.seekg ( 0x35d1, ios_base::beg );

		while ( 1 ) {
			char name[16] = {0};
			in.read( name, sizeof(name) );
			if ( name[0] == 0 || name[0] > 10)
				break;

			int len = name[0];
			name[len+1] = 0;
			names.push_back ( name+1 );
		}
		in.close();

		Tcl_Obj* lst = Tcl_NewListObj ( 0, 0 );
		list<string>::iterator end = names.end(), pp;
		for ( pp=names.begin(); pp!=end; ++pp ){
			Tcl_Obj* obj = Tcl_NewStringObj ( pp->c_str(), pp->length() );
			Tcl_ListObjAppendElement ( interp, lst, obj );
		}

		Tcl_SetObjResult ( interp, lst );
	} catch ( ... ){
	}

	return TCL_OK;
}


int Gs_Init(Tcl_Interp* interp)
{
	Tcl_CreateObjCommand ( interp, "get_chnames", (Tcl_ObjCmdProc*)get_chnames, 0, 0 );
	return TCL_OK;
}

