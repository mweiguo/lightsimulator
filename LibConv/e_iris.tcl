package require snit
namespace eval SptParser {

    snit::type EIris {
	typevariable channel
        typevariable Cmd -array { iris "iris" }

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
	    set to 255
	    set inverted 0
	    for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [regexp -nocase {CHANNELTYPE[ \t]+RANGE[ \t]+FROM[ \t]+([0-9.-]+)[ \t]+TO[ \t]+([0-9.-]+)[ \t]+inverted} $line p from to] } {
		    set inverted 1
                    continue
		} elseif { [regexp -nocase {CHANNELTYPE[ \t]+RANGE[ \t]+FROM[ \t]+([0-9.-]+)[ \t]+TO[ \t]+([0-9.-]+)} $line p from to] } {
		    set inverted 0
		    continue
		} elseif { [regexp -nocase {CHANNELTYPE[ \t]+inverted} $line p] } {
		    set inverted 1
                    continue
		} elseif { [regexp -nocase {CHANNELTYPE} $line p] } {
		    set inverted 0
                    continue
		} elseif { [regexp {OPEN[ \t]+([0-9.-]+)[ \t]*%} $line p open] } {
		    if { ![info exists close] } continue
		    lappend fixture(CHANNELS) $channel
		    lappend fixture($channel,COMMAND) $Cmd(iris)
		    if { $inverted == 0 } {
			lappend fixture($channel,$Cmd(iris)) [list $from $to STEP [expr $open/100.0] [expr $close/100.0]]
		    } else {
			lappend fixture($channel,$Cmd(iris)) [list $from $to STEP [expr $close/100.0] [expr $open/100.0]]
		    }
		} elseif { [regexp {(CLOSED)([ \t]+)([0-9.-]+)} $line p a1 a2 close] } {
		    if { ![info exists open] } continue
		    lappend fixture(CHANNELS) $channel
		    lappend fixture($channel,COMMAND) $Cmd(iris)
		    if { $inverted == 0 } {
			lappend fixture($channel,$Cmd(iris)) [list $from $to STEP [expr $open/100.0] [expr $close/100.0]]
		    } else {
			lappend fixture($channel,$Cmd(iris)) [list $from $to STEP [expr $close/100.0] [expr $open/100.0]]
		    }
		} else {
                    regexp -nocase {[ \t]*([^ \t]*)[ \t]*} $line p key
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