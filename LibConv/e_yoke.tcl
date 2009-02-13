package require snit
namespace eval SptParser {

    snit::type EYoke {
	typevariable KeyWord1 {HEIGHT WIDTH DEPTH THICKNESS CONNECTION PAN TILT BASE SPEED }
        typevariable Cmd -array { pan "pan" tilt "tilt" pancorse "pan_corse" tiltcorse "tilt_corse" panfine "pan_fine" tiltfine "tilt_fine" movespeed "set_movespeed"}


        typemethod parse { ct fix i data } {
            upvar $ct channeltype
            upvar $fix     fixture
            set line [SptParser::remove_comments [lindex $data $i]]

            if { [SptParser::parse_line "yoke height num unit" $line "0 1"] } {
            } elseif { [SptParser::parse_line "yoke swapable" $line "0 1"] } {
            } elseif { [SptParser::parse_line "yoke" $line "0"] } {
            } elseif { [SptParser::parse_line "yoke no leg" $line "0 1 2"] } {
                return $i
            } else {
                SptParser::PutsVars i line
            }

            for {incr i} { $i<[llength $data] } {incr i } {

                set line [SptParser::remove_comments [lindex $data $i]]
                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

                if { [SptParser::parse_line "height num unit" $line 0] } {
                    continue
                } elseif { [SptParser::parse_line "width num unit" $line 0] } {
                    continue
                } elseif { [SptParser::parse_line "depth num unit" $line 0] } {
                    continue
                } elseif { [SptParser::parse_line "thickness vertical num unit" $line "0 1"] } {
                    incr i
                    set line [SptParser::remove_comments [lindex $data $i]]
                    if { ![SptParser::parse_line "horizontal num unit" $line 0] } {  SptParser::PutsVars i line }
                    continue
                } elseif { [SptParser::parse_line "connection offset num unit" $line "0 1"] } {
                    continue
                } elseif { [SptParser::parse_line "base" $line 0] } {
                    set i [$type parse_base $i $data]
                    continue
		} elseif { [regexp -nocase {^[ \t]*pan[ \t]+invertable[ \t]+offset[ \t]+([0-9]+)[ \t]+high[ \t]+offset[ \t]+([0-9]+)} $line p loff hioff] } {
#                    set channeltype($) MOVE
		    lappend fixture(CHANNELS) $hioff; # coarse
		    lappend fixture($hioff,COMMAND) $Cmd(pancorse)
		    lappend fixture(CHANNELS) $loff; # coarse
		    lappend fixture($loff,COMMAND) $Cmd(panfine)
                    set i [$type parse_pan $i $data fixture $hioff $loff 2]
		    continue
		} elseif { [regexp -nocase {^[ \t]*pan[ \t]+offset[ \t]+([0-9]+)[ \t]+high[ \t]+offset[ \t]+([0-9]+)} $line p loff hioff] } {
#                    set channeltype($off2) MOVE
		    lappend fixture(CHANNELS) $hioff; # coarse
		    lappend fixture($hioff,COMMAND) $Cmd(pancorse)
		    lappend fixture(CHANNELS) $loff; # coarse
		    lappend fixture($loff,COMMAND) $Cmd(panfine)
                    set i [$type parse_pan $i $data fixture $hioff $loff 2]
                    continue
		} elseif { [regexp -nocase {^[ \t]*pan[ \t]+invertable[ \t]+offset[ \t]+([0-9]+)} $line p off] } {
#                    set channeltype($off) MOVE
		    lappend fixture(CHANNELS) $off
		    lappend fixture($off,COMMAND) $Cmd(pan)
                    set i [$type parse_pan $i $data fixture $off 0 1]
                    continue
		} elseif { [regexp -nocase {^[ \t]*pan[ \t]+offset[ \t]+([0-9]+)} $line p off] } {
#                    set channeltype($off) MOVE
		    lappend fixture(CHANNELS) $off
		    lappend fixture($off,COMMAND) $Cmd(pan)
                    set i [$type parse_pan $i $data fixture $off 0 1]
		    continue
		} elseif { [regexp -nocase {^[ \t]*tilt[ \t]+invertable[ \t]+offset[ \t]+([0-9]+)[ \t]+high[ \t]+offset[ \t]+([0-9]+)} $line p loff hioff] } {
#                    set channeltype($off2) MOVE
		    lappend fixture(CHANNELS) $hioff; # coarse
		    lappend fixture($hioff,COMMAND) $Cmd(tiltcorse)
		    lappend fixture(CHANNELS) $loff; # coarse
		    lappend fixture($loff,COMMAND) $Cmd(tiltfine)
                    set i [$type parse_tilt $i $data fixture $hioff $loff 2]
                    continue
		} elseif { [regexp -nocase {^[ \t]*tilt[ \t]+offset[ \t]+([0-9]+)[ \t]+high[ \t]+offset[ \t]+([0-9]+)} $line p loff hioff] } {
#                    set channeltype($off2) MOVE
		    lappend fixture(CHANNELS) $hioff; # coarse
		    lappend fixture($hioff,COMMAND) $Cmd(tiltcorse)
		    lappend fixture(CHANNELS) $loff; # coarse
		    lappend fixture($loff,COMMAND) $Cmd(tiltfine)
                    set i [$type parse_tilt $i $data fixture $off2 $loff 2]
                    continue
		} elseif { [regexp -nocase {^[ \t]*tilt[ \t]+invertable[ \t]+offset[ \t]+([0-9]+)} $line p off] } {
#                    set channeltype($off) MOVE
		    lappend fixture(CHANNELS) $off
		    lappend fixture($off,COMMAND) $Cmd(tilt)
                    set i [$type parse_tilt $i $data fixture $off 0 1]
                    continue
		} elseif { [regexp -nocase {^[ \t]*tilt[ \t]+offset[ \t]+([0-9]+)} $line p off] } {
#                    set channeltype($off) MOVE
		    lappend fixture(CHANNELS) $off
		    lappend fixture($off,COMMAND) $Cmd(tilt)
                    set i [$type parse_tilt $i $data fixture $off 0 1]
                    continue
                } elseif { [regexp -nocase {(^[ \t]*speed)([ \t]+)(fixed)([ \t]+)(at)([ \t]+)([0-9]+)} $line p a1 a2 a3 a4 a5 a6 num] } {
		    #					set fixture(MOVESPEED) $num
		    set fixture(PANSPEED)  $num
		    set fixture(TILTSPEED) $num
                    continue
                } elseif { [regexp -nocase {(^[ \t]*speed)([ \t]+)(variable)([ \t]+)(offset)([ \t]+)([0-9]+)} $line p a1 a2 a3 a4 a5 a6 off] } {
                    set channeltype($off) MOVESPEED
		    lappend fixture(CHANNELS) $off
		    lappend fixture($off,COMMAND) $Cmd(movespeed)
                    set i [$type parse_speed $i $data fixture $off]
                    continue
                } else {
                    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
                    if { [lsearch $SptParser::KeyWords $key] != -1  } {
			return [expr $i - 1 ]
		    }
                    SptParser::PutsVars i line
                    break
                }
            }
            return [expr $i-1]
    	}

	typemethod parse_base { i data } {

	    incr i
	    set line [SptParser::remove_comments [lindex $data $i]]
	    if { ![SptParser::parse_line "width num unit" $line 0] } {  SptParser::PutsVars i line }

	    incr i
	    set line [SptParser::remove_comments [lindex $data $i]]
	    if { ![SptParser::parse_line "height num unit" $line 0] } {  SptParser::PutsVars i line }

	    incr i
	    set line [SptParser::remove_comments [lindex $data $i]]
	    if { ![SptParser::parse_line "depth num unit" $line 0] } {  SptParser::PutsVars i line }

	    incr i
	    set line [SptParser::remove_comments [lindex $data $i]]
	    if { ![SptParser::parse_line "marker num degrees" $line 0] } {  SptParser::PutsVars i line }

	    return $i
	}

        typemethod parse_pan { i data fix hich loch chnum } {
	    upvar $fix fixture

            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

                if { [regexp -nocase {([0-9.-]+)[ \t]+degrees[ \t]+at[ \t]+([0-9]+)} $line p deg byteval] } {
		    if { ![info exists min] } {
			set min $byteval
			set max $byteval
			set mindeg $deg
			set maxdeg $deg
		    } else {
			if { $byteval < $min } {
			    set min $byteval
			    set mindeg $deg
			} elseif { $byteval > $max } {
			    set max $byteval
			    set maxdeg $deg
			}
			
			if { $chnum == 1 } {
			    lappend fixture($hich,$Cmd(pan)) [list $min $max STEP $mindeg $maxdeg]
			} elseif { $chnum == 2 } {
			    set minhi [expr $min >> 8]
			    set minlo [expr $min & 0xFF]
			    set maxhi [expr $max >> 8]
			    set maxlo [expr $max & 0xFF]
			    lappend fixture($hich,$Cmd(pancorse)) [list $minhi $maxhi STEP $mindeg $maxdeg]
			    lappend fixture($loch,$Cmd(panfine)) [list $minlo $maxlo STEP $mindeg $maxdeg]
			}
		    }
                    continue
                } else {
                    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
                    if { [lsearch $KeyWord1 $key] != -1  } { return [expr $i - 1 ] }
                    if { [lsearch $SptParser::KeyWords $key] != -1  } { return [expr $i - 1 ] }
                    SptParser::PutsVars i line
                    break
                }
            }

            return [expr $i-1]
        }

