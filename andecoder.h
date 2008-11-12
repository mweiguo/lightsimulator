#pragma once

//typedef struct pcap pcap_t;
//struct Tcl_Interp;

class clsANDecorder
{
public:
	clsANDecorder ();

	int select_device ( Tcl_Interp* interp );
	int start_recieving (Tcl_Interp* interp, const char* szCmd, int device );
	int pause_recieving ( ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[] );
	int resume_recieving ( ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[] );
	int close_artnet ( ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[] );
private:
	bool bStopParse, bCancelParse;
	//int decode_artnet ( ARTNETHEADER *pArtNetHeader, Tcl_Interp* interp, const char* szCmd );
	int enter_capture_loop (pcap_t* phandle, Tcl_Interp* interp, const char* szCmd);
};

