package require snit
namespace eval SptParser {

    snit::type EStrobe {

	typevariable KeyWord1 {OPEN CLOSED }
        typevariable Cmd -array { openintensity "intensity_inopenstate" open "open_shutter" close "close_shutter" strobe "strobe" }

    	typemethod parse { ct fix i data } {
	    upvar $ct channeltype
            upvar $fix     fixture
	    set line [lindex $data $i]

	    if { ![regexp -nocase {(strobe)([ \t]+)(offset)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 channel] } {
		set "$line"
		SptParser::PutsVars i line
	    }

	    set channeltype($channel) CONTROL

	    set strobeFrom -1
	    set strobeTo -1
	    for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
		regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		set key1 [lindex $line 1]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [lsearch $SptParser::KeyWords $key] != -1  } {
                    return [expr $i - 1 ]
                }

		if { [SptParser::parse_channeltype $line] } { 
		    SptParser::PutsVars i line
		} elseif { [regexp -nocase {open[ \t]+from[ \t]+([0-9]+)[ \t]+to[ \t]+([0-9]+)} $line p from to] } {
		    lappend fixture(CHANNELS) $channel

		    # here should check this value wthether used by intensity, if so 
		    if { [info exists fixture($channel,COMMAND)] && [lcontain $fixture($channel,COMMAND) intensity] } {
			# remove intensity command, because intensity_inopenstate will replace it
			set idx 0
			foreach cmd $fixture($channel,intensity) {
			    lassign $cmd fdmx tdmx type fintensity tintensity
			    if { $from == $fdmx && $to == $tdmx } {
				lappend fixture($channel,COMMAND) $Cmd(openintensity)
				lappend fixture($channel,$Cmd(openintensity)) [list $fdmx $tdmx $type $fintensity $tintensity]

#				puts "fixture($channel,intensity) = $fixture($channel,intensity), idx = $idx"
				set fixture($channel,intensity) [lreplace $fixture($channel,intensity) $idx $idx]
#				puts "set fixture($channel,intensity) [lreplace $fixture($channel,intensity) $idx $idx]"
#				puts "fixture($channel,intensity) = $fixture($channel,intensity), idx = $idx"	
				break
			    }
			    incr idx
			}
		    } else {
			lappend fixture($channel,COMMAND) $Cmd(open)
			lappend fixture($channel,$Cmd(open)) [list $from $to ONOFFg]
		    }

		} elseif { [regexp -nocase {(closed)([ \t]+)(from)([ \t]+)([0-9]+)([ \t]+)(to)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 from s3 key3 s4 to] } {
		    lappend fixture(CHANNELS) $channel
		    lappend fixture($channel,COMMAND) $Cmd(close)
		    lappend fixture($channel,$Cmd(close)) [list $from $to ONOFF]
		} elseif { [regexp -nocase {([0-9\.\-]+)([ \t]+)(at)([ \t]+)([0-9]+)} $line p value a1 a2 a3 para] } {
		    #					lappend fixture(CHANNELS) $channel
		    #					lappend fixture($channel,COMMAND) $Cmd(strobe)
		    set fixture($channel,$para) $value
		    #					puts "set fixture($channel,$para) $value"
		    if { $strobeFrom == -1 } {
			set strobeSpeedFrom $value
			set strobeFrom $para
		    } elseif { $strobeTo == -1 } {
			set strobeSpeedTo $value
			set strobeTo $para

			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(strobe)
			lappend fixture($channel,$Cmd(strobe)) [list $strobeFrom $strobeTo CONTINUE $strobeSpeedFrom $strobeSpeedTo]

			set strobeFrom -1
			set strobeTo -1
		    }
		} else {
		    SptParser::PutsVars i line
		}
	    }

            return [expr $i - 1]
    	}

    }
}

