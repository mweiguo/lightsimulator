#pragma once


typedef struct tagIPHeader {
	unsigned char header_len : 4;
	unsigned char version : 4;
	unsigned char type;
	unsigned short totol_len;
	unsigned short id;
	unsigned short off;
	unsigned char  ttl;
	unsigned char  proto;
	unsigned short checksum;
	unsigned long  src_addr;
	unsigned long  dest_addr;
}IPHEADER;


typedef struct tagUDPHeader {
	unsigned short src_port;
	unsigned short dest_port;
	unsigned short len;
	unsigned short checksum;
}UDPHEADER;

typedef struct tagArtNetHeader {
	unsigned char    	id[8];
	unsigned short		op_code;
	unsigned short		protver;

	unsigned char			sequence;
	unsigned char			physical;
	unsigned short		universe;
	unsigned short		length;
	unsigned char		pdata[1];
}ARTNETHEADER;