/*
 *  Copyright (C) 2009-2010 Michael J. Chudobiak.
 *
 *  This file is part of moserial.
 *
 *  moserial is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  moserial is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with moserial.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gtk;
using GLib;

public class moserial.HexTextBuffer : TextBuffer
{
	private TextMark nextHexMark;
        private TextMark nextCharMark;
        private TextTag addressTag;
        private TextTag oddTag;
        private int hexBytes;
        construct {
		setup();
     	        addressTag = this.create_tag("hex_address", "foreground", "#2020ff", null);
     	        oddTag = this.create_tag("hex_odd", "foreground", "#2020ff", null);
     	        
        }
        public void applyPreferences(Preferences preferences) {
        	addressTag.foreground=preferences.highlightColor;
	       	oddTag.foreground=preferences.highlightColor;
        }
        public void clear() {
        	this.delete_mark(nextHexMark);
        	this.delete_mark(nextCharMark);
		this.set_text("", 0);
		setup();
        }
        private void setup() {
		TextIter nextHexIter;
		TextIter nextCharIter;
	        this.get_end_iter(out nextHexIter);
	        nextHexMark = new TextMark("nextHex", true);
	        this.add_mark(nextHexMark, nextHexIter);
	        nextCharIter=nextHexIter;
	        nextCharMark = new TextMark("nextChar", true);
     	        this.add_mark(nextCharMark, nextCharIter);
     	        hexBytes=0;
        }
        public void add(uchar data) {
		TextIter nextHexIter;
        	TextIter nextCharIter;
        	string incomingHexBuffer = "";

        	// Every insert or delete operation invalidates TextIters and they must be recovered.

        	if((hexBytes % 16)==0 ){
        			// Mark start
                                TextIter startIter;
	                        this.get_iter_at_mark(out nextCharIter, nextCharMark);
                        	TextMark startMark = new TextMark("startMark", true);
                        	this.add_mark(startMark, nextCharIter);

                        	// Insert offset info (hexBytes)
#if VALA_0_16
				this.insert(ref nextCharIter, "\n%08x".printf(hexBytes), 9);
#else
				this.insert(nextCharIter, "\n%08x".printf(hexBytes), 9);
#endif
	                        this.get_iter_at_offset(out nextCharIter, this.cursor_position);

				// Format offset info
	                        this.get_iter_at_mark(out startIter, startMark);
	                        this.apply_tag_by_name("hex_address", startIter, nextCharIter);
	                        this.delete_mark(startMark);

	                        // Blank space
#if VALA_0_16
				this.insert(ref nextCharIter, " ", 1);
#else
				this.insert(nextCharIter, " ", 1);
#endif
	                        this.get_iter_at_offset(out nextCharIter, this.cursor_position);

	                        // Save current position in nextHexMark
	                        this.delete_mark(nextHexMark);
	                        nextHexIter = nextCharIter;
				nextHexMark = new TextMark("nextHex", true);
	                        this.add_mark(nextHexMark, nextHexIter);

				// Put 51 blank spaces
#if VALA_0_16
				this.insert(ref nextCharIter, "                                                   ", 51);
#else
				this.insert(nextCharIter, "                                                   ", 51);
#endif
	                        this.get_iter_at_offset(out nextCharIter, this.cursor_position);
				// Save current nextCharMark
	                        this.delete_mark(nextCharMark);
	                        nextCharMark = new TextMark("nextChar", true);
	                        this.add_mark(nextCharMark, nextCharIter);
	                }
                        else if((hexBytes % 8)==0) {
                        	// Every 8 characters put a separation of 2 spaces
	                        this.get_iter_at_mark(out nextHexIter, nextHexMark);
#if VALA_0_16
				this.insert(ref nextHexIter, "  ", 2);
#else
				this.insert(nextHexIter, "  ", 2);
#endif
	                        this.get_iter_at_mark(out nextHexIter, nextHexMark);
	                        nextHexIter.forward_chars(2);
				// Save current nextHexMark
	                        this.delete_mark(nextHexMark);
	                        nextHexMark = new TextMark("nextHex", true);
	                        this.add_mark(nextHexMark, nextHexIter);
	                        // Remove space to align chars
	                        TextIter tempIter;
	                        tempIter = nextHexIter;
        	                tempIter.forward_chars(2);
#if VALA_0_16
				this.delete(ref nextHexIter, ref tempIter);
#else
				this.delete(nextHexIter, tempIter);
#endif
			}
			// Put hex data at nextHexMark
			this.get_iter_at_mark(out nextHexIter, nextHexMark);
                        incomingHexBuffer += "%02X ".printf(data);
#if VALA_0_16
			this.insert(ref nextHexIter, incomingHexBuffer, (int)incomingHexBuffer.length);
#else
			this.insert(nextHexIter, incomingHexBuffer, (int)incomingHexBuffer.length);
#endif

                        this.get_iter_at_mark(out nextHexIter, nextHexMark);
                        nextHexIter.forward_chars(incomingHexBuffer.length);
                        // Save current nextHexMark
                        this.delete_mark(nextHexMark);
                        nextHexMark = new TextMark("nextHex", true);
                        this.add_mark(nextHexMark, nextHexIter);
                        // Remove space to align chars
                        TextIter tempIter;
                        tempIter = nextHexIter;
                        tempIter.forward_chars(3);
#if VALA_0_16
			this.delete(ref nextHexIter, ref tempIter);
#else
			this.delete(nextHexIter, tempIter);
#endif                
                        incomingHexBuffer = "";
                        hexBytes++;
                        
                        // Place character at nextCharMark
                        this.get_iter_at_mark(out nextCharIter, nextCharMark);
                        unichar c = "%c".printf(data).get_char();
                        string s = "%c".printf(data);
                        if (s.validate() && c.isprint()) {
#if VALA_0_16
				this.insert(ref nextCharIter, s, (int)s.length);
#else
				this.insert(nextCharIter, s, (int)s.length);
#endif
	                        this.get_iter_at_mark(out nextCharIter, nextCharMark);
	                        nextCharIter.forward_chars(s.length);
	                }
                        else {
#if VALA_0_16
				this.insert(ref nextCharIter, ".", 1);
#else
				this.insert(nextCharIter, ".", 1);
#endif
	                        this.get_iter_at_mark(out nextCharIter, nextCharMark);
	                        nextCharIter.forward_chars(1);
	                }
			// Save current nextCharMark
			this.delete_mark(nextCharMark);
                        nextCharMark = new TextMark("nextChar", true);
                        this.add_mark(nextCharMark, nextCharIter);
        }
}
