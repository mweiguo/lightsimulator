#include "stdafx.h"
#include "andecoder.h"
#include "MethodDispatcher.h"
#include "dispatch.h"

extern MethodDispatcher dispatcher;
extern tinyLogger log1;


//----------------------------------------------------------------------------------------------------------------
clsANDecorder::clsANDecorder (): bStopParse(false), bCancelParse(false)
{
}
//----------------------------------------------------------------------------------------------------------------
pcap_if_t* palldev;
int clsANDecorder::select_device ( Tcl_Interp* interp )
{
	// select device
	//pcap_if_t* palldev;
	char errbuf[PCAP_ERRBUF_SIZE] = {0};
	if ( 0 != pcap_findalldevs_ex ( PCAP_SRC_IF_STRING, NULL, &palldev, errbuf ) ){
		LOG_ERROR ( log1, "can not get device list\n" );
		Tcl_SetResult ( interp, "can not get device list", TCL_VOLATILE );
		pcap_freealldevs(palldev);
		palldev = 0;
		return -1;
	}
	// find specific device
	
	std::vector<Tcl_Obj*> lists;
	lists.push_back ( 0 ); // reserved
	int i=1; 
	for ( pcap_if_t* p=palldev; p; p=p->next, i++ ){
		std::string ipAddr;
		if ( p->addresses && AF_INET == p->addresses->addr->sa_family )
		{
			sockaddr_in* pp = (sockaddr_in*)p->addresses->addr;
			in_addr* paddr = (in_addr*)&(pp->sin_addr);
			std::stringstream ss;
			ss << (unsigned)paddr->s_net << '.' << (unsigned)paddr->s_host << '.' << (unsigned)paddr->s_lh << '.' << (unsigned)paddr->s_impno << ':' << (unsigned)pp->sin_port;
			ipAddr = ss.str();
		}
		Tcl_Obj* argv[3] = { Tcl_NewIntObj ( i ), Tcl_NewStringObj ( p->name, strlen(p->name)), Tcl_NewStringObj ( ipAddr.data(), ipAddr.length()) };
		lists.push_back ( Tcl_NewListObj ( 3, argv ));
	}

	// check whether selection script exist
	Tcl_Eval ( interp, "info procs device_selection" );
	const char* szResult = Tcl_GetStringResult ( interp );
	if ( strcmp( szResult, "device_selection") != 0 ) {
		LOG_ERROR ( log1, "should define 'proc device_selection args' first\n" );
		Tcl_SetResult ( interp, "should define 'proc device_selection args' first", TCL_VOLATILE );
		pcap_freealldevs(palldev);
		palldev = 0;
		return -1;
	}

	// select device
	lists[0] = Tcl_NewStringObj ( "device_selection", strlen("device_selection"));
	Tcl_EvalObjv ( interp, lists.size(), &lists.front(), TCL_EVAL_DIRECT );
	szResult = Tcl_GetStringResult ( interp );
	if ( strcmp ( szResult , "-1" ) == 0 ) {
		LOG_ERROR ( log1, "should select validate device id\n" );
		Tcl_SetResult ( interp, "should select validate device id", TCL_VOLATILE );
		palldev = 0;
		return -1;
	}

	LOG_INFO ( log1, "select device: \n", szResult );
	//pcap_freealldevs(palldev);

	return atoi( szResult );
}
//----------------------------------------------------------------------------------------------------------------
int clsANDecorder::start_recieving (Tcl_Interp* interp, const char* szCmd, int device )
{
	char errbuf[PCAP_ERRBUF_SIZE] = {0};
	// collect add device info
	//pcap_if_t* palldev;
	//if ( 0 != pcap_findalldevs_ex ( PCAP_SRC_IF_STRING, NULL, &palldev, errbuf ) ){
	//	std::cout << "can not get device list" << std::endl;
	//	Tcl_SetResult ( interp, "can not get device list", TCL_VOLATILE );
	//	pcap_freealldevs(palldev);
	//	return -1;
	//}
	// find specific device
	int i = device;
	pcap_if_t* pd = palldev;
	for ( int j=1; j<i; j++, pd=pd->next );  // skip
	if ( !pd ) {
		LOG_ERROR ( log1, "can not get selected device\n" );
		Tcl_SetResult ( interp, "can not get selected device ", TCL_VOLATILE );
		pcap_freealldevs(palldev);
		palldev = 0;
		return -1;
	}

	// open adapter
	pcap_t* phandle = pcap_open ( pd->name, 65536, PCAP_OPENFLAG_PROMISCUOUS, 300, NULL, errbuf );
	if ( 0 == phandle ){
		LOG_ERROR ( log1, "open adapter error\n" );
		Tcl_SetResult ( interp, errbuf, TCL_VOLATILE );
		pcap_freealldevs(palldev);
		palldev = 0;
		return -1;
	}

	// set filter option
	bpf_u_int32 netmask;
	if ( pd->addresses )
		netmask = ((sockaddr_in*)(pd->addresses->netmask->sa_data))->sin_addr.s_addr;
	else
		netmask = 0xffffff;
	bpf_program fp;
	if ( -1 == pcap_compile ( phandle, &fp, "udp", 1, netmask ) ){
		LOG_ERROR ( log1, "error in pcap_compile\n" );
		Tcl_SetResult ( interp, "error in pcap_compile", TCL_VOLATILE );
		pcap_freealldevs(palldev);
		palldev = 0;
		return -1;
	}
	if ( -1 == pcap_setfilter ( phandle, &fp ) ){
		LOG_ERROR ( log1, "error in pcap_setfilter\n" );
		Tcl_SetResult ( interp, "error in pcap_setfilter", TCL_VOLATILE );
		pcap_freealldevs(palldev);
		palldev = 0;
		return -1;
	}
	enter_capture_loop ( phandle, interp, szCmd );
	pcap_freealldevs(palldev);
	palldev = 0;

	return 0;
}
		
