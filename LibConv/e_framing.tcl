package require snit
namespace eval SptParser {

    snit::type EFraming {
	typevariable KeyWord1 {BLADE ROTATOR }
        typevariable Cmd -array { moveblade "move_blade" rotateblade "rotate_blade" rotateblades "rotate_blades" bladeleft "blade_left" bladeright "blade_right" }
        typemethod parse { ct fix i data } {
            upvar $ct      channeltype
            upvar $fix     fixture
	    
	    # for shutter occurrence
	    set shutters { topshutter bottomshutter leftshutter rightshutter }
	    set shutterOccurrence 0

	    set line [SptParser::remove_comments [lindex $data $i]]
	    if { ![SptParser::parse_line "framing" $line 0] } {
		SptParser::PutsVars i line
	    }

	    for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
		regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [lsearch $SptParser::KeyWords $key] != -1  } { return [expr $i - 1 ] }

		if { $key == "TYPE" } {
		    if { ![SptParser::parse_line "type = name" $line "0 1"] } { SptParser::PutsVars i line }
		} elseif { [regexp -nocase {blade[ \t]+at[ \t]+([0-9]+\.?[0-9]+)[ \t]+degrees} $line p degree] } {
		    if { ![info exists fixture(BLADES)] } {
			set bladeid 0			
		    } else { 
			set bladeid [llength $fixture(BLADES)]
		    }
		    lappend fixture(BLADES) [list $bladeid $degree]
		    set i [$type parse_blade $i $data fixture $bladeid]
		} elseif { [regexp -nocase {rotator[ \t]+offset[ \t]+([0-9]+)} $line p channel] } {
		    set channeltype($channel) FRAMING_ROTATE
		    set i [$type parse_rotator $i $data fixture $channel]
		} else {
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i+1]
	}

	typemethod parse_blade { i data fix bladeid} {
	    upvar $fix fixture

	    for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
		set rtn [SptParser::check_misc $i $data $line]
		regexp -nocase {[ \t]*([^ \t]*)[ \t]*} $line p key
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [lsearch $SptParser::KeyWords $key] != -1  } { return [expr $i - 1 ] }
		if { [lsearch $KeyWord1 $key] != -1} {  return [expr $i - 1 ] }

