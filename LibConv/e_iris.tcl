package require snit
namespace eval SptParser {

    snit::type EIris {
		typevariable channel
        typevariable Cmd -array { iris "zoom" }

        typemethod parse { ct fix i data } {
            upvar $ct      channeltype
            upvar $fix     fixture

            set line [SptParser::remove_comments [lindex $data $i]]

            if { ![regexp -nocase {(iris)([ \t]+)(offset)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 channel] } {
                set $line
				SptParser::PutsVars i line
			}

    		set channeltype($channel) IRIS


            set from 0
            set to 0
    		for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

  				set rtn [SptParser::check_misc $i $data $line]
    			if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

				if { [regexp -nocase {(CHANNELTYPE)([ \t]+)(RANGE)([ \t]+)(FROM)([ \t]+)([0-9.-]+)([ \t]+)(TO)([ \t]+)([0-9.-]+)([ \t]+)(inverted)} $line p a1 a2 a3 a4 a5 a6 from a8 a9 a10 to s key] } {
                    continue
				} elseif { [regexp -nocase {(CHANNELTYPE)([ \t]+)(RANGE)([ \t]+)(FROM)([ \t]+)([0-9.-]+)([ \t]+)(TO)([ \t]+)([0-9.-]+)} $line p a1 a2 a3 a4 a5 a6 from a8 a9 a10 to] } {
                    continue
				} elseif { [regexp {(OPEN)([ \t]+)([0-9.-]+)} $line p a1 a2 open] } {
					if {[info exists close]} {
						if { ![info exists key] } {
							lappend fixture(CHANNELS) $channel
							lappend fixture($channel,COMMAND) $Cmd(iris)
							lappend fixture($channel,$Cmd(iris)) [list $from $to STEP [expr $fixture(MAXOPENING)*$open/100.0] [expr $fixture(MAXOPENING)*$close/100.0]]
						} else {
							lappend fixture(CHANNELS) $channel
							lappend fixture($channel,COMMAND) $Cmd(iris)
							lappend fixture($channel,$Cmd(iris)) [list $from $to STEP [expr $fixture(MAXOPENING)*$close/100.0] [expr $fixture(MAXOPENING)*$open/100.0]]
						}
					}
                    continue
				} elseif { [regexp {(CLOSED)([ \t]+)([0-9.-]+)} $line p a1 a2 close] } {
					if {[info exists open]} {
						if { ![info exists key] } {
							lappend fixture(CHANNELS) $channel
							lappend fixture($channel,COMMAND) $Cmd(iris)
							lappend fixture($channel,$Cmd(iris)) [list $from $to STEP [expr $fixture(MAXOPENING)*$open/100.0] [expr $fixture(MAXOPENING)*$close/100.0]]
						} else {
							lappend fixture(CHANNELS) $channel
							lappend fixture($channel,COMMAND) $Cmd(iris)
							lappend fixture($channel,$Cmd(iris)) [list $from $to STEP [expr $fixture(MAXOPENING)*$close/100.0] [expr $fixture(MAXOPENING)*$open/100.0]]
						}
					}
                    continue
				} else {
                    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
                    if { [lsearch $SptParser::KeyWords $key] != -1  } {
                        return [expr $i - 1 ]
                    }
					SptParser::PutsVars i line
				}
			}

			return [expr $i+1]
		}
	}
}