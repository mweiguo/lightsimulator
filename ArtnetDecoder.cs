using System;
using System.Collections;
using System.Collections.Generic;
//using Tamir.IPLib;
//using Tamir.IPLib.Packets;
using System.IO;
using System.Net.Sockets;
using System.Net;
using System.Text;

namespace cp
{
	public abstract class DMXProtocolDecoder
	{
		/// <summary>
		/// 
		/// </summary>
		/// <param name="universe"></param>
		/// <param name="data"></param>
		public delegate void OnReceivePacket(int universe, byte[] data);

		/// <summary>
		/// 
		/// </summary>
		/// <param name="callback"></param>
		public abstract void DecodePackets(OnReceivePacket callback);

		public abstract string Protocol{get;}

		/// <summary>
		/// 
		/// </summary>
		public abstract void Dispose();

		static DMXProtocolDecoder _curDecoder;

		public static DMXProtocolDecoder Decoder
		{
			get
			{
				return _curDecoder;
			}
		}

		public delegate void OnProtocolChange();

		public static event OnProtocolChange onProtocolChange;

		public static void ChangeProtocol(string protocol)
		{
			if(_curDecoder != null)
			{
				if(_curDecoder.Protocol == protocol)
					return;
				_curDecoder.Dispose();
				_curDecoder = null;
			}

			if(protocol == "Art-Net")
				_curDecoder = new ArtNetDecoder();
			else if(protocol == "sACN")
				_curDecoder = new sACNDecoder();
			else if(protocol == "Mini")
				_curDecoder = new MiniDecoder();
				
			onProtocolChange();
		}
	}

	public class ArtNetDecoder : DMXProtocolDecoder
	{
		Socket _s;
		byte[] _buffer = new Byte[1024];
		EndPoint _senderRemote;

		public override string Protocol
		{
			get
			{
				return "Art-Net";
			}
		}
		public ArtNetDecoder()
		{
			_s = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
			IPHostEntry hostEntry = Dns.GetHostEntry(Dns.GetHostName());
			IPEndPoint endPoint = new IPEndPoint(hostEntry.AddressList[0], 6454);
			IPEndPoint sender = new IPEndPoint(IPAddress.Any, 0);
			_senderRemote = (EndPoint)sender;

			_s.Bind(endPoint);
			_s.ReceiveBufferSize = 65536;
		}

		void DecodePacket(int len, OnReceivePacket callback)
		{
			// decode artnet header
			BinaryReader reader = new BinaryReader(new MemoryStream(_buffer, false));
			if(len < 20)
				return;

			byte[] id = reader.ReadBytes(8);
			if(!(id[0] == 'A' && id[1] == 'r' && id[2] == 't' && id[3] == '-' && id[4] == 'N' && id[5] == 'e' && id[6] == 't'))
				return;
			
			// skip some fields
			reader.ReadInt32();
			reader.ReadInt16();

			int universe = reader.ReadInt16();
			int length = Util.ntos ( reader.ReadInt16() );
			byte[] data = reader.ReadBytes(length);

			if(universe < 0 || universe > 3)
			{
				Log.Warning("universe out of range. Should be in [0 - 3].");
				return;
			}

			// invoke callback
			callback(universe, data);
		}

		public override void DecodePackets(OnReceivePacket callback)
		{
			while(_s.Poll(0, SelectMode.SelectRead))
			{
				int len = _s.ReceiveFrom(_buffer, ref _senderRemote);
				DecodePacket(len, callback);
			}
		}

		public override void Dispose()
		{
			_s.Shutdown(SocketShutdown.Receive);
			_s.Close();
		}
	}

	public class sACNDecoder : DMXProtocolDecoder
	{
		public struct CID
		{
			public long High;
			public long Low;

			public static bool operator == (CID a, CID b)
			{
				return (a.Low == b.Low && a.High == b.High);
			}
			public static bool operator !=(CID a, CID b)
			{
				return (a.Low != b.Low || a.High != b.High);
			}
			public override bool Equals(object o)
			{
				if(!(o is CID))
					return false;
				CID o2 = (CID)o;
				return (Low == o2.Low && High == o2.High);
			}
			public override int GetHashCode()
			{
				return (int)(High ^ Low);
			}
		}
		class Source
		{
			CID _id;
			int _expiredTime;

			public CID SRC_CID
			{
				get
				{
					return _id;
				}
				set
				{
					_id = value;
				}
			}
			public Source(int interval)
			{
				_expiredTime = Environment.TickCount + interval;
			}
			public void Reset(int interval)
			{
				_expiredTime = Environment.TickCount + interval;
			}
			public bool Expired
			{
				get
				{
					return _expiredTime <= Environment.TickCount;
				}
			}
		}

		Socket _s;
		byte[] _buffer = new Byte[1024];
		EndPoint _senderRemote;
		List<Source>[] _source = new List<Source>[64];

		public sACNDecoder()
		{
			// initialize sources
			for(int i = 0; i < 64; i++)
				_source[i] = new List<Source>();

			IPHostEntry hostEntry = Dns.GetHostEntry(Dns.GetHostName());
			IPEndPoint endPoint = new IPEndPoint(hostEntry.AddressList[0], 5568);
			IPEndPoint sender = new IPEndPoint(IPAddress.Any, 0);
			_senderRemote = (EndPoint)sender;
			
			// create socket
			_s = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
			_s.ReceiveBufferSize = 65536;
			_s.Bind(endPoint);

			// join group because stream ACN is multiple cast protocol
			for(int i = 0; i < 64; i++)
			{
				IPAddress mcastAddress = IPAddress.Parse(string.Format("239.255.0.{0}", i));
				MulticastOption mcastOption = new MulticastOption(mcastAddress);
				_s.SetSocketOption(SocketOptionLevel.IP, SocketOptionName.AddMembership, mcastOption);
			}
		}

