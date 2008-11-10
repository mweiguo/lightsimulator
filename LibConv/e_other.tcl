package require snit
namespace eval SptParser {

    snit::type EOther {

        typevariable Cmd -array { focus "focus" strobe "strobe" move_leftshutter "move_leftshutter" move_topshutter "move_topshutter" move_rightshutter "move_rightshutter" move_bottomshutter "move_bottomshutter" rotate_leftshutter "rotate_leftshutter" rotate_topshutter "rotate_topshutter" rotate_rightshutter "rotate_rightshutter" rotate_bottomshutter "rotate_bottomshutter" fader "intensity"}
	
        typemethod parse { ct fix i data } {
            upvar $ct      channeltype
            upvar $fix     fixture
	    #			puts [array get channeltype]

            set line [SptParser::remove_comments [lindex $data $i]]
	    if { ![regexp -nocase {(other)([ \t]*)"(.*)"([ \t]*)(offset)([ \t]+)([0-9]+)} $line p key1 s1 name s2 key2 s3 channel] } {
		return $i
	    }

	    if { [info exists channeltype($channel)] } {
		if { $channeltype($channel)=="EFFECTWHEEL" } {
		    set i [$type parse_effectwheel $i $data fixture]
		} elseif { $channeltype($channel)=="GOBOWHEEL" } {
		    set i [$type parse_gobowheel $i $data fixture $channel]
		} elseif { $channeltype($channel)=="COLORWHEEL" } {
		    set i [$type parse_colorwheel $i $data fixture $channel]
		} elseif { $channeltype($channel)=="COLOR" } {
		    set i [$type parse_color $i $data fixture]
		} elseif { $channeltype($channel)=="CONTROL" } {
		    set i [$type parse_control $i $data fixture $channel]
		} elseif { $channeltype($channel)=="MOVESPEED" } {
		    set i [$type parse_pan_tilt_speed $i $data fixture $channel]
		} elseif { $channeltype($channel)=="MOVE" } {
		    set i [$type parse_move $i $data fixture]
		} elseif { $channeltype($channel)=="INTENSITY" } {
		    set i [$type parse_intensity $i $data fixture]
		} elseif { $channeltype($channel)=="IRIS" } {
		    set i [$type parse_iris $i $data fixture]
		} elseif { $channeltype($channel)=="FRAMING_ROTATE" } {
		    set i [$type parse_framing_rotate $i $data fixture]
		} elseif { $channeltype($channel)=="FRAMING_INOUT" } {
		    set i [$type parse_framing_inout $i $data fixture]
		}
	    } else {
		if {[regexp -nocase {(other)([ \t]*)"(gobo)([ \t]*)([0-9])([ \t]+)(fine)"([ \t]+)(offset)([ \t]+)([0-9]+)} $line p key0 s0 key1 s1 slot s2 key2 s3 key3 s4 offset] } {
		    set i [$type parse_gobowheel $i $data fixture $channel]
		} elseif { [regexp -nocase {(OTHER)([ \t]*)"(reset)"([ \t]*)(OFFSET)([ \t]*)([0-9]+)} $line p key1 s1 name s2 key2 s3 offset] } {
		    set i [$type parse_control $i $data fixture $channel]
		} elseif { [regexp -nocase {(OTHER)([ \t]*)"(pan/tilt speed)"([ \t]*)(OFFSET)([ \t]*)([0-9]+)} $line p key1 s1 name s2 key2 s3 offset] } {
		    set i [$type parse_pan_tilt_speed $i $data fixture $channel]
		} elseif { [regexp -nocase {OTHER[ \t]*"focus"[ \t]*OFFSET[ \t]*([0-9]+)} $line p offset] } {
		    set i [$type parse_focus $i $data fixture $offset]
		} elseif { [regexp -nocase {(OTHER)([ \t]*)"(lamp control)"([ \t]*)(OFFSET)([ \t]*)([0-9]+)} $line p key1 s1 name s2 key2 s3 offset] } {
		    set i [$type parse_control $i $data fixture $channel]
		} elseif { [regexp -nocase {(OTHER)([ \t]*)"(color speed)"([ \t]*)(OFFSET)([ \t]*)([0-9]+)} $line p key1 s1 name s2 key2 s3 offset] } {
		    set i [$type parse_colorwheel $i $data fixture $channel]
		} elseif { [regexp -nocase {(OTHER)([ \t]*)"(gobo speed)"([ \t]*)(OFFSET)([ \t]*)([0-9]+)} $line p key1 s1 name s2 key2 s3 offset] } {
		    set i [$type parse_gobowheel $i $data fixture $channel]
		} elseif { [regexp -nocase {(OTHER)([ \t]*)"(.*)"([ \t]*)(OFFSET)([ \t]*)([0-9]+)} $line p key1 s1 name s2 key2 s3 offset] } {
                    set name [SptParser::replace_string $name " " ""]
		    if { [info exists fixture(EFFECTS)] && [expr -1 != [lsearch $fixture(EFFECTS) $name]] } {
			set i [$type parse_effectwheel $i $data fixture]
		    }
		} else {
		    SptParser::PutsVars i line
		}
	    }
	    return $i
	    #			return [expr $i+1]
	}
	
	# -------------------------------------------------------------------------------

	typemethod parse_control { i data fix channel} {
            upvar $fix     fixture
	    set sFrom -1
	    set sTo -1
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("strobe")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    for { set pp $from} {$pp !=$to} { incr pp } {
			if { $sFrom == -1 } {
			    if {[info exists fixture($channel,$from)]} {
				set sFrom $pp
			    }
			} elseif {[info exists fixture($channel,$to)]} {
			    lappend fixture($channel,$Cmd(strobe)) [list $from $to CONTINUE $fixture($channel,$from) $fixture($channel,$to)]
			    set sFrom -1
			}
		    }
		    continue
		} elseif { [regexp -nocase {("pulse open slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 pulseOpenSlow] } {
		    if { [info exists pulseOpenFast] && [info exists fixture($channel,$pulseOpenFast)] && [info exists fixture($channel,$pulseOpenSlow)] } {
			if { $pulseOpenFast < $pulseOpenSlow } {
			    lappend fixture($channel,$Cmd(strobe)) [list $pulseOpenFast $pulseOpenSlow CONTINUE $fixture($channel,$pulseOpenFast) $fixture($channel,$pulseOpenSlow)]
			} else {
			    lappend fixture($channel,$Cmd(strobe)) [list $pulseOpenSlow $pulseOpenFast CONTINUE $fixture($channel,$pulseOpenSlow) $fixture($channel,$pulseOpenFast)]
			}
		    }
		    continue
		} elseif { [regexp -nocase {("pulse open fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 pulseOpenFast] } {
		    if { [info exists pulseOpenSlow] && [info exists fixture($channel,$pulseOpenFast)] && [info exists fixture($channel,$pulseOpenSlow)] } {
			if { $pulseOpenFast < $pulseOpenSlow } {
			    lappend fixture($channel,$Cmd(strobe)) [list $pulseOpenFast $pulseOpenSlow CONTINUE $fixture($channel,$pulseOpenFast) $fixture($channel,$pulseOpenSlow)]
			} else {
			    lappend fixture($channel,$Cmd(strobe)) [list $pulseOpenSlow $pulseOpenFast CONTINUE $fixture($channel,$pulseOpenSlow) $fixture($channel,$pulseOpenFast)]
			}
		    }
		    continue
		} elseif { [regexp -nocase {("pulse close slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 pulseCloseSlow] } {
		    if { [info exists pulseCloseFast] && [info exists fixture($channel,$pulseCloseSlow)] && [info exists fixture($channel,$pulseCloseFast)] } {
			if { $pulseCloseFast < $pulseCloseSlow } {
			    lappend fixture($channel,$Cmd(strobe)) [list $pulseCloseFast $pulseCloseSlow CONTINUE $fixture($channel,$pulseCloseFast) $fixture($channel,$pulseCloseSlow)]
			} else {
			    lappend fixture($channel,$Cmd(strobe)) [list $pulseCloseSlow $pulseCloseFast CONTINUE $fixture($channel,$pulseCloseSlow) $fixture($channel,$pulseCloseFast)]
			}
		    }
		    continue
		} elseif { [regexp -nocase {("pulse close fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 pulseCloseFast] } {
		    if { [info exists pulseCloseSlow] && [info exists fixture($channel,$pulseCloseSlow)] && [info exists fixture($channel,$pulseCloseFast)] } {
			if { $pulseCloseFast < $pulseCloseSlow } {
			    lappend fixture($channel,$Cmd(strobe)) [list $pulseCloseFast $pulseCloseSlow CONTINUE $fixture($channel,$pulseCloseFast) $fixture($channel,$pulseCloseSlow)]
			} else {
			    lappend fixture($channel,$Cmd(strobe)) [list $pulseCloseSlow $pulseCloseFast CONTINUE $fixture($channel,$pulseCloseSlow) $fixture($channel,$pulseCloseFast)]
			}
		    }
		    continue
		} elseif { [regexp -nocase {("random fast")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key s1 key1 s2 ranFastMin s3 key2 s4 ranFastMax] } {
		    if { [info exists ranSlowMin] && [info exists ranSlowMax] && [info exists fixture($channel,$from)] && [info exists fixture($channel,$to)] } {
			if { $ranSlowMin < $ranFastMin } {
			    lappend fixture($channel,$Cmd(strobe)) [list $ranSlowMin $ranFastMax CONTINUE $fixture($channel,$ranSlowMin) $fixture($channel,$ranFastMax)]
			} else {
			    lappend fixture($channel,$Cmd(strobe)) [list $ranFastMin $ranSlowMax CONTINUE $fixture($channel,$ranFastMin) $fixture($channel,$ranSlowMax)]
			}
		    }
		    continue
		} elseif { [regexp -nocase {("random mid.")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key s1 key1 s2 from s3 key2 s4 to] } {
		    continue
		} elseif { [regexp -nocase {("random slow")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key s1 key1 s2 ranSlowMin s3 key2 s4 ranSlowMax] } {
		    if { [info exists ranFastMin] && [info exists ranFastMax] } {
			if { $ranSlowMin < $ranFastMin && [info exists fixture($channel,$ranSlowMin)] && [info exists fixture($channel,$ranFastMax)] } {
			    lappend fixture($channel,$Cmd(strobe)) [list $ranSlowMin $ranFastMax CONTINUE $fixture($channel,$ranSlowMin) $fixture($channel,$ranFastMax)]
			} elseif { $ranSlowMin > $ranFastMin && [info exists fixture($channel,$ranFastMin)] && [info exists fixture($channel,$ranSlowMax)] } {
			    lappend fixture($channel,$Cmd(strobe)) [list $ranFastMin $ranSlowMax CONTINUE $fixture($channel,$ranFastMin) $fixture($channel,$ranSlowMax)]
			}
		    }
		    continue
		} elseif { [regexp -nocase {("random pulse open fast")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key s1 key1 s2 ranPulseOpenFastMin s3 key2 s4 ranPulseOpenFastMax] } {
		    if { [info exists ranPulseOpenSlowMin] && [info exists ranPulseOpenSlowMax] } {
			if { $ranPulseOpenSlowMin < $ranPulseOpenFastMin && [info exists fixture($channel,$ranPulseOpenSlowMin)] && [info exists fixture($channel,$ranPulseOpenFastMax)] } {
			    lappend fixture($channel,$Cmd(strobe)) [list $ranPulseOpenSlowMin $ranPulseOpenFastMax CONTINUE $fixture($channel,$ranPulseOpenSlowMin) $fixture($channel,$ranPulseOpenFastMax)]
			} elseif { $ranPulseOpenSlowMin > $ranPulseOpenFastMin && [info exists fixture($channel,$ranPulseOpenFastMin)] && [info exists fixture($channel,$ranPulseOpenSlowMax)] } {
			    lappend fixture($channel,$Cmd(strobe)) [list $ranPulseOpenFastMin $ranPulseOpenSlowMax CONTINUE $fixture($channel,$ranPulseOpenFastMin) $fixture($channel,$ranPulseOpenSlowMax)]
			}
		    }
		    continue
		} elseif { [regexp -nocase {("random pulse open slow")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key s1 key1 s2 ranPulseOpenSlowMin s3 key2 s4 ranPulseOpenSlowMax] } {
		    if { [info exists ranPulseOpenFastMin] && [info exists ranPulseOpenFastMax] } {
			if { $ranPulseOpenSlowMin < $ranPulseOpenFastMin && [info exists fixture($channel,$ranPulseOpenSlowMin)] && [info exists fixture($channel,$ranPulseOpenFastMax)] } {
			    lappend fixture($channel,$Cmd(strobe)) [list $ranPulseOpenSlowMin $ranPulseOpenFastMax CONTINUE $fixture($channel,$ranPulseOpenSlowMin) $fixture($channel,$ranPulseOpenFastMax)]
			} elseif { $ranPulseOpenSlowMin > $ranPulseOpenFastMin && [info exists fixture($channel,$ranPulseOpenFastMin)] && [info exists fixture($channel,$ranPulseOpenSlowMax)] } {
			    lappend fixture($channel,$Cmd(strobe)) [list $ranPulseOpenFastMin $ranPulseOpenSlowMax CONTINUE $fixture($channel,$ranPulseOpenFastMin) $fixture($channel,$ranPulseOpenSlowMax)]
			}
		    }
		    continue
		} elseif { [regexp -nocase {("random pulse close fast")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key s1 key1 s2 ranPulseCloseFastMin s3 key2 s4 ranPulseCloseFastMax] } {
		    if { [info exists ranPulseCloseSlowMin] && [info exists ranPulseCloseSlowMax] } {
			if { $ranPulseCloseSlowMin < $ranPulseCloseFastMin && [info exists fixture($channel,$ranPulseCloseSlowMin)] && [info exists fixture($channel,$ranPulseCloseFastMax)] } {
			    lappend fixture($channel,$Cmd(strobe)) [list $ranPulseCloseSlowMin $ranPulseCloseFastMax CONTINUE $fixture($channel,$ranPulseCloseSlowMin) $fixture($channel,$ranPulseCloseFastMax)]
			} elseif { $ranPulseCloseSlowMin > $ranPulseCloseFastMin && [info exists fixture($channel,$ranPulseCloseFastMin)] && [info exists fixture($channel,$ranPulseCloseSlowMax)] } {
			    lappend fixture($channel,$Cmd(strobe)) [list $ranPulseCloseFastMin $ranPulseCloseSlowMax CONTINUE $fixture($channel,$ranPulseCloseFastMin) $fixture($channel,$ranPulseCloseSlowMax)]
			}
		    }
		    continue
		} elseif { [regexp -nocase {("random pulse close slow")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key s1 key1 s2 ranPulseCloseSlowMin s3 key2 s4 ranPulseCloseSlowMax] } {
		    if { [info exists ranPulseCloseFastMin] && [info exists ranPulseCloseFastMax] } {
			if { $ranPulseCloseSlowMin < $ranPulseCloseFastMin && [info exists fixture($channel,$ranPulseCloseSlowMin)] && [info exists fixture($channel,$ranPulseCloseFastMax)] } {
			    lappend fixture($channel,$Cmd(strobe)) [list $ranPulseCloseSlowMin $ranPulseCloseFastMax CONTINUE $fixture($channel,$ranPulseCloseSlowMin) $fixture($channel,$ranPulseCloseFastMax)]
			} elseif { $ranPulseCloseSlowMin > $ranPulseCloseFastMin && [info exists fixture($channel,$ranPulseCloseFastMin)] && [info exists fixture($channel,$ranPulseCloseSlowMax)] } {
			    lappend fixture($channel,$Cmd(strobe)) [list $ranPulseCloseFastMin $ranPulseCloseSlowMax CONTINUE $fixture($channel,$ranPulseCloseFastMin) $fixture($channel,$ranPulseCloseSlowMax)]
			}
		    }
		    continue
		} elseif { [regexp -nocase {("slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 slow] } {
		    if { [info exists fast] } {
			if { $slow < $fast && [info exists fixture($channel,$slow)] && [info exists fixture($channel,$fast)] } {
			    lappend fixture($channel,$Cmd(strobe)) [list $slow $fast CONTINUE $fixture($channel,$slow) $fixture($channel,$fast)]
			} elseif { $fast < $slow && [info exists fixture($channel,$slow)] && [info exists fixture($channel,$fast)] } {
			    lappend fixture($channel,$Cmd(strobe)) [list $fast $slow CONTINUE $fixture($channel,$fast) $fixture($channel,$slow)]
			}
		    }
		    continue
		} elseif { [regexp -nocase {("fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 fast] } {
		    if { [info exists slow] } {
			if { $slow < $fast && [info exists fixture($channel,$slow)] && [info exists fixture($channel,$fast)] } {
			    lappend fixture($channel,$Cmd(strobe)) [list $slow $fast CONTINUE $fixture($channel,$slow) $fixture($channel,$fast)]
			} elseif { $fast < $slow && [info exists fixture($channel,$slow)] && [info exists fixture($channel,$fast)] } {
			    lappend fixture($channel,$Cmd(strobe)) [list $fast $slow CONTINUE $fixture($channel,$fast) $fixture($channel,$slow)]
			}
		    }
		    continue
		} elseif { [regexp -nocase {("lamp on")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("lamp @ 50%")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("lamp off")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reset")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("off")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("on")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("on \(half power\)")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("on \(full power\)")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("lamp left on")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("lamp right on")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("2 lamps on")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("no function")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("idle")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("no function")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("reset pan\\tilt")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reset bay 1")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reset bay 2")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reset scroller/lens")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reset all")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reset color")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reset gobos")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reset beam")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reset dim\\shut")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("safe")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("p&t mspeed off")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("display on")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("display off")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("display dim")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("display bright")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("home all")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("shutdown")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reserved")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("camera reset")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("home p/t")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("home beam")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("projector menu")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("projector up")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("projector down")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("projector left")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("projector right")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("projector select")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("projector floor")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("projector ceiling")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("projector front")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("projector rear")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("soft focus[ \t]+")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("zoom normal")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("zoom fast autofocus")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("zoom slow autofocus")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("park")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("home")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("zoom control free")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("zoom autofocus")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("pan\\tilt soft move")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("pan\\tilt normal move")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("fans max")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("bi\-color")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("program stop")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("program pause [0-9]+ sec.")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("program pause [0-9]+ min.")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("bi\-color")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reserved")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("closed")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("fan right -> left")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("fan left -> right")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
                } elseif { [regexp -nocase {("dimmer closed")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
                    continue
                } elseif { [regexp -nocase {("dimmer open")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
                    continue
                } elseif { [regexp -nocase {("random slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
                    continue
                } elseif { [regexp -nocase {("random fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
                    continue
                } elseif { [regexp -nocase {("strobe slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
                    continue
                } elseif { [regexp -nocase {("strobe fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
                    continue
                } elseif { [regexp -nocase {("pis dwn slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
                    continue
                } elseif { [regexp -nocase {("pis dwn fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
                    continue
                } elseif { [regexp -nocase {("pis up slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
                    continue
                } elseif { [regexp -nocase {("pis up fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
                    continue
                } elseif { [regexp -nocase {("b\.o\. move")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
                    continue
                } elseif { [regexp -nocase {("b\.o\. col/gobo")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
                    continue
                } elseif { [regexp -nocase {("b\.o\. p/t")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
                    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}
	

	# -------------------------------------------------------------------------------

	typemethod parse_reset { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("reset")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("no function")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("no function")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("idle")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("park")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reset pan\\tilt")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reset all")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reset exc. pan\\tilt")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_strobe { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("closed")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("fan right -> left")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("fan left -> right")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
                } elseif { [regexp -nocase {("dimmer closed")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
                    continue
                } elseif { [regexp -nocase {("dimmer open")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
                    continue
                } elseif { [regexp -nocase {("random slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
                    continue
                } elseif { [regexp -nocase {("random fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
                    continue
                } elseif { [regexp -nocase {("strobe slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
                    continue
                } elseif { [regexp -nocase {("strobe fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
                    continue
                } elseif { [regexp -nocase {("pis dwn slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
                    continue
                } elseif { [regexp -nocase {("pis dwn fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
                    continue
                } elseif { [regexp -nocase {("pis up slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
                    continue
                } elseif { [regexp -nocase {("pis up fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
                    continue
                } elseif { [regexp -nocase {("b\.o\. move")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
                    continue
                } elseif { [regexp -nocase {("b\.o\. col/gobo")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
                    continue
                } elseif { [regexp -nocase {("b\.o\. p/t")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
                    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}
	
	# -------------------------------------------------------------------------------

	typemethod parse_strobe_effects { i data fix channel } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("OFF")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("no function")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("no function")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("pulse open fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("pulse open slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("pulse close fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("pulse close slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 fast] } {
		    if { [info exists slow] } {
                        lappend fixture($channel,$Cmd(strobe)) [list $slow $fast CONTINUE $fixture($channel,$slow) $fixture($channel,$fast)]
		    }
		    continue
		} elseif { [regexp -nocase {("slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 slow] } {
		    if { [info exists fast] } {
                        lappend fixture($channel,$Cmd(strobe)) [list $slow $fast CONTINUE $fixture($channel,$slow) $fixture($channel,$fast)]
		    }
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}
	
	# -------------------------------------------------------------------------------
	
	typemethod parse_strobe_random { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]
		
		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}
		
		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("OFF")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("random fast")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("random mid.")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("random slow")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("random pulse open fast")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("random pulse open slow")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("random pulse close fast")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("random pulse close slow")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("no function")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("no function")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}
	
	# -------------------------------------------------------------------------------

	typemethod parse_shutter_effect { i data fix channel } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("closed")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("strobe")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    lappend fixture($channel,$Cmd(strobe)) [list $from $to CONTINUE $fixture($channel,$from) $fixture($channel,$to)]
		    continue
		} elseif { [regexp -nocase {("pulse")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("random strobe")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("random pulse")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("no function")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("no function")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}
	
	# -------------------------------------------------------------------------------

	typemethod parse_color_effects { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("yellow with hole")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("blue with hole")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("green with hole")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("magenta with hole")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("uv filter")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("4 color")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("yellow")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("orange")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("white")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("warm filter")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("cold filter")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("warm filter")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("cold filter")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("blue with hole")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("yellow with hole")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("red")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("4 color")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("uv filter")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("slow \(10 rph\)")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("fast \(300 rpm\)")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_gobo_index_1_fine { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("minimum")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("maximum")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("[0-9]+")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_animation_wheel { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("no_effect")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("indexed v")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("indexed h")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("rotating v")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("rotating h")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("macro 1")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("macro 2")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("macro 3")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("macro 4")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("macro 5")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("Scroll (idx) V")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("Scroll (idx) h")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("Scroll (rot) V")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("Scroll (rot) g")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_animation_index { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("min")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("max")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_animation_rotating { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("ccw slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("ccw fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("cw slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("cw fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("static")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_iris { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("fast open")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("slow open")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("fast close")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("slow close")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("pulse slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("pulse fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("pulse open[ \t]+fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("pulse open[ \t]+slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("pulse close[ \t]+fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("pulse close[ \t]+slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("iris")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("iris open")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("random pulse open fast")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("random pulse open slow")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("random pulse close fast")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("random pulse close slow")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("wide open")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("close")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("large")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("small")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("small")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("wide open")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("max")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_macros { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("no macro")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reserved")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_focus { i data fix channel} {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("in")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("out")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {"far"[ \t]*at[ \t]*([0-9]+)} $line p faroffset] } {
		    if { [info exists nearoffset] } {
			lappend fixture(CHANNELS) $channel
                        lappend fixture($channel,COMMAND) $Cmd(focus)
			lappend fixture($channel,$Cmd(focus)) [list $nearoffset $faroffset CONTINUE 0 1]
		    }
		    continue
		} elseif { [regexp -nocase {"near"[ \t]*at[ \t]*([0-9]+)} $line p nearoffset] } {
		    if { [info exists faroffset] } {
			lappend fixture(CHANNELS) $channel
                        lappend fixture($channel,COMMAND) $Cmd(focus)
			lappend fixture($channel,$Cmd(strobe)) [list $nearoffset $faroffset CONTINUE 0 1]
		    }
		    continue
		} elseif { [regexp -nocase {("wide lens near")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("wide lens far")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("narrow lens near")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("narrow lens far")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_framing_s1_inout { i data fix channel} {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("out")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 out] } {
		    if { [info exists in] } {
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(move_leftshutter)
			lappend fixture($channel,$Cmd(move_leftshutter)) [list $out $in STEP 89 0]
		    }
		    continue
		} elseif { [regexp -nocase {("in")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 in] } {
		    if { [info exists out] } {
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(move_leftshutter)
			lappend fixture($channel,$Cmd(move_leftshutter)) [list $out $in STEP 89 0]
		    }
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_framing_s1_angle { i data fix channel} {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("\-")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 neg] } {
		    puts aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
		    if { [expr [info exists pos] && [info exists from] && [info exists to]] } {
			puts __aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(rotate_leftshutter)
			lappend fixture($channel,$Cmd(rotate_leftshutter)) [list $neg $pos STEP -90 90]
		    }
		    continue
		} elseif { [regexp -nocase {("\+")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 pos] } {
		    puts bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
		    if { [expr [info exists neg] && [info exists from] && [info exists to]] } {
			puts __bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(rotate_leftshutter)
			lappend fixture($channel,$Cmd(rotate_leftshutter)) [list $neg $pos STEP -90 90]
		    }
		    continue
		} elseif { [regexp -nocase {("parallel")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    puts ccccccccccccccccccccccccccccccccccccccccccccc
		    if { [expr [info exists neg] && [info exists pos]] } {
			puts __ccccccccccccccccccccccccccccccccccccccccccccc
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(rotate_leftshutter)
			lappend fixture($channel,$Cmd(rotate_leftshutter)) [list $neg $pos STEP -90 90]
		    }
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_framing_s2_inout { i data fix channel} {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("out")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 out] } {
		    if { [info exists in] } {
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(move_topshutter)
			lappend fixture($channel,$Cmd(move_topshutter)) [list $out $in STEP 89 0]
		    }
		    continue
		} elseif { [regexp -nocase {("in")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 in] } {
		    if { [info exists out] } {
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(move_topshutter)
			lappend fixture($channel,$Cmd(move_topshutter)) [list $out $in STEP 89 0]
		    }
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_framing_s2_angle { i data fix channel } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("\-")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 neg] } {
		    if { [expr [info exists pos] && [info exists from] && [info exists to]] } {
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(rotate_topshutter)
			lappend fixture($channel,$Cmd(rotate_topshutter)) [list $neg $pos STEP -90 90]
		    }
		    continue
		} elseif { [regexp -nocase {("\+")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 pos] } {
		    if { [expr [info exists neg] && [info exists from] && [info exists to]] } {
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(rotate_topshutter)
			lappend fixture($channel,$Cmd(rotate_topshutter)) [list $neg $pos STEP -90 90]
		    }
		    continue
		} elseif { [regexp -nocase {("parallel")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    if { [expr [info exists pos] && [info exists neg]] } {
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(rotate_topshutter)
			lappend fixture($channel,$Cmd(rotate_topshutter)) [list $neg $pos STEP -90 90]
		    }
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_framing_s3_inout { i data fix channel} {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("out")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 out] } {
		    if { [info exists in] } {
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(move_rightshutter)
			lappend fixture($channel,$Cmd(move_rightshutter)) [list $out $in STEP 89 0]
		    }
		    continue
		} elseif { [regexp -nocase {("in")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 in] } {
		    if { [info exists out] } {
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(move_rightshutter)
			lappend fixture($channel,$Cmd(move_rightshutter)) [list $out $in STEP 89 0]
		    }
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_framing_s3_angle { i data fix channel} {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("\-")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 neg] } {
		    if { [expr [info exists pos] && [info exists from] && [info exists to]] } {
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(rotate_rightshutter)
			lappend fixture($channel,$Cmd(rotate_rightshutter)) [list $neg $pos STEP -90 90]
		    }
		    continue
		} elseif { [regexp -nocase {("\+")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 pos] } {
		    if { [expr [info exists neg] && [info exists from] && [info exists to]] } {
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(rotate_rightshutter)
			lappend fixture($channel,$Cmd(rotate_rightshutter)) [list $neg $pos STEP -90 90]
		    }
		    continue
		} elseif { [regexp -nocase {("parallel")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    if { [expr [info exists pos] && [info exists neg]] } {
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(rotate_rightshutter)
			lappend fixture($channel,$Cmd(rotate_rightshutter)) [list $neg $pos STEP -90 90]
		    }
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_framing_s4_inout { i data fix channel} {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("out")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 out] } {
		    if { [info exists in] } {
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(move_bottomshutter)
			lappend fixture($channel,$Cmd(move_bottomshutter)) [list $out $in STEP 89 0]
		    }
		    continue
		} elseif { [regexp -nocase {("in")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 in] } {
		    if { [info exists out] } {
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(move_bottomshutter)
			lappend fixture($channel,$Cmd(move_bottomshutter)) [list $out $in STEP 89 0]
		    }
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_framing_s4_angle { i data fix channel} {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("\-")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 neg] } {
		    if { [expr [info exists neg] && [info exists from] && [info exists to]] } {
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(rotate_bottomshutter)
			lappend fixture($channel,$Cmd(rotate_bottomshutter)) [list $neg $pos STEP -90 90]
		    }
		    continue
		} elseif { [regexp -nocase {("\+")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 pos] } {
		    if { [expr [info exists pos] && [info exists from] && [info exists to]] } {
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(rotate_bottomshutter)
			lappend fixture($channel,$Cmd(rotate_bottomshutter)) [list $neg $pos STEP -90 90]
		    }
		    continue
		} elseif { [regexp -nocase {("parallel")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    if { [expr [info exists pos] && [info exists neg]] } {
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(rotate_bottomshutter)
			lappend fixture($channel,$Cmd(rotate_bottomshutter)) [list $neg $pos STEP -90 90]
		    }
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_framing_rotation { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("right")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("center")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("left")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_speed_other { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("tracking")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("studio disabled")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("studio enabled")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("shortcuts disabled")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("shortcuts enabled")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("fast")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_gobo_shake { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("normal")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("gobo shake")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("black move")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_gobo1_shake { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("gobo 1 slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 1 fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 2 slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 2 fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 3 slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 3 fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 4 slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 4 fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 5 slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 5 fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 6 slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 6 fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 7 slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 7 fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_gobo2_shake { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("gobo 2 slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 2 fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 3 slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 3 fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 4 slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 4 fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 5 slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 5 fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 6 slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 6 fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 1 slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 1 fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_gobo3_shake { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("gobo 2 slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 2 fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 3 slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 3 fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 4 slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 4 fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 5 slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 5 fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 6 slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 6 fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 1 slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo 1 fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_gobo2_fine { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("min")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("max")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("[0-9]+\%")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_gobo_fine { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("min")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("max")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("[0-9]+")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_gobo1_fine { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("min")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("max")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("[0-9]+\%")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_gobo3_fine { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("min")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("max")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("[0-9]+\%")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_frost_prism { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("lens")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("light frost")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("medium frost")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("heavy frost")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("cylinder prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("9 facet prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("9 faced prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("8 face prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("5 facet prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("5 faced prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("5 face prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("5 face")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("4 faced prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("4 face prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("4 face[ \t]+cw fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("4 face[ \t]+cw slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("4 face[ \t]+ccw fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("4 face[ \t]+ccw slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("4 face stop")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("4 face")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("2 facet prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("2 faced prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("2 face prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("2 face")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("2 face stop")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("2 face[ \t]+cw fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("2 face[ \t]+cw slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("2 face[ \t]+ccw fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("2 face[ \t]+ccw slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("linear")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("3d prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("linear[ \t]+ccw fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("linear[ \t]+ccw slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("linear stop")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("linear[ \t]+cw fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("linear[ \t]+cw slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("3d[ \t]+cw fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("3d[ \t]+cw slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("3d stop")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("3d[ \t]+ccw slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("3d[ \t]+ccw fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("full")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("warm filter")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("cold filter")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("prism 1")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("prism 2")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("frost")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("frost hole")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("frost")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("gobo1")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("gobo1\+warm")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("gobo1\+cold")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("gobo1\+prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("gobo2")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("gobo2\+warm")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("gobo2\+cold")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("gobo2\+prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("gobo3")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("gobo3\+warm")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("gobo3\+cold")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("gobo3\+prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("gobo4")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("gobo4\+warm")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("gobo4\+cold")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("gobo4\+prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("no effect")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("linear prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("stop")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("wide")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_frost_light { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("full")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_frost_heavy { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("full")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_prism_rotate { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("[0-9]+ degrees")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("[0-9]+")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("prism ccw fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("prism ccw slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("prism stop")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("prism cw fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("prism cw slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("fast rot. ccw")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("slow rot. ccw")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("fast rot. cw")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("slow rot. cw")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("stop")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("slow rotation")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("fast rotation")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("counter clock rotation")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("stop")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("rotate min")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("rotate max")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("rotation")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("rotate cw max")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("rotate cw min")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("stopped")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("rotate ccw max")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("rotate ccw min")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_prism_selection { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("4 face prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("multi prism")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_beam_shaper { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("full")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_beam_shape { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("vertical")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("horizontal")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_diffusers { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("ovalizer 1")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("ovalizer 2")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("diffuser")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("light diffuser")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("mid-range diffuser")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("strong diffuser")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		    # 				} elseif { [regexp -nocase {("open")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    # 					continue
		    # 				} elseif { [regexp -nocase {("ovalizer 1")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    # 					continue
		    # 				} elseif { [regexp -nocase {("ovalizer 2")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    # 					continue
		    # 				} elseif { [regexp -nocase {("diffuser")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    # 					continue
		} elseif { [regexp -nocase {("excluded")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("inserted")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_effectwheel { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {(".*")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
                    set name [SptParser::replace_string $key " " ""]
		    if { [info exists fixture(EFFECTS)] && [expr -1 == [lsearch $fixture(EFFECTS) $name]] } {
			continue
		    } else {
			regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
			if { [lsearch $SptParser::KeyWords $key] != -1  } {
			    break
			}
			SptParser::PutsVars i line
		    }
		} elseif { [regexp -nocase {"([0-9\.\-]+)"([ \t]*)(at)([ \t]*)([0-9]+)} $line p degree s1 key a3 num] } {
		    continue
		} elseif { [regexp -nocase {"far"([ \t]*)(at)([ \t]*)([0-9]+)} $line p key1 s1 key1 a3 num] } {
		    continue
		} elseif { [regexp -nocase {"near"([ \t]*)(at)([ \t]*)([0-9]+)} $line p key1 s1 key1 a3 num] } {
		    continue
		} elseif { [regexp -nocase {"min"([ \t]*)(at)([ \t]*)([0-9]+)} $line p key1 s1 key1 a3 num] } {
		    continue
		} elseif { [regexp -nocase {"max"([ \t]*)(at)([ \t]*)([0-9]+)} $line p key1 s1 key1 a3 num] } {
		    continue
		} elseif { [regexp -nocase {"open"([ \t]*)(at)([ \t]*)([0-9]+)} $line p key1 s1 key1 a3 num] } {
		    continue
		} elseif { [regexp -nocase {"full"([ \t]*)(at)([ \t]*)([0-9]+)} $line p key1 s1 key1 a3 num] } {
		    continue
		} elseif { [regexp -nocase {"([0-9]+)([ \t]+)Degrees"([ \t]*)(at)([ \t]*)([0-9]+)} $line p degree s1 key1 s2 key2 s3 num] } {
		    continue
		} elseif { [regexp -nocase {"(.*)([ \t]+)(rot. ccw)"([ \t]*)(at)([ \t]*)([0-9]+)} $line p speed s1 key1 s2 key2 s3 num] } {
		    continue
		} elseif { [regexp -nocase {"(.*)([ \t]+)(rot. cw)"([ \t]*)(at)([ \t]*)([0-9]+)} $line p speed s1 key1 s2 key2 s3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_ovalizer { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("excluded")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("inserted")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("[0-9]+")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_warm_filter { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("excluded")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("inserted")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_linear_frost { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("full")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_lens { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("sharp frames")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("sharp gobos")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("iris focal lens")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("gobo focal lens")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("narrow focal lens")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("narrow")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("narrow angle")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_internal_media_frame { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("full")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_pan_tilt_speed { i data fix channel } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("normal")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("ultra fast")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("vector fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("vector slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("tracking fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("tracking slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("tracking slow")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("full")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("slow")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("tracking")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("blackout")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("direct")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_color_speed { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("full")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("[0-9]+ second")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("[0-9]+ minute")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_beam_speed { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("full")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_move_speed { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("low")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("high")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("x-fade")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_intput_source { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("safe")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("s\-video in.3")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("internal source in.1")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("display off")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reserved")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_camera_zoom { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("auto")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_camera_zoom_fine { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("min")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("max")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_camera_focus { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("far")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("near")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_camera_focus_fine { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("min")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("max")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_camera_infra_red { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("off")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("ir auto/illuminator off")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("ir manual")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_camera_shutter { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("auto")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("shutter speed=30")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("shutter speed=15")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("shutter speed=8")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("shutter speed=4")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("shutter speed=2")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("shutter speed=1")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_camera_white_balance { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("auto")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("indoor")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("outdoor")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reserved")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_camera_orientation { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("flip off/mirror off")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("flip off/mirror on")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("flip on/mirror off")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("flip on/mirror on")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_camera_effects { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("off")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("freeze on/neg. off/b&w off")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("freeze off/neg. on/b&w off")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("freeze on/neg. on/b&w off")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("freeze off/neg. off/b&w on")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("freeze on/neg. off/b&w on")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_pan_tilt_mode { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("standard move")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("soft move")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_lamp_power_control { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("[0-9]+w")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_zap_effect { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("normal")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("zap effect")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("zap speed slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("zap speed fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("black move")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_lamp_right { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("park")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("lamp on")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("lamp off")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("idle")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_lamp_left_reset { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("park")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("2 lamps on")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("lamp on")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("lamp off")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reset pan/tilt")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reset cmy/zoom")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reset all exc. int.")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reset all")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("reset color")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_movement_type { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("normal")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("x rotate ccw")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("x rotate cw")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("y rotate cw")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("y rotate ccw")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("y rotate cw/x rotate ccw")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("y rotate ccw/x rotate cw")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("y/x rotate double speed")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_effects_rotate { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("[0-9]+")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("rotate cw max")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("rotate cw min")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("stop")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("rotate ccw max")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("rotate ccw min")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_black_move { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("normal")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("black move")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_color_pause { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("[0-9]+ second")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("[0-9]+ minute")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_programs { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("no functiion")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("no effect")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("program [0-9]+")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("random program")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("random")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("program sequence")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("sequence")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_color_mode { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("step")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("scroll")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_auto_function { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("idle")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("col. seq. fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("col. seq. slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("auto prog 2")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("full col. seq. fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("full col. seq. slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("auto prog 3")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("half col. seq. fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("half col. seq. slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("auto prog 4")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("rot. col. seq. fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("rot. col. seq. slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("random")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("all programs")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_reset_fan { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("reset")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("no function")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_colormode { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("normal")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("alternate")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("step")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("scroll")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_random_colors { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("fast")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("medium")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("slow")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_prism_macros { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("macro 1")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("macro 2")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("macro 3")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("macro 4")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("macro 5")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("macro 6")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("macro 7")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("macro 8")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_3_facet_prism { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("open")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("3 facet")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("stop")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("cw fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("cw slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("ccw fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("ccw slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_gobo_shake_blackout { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("no effect")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("blackout")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("shake slow")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} elseif { [regexp -nocase {("shake fast")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_shake_amplitude { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("min")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("max")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("size[ \t]+[0-9]+")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_gobo_color_mode { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("gobo\\color step")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("gobo scroll")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("color scroll")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("gobo\\color scroll")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_blackout { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("no blackout")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("blackout while moving")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_filter { i data fix } {
            upvar $fix     fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {("clear")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("wide")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {("beamshape[ \t+][0-9]+")([ \t]*)(at)([ \t]*)([0-9]+)} $line p key a1 a2 a3 num] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_silence { i data } {
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [SptParser::parse_line {"name" from num to num} $line "1 3"] } {
		    continue
		} elseif { [SptParser::parse_line {"name" at num} $line 1] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_gobowheel { i data fix channel } {
	    upvar $fix fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {"(gobo)([ \t]+)([0-9])([ \t]+)(slow)"([ \t]+)(at)([ \t]+)([0-9]+)} $line p key1 s1 slot s2 key2 s3 key3 s4 num1] } {
		    continue
		} elseif { [regexp -nocase {"(gobo)([ \t]+)([0-9])([ \t]+)(fast)"([ \t]+)(at)([ \t]+)([0-9]+)} $line p key1 s1 slot s2 key2 s3 key3 s4 num2] } {
		    continue
		} elseif { [regexp -nocase {"(min)"([ \t]+)(at)([ \t]+)([0-9]+)} $line p key1 s1 key2 s3 num1] } {
		    continue
		} elseif { [regexp -nocase {"(max)"([ \t]+)(at)([ \t]+)([0-9]+)} $line p key1 s1 key2 s3 num2] } {
		    continue
		} elseif { [regexp -nocase {"(fast)"([ \t]+)(at)([ \t]+)([0-9]+)} $line p key1 s1 key2 s3 num2] } {
		    continue
		} elseif { [regexp -nocase {"(slow)"([ \t]+)(at)([ \t]+)([0-9]+)} $line p key1 s1 key2 s3 num2] } {
		    continue
		} elseif { [regexp -nocase {"(direct)"([ \t]+)(at)([ \t]+)([0-9]+)} $line p key1 s1 key2 s3 num2] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_colorwheel { i data fix channel} {
	    upvar $fix fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [SptParser::parse_channeltype $line] } {
		    continue
		} elseif { [regexp -nocase {(".*")([ \t]*)(FROM)([ \t]*)([0-9]+)([ \t]*)(TO)([ \t]*)([0-9]+)} $line p key a1 a2 a3 from a4 a5 a6 to] } {
		    continue
		} elseif { [regexp -nocase {"(min)"([ \t]+)(at)([ \t]+)([0-9]+)} $line p key1 s1 key2 s3 min] } {
		    if { [info exists max] } {
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(fader)
			lappend fixture($channel,$Cmd(fader)) [list 0 255 STEP 0 2]
		    }
		    continue
		} elseif { [regexp -nocase {"(max)"([ \t]+)(at)([ \t]+)([0-9]+)} $line p key1 s1 key2 s3 max] } {
		    if { [info exists min] } {
			lappend fixture(CHANNELS) $channel
			lappend fixture($channel,COMMAND) $Cmd(fader)
			lappend fixture($channel,$Cmd(fader)) [list 0 255 STEP 0 2]
		    }
		    continue
		} elseif { [regexp -nocase {"(fast)"([ \t]+)(at)([ \t]+)([0-9]+)} $line p key1 s1 key2 s3 max] } {
		    continue
		} elseif { [regexp -nocase {"(slow)"([ \t]+)(at)([ \t]+)([0-9]+)} $line p key1 s1 key2 s3 max] } {
		    continue		  
		} elseif { [regexp -nocase {"(direct)"([ \t]+)(at)([ \t]+)([0-9]+)} $line p key1 s1 key2 s3 max] } {
		    continue
		} else {
		    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			break
		    }
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_color { i data fix } {
	    upvar $fix fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		# jusr print them out
		regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		if { [lsearch $SptParser::KeyWords $key] != -1  } {
		    break
		}
		SptParser::PutsVars i line
		#end
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_move { i data fix } {
	    upvar $fix fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		# jusr print them out
		regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		if { [lsearch $SptParser::KeyWords $key] != -1  } {
		    break
		}
		SptParser::PutsVars i line
		#end
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_intensity { i data fix } {
	    upvar $fix fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		# jusr print them out
		regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		if { [lsearch $SptParser::KeyWords $key] != -1  } {
		    break
		}
		SptParser::PutsVars i line
		#end
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_framing_rotate { i data fix } {
	    upvar $fix fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		# jusr print them out
		regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		if { [lsearch $SptParser::KeyWords $key] != -1  } {
		    break
		}
		SptParser::PutsVars i line
		#end
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

	typemethod parse_framing_inout { i data fix } {
	    upvar $fix fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		# jusr print them out
		regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		if { [lsearch $SptParser::KeyWords $key] != -1  } {
		    break
		}
		SptParser::PutsVars i line
		#end
	    }
	    return [expr $i - 1]
	}

	# -------------------------------------------------------------------------------

    }
}


# set i [$type parse_gobowheel $i $data fixture]
# set i [$type parse_colorwheel $i $data fixture]
# set i [$type parse_color $i $data fixture]
# set i [$type parse_move $i $data fixture]
# set i [$type parse_intensity $i $data fixture]
# set i [$type parse_iris $i $data fixture]
# set i [$type parse_framing_rotate $i $data fixture]
# set i [$type parse_framing_inout $i $data fixture]

