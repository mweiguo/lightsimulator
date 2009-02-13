package require snit

namespace eval SptParser {

    snit::type EFader {

        typevariable Cmd -array { fader "intensity" openintensity "intensity_inopenstate"}

	typemethod setOpenIntensity { fix channel fdmx tdmx fintensity tintensity } {
            upvar $fix     fixture
	    if { [info exists fixture($channel,COMMAND)] && [lcontain $fixture($channel,COMMAND) open_shutter] } {
#		puts "lappend fixture($channel,$Cmd(openintensity)) [list $fdmx $tdmx STEP $fintensity $tintensity]"
		set idx 0
		foreach cmd $fixture($channel,open_shutter) {
		    lassign $cmd from to
		    if { $from == $fdmx && $to == $tdmx } {
			lappend fixture($channel,COMMAND) $Cmd(openintensity)
			lappend fixture($channel,$Cmd(openintensity)) [list $fdmx $tdmx STEP $fintensity $tintensity]
			# remove open_shutter command, because intensity_inopenstate will replace it
			set fixture($channel,open_shutter) [lreplace $fixture($channel,open_shutter) $idx $idx]
			break
		    }
		    incr idx
		}
	    } else {
		lappend fixture($channel,COMMAND) $Cmd(fader)
		lappend fixture($channel,$Cmd(fader)) [list $fdmx $tdmx STEP 0 1]
#		puts "lappend fixture($channel,$Cmd(fader)) [list $fdmx $tdmx STEP 0 1]"
	    }
	}

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
	    set meetChannelType 0
	    
	    for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
		regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue }

		if { [lsearch $SptParser::KeyWords $key] != -1  } { 
		    if { $meetChannelType == 0 } {
			$type setOpenIntensity fixture $channel 0 255 0 1    
		    }
		    return [expr $i - 1 ] 
		}

		if { $key == "CHANNELTYPE" } {
		    if { [regexp -nocase {channeltype[ \t]+range[ \t]+from[ \t]+([0-9]+)[ \t]+to[ \t]+([0-9]+)} $line p fo to] } {
			set meetChannelType 1
			$type setOpenIntensity fixture $channel $fo $to 0 1

		    } elseif { [regexp -nocase {channeltype[ \t]+inverted} $line p] } {
			set meetChannelType 1
			$type setOpenIntensity fixture $channel 0 255 1 0

		    } elseif { [regexp -nocase {channeltype[ \t]+normal} $line p] } {
		    } else {
			puts $line
			set bbb
		    }
		} else {
		    SptParser::PutsVars i line
		}
	    }

	    if { $meetChannelType == 0 } {
		$type setOpenIntensity fixture $channel 0 255 0 1    
	    }
	    return [expr $i - 1]
    	}
    }
}

