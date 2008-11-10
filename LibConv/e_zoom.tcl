package require snit

namespace eval SptParser {

    snit::type EZoom {

        typevariable Cmd -array { zoom "zoom" }

        typemethod parse { ct fix i data } {

            upvar $ct      channeltype
            upvar $fix     fixture
            set line [SptParser::remove_comments [lindex $data $i]]

			if { ![regexp -nocase {(zoom)([ \t]+)(offset)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 channel] } {
				set "$line"
				SptParser::PutsVars i line
			}

    		set channeltype($channel) ZOOM

    		for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
    			regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
				set key1 [lindex $line 1]

				set rtn [SptParser::check_misc $i $data $line]
    			if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

    			if { [lsearch $SptParser::KeyWords $key] != -1  } { return [expr $i - 1 ] }

				if { [regexp -nocase {(^[ \t]*channeltype)([ \t]+)(range)([ \t]+)(from)([ \t]+)([0-9]+)([ \t]+)(to)([ \t]+)([0-9]+)([ \t]+)(inverted)} $line p key s1 range s2 a1 s3 from s4 a2 s5 to s6 key1] } {
                    lappend fixture(CHANNELS) $channel
                    lappend fixture($channel,COMMAND) $Cmd(zoom)
					scan $to %d to
					scan $from %d from
                    lappend fixture($channel,$Cmd(zoom)) [list $from $to STEP [expr $fixture(MINOPENING) + ($fixture(MAXOPENING)-$fixture(MINOPENING))*$to/255.0] [expr $fixture(MINOPENING) + ($fixture(MAXOPENING)-$fixture(MINOPENING))*$from/255.0]]
				} elseif { [regexp -nocase {(^[ \t]*channeltype)([ \t]+)(range)([ \t]+)(from)([ \t]+)([0-9]+)([ \t]+)(to)([ \t]+)([0-9]+)} $line p key s1 range s2 a1 s3 from s4 a2 s5 to] } {
                    lappend fixture(CHANNELS) $channel
                    lappend fixture($channel,COMMAND) $Cmd(zoom)
					scan $to %d to
					scan $from %d from
                    lappend fixture($channel,$Cmd(zoom)) [list $from $to STEP [expr $fixture(MINOPENING) + ($fixture(MAXOPENING)-$fixture(MINOPENING))*$from/255.0] [expr $fixture(MINOPENING) + ($fixture(MAXOPENING)-$fixture(MINOPENING))*$to/255.0]]
				} elseif { [regexp -nocase {(^[ \t]*channeltype)([ \t]+)(inverted)} $line p] } {
                    lappend fixture(CHANNELS) $channel
                    lappend fixture($channel,COMMAND) $Cmd(zoom)
                    lappend fixture($channel,$Cmd(zoom)) [list 0 255 STEP $fixture(MAXOPENING) $fixture(MINOPENING)]
				} elseif { [regexp -nocase {(^[ \t]*channeltype)} $line p] } {
                    lappend fixture(CHANNELS) $channel
                    lappend fixture($channel,COMMAND) $Cmd(zoom)
                    lappend fixture($channel,$Cmd(zoom)) [list 0 255 STEP $fixture(MINOPENING) $fixture(MAXOPENING)]
				}
			}
			return [expr $i - 1 ]
    	}
    }
}

