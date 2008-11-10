package require snit

namespace eval SptParser {

    snit::type EFader {

        typevariable Cmd -array { fader "intensity" }
        typemethod parse { ct fix i data } {
            upvar $ct      channeltype
            upvar $fix     fixture
            set line [SptParser::remove_comments [lindex $data $i]]


            if { [regexp -nocase {(fader)([ \t]+)(additive)([ \t]+)(offset)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 key3 s3 channel] } {
	    } elseif { [regexp -nocase {(fader)([ \t]+)(offset)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 channel] } {
            } elseif { [regexp -nocase {(fader)([ \t]+)(nooffset)} $line p key1 s1 key2] } {
		return $i
            } else {
                set $line
                SptParser::PutsVars i line
            }

	    set channeltype($channel) INTENSITY
	    lappend fixture(CHANNELS) $channel
	    lappend fixture($channel,COMMAND) $Cmd(fader)
	    lappend fixture($channel,$Cmd(fader)) [list 0 255 STEP 0 [expr 2 * $fixture(WATTAGE) / 250.0]]					

	    for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
		regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [lsearch $SptParser::KeyWords $key] != -1  } {	return [expr $i - 1 ] }

		if { $key == "CHANNELTYPE" } {
		    if { [regexp -nocase {channeltype[ \t]+range[ \t]+from[ \t]+([0-9]+)[ \t]+to[ \t]+([0-9]+)} $line p fo to] } {
			set fixture($channel,$Cmd(fader)) [lreplace $fixture($channel,$Cmd(fader)) end end]
			lappend fixture($channel,$Cmd(fader)) [list $fo $to STEP 0 [expr 2 * $fixture(WATTAGE) / 250.0]]					
		    } elseif { [regexp -nocase {channeltype[ \t]+inverted} $line p] } {
			set fixture($channel,$Cmd(fader)) [lreplace $fixture($channel,$Cmd(fader)) end end]
			lappend fixture($channel,$Cmd(fader)) [list 255 0 STEP 0 [expr 2 * $fixture(WATTAGE) / 250.0]]					
		    } elseif { [regexp -nocase {channeltype[ \t]+normal} $line p] } {
		    } else {
			puts $line
			set bbb
		    }
		} else {
		    SptParser::PutsVars i line
		}
	    }

	    return [expr $i - 1]
    	}
    }
}

