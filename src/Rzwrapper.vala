//Class for communicating with the rz program
public class moserial.Rzwrapper: GLib.Object
{
	public enum Protocol {XMODEM, YMODEM, ZMODEM, NULL}
	public Protocol protocol {get; construct;}
	public SerialConnection? sc;
        private IOChannel IOChannelInput;
        private IOChannel IOChannelOutput;
        private IOChannel IOChannelError;
        //int inputChannelId;
	uint outputChannelId;
        uint errorChannelId;
        private GLib.Pid pid;
        signal void transferComplete();
        signal void updateStatus(string newStatus);
        public bool running=false;
        public string? path {get; construct;}
        public string filename {get; construct;}
	public Rzwrapper(Protocol? protocol, SerialConnection? sc, string? p, string? filename) {
		this.protocol = protocol;
		this.sc = sc;
		this.path = p;
		this.filename = filename;
	}
	construct {
		if(protocol==Protocol.NULL || path==null) {
			running=false;
		}
		else
		{
			string[] argv;
			if(protocol==Protocol.XMODEM)
				argv = new string[4];
			else
				argv = new string[3];
			argv[0] = "rz";
			switch(protocol) {
				case Protocol.XMODEM:
					argv[1] = "--xmodem";
					break;
				case Protocol.YMODEM:
					argv[1] = "--ymodem";
					break;
				case Protocol.ZMODEM:
				default:
					argv[1] = "--zmodem";
					break;
			
			}
			argv[2] = "-vv";
			if(protocol==Protocol.XMODEM)
				argv[3]=filename;
			int output;
			int error;
			int input;
			//size_t bytesRead=0;
			//char[1000] m_buf = new char[1000];
		
			try{
				Process.spawn_async_with_pipes(path, argv, null, SpawnFlags.SEARCH_PATH, null, out pid, out input, out output, out error);
				IOChannelOutput = new GLib.IOChannel.unix_new(output);
				IOChannelInput = new GLib.IOChannel.unix_new(input);
				IOChannelError = new GLib.IOChannel.unix_new(error);
				IOChannelOutput.set_encoding(null);
				IOChannelOutput.set_flags(GLib.IOFlags.NONBLOCK);
				IOChannelError.set_encoding(null);
				IOChannelError.set_flags(GLib.IOFlags.NONBLOCK);
				IOChannelInput.set_encoding(null);
				//IOChannelInput.set_flags(GLib.IOFlags.NONBLOCK);

				outputChannelId = IOChannelOutput.add_watch(GLib.IOCondition.IN, this.readBytes);
				errorChannelId = IOChannelError.add_watch(GLib.IOCondition.IN, this.readError);
				running=true;
			}
			catch(GLib.SpawnError e)
			{
				running=false;
				stdout.printf("spawn error: %s\n", e.message);
				var errorDialog = new Gtk.MessageDialog (null, Gtk.DialogFlags.DESTROY_WITH_PARENT, Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, "%s".printf(e.message));
                        	errorDialog.run();
                        	errorDialog.destroy();
			}
		}
	}
	public void writeChar(uchar byte) {
		if(running)
		{
			size_t bytesWritten;
			char[] b = new char[1];
			b[0] = (char)byte;
			try {
				if(running)
					IOChannelInput.write_chars(b, out bytesWritten);
				//if(running)
				//	IOChannelInput.flush();
			}
			catch(GLib.IOChannelError e)
			{
				shutdown();
				stdout.printf("writeChar() %s\n", e.message);
			}
			catch(GLib.ConvertError e)
			{
				stdout.printf("%s\n", e.message);
			}
		}
	}
	public void flush()
	{
		if(running)
		{
			try {
				if(running)
					IOChannelInput.flush();
			}
			catch(GLib.IOChannelError e)
			{
				shutdown();
				stdout.printf("flush() %s\n", e.message);
			}
		}
	}
	private bool readError(GLib.IOChannel source, GLib.IOCondition condition) {
                if(running) {
		        char[1000] m_buf = new char[1000];
			string message="";
			string messages="";
		        size_t bytesRead=0;
		        if(!(condition == IOCondition.IN))
		        	return true;
		        try {
			        source.read_chars(m_buf, out bytesRead);
			}
			catch (ConvertError e)	        {
				stdout.printf("readError() %s\n", e.message);
			}
			for (int x=0; x<bytesRead; x++) {
				unichar c = m_buf[x];
				if(c.isprint() || c.isspace())
					messages=messages+"%c".printf(m_buf[x]);
			}

			message = MoUtils.getLastMessage(messages);
			if(!(message==""))
				updateStatus(message);
			if(!(messages.str("Transfer complete")==null)) {
				shutdown();
			}
			if(!(messages.str("Transfer incomplete")==null)) {
				shutdown();
			}
	                return true;
		}
		else
			return false;

        }
        public void transferCanceled(GLib.Object o) {
        	//send cancel string to remote client and rz
        	
        	if(running) {
	        	updateStatus("canceled");
	        	for(int x=0;x<20;x++) {
	        		if(protocol==Protocol.ZMODEM) {
			        	sc.sendByte('X'&037);
			        	writeChar('X'&037);
		        	}
		        	else
		        		sc.sendByte(0x18);
        		}
        		GLib.Timeout.add(2000, shutdown_timeout);
        	}
        }
        private bool shutdown_timeout()
        {
        	shutdown();
        	return false;
        }
        private void shutdown() {
        	if(running) {
	        	running=false;
			GLib.Source.remove(outputChannelId);
			GLib.Source.remove(errorChannelId);
			Process.close_pid(pid);
			transferComplete();
		}
        }
        private bool readBytes(GLib.IOChannel source, GLib.IOCondition condition) {
                if(running) {
		        char[1000] m_buf = new char[1000];

		        size_t bytesRead=0;
		        if(!(condition == IOCondition.IN))
		        	return true;
		        try {
			        source.read_chars(m_buf, out bytesRead);
			}
			catch (ConvertError e)	        {
				stdout.printf("readBytes() %s\n", e.message);
			}
			for (int x=0; x<bytesRead; x++) {
				sc.sendByte(m_buf[x]);
				//sendByte(m_buf[x]);
				//outgoingHexTextBuffer.add(m_buf[x]);
			}
		
		        return true;
                }
                else
                	return false;
        }
}