        typemethod parse_tilt { i data fix hich loch chnum } {
	    upvar $fix fixture

            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]

                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

                if { [regexp -nocase {([0-9.-]+)[ \t]+degrees[ \t]+at[ \t]+([0-9]+)} $line p deg byteval] } {
		    if { ![info exists min] } {
			set min $byteval
			set max $byteval
			set mindeg $deg
			set maxdeg $deg
		    } else {
			if { $byteval < $min } {
			    set min $byteval
			    set mindeg $deg
			} elseif { $byteval > $max } {
			    set max $byteval
			    set maxdeg $deg
			}
			
			if { $chnum == 1 } {
			    lappend fixture($hich,$Cmd(tilt)) [list $min $max STEP $mindeg $maxdeg]
			} elseif { $chnum == 2 } {
			    set minhi [expr $min >> 8]
			    set minlo [expr $min & 0xFF]
			    set maxhi [expr $max >> 8]
			    set maxlo [expr $max & 0xFF]
			    lappend fixture($hich,$Cmd(tiltcorse)) [list $minhi $maxhi STEP $mindeg $maxdeg]
			    lappend fixture($loch,$Cmd(tiltfine)) [list $minlo $maxlo STEP $mindeg $maxdeg]
			}
		    }
                    continue
                } else {
                    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
                    if { [lsearch $KeyWord1 $key] != -1  } { return [expr $i - 1 ] }
                    if { [lsearch $SptParser::KeyWords $key] != -1  } { return [expr $i - 1 ] }
                    SptParser::PutsVars i line
                    break
                }
            }
            return [expr $i-1]
        }

	typemethod parse_speed { i data fix channel} {
	    upvar $fix fixture

	    set atTimes 0
	    for {incr i} { $i<[llength $data] } {incr i } {
                set line [lindex $data $i]
		if { [regexp -nocase {([0-9\.]+).*(normal)} $line p speed key] } {
		    #					set fixture(MOVESPEED) $speed
		    set fixture(PANSPEED)  $speed
		    set fixture(TILTSPEED) $speed
		}

                set line [SptParser::remove_comments [lindex $data $i]]

		set rtn [SptParser::check_misc $i $data $line]
		if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

		if { [regexp -nocase {(^[ \t]*)([0-9]+)([ \t]+)(from)([ \t]+)([0-9]+)([ \t]+)(to)([ \t]+)([0-9]+)} $line p s0 speed s1 from s2 start s3 to s4 end] } {
		    for { set idx $start} {$idx<=$end} {incr idx} {
			lappend fixture($channel,$Cmd(movespeed)) [list $idx $idx STEP $speed $speed]
		    }
		    set hashTable($start) [list $start $end $speed $speed]
		    lappend index $start
                    continue
		} elseif { [regexp -nocase {([0-9\.]+)([ \t]+)(at)([ \t]+)([0-9]+)} $line p speed s1 key s2 num] } {
		    incr atTimes
		    if { $atTimes != 2 } {
			set fromSpeed $speed
			set fromOffset $num
		    } else {
			set toSpeed $speed
			set toOffset $num
			lappend fixture($channel,$Cmd(movespeed)) [list $fromOffset $toOffset STEP $fromSpeed $toSpeed]
			set atTimes 0
		    }
                    continue
		} else {
                    regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
                    if { [lsearch $KeyWord1 $key] != -1 || [lsearch $SptParser::KeyWords $key] != -1  } {
			if {![info exists index]} { return [expr $i -1] }
			set index [lsort -increasing $index]
			foreach idx $index {
			    lassign $hashTable($idx) start end fspeed tspeed
			    lappend fixture($channel,$Cmd(movespeed)) [list $start $end STEP $fspeed $tspeed]
			}
			return [expr $i - 1 ]
		    }
                    SptParser::PutsVars i line
                    break
		}
	    }

	    if {![info exists index]} { return [expr $i -1] }
	    set index [lsort -increasing $index]
	    foreach idx $index {
		lassign $hashTable($idx) start end fspeed tspeed
		lappend fixture($channel,$Cmd(movespeed)) [list $start $end STEP $fspeed $tspeed]
	    }

	    return [expr $i-1]
	}
    }
}