		public override string Protocol
		{
			get
			{
				return "sACN";
			}
		}

		void DecodePacket(int len, OnReceivePacket callback)
		{
			int priority, sequence_number, universe, start_code, property_count;
			byte[] id;
			char[] source_name;
			CID cid;

			// check ACN header
			BinaryReader reader = new BinaryReader(new MemoryStream(_buffer, false));
			if(len < 20)				return;

			if(0x10 != Util.ntos(reader.ReadInt16()))	return;                 // preamble size
			if(0 != reader.ReadInt16())					return; 				// postamble size
			id = reader.ReadBytes(12);											// ACN Packet identifier
			if(!(id[0] == 'A' && id[1] == 'S' && id[2] == 'C' && id[3] == '-' && id[4] == 'E' && id[5] == '1' &&
				id[6] == '.' && id[7] == '1' && id[8] == '7' && id[9] == '\0' && id[10] == '\0' && id[11] == '\0'))
				return;
			reader.ReadInt16();													// flags and length
			if(0x3 != Util.ntol(reader.ReadInt32()))	return;					// vector
			cid.Low = reader.ReadInt64();										// CID
			cid.High = reader.ReadInt64();
			reader.ReadInt16();													// framing layer flags and length
			if(0x2 != Util.ntol(reader.ReadInt32()))	return;					// framing vector
			source_name = reader.ReadChars(32);									// framing source name
			priority = reader.ReadByte();										// framing priority
			sequence_number = reader.ReadByte();								// framing sequence number
			universe = Util.ntos(reader.ReadInt16());							// framing universe
			reader.ReadInt16();													// DMP layer flags and length
			if(0x2 != reader.ReadByte())				return;					// DMP layer vector
			if(0xa1 != reader.ReadByte())				return;					// DMP layer address type & data type
			start_code = reader.ReadInt16();									// DMP layer first property address
			if(0x1 != Util.ntos(reader.ReadInt16()))	return;					// DMP layer address increment
			property_count = Util.ntos(reader.ReadInt16());						// DMP layer property count

			// update source
			bool foundsource = false;
			List<Source> sources = _source[universe];
			foreach(Source source in sources)
			{
				if(source.SRC_CID == cid)
				{
					foundsource = true;
					source.Reset(2500);
				}
			}
			sources.RemoveAll(delegate(Source obj)
			{
				if(obj.Expired)
				{
					Log.Info("stream ACN, lost source, sourceid={0} - {1}", cid.Low, cid.High );
					return true;
				}
				return false;
			});
			if(!foundsource)
			{
				// set timeout to 2.5s, detail reference at E1.31 6.2.1
				Source src = new Source(2500);
				src.SRC_CID = cid;
				sources.Add(src);
				Log.Info("stream ACN, new source added, sourceid={0} - {1}", cid.Low, cid.High);
			}


			// decode data
			if(universe < 0 || universe > 3)
			{
				Log.Warning("universe out of range. Should be in [0 - 3].");
				return;
			}
			byte[] data = reader.ReadBytes(property_count);

			// invoke callback
			callback(universe, data);
		}

		public override void DecodePackets(OnReceivePacket callback)
		{
			while(_s.Poll(0, SelectMode.SelectRead))
			{
				int len = _s.ReceiveFrom(_buffer, ref _senderRemote);
				DecodePacket(len, callback);
			}
		}

		public override void Dispose()
		{
			_s.Shutdown(SocketShutdown.Receive);
			_s.Close();
		}
	}

	public class MiniDecoder : DMXProtocolDecoder
	{
		Socket _s;
		byte[] _buffer = new Byte[1024];
		EndPoint _senderRemote;

		public override string Protocol
		{
			get
			{
				return "Mini";
			}
		}
		public MiniDecoder()
		{
			_s = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
			IPHostEntry hostEntry = Dns.GetHostEntry(Dns.GetHostName());
			IPEndPoint endPoint = new IPEndPoint(hostEntry.AddressList[0], 11000);
			IPEndPoint sender = new IPEndPoint(IPAddress.Any, 0);
			_senderRemote = (EndPoint)sender;

			_s.Bind(endPoint);
			_s.ReceiveBufferSize = 65536;
		}

		public override void DecodePackets(OnReceivePacket callback)
		{
			while(_s.Poll(0, SelectMode.SelectRead))
			{
				int len = _s.ReceiveFrom(_buffer, ref _senderRemote);
				DecodePacket(len, callback);
			}
		}

		public override void Dispose()
		{
			_s.Shutdown(SocketShutdown.Receive);
			_s.Close();
		}
		
		void DecodePacket(int len, OnReceivePacket callback)
		{
			// decode artnet header
			BinaryReader reader = new BinaryReader(new MemoryStream(_buffer, false));
			if(len < 20)
				return;

			byte[] buf = reader.ReadBytes(6);
			if(!(buf[0] == 'M' && buf[1] == 'i' && buf[2] == 'n' && buf[3] == 'i'))
				return;

			int universe = buf[5];
			int length = Util.ntos ( reader.ReadInt16() );
			byte[] data = reader.ReadBytes(length);

			if(universe < 0 || universe > 3)
			{
				Log.Warning("universe out of range. Should be in [0 - 3].");
				return;
			}

			// invoke callback
			callback(universe, data);
		}


	}

}



