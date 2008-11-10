package require snit
namespace eval SptParser {

    snit::type EGobo_rotation {
		typevariable channel
        typevariable Cmd -array { rotate_cw "rotate_gobo_cw" rotate_ccw "rotate_gobo_ccw"}

        typemethod parse { xmlRoot fix i data } {

            upvar $xmlRoot root
            upvar $fix     fixture
            set line [SptParser::remove_comments [lindex $data $i]]

			if { ![SptParser::parse_line "gobo_rotation offset num" $line "0 1"] } {
				SptParser::PutsVars i line
			} else {
                set channel [lindex $line 2]
			}

            set idx 0
            set beginspeed ""
            set endspeed ""
			set lines {}
    		for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
    			set key [lindex $line 0]
				set key1 [lindex $line 1]

  				set rtn [SptParser::check_misc $i $data $line]
    			if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

				if { [SptParser::parse_channeltype $line] } {
#                    SptParser::PutsVars i line
					continue
				} elseif { [SptParser::parse_line "num at 0num" $line 1] } {
                    regexp {([0-9.-]+)([ \t]+)(AT)([ \t]+)([0-9]+)} $line p a1 a2 a3 a4 a5
                    incr idx
                    if { $idx ==  2} {
                        set endspeed $a1
                        set to $a5
                        lappend fixture(CHANNELS) $channel
                        if { $beginspeed >= 0 } {
                            lappend fixture($channel,COMMAND) $Cmd(rotate_cw)
                            lappend fixture($channel,$Cmd(rotate_cw)) [list $from $to STEP $beginspeed $endspeed]
                        } else {
                            lappend fixture($channel,COMMAND) $Cmd(rotate_ccw)
                            lappend fixture($channel,$Cmd(rotate_ccw)) [list $from $to STEP [expr -1 * $beginspeed] [expr -1 * $endspeed]]
                        }

                        set idx 0
                    } else {
                        set beginspeed $a1
                        set from $a5
                    }
					continue
				} elseif { [SptParser::parse_line "num from num to num" $line "1 3"] } {
#                    regexp {([0-9.]+)([ \t]+)(FROM)([ \t]+)([0-9]+)([ \t]+)(TO)([ \t]+)([0-9]+)} $line p a1 a2 a3 a4 a5 a6 a7 a8 a9
					continue
				} else {
                    set key [lindex $line 0]
                    if { [lsearch $SptParser::KeyWords $key] != -1  } {
                        return [expr $i - 1 ]
                    }
                    SptParser::PutsVars i line key
				}
			}

			return [expr $i - 1]
    	}
    }
}
