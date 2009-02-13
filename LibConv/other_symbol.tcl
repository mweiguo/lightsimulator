namespace eval SptParser {
    package require Tclx

    variable gVersion 5.0.0.0

    # this function will modify the index
    proc parse_define { i data {macro ""}} {
        if { $macro == "" } {
            set line [SptParser::remove_comments [lindex $data $i]]
        } else {
            set line $macro
        }

	if { [parse_line "#msdversion" $line 0] } {
            if { ![compare_version [lindex $line 1] [lindex $line 2]] } {
		return [skip_define [expr $i + 1] $data]
	    }
            return 0
        } elseif { [parse_line "#else" $line 0] } {
            return [skip_else $i $data]
        } elseif { [parse_line "#mendversion" $line 0] } {
            return $i
	}
	return -1
    }

    # will return next define symbol's line index
    proc skip_define { i data } {

	for {} { $i<[llength $data] } {incr i } {
	    set line [lindex $data $i]
	    set line [string trimleft $line " "]
	    if {[string range $line 0 0]=="#"} { return $i }
	}
	return [expr $i - 1]
    }

    proc skip_else { i data } {

	for {} { $i<[llength $data] } {incr i } {
	    set line [lindex $data $i]
	    set line [string trimleft $line " "]
	    #			if {[string range $line 0 0]=="#"} { return $i }
	    if { [regexp -nocase {#mendversion} $line] } {return $i }
	}
	return [expr $i - 1]		
    }

    proc compare_version { sign version } {
	#       PutsVars sign version
	variable gVersion

	set st [split $gVersion .]
	lassign $st v1 v2 v3 v4
	if { $v1 ==""} { set v1 0 }
	if { $v2 ==""} { set v2 0 }
	if { $v3 ==""} { set v3 0 }
	if { $v4 ==""} { set v4 0 }
	set st [expr $v1*1000 + $v2*100 + $v3*10 + $v4]

	set dt [split $version .]
	lassign $dt v1 v2 v3 v4
	if { $v1 ==""} { set v1 0 }
	if { $v2 ==""} { set v2 0 }
	if { $v3 ==""} { set v3 0 }
	if { $v4 ==""} { set v4 0 }
	set dt [expr $v1*1000 + $v2*100 + $v3*10 + $v4]

	return [expr $st $sign $dt]
    }

    # if this line is comment return 1, else return 0
    proc parse_comment { line } {
	set line [string trimleft $line " "]
	if {[string range $line 0 1]=="//"} { return 1 }
	return 0
    }

    # if data match the pattern return 1,else return 0
    proc parse_line { pattern line {cmpids ""} {bmatchall 0} } {
	# convert to list first
	set pattern [split $pattern]

	foreach cmpid $cmpids {
	    set pnodes($cmpid) [lindex $pattern $cmpid]
	}

	# build pattern
	set ps1 {([ \t]*)}
	set ps2 {([ \t]+)}
	set pc1 {([^ \t]+)}
	#        set pc2 {("[^ \t]+.*[^ \t]+")|("[^ \t]+")}
	set pc2 {(".+")}

	set lastNeedSpace 0
	for {set i 0} {$i<[llength $pattern]} {incr i} {
	    set t [lindex $pattern $i]
	    set needspace 1


	    if { [info exists pnodes($i) ] } {
		set pt "($pnodes($i))"
	    } elseif { [string first "\"" $t] != -1 && [string last "\"" $t] != -1 } {
		set pt $pc2
		set needspace 0
	    } else {
		set pt $pc1
	    }

	    if { $i == [expr [llength $pattern] - 1]} {
		if { $bmatchall } {
		    set needspace 0
		}
	    }

	    if { $lastNeedSpace && $needspace } {
		append p $ps2 $pt
	    } else {
		append p $ps1 $pt
	    }

	    set lastNeedSpace $needspace
	}

	set p "^${p}"
	if { $bmatchall } {
	    append p $
	}
	#        puts $p
	return [regexp -nocase $p $line]

	return 1
    }


    # return value 0 == just skip   >0 == set index & skip   == -1 do nothing
    proc check_misc { i data line } {
	if { [string trim $line ]== "" } { return 0 } ; #skip space line
	if { [SptParser::parse_comment $line] } { return 0 }   ; #skip comment
	set rtn [SptParser::parse_define $i $data] ; # choose define block
	return $rtn
    }

    proc parse_channeltype { line } {
	if { ![parse_line "CHANNELTYPE" $line 0] } {
	    return 0
	}

	if { [parse_line "CHANNELTYPE RANGE FROM num TO num" $line "0 1 2 4"] } {
	    return 1
	} elseif { [parse_line "CHANNELTYPE NORMAL" $line "0 1"] } {
	    return 1
	} elseif { [parse_line "CHANNELTYPE INVERTED" $line "0 1"] } {
	    return 1
	} elseif { [parse_line "CHANNELTYPE NOFADE" $line "0 1"] } {
	    return 1
	} elseif { [parse_line {CHANNELTYPE NAME = "name"} $line "0 1 2"] } {
	    return 1
	} elseif { [parse_line {CHANNELTYPE} $line 0] } {
	    return 1
	}
	return 0
    }

    proc PutsVars {args} {
	set topfn       [lindex [info level  1] 0]
	set bottomfn    [lindex [info level -1] 0]

	if {$topfn == $bottomfn } {
	    puts -nonewline "$topfn : "
	} else {
	    puts -nonewline "$topfn ... $bottomfn : "
	}

	foreach var $args {
	    upvar $var v
	    if {[info exists v]} {
		puts -nonewline "$var='$v'  "
	    } else {
		puts -nonewline "$var='UNKNOWN'  "
	    }
	}
	puts ""
    }

    proc remove_comments { str } {
	set idx [string first // $str]
	if { $idx == -1 } {
	    return $str
	}
	incr idx -1
	return [string range $str 0 $idx]
    }

    proc replace_string { str oldstr newstr } {
	set len [string length $oldstr]
	while { 1 } {
	    set first [string first $oldstr $str 0]
	    set last [expr $len + $first -1]

	    if { -1 == $first }  break
	    set str [string replace $str $first $last ""]
	}

	return $str
    }

    # in        : xmlRoot
    # in        : fixInfo
    proc genxml { xmlDoc xmlRoot fixInfo } {
	upvar $xmlDoc doc
	upvar $xmlRoot root
	upvar $fixInfo fixture

	if { [info exists fixture(PANSPEED)] } {
	    set speed [$doc createElement PANSPEED]
	    $speed setAttribute value $fixture(PANSPEED)
	    $root appendChild $speed
	}
	if { [info exists fixture(TILTSPEED)] } {
	    set speed [$doc createElement TILTSPEED]
	    $speed setAttribute value $fixture(TILTSPEED)
	    $root appendChild $speed
	}

	# channel number
	if { [info exists fixture(CHANNELNUM)] } {
	    set ch [$doc createElement CHANNELNUM]
	    set chtext [$doc createTextNode $fixture(CHANNELNUM)]
	    $ch appendChild $chtext
	    $root appendChild $ch
	}

	# model file reference
	if { [info exists fixture(MODELFILE)] } {
	    set mod [$doc createElement MODELFILE]
	    set modtext [$doc createTextNode $fixture(MODELFILE)]
	    $mod appendChild $modtext
	    $root appendChild $mod
	}

	if { [info exists fixture(MANUFACTOR)] } {
	    set manu [$doc createElement MANUFACTOR]
	    set manutext [$doc createTextNode $fixture(MANUFACTOR)]
	    $manu appendChild $manutext
	    $root appendChild $manu
	}

	if { [info exists fixture(CHANNELS)] } {
	    set fixture(CHANNELS) [lrmdups $fixture(CHANNELS)]

	    # iterate each channel
	    foreach ch $fixture(CHANNELS) {
		set fixture($ch,COMMAND) [lrmdups $fixture($ch,COMMAND)]

		set channel [$doc createElement CHANNEL]
		$root appendChild $channel
		$channel setAttribute id $ch
		if { [info exists fixture(CHANNELNAME,$ch)] } {
		    $channel setAttribute name $fixture(CHANNELNAME,$ch)
		}

		# iterate each command
		foreach cmd $fixture($ch,COMMAND) {	    
		    if { [info exists fixture($ch,$cmd)]==0 } continue
#		    puts "fixture($ch,COMMAND) = $cmd"
		    foreach values $fixture($ch,$cmd) {
			lassign $values vfrom vto vtype vpara1 vpara2 vpara3 vpara4

			set command [$doc createElement COMMAND]
			$channel appendChild $command
			$command setAttribute name $cmd

			set range [$doc createElement RANGE]
			$command appendChild $range
			$range setAttribute from $vfrom to $vto

			if { "" != $vpara1 } {
			    set para1 [$doc createElement PARA1]
			    set para1text [$doc createTextNode $vpara1]
			    $para1 appendChild $para1text
			    $command appendChild $para1
			}
			if { "" != $vpara2 } {
			    set para2 [$doc createElement PARA2]
			    set para2text [$doc createTextNode $vpara2]
			    $para2 appendChild $para2text
			    $command appendChild $para2
			}
			if { "" != $vpara3 } {
			    set para3 [$doc createElement PARA3]
			    set para3text [$doc createTextNode $vpara3]
			    $para3 appendChild $para3text
			    $command appendChild $para3
			}
			if { "" != $vpara4 } {
			    set para4 [$doc createElement PARA4]
			    set para4text [$doc createTextNode $vpara4]
			    $para4 appendChild $para4text
			    $command appendChild $para4
			}
		    }
		}
	    }
	}
	
	# iterate each effectwheel
	if { [info exists fixture(EFFECTWHEELS)] } {
	    foreach wh $fixture(EFFECTWHEELS) {
		if  { [info exists fixture(EFFECTWHEEL,$wh)]==0 } continue
		set wheel [$doc createElement EFFECTWHEEL]
		$root appendChild $wheel
		$wheel setAttribute id $wh

		# add blank slot
		set slot [$doc createElement SLOT]
		$wheel appendChild $slot
		$slot setAttribute id 0 name blank path blank.bmp
		# iterate each slot
		foreach values $fixture(EFFECTWHEEL,$wh) {
		    lassign $values sid name path
		    set slot [$doc createElement SLOT]
		    $wheel appendChild $slot
		    $slot setAttribute id $sid name $name path $path
		}
	    }
	}

	# iterate each gobowheel
	if { [info exists fixture(GOBOWHEELS)] } {
	    foreach wh $fixture(GOBOWHEELS) {
		if  { [info exists fixture(GOBOWHEEL,$wh)]==0 } continue
		set wheel [$doc createElement GOBOWHEEL]
		$root appendChild $wheel
		$wheel setAttribute id $wh

		# add blank slot
		set slot [$doc createElement SLOT]
		$wheel appendChild $slot
		$slot setAttribute id 0 name blank path blank.bmp
		# iterate each slot
		foreach values $fixture(GOBOWHEEL,$wh) {
		    lassign $values sid name path
		    set slot [$doc createElement SLOT]
		    $wheel appendChild $slot
		    $slot setAttribute id $sid name $name path $path
		}
	    }
	}

	# iterate each colorwheel
	if { [info exists fixture(COLORWHEELS)] } {
	    foreach wh $fixture(COLORWHEELS) {
		if { [info exists fixture(COLORWHEEL,$wh)]==0 } continue
		set wheel [$doc createElement COLORWHEEL]
		$root appendChild $wheel
		$wheel setAttribute id $wh

		# add blank slot
		set slot [$doc createElement SLOT]
		$wheel appendChild $slot
		$slot setAttribute id 0 name blank r 255 g 255 b 255
		# iterate each slot
		foreach values $fixture(COLORWHEEL,$wh) {
		    lassign $values sid name r g b
		    set slot [$doc createElement SLOT]
		    $wheel appendChild $slot
		    $slot setAttribute id $sid name $name r $r g $g b $b
		}
	    }
	}

	# iterate each animation wheel
	if { [info exists fixture(ANIMATIONWHEELS)] } {
	    foreach wh $fixture(ANIMATIONWHEELS) {
		if { [info exists fixture(ANIMATIONWHEEL,$wh)]==0 } continue
		lassign $fixture(ANIMATIONWHEEL,$wh) id name path

		set wheel [$doc createElement ANIMATIONWHEEL]
		$root appendChild $wheel
		$wheel setAttribute id $id name $name path $path
	    }
	}

	# iterate each lens
	if { [info exists fixture(LENS)] } {
	    foreach lens $fixture(LENS) {
		lassign $lens name min max

		set lens [$doc createElement LENS]
		$root appendChild $lens
		$lens setAttribute name $name min $min max $max
	    }
	}

	if { [info exists fixture(MINOPENING)] && [info exists fixture(MAXOPENING)] } {
	    set lens [$doc createElement LENS]
	    $root appendChild $lens
	    $lens setAttribute name DEFAULT min $fixture(MINOPENING) max $fixture(MAXOPENING)
	    
	}

	# POWER
	if { [info exists fixture(WATTAGE)] } {
	    set power [$doc createElement POWER]
	    $root appendChild $power
	    $power setAttribute wattage $fixture(WATTAGE)
	}
	
	# WEIGHT
	if { [info exists fixture(WEIGHT)] } {
	    set weight [$doc createElement WEIGHT]
	    $root appendChild $weight
	    $weight setAttribute weight $fixture(WEIGHT)
	}
	
	# blades
	if { [info exists fixture(BLADES)] } {
	    foreach b $fixture(BLADES) {
		lassign $b bladeid degree
		set blade [$doc createElement BLADE]
		$root appendChild $blade
		$blade setAttribute id $bladeid degree $degree

	    }
	}
	
    }
}