package require snit
namespace eval SptParser {

    snit::type EFraming {
		typevariable KeyWord1 {BLADE ROTATOR }
        typevariable Cmd -array { leftshutter_leftfader "leftshutter_leftfader" leftshutter_rightfader "leftshutter_rightfader" topshutter_leftfader "topshutter_leftfader" topshutter_rightfader "topshutter_rightfader" rightshutter_leftfader "rightshutter_leftfader" rightshutter_rightfader "rightshutter_rightfader"	bottomshutter_leftfader "bottomshutter_leftfader" bottomshutter_rightfader "bottomshutter_rightfader"}

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
				} elseif { [regexp -nocase {(blade)([ \t]+)(at)([ \t]+)([0-9\.\-]+)([ \t]+)(degrees)} $line p key1 s1 key2 s2 degree s3 key3] } {
					set line1 [lindex $data $i]
					if { [regexp -nocase {top} $line1] } {
						set shutter topshutter
						incr shutterOccurrence
					} elseif { [regexp -nocase {bottom} $line1]} {
						set shutter bottomshutter
						incr shutterOccurrence
					} elseif { [regexp -nocase {left} $line1]} {
						set shutter leftshutter
						incr shutterOccurrence
					} elseif { [regexp -nocase {right} $line1]} {
						set shutter rightshutter
						incr shutterOccurrence
					} else {
						set shutter [lindex $shutters $shutterOccurrence ]
						puts "$shutter : $shutters : $shutterOccurrence"
						incr shutterOccurrence
					}
					
					set i [$type parse_blade $i $data fixture $shutter]
				} elseif { [regexp -nocase {(rotator)([ \t]+)(offset)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 channel] } {
               		set channeltype($channel) FRAMING_ROTATE
					set i [$type parse_rotator $i $data]
				} else {
					SptParser::PutsVars i line
				}
			}
			return [expr $i+1]
		}

		typemethod parse_blade { i data fix shutter} {
			upvar $fix fixture

    		for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
 				set rtn [SptParser::check_misc $i $data $line]
				regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
    			if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

    			if { [lsearch $SptParser::KeyWords $key] != -1  } { return [expr $i - 1 ] }
    			if { [lsearch $KeyWord1 $key] != -1} {  return [expr $i - 1 ] }

				if { [regexp -nocase {(inout)([ \t]+)(offset)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 channel] } {
					lappend fixture(CHANNELS) $channel
					lappend fixture($channel,COMMAND) move_$shutter
					lappend fixture($channel,move_$shutter) [list 0 255 STEP 89 0]
                    set i [$type parse_inout $i $data fixture]
				} elseif { [regexp -nocase {(angle)([ \t]+)(offset)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 channel] } {
					lappend fixture(CHANNELS) $channel
					lappend fixture($channel,COMMAND) rotate_$shutter
					lappend fixture($channel,rotate_$shutter) [list 0 255 STEP -90 90]
                    set i [$type parse_angle $i $data fixture]
				} elseif { [regexp -nocase {(left)([ \t]+)(offset)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 channel] } {
					lappend fixture(CHANNELS) $channel
					lappend fixture($channel,COMMAND) $Cmd(${shutter}_leftfader)
					lappend fixture($channel,$Cmd(${shutter}_leftfader)) [list 0 255 STEP $fixture(MINOPENING) $fixture(MAXOPENING)]
				} elseif { [regexp -nocase {(right)([ \t]+)(offset)([ \t]+)([0-9]+)} $line p key1 s1 key2 s2 channel] } {
					lappend fixture(CHANNELS) $channel
					lappend fixture($channel,COMMAND) $Cmd(${shutter}_rightfader)
					lappend fixture($channel,$Cmd(${shutter}_rightfader)) [list 0 255 STEP $fixture(MINOPENING) $fixture(MAXOPENING)]
				} elseif { [regexp -nocase {(channeltype)([ \t]+)(name)([ \t]+)(=)([ \t]+)"(.*)"} $line p key1 s1 key2 s2 key3 s3 name] } {
				} elseif { [regexp -nocase {([0-9\.\-]+)([ \t]+)(at)([ \t]+)([0-9]+)} $line p num1 s1 key s2 num2] } {
					
				} else {
					SptParser::PutsVars i line
				}
			}
			return [expr $i+1]
		}

		typemethod parse_rotator { i data } {
			for {incr i} { $i<[llength $data] } {incr i } {
				set line [SptParser::remove_comments [lindex $data $i]]
				regexp -nocase {([ \t]*)([^ \t]*)([ \t]*)} $line p s1 key s2
				set key1 [lindex $line 1]

				set rtn [SptParser::check_misc $i $data $line]
				if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue	}

				if { [lsearch $SptParser::KeyWords $key] != -1  } { return [expr $i - 1 ] }
				if { [lsearch $KeyWord1 $key] != -1} {  return [expr $i - 1 ] }

				if { [SptParser::parse_line "num at num" $line 1] } {
					continue
				} elseif { [SptParser::parse_line "num from num to num" $line "1 3"] } {
					continue
				} else {
					SptParser::PutsVars i line
				}
			}
			return [expr $i+1]
		}

        typemethod parse_inout {i data fix } {
            upvar $fix fixture
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue   }

				if { [regexp -nocase {(channeltype)([ \t]+)(name)([ \t]*)(=)([ \t]*)"(name)"} $line p key1 s1 key2 s2 key3 s4 name] } {
                    continue
                } else {
                    break
                }
            }
            return [expr $i - 1 ]
        }

        typemethod parse_angle {i data fix } {
            upvar $fix fixture
            for {incr i} { $i<[llength $data] } {incr i } {
                set line [SptParser::remove_comments [lindex $data $i]]
                set rtn [SptParser::check_misc $i $data $line]
                if { $rtn > 0 } { set i $rtn; continue } elseif { $rtn != -1 } { continue   }

				if { [regexp -nocase {(channeltype)([ \t]+)(name)([ \t]*)(=)([ \t]*)"(name)"} $line p key1 s1 key2 s2 key3 s4 name] } {
                    continue
                } else {
                    break
                }
            }
            return [expr $i - 1 ]
        }
	}
}