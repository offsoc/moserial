errordomain HexParseError {
	INVALID_INPUT;
}
public class InputParser : GLib.Object
{
	/* We need this due to some strange Vala bug stopping us using string.replace in two different classes 
	   should look into it and possibly file a bug */
	public static string statusReplace(string oldString) { 
		return oldString.replace("\\r", "\\n");
	}
	
	public static uchar[] parseHex(string s) throws HexParseError {
		
		long len = s.length;
		uchar[] r=new uchar[(len+1)/2];
        	for(int x=0; x<(len+1)/2; x++) {
        		unichar c;
        		int i;
        		int temp;

	       		c=s.get_char();

	       		if(len>1) {
		       		i=xtoi(c)*16;
	       			if(i<0)
	       				throw new HexParseError.INVALID_INPUT(_("Invalid Input"));
		       		s=s.next_char();
	       		
		       		c=s.get_char();
	       		
	       			temp=xtoi(c);
	       			if(temp<0)
	       				throw new HexParseError.INVALID_INPUT(_("Invalid Input"));
	       			i=i+temp;
		       	}
		       	else {
		       		i=xtoi(c);
	       			if(i<0)
	       				throw new HexParseError.INVALID_INPUT(_("Invalid Input"));
		       	}
	       		s=s.next_char();
	       		r[x]=(uchar)i;
        	}
        	
		return r;
	}
	
	// There should be bindings to something in vala that can do this but there dosen't seem to be yet 2009-01-31
	private static char xtoi(unichar c) {
		char i=-1;
		switch(c){
			case '0':
			i=0;
			break;
			case '1':
			i=1;
			break;
			case '2':
			i=2;
			break;
			case '3':
			i=3;
			break;
			case '4':
			i=4;
			break;
			case '5':
			i=5;
			break;
			case '6':
			i=6;
			break;
			case '7':
			i=7;
			break;
			case '8':
			i=8;
			break;
			case '9':
			i=9;
			break;
			case 'a':
			i=10;
			break;
			case 'b':
			i=11;
			break;
			case 'c':
			i=12;
			break;
			case 'd':
			i=13;
			break;
			case 'e':
			i=14;
			break;
			case 'f':
			i=15;
			break;
			
			case 'A':
			i=10;
			break;
			case 'B':
			i=11;
			break;
			case 'C':
			i=12;
			break;
			case 'D':
			i=13;
			break;
			case 'E':
			i=14;
			break;
			case 'F':
			i=15;
			break;
		}
		return i;				
	}
}