		if { [regexp -nocase {inout[ \t]+offset[ \t]+([0-9]+)} $line p channel] } {
		    lappend fixture(CHANNELS) $channel
		    lappend fixture($channel,COMMAND) $Cmd(moveblade)
		    lappend fixture($channel,$Cmd(moveblade)) [list 0 255 STEP $bladeid 1 0.5] ;# 0 - open 255 - close
                    set i [$type parse_inout $bladeid $channel $i $data fixture]
		} elseif { [regexp -nocase {angle[ \t]+offset[ \t]+([0-9]+)} $line p channel] } {
                    set i [$type parse_angle $bladeid $channel $i $data fixture]
		} elseif { [regexp -nocase {left[ \t]+offset[ \t]+([0-9]+)} $line p channel] } {
		    lappend fixture(CHANNELS) $channel
		    lappend fixture($channel,COMMAND) $Cmd(bladeleft)
		    lappend fixture($channel,$Cmd(bladeleft)) [list 0 255 STEP $bladeid 1 0.5]
		} elseif { [regexp -nocase {right[ \t]+offset[ \t]+([0-9]+)} $line p channel] } {
		    lappend fixture(CHANNELS) $channel
		    lappend fixture($channel,COMMAND) $Cmd(bladeright)
		    lappend fixture($channel,$Cmd(bladeright)) [list 0 255 STEP $bladeid 1 0.5]
		} elseif { [regexp -nocase {(channeltype)([ \t]+)(name)([ \t]+)(=)([ \t]+)"(.*)"} $line p key1 s1 key2 s2 key3 s3 name] } {
		} elseif { [regexp -nocase {([0-9\.\-]+)([ \t]+)(at)([ \t]+)([0-9]+)} $line p num1 s1 key s2 num2] } {
		} else {
		    SptParser::PutsVars i line
		}
	    }
	    return [expr $i+1]
	}

	typemethod parse_rotator { i data fix channel } {
            upvar $fix fixture
	    for {incr i} { $i<[llength $data] } {incr i } {
		set line [SptParser::remove_comments [lindex $data $i]]
		regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
		set key1 [lindex $line 1]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

# 		if { [lsearch $SptParser::KeyWords $key] != -1  } { return [expr $i - 1 ] }
# 		if { [lsearch $KeyWord1 $key] != -1} {  return [expr $i - 1 ] }

		if { [regexp -nocase {(\-?[0-9]+\.?[0-9]*)[ \t]+at[ \t]+([0-9]+)} $line p angle dmxval]} {
		    if { ![info exists minangle] } {
			set minangle $angle
			set maxangle $angle
			set minangledmx $dmxval
			set maxangledmx $dmxval
		    } else {
			if { $angle < $minangle } {
			    set minangle $angle
			    set minangledmx $dmxval
			} elseif { $angle > $maxangle } {
			    set maxangle $angle
			    set maxangledmx $dmxval
			}
		    }
		} elseif { [regexp -nocase {([+\-]?[0-9]+\.?[0-9]*)[ \t]+from[ \t]+([0-9]+)[ \t]+to[ \t]+([0-9]+)} $line p angle dmxvalf dmxvalt]} {
		} else {
 		    lappend fixture(CHANNELS) $channel
 		    lappend fixture($channel,COMMAND) $Cmd(rotateblades)
 		    lappend fixture($channel,$Cmd(rotateblades)) [list $minangledmx $maxangledmx STEP $minangle $maxangle]
		    break
		}
	    }
	    return [expr $i - 1]
	}

        typemethod parse_inout { bladeid channel i data fix } {
            upvar $fix fixture
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue   }

		if { [regexp -nocase {channeltype[ \t]+name[ \t]*=[ \t]*"(name)"} $line p name] } {
#		    set fixture(COMMAND,$name) [list EFraming::parse_inout $bladeid $channel]
                    continue
		} elseif { [regexp -nocase {"out"[ \t]+at[ \t]+([0-9]+)} $line p outdmx] } {
# 		    if { [info exists indmx] } {
# 			lappend fixture(CHANNELS) $ch
# 			lappend fixture($channel,COMMAND) $moveblade
# 			lappend fixture($channel,$moveblade) [list $outdmx $indmx STEP $bladeid 0 1]
# 		    }
		} elseif { [regexp -nocase {"in"[ \t]+at[ \t]+([0-9]+)} $line p indmx] } {
# 		    if { [info exists outdmx] } {
# 			lappend fixture(CHANNELS) $ch
# 			lappend fixture($channel,COMMAND) $moveblade
# 			lappend fixture($channel,$moveblade) [list $outdmx $indmx STEP $bladeid 0 1]
# 		    }
                } else {
                    break
                }
            }
            return [expr $i - 1 ]
        }

        typemethod parse_angle { bladeid channel i data fix } {
            upvar $fix fixture
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue   }

		if { [regexp -nocase {channeltype[ \t]+name[ \t]*=[ \t]*"(.*)"} $line p name] } {
#		    set fixture(COMMAND,$name) [list EFraming::parse_angle $bladeid $channel]
                    continue
		} elseif { [regexp -nocase {(\-?[0-9]+)[ \t]+at[ \t]+([0-9]+)} $line p angle dmxval]} {
#		    set fixture(BLADEANGLE,$bladeid,$dmxval) $angle
		    if { ![info exists minangle] } {
			set minangle $angle
			set maxangle $angle
			set minangledmx $dmxval
			set maxangledmx $dmxval
		    } else {
			if { $angle < $minangle } {
			    set minangle $angle
			    set minangledmx $dmxval
			} elseif { $angle > $maxangle } {
			    set maxangle $angle
			    set maxangledmx $dmxval
			}
		    }
		} elseif { [regexp -nocase {"-"[ \t]+at[ \t]+([0-9]+)} $line p leftdmx]} {
# 		    if { ![info exists rightdmx] } continue
#  		    lappend fixture(CHANNELS) $channel
#  		    lappend fixture($channel,COMMAND) $rotateblade
# 		    lappend fixture($channel,$rotateblade) [list $leftdmx $rightdmx STEP $bladeid $fixture(BLADEANGLE,$bladeid,$leftdmx) $fixture(BLADEANGLE,$bladeid,$rightdmx)]
		} elseif { [regexp -nocase {"parallel"[ \t]+from[ \t]+([0-9]+)[ \t]+to[ \t]+([0-9]+)} $line p parf part]} {
		} elseif { [regexp -nocase {"+"[ \t]+at[ \t]+([0-9]+)} $line p rightdmx]} {
# 		    if { ![info exists leftdmx] } continue
#  		    lappend fixture(CHANNELS) $channel
#  		    lappend fixture($channel,COMMAND) $rotateblade
#  		    lappend fixture($channel,$rotateblade) [list $leftdmx $rightdmx STEP $bladeid $fixture(BLADEANGLE,$bladeid,$leftdmx) $fixture(BLADEANGLE,$bladeid,$rightdmx)]
                } else {
 		    lappend fixture(CHANNELS) $channel
 		    lappend fixture($channel,COMMAND) $Cmd(rotateblade)
 		    lappend fixture($channel,$Cmd(rotateblade)) [list  $minangledmx $maxangledmx STEP $bladeid $minangle $maxangle]
                    break
                }
            }
            return [expr $i - 1 ]
        }
    }
}