//----------------------------------------------------------------------------------------------------------------
int clsANDecorder::enter_capture_loop (pcap_t* phandle, Tcl_Interp* interp, const char* szCmd)
{
	// capture packets
	//static unsigned int time = GetTickCount ();
	int i =0;
	while ( ++i ){
		if ( bStopParse )	continue;
		if ( bCancelParse ) {
			bCancelParse = false;
			break;
		}
		pcap_pkthdr* pheader;
		const unsigned char* pdata;

		if ( 1 != pcap_next_ex ( phandle, &pheader, &pdata ) ){
			LOG_WARNING ( log1, "recieve packet time out: %d ms\n", 300 );
			Tcl_SetResult ( interp, "recieve packet time out", TCL_VOLATILE );
			continue;
		}

		// interpret Art-Net only
		IPHEADER *pIpHeader = (IPHEADER*)(pdata+14);
		UDPHEADER *pUdpHeader = (UDPHEADER*)((char*)pIpHeader+sizeof(IPHEADER));
		ARTNETHEADER *pArtNetHeader = (ARTNETHEADER*)((char*)pUdpHeader+sizeof(UDPHEADER));

		// check if packet is artnet first
		if ( strcmp ( (char*)pArtNetHeader->id, "Art-Net" )!= 0 )
			continue;
		//if ( GetTickCount () - time < 50 )
		//	continue;

		if ( pArtNetHeader->op_code != 0x5000 )
			continue;
		pArtNetHeader->length  = ntohs ( pArtNetHeader->length );

		if ( pArtNetHeader->universe < 0 || pArtNetHeader->universe > 3 ) {
			LOG_WARNING ( log1, "universe number should in range [0-4]\n" );
			continue;
		}

		dispatch_dmx ( interp, pArtNetHeader->universe, pArtNetHeader->pdata, pArtNetHeader->length );
		//time = GetTickCount ();
	}
	return 0;
}

//----------------------------------------------------------------------------------------------------------------

//int clsANDecorder::decode_artnet ( ARTNETHEADER *pArtNetHeader, Tcl_Interp* interp, const char* szCmd )
//{
//	pArtNetHeader->op_code = ntohs ( pArtNetHeader->op_code );
//	pArtNetHeader->protver = ntohs ( pArtNetHeader->protver );
//	pArtNetHeader->length  = ntohs ( pArtNetHeader->length );
//	static unsigned int oVal = GetTickCount(), nVal;
//	static int ii=0;
//
//	//std::for_each ( pArtNetHeader->pdata, pArtNetHeader->pdata+512, HexOut<unsigned int>() );
//	//std::cout << std::endl;
//	dispatch_dmx ( interp, pArtNetHeader->pdata, pArtNetHeader->length );
//
//	return 0;
//}

//----------------------------------------------------------------------------------------------------------------
int clsANDecorder::pause_recieving ( ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[] )
{
	if ( objc != 1 ){
		Tcl_WrongNumArgs ( interp, objc, objv, "pause_recv_artnet" );
		return TCL_ERROR;
	}
	bStopParse = true;
	return TCL_OK;
}

//----------------------------------------------------------------------------------------------------------------
int clsANDecorder::resume_recieving ( ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[] )
{
	if ( objc != 1 ){
		Tcl_WrongNumArgs ( interp, objc, objv, "resume_recv_artnet" );
		return TCL_ERROR;
	}
	bStopParse = false;
	return TCL_OK;
}

//----------------------------------------------------------------------------------------------------------------
int clsANDecorder::close_artnet ( ClientData clientData, Tcl_Interp* interp, int objc, Tcl_Obj* const objv[] )
{
	if ( objc != 1 ){
		Tcl_WrongNumArgs ( interp, objc, objv, "stop_recv_artnet" );
		return TCL_ERROR;
	}
	// close worker thread
	bCancelParse = true;
	return TCL_OK;
}

//----------------------------------------------------------------------------------------------------------------
