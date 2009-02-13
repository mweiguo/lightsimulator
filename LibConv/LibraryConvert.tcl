package require tdom
package require Pgtcl 1.5
package require Tclx

set fixtureTable {}
array set modelTable {}
set colorwheelTable {}
set gobowheelTable {}
set effectwheelTable {}
set protocolTable {}
set colorTable {}
set goboTable {}
set effectTable {}
set animationTable {}
set COLORTBL_IDSEED 0
set GOBOTBL_IDSEED 0
set EFFECTTBL_IDSEED 0
set ANIMATIONTBL_IDSEED 0

set protocolID 0

# ------------------------------------------------ convert XML version Fixture Library to pgsql
proc libconvert libpath {
    global manufacturerTable
    global fixtureTable
    global modelTable
    global colorwheelTable
    global gobowheelTable
    global effectwheelTable
    global animationwheelTable
    global protocolTable
    global colorTable
    global goboTable
    global effectTable
    global animationTable
    global lensTable
    global bladesTable

    #==============================================================================================
    #   t_fixturemodelpara               t_Manufacturer
    #              |                            |
    #              ---------------------------------------------------------------------
    #              |                                    |              |               |
    #          t_Fixtures                           t_Colors        t_Gobos        t_Effects
    #              |                                    |              |               |
    #              |                                    |              |               |
    #              |                                    |              |               |
    #        t_dmxprotocol                         t_GoboWheel   t_EffectWheel   t_colorwheel
    #
    #==============================================================================================

    # build 10 table in memory
    set dirs [glob -nocomplain -type d -directory $libpath *]
    set fixid 0
    set modid 0
    foreach dir $dirs {
	set tmp [file split $dir]
	set manu [lindex $tmp end]
	lappend manufacturerTable $manu; # dirs should be filled in manufaturerTable

	set files [glob -nocomplain -type f -directory $dir -tails *.xml]
	set models {}
	set protocols {}
	foreach file $files {
	    if { [regexp {mod.*} $file] } {
		lappend models $file
	    } else {
		lappend protocols $file
	    }
	}
	foreach model $models {
	    set rst [parse_model $modid $dir/$model]
	    if { 0 == [llength $rst] } continue
	    set modelTable($model) $rst
	    incr modid
	}

	foreach protocol $protocols {
	    if { [parse_dmxprotocol $fixid $dir/$protocol $manu]} {
		incr fixid
	    }
	}
    }
    puts "parse ok"
    # save each table to database
    set conn [pg_connect -conninfo { host=localhost port=5432 dbname=vt20 user=postgres password=12345}]
    # clear 10 table
    pg_exec $conn {delete from "t_fixturemodelpara"}
    pg_exec $conn {delete from "t_Manufacturer"}
    puts "clear tables ok"
    # fill t_Manufacturer
    foreach name $manufacturerTable {
	set rsthandle [pg_exec $conn "INSERT INTO \"t_Manufacturer\"(name) VALUES ('$name')"]
#	puts "set rsthandle \[pg_exec $conn \"INSERT INTO \"t_Manufacturer\"(name) VALUES ('$name')\"\]"
	pg_result $rsthandle -clear
    }
    # fill t_fixturemodelpara
    foreach {name modelpara} [array get modelTable] {
	lassign $modelpara modid offx  offy  offz  length  radius  ratio type filename
	set rsthandle [pg_exec $conn "INSERT INTO t_fixturemodelpara( offx, offy, offz, length, radius, ratio, \"type\", model_path, id) VALUES ($offx, $offy, $offz, $length, $radius, $ratio, $type, '$filename', $modid)"]
	pg_result $rsthandle -clear
    }
    puts "fill t_fixturemodelpara ok"
    # fill t_Fixtures
    foreach fixture $fixtureTable {
	lassign $fixture manufacturer fixtureName power fixid mvspeed channelNum supporties modid weight
	set rsthandle [pg_exec $conn "INSERT INTO \"t_Fixtures\"( manufacturer, name, power, id, channel_num, support_ies, model_id, weight, init_mvspeed) VALUES ('$manufacturer', '$fixtureName', $power, $fixid, $channelNum, $supporties, $modid, $weight, $mvspeed)"]
#	puts "$rsthandle INSERT INTO \"t_Fixtures\"( manufacturer, name, power, id, channel_num, support_ies, model_id, weight, init_mvspeed) VALUES ('$manufacturer', '$fixtureName', $power, $fixid, $channelNum, $supporties, $modid, $weight, $mvspeed)"
	pg_result $rsthandle -clear
    }
    puts "fill t_Fixtures ok"
    # fill t_Colors
    foreach color $colorTable {
	lassign $color id color_name red green blue manu
	set rsthandle [pg_exec $conn "INSERT INTO \"t_Colors\"( id, color_name, red, green, blue, manufacturer) VALUES ($id, '$color_name', $red, $green, $blue, '$manu')"]
	pg_result $rsthandle -clear
    }
    puts "fill t_Colors ok"
    # fill t_Gobos
    foreach gobo $goboTable {
	lassign $gobo id gobo_name image_path manu
	set rsthandle [pg_exec $conn "INSERT INTO \"t_Gobos\"(id, gobo_name, image_path, manufacturer) VALUES ($id, '$gobo_name', '$image_path', '$manu')"]
	pg_result $rsthandle -clear
    }
    puts "fill t_Gobos ok"
    # fill t_Effects
    foreach effect $effectTable {
	lassign $effect id effect_name image_path manu data
	if { $data == "" } {
	    if { $id == 29 || $id == 30 || $id == 31 || $id == 32 } {
		puts "INSERT INTO \"t_Effects\"( id, effect_name, image_path, manufacturer) VALUES ($id, '$effect_name', '$image_path', '$manu')"
	    }
	    set rsthandle [pg_exec $conn "INSERT INTO \"t_Effects\"( id, effect_name, image_path, manufacturer) VALUES ($id, '$effect_name', '$image_path', '$manu')"]
	} else {
	    if { $id == 29 || $id == 30 || $id == 31 || $id == 32 } {
		puts "INSERT INTO \"t_Effects\"( id, effect_name, image_path, manufacturer, effect_data) VALUES ($id, '$effect_name', '$image_path', '$manu', '$data')"
	    }
	    set rsthandle [pg_exec $conn "INSERT INTO \"t_Effects\"( id, effect_name, image_path, manufacturer, effect_data) VALUES ($id, '$effect_name', '$image_path', '$manu', '$data')"]
	}
	pg_result $rsthandle -clear
    }
    puts "fill t_Effects ok"
    
#    puts $animationTable
    foreach animation $animationTable {
	lassign $animation wheelid animation_name image_path manu
#	puts "INSERT INTO \"t_Animations\"( name, path, id, manufacturer) VALUES ('$animation_name', '$image_path', $wheelid, '$manu')"
	set rsthandle [pg_exec $conn "INSERT INTO \"t_Animations\"( name, path, id, manufacturer) VALUES ('$animation_name', '$image_path', $wheelid, '$manu')"]
	pg_result $rsthandle -clear
    }
    puts "fill t_Animation ok"

    # fill t_GoboWheel
    foreach gobo $gobowheelTable {
	lassign $gobo slotid fixid wheelid goboid
	set rsthandle [pg_exec $conn "INSERT INTO \"t_GoboWheel\"( slot_id, fixture_id, wheel_id, gobo_id) VALUES ($slotid, $fixid, $wheelid, $goboid)"]
	pg_result $rsthandle -clear
    }
    
    puts "fill t_GoboWheel ok"
    # fill t_ColorWheel
    foreach color $colorwheelTable {
    	lassign $color wheelid slotid fixid colorid
	set rsthandle [pg_exec $conn "INSERT INTO \"t_colorwheel\"( wheel_id, slot_id, fixture_id, color_id) VALUES ($wheelid, $slotid, $fixid, $colorid)"]
	pg_result $rsthandle -clear
    }
    puts "fill t_ColorWheel ok"
    # fill t_EffectWheel
    foreach effect $effectwheelTable {
	lassign $effect slotid fixid wheelid effectid
	set rsthandle [pg_exec $conn "INSERT INTO \"t_EffectWheel\"( slot_id, fixture_id, wheel_id, effect_id) VALUES ($slotid, $fixid, $wheelid, $effectid)"]
	pg_result $rsthandle -clear
    }
    puts "fill t_EffectWheel ok"
    # fill t_dmxprotocol
    foreach protocol $protocolTable {
	lassign $protocol channelID para1 para2 para3 para4 from to fixid cmdName protocolID channelName
	if { "" == $para4 } {
	    set rsthandle [pg_exec $conn "INSERT INTO t_dmxprotocol( channel_id, para1, para2, para3, start_value, end_value, fixture_id, command_name, id, name) VALUES ($channelID, $para1, $para2, '$para3', $from, $to, $fixid, '$cmdName', $protocolID, '$channelName')"]
	} else {
	    set rsthandle [pg_exec $conn "INSERT INTO t_dmxprotocol( channel_id, para1, para2, para3, start_value, end_value, fixture_id, command_name, id, name, para4) VALUES ($channelID, $para1, $para2, '$para3', $from, $to, $fixid, '$cmdName', $protocolID, '$channelName', '$para4')"]
	}
        pg_result $rsthandle -clear
    }
    puts "fill t_dmxprotocol ok"

    # fill t_lens
    foreach lens $lensTable {
	lassign $lens name min max fixid
#	puts "pg_exec $conn INSERT INTO \"t_lens\"( min_opening, max_opening, fixture_id, lens_name) VALUES ($min, $max, $fixid, '$name')"
	set rsthandle [pg_exec $conn "INSERT INTO \"t_lens\"( min_opening, max_opening, fixture_id, lens_name) VALUES ($min, $max, $fixid, '$name')"]
	pg_result $rsthandle -clear
    }
    puts "fill t_lens ok"
    
    # fill t_blades
    foreach blade $bladesTable {
	lassign $blade index degree fixid
	set rsthandle [pg_exec $conn "INSERT INTO t_blades( blade_index, degree, fixture_id) VALUES ($index, $degree, $fixid)"]
	pg_result $rsthandle -clear
    }
    puts "fill t_blades ok"

    # fill t_animationwheel
    foreach wheel $animationwheelTable {
	lassign $wheel id fixid animation_id
	set rsthandle [pg_exec $conn "INSERT INTO \"t_AnimationWheel\"( wheel_id, fixture_id, animation_id) VALUES ($id, $fixid, $animation_id)"]
	pg_result $rsthandle -clear
    }
    puts "puts t_animationwheel ok"
    
    pg_disconnect $conn
}

# parse xml version fixture libraray, add correspond information to each memory Table
proc parse_dmxprotocol {fixid protocolpath manu} {
    global manufacturerTable
    global fixtureTable
    global modelTable
    global colorwheelTable
    global gobowheelTable
    global effectwheelTable
    global protocolTable
    global colorTable
    global goboTable
    global effectTable
    global lensTable
    global bladesTable
    global animationwheelTable

    global protocolID

    # read xml file
    set tmp [file split $protocolpath]
    set fixtureName [lindex $tmp end]
    set fixtureName [string range $fixtureName 0 end-4]
    set f [open $protocolpath]
    fconfigure $f -encoding "utf-8"
    set data [read $f]
    close $f
    
    # use xml tool parse files
    set doc [dom parse $data]
    set tagRoot [$doc getElementsByTagName ROOT]
    set tagChannelNum [$doc getElementsByTagName CHANNELNUM]
    set tagModelFile [$doc getElementsByTagName MODELFILE]
    set tagChannels [$doc getElementsByTagName CHANNEL]
    set tagGoboWheels [$doc getElementsByTagName GOBOWHEEL]
    set tagColorWheels [$doc getElementsByTagName COLORWHEEL]
    set tagEffectWheels [$doc getElementsByTagName EFFECTWHEEL]
    set tagLenses [$doc getElementsByTagName LENS]
    set tagPowers [$doc getElementsByTagName POWER]
    set tagWeights [$doc getElementsByTagName WEIGHT]
    set tagBlades [$doc getElementsByTagName BLADE]
    set tagAnimationWheels [$doc getElementsByTagName ANIMATIONWHEEL]

    # should do parameter checking here
    if { $tagChannelNum == "" } { return 0 }

    # CHANNELNUM part
    set channelNum [$tagChannelNum text]
    # MODELFILE part
    set modfile [$tagModelFile text]
    
    if { ![info exists modelTable($modfile)] } { 
        return 0 
    }
    
    set modid [lindex $modelTable($modfile) 0]

    # CHANNEL part
    foreach tagChannel $tagChannels {
        if { [catch {
            set channelID [$tagChannel getAttribute id]
            set channelName [$tagChannel getAttribute name]
            set tagCmds [$tagChannel childNodes]
            foreach tagCmd $tagCmds {
                set cmdName [$tagCmd getAttribute name]
                set subNodes [$tagCmd childNodes]
                set from ""; set to ""; set para1 "0"; set para2 "0"; set para3 ""; set para4 ""
		foreach subNode $subNodes {
		    switch [$subNode nodeName] {
			RANGE {set from [$subNode getAttribute from]; set to [$subNode getAttribute to]}
			PARA1 {set para1 [$subNode text]}
			PARA2 {set para2 [$subNode text]}
			PARA3 {set para3 [$subNode text]}
			PARA4 {set para4 [$subNode text]}
		    }
		}
		lappend protocolTable [list $channelID $para1 $para2 $para3 $para4 $from $to $fixid $cmdName $protocolID $channelName]
		incr protocolID
	    } } result ] } {
	    #	    puts $result
	    continue
	}
    }

    # COLORWHEEL part: fill colorTable and colorwheelTable
    foreach tagColorWheel $tagColorWheels {
	set wheelid [$tagColorWheel getAttribute id]
	set tagSlots [$tagColorWheel childNodes]
	foreach tagSlot $tagSlots {
	    set slotid [$tagSlot getAttribute id]
	    set colorname [$tagSlot getAttribute name]
	    set r [$tagSlot getAttribute r]
	    set g [$tagSlot getAttribute g]
	    set b [$tagSlot getAttribute b]
	   
	    lappend colorwheelTable [list $wheelid $slotid $fixid [add_color $colorname $r $g $b $manu]]
	}
    }

    # GOBOWHEEL part: fill goboTable and gobowheelTable
    foreach tagGoboWheel $tagGoboWheels {
	set wheelid [$tagGoboWheel getAttribute id]
	set tagSlots [$tagGoboWheel childNodes]
	foreach tagSlot $tagSlots {
	    set slotid [$tagSlot getAttribute id]
	    set goboname [$tagSlot getAttribute name]
	    set imgpath [$tagSlot getAttribute path]

	    regsub -nocase {\.bmp} $imgpath .dds imgpath

	    regexp -nocase {(.*)\.dds} $imgpath p goboname
	    
#	    puts "add_gobo $goboname $imgpath $manu"
	    lappend gobowheelTable [list $slotid $fixid $wheelid [add_gobo $goboname $imgpath $manu] ]
	}
    }

    # EFFECTWHEEL part: fill effectTable and effectwheelTable
    foreach tagEffectWheel $tagEffectWheels {
	set wheelid [$tagEffectWheel getAttribute id]
	set tagSlots [$tagEffectWheel childNodes]
	foreach tagSlot $tagSlots {
	    set slotid [$tagSlot getAttribute id]
	    set effectname [$tagSlot getAttribute name]
	    set imgpath [$tagSlot getAttribute path]
	    regsub -all {\\} $imgpath / imgpath
	    regsub -nocase {\.bmp} $imgpath .dds imgpath
	    regexp -nocase {(.*)/(.*)\.dds} $imgpath p effectfolder effectname
	    lappend effectwheelTable [list $slotid $fixid $wheelid [add_effect $effectname $imgpath $manu]]
	}
    }

    # ANIMATIONS part: fill animationTable and animationwheelTable
    foreach tagAnimationWheel $tagAnimationWheels {
	set wheelid    [$tagAnimationWheel getAttribute id]
	set name  [$tagAnimationWheel getAttribute name]
	set imgpath  [$tagAnimationWheel getAttribute path]
	regsub -all {\\} $imgpath / imgpath
	regsub -nocase {\.bmp} $imgpath .dds imgpath
	lappend animationwheelTable [list $wheelid $fixid [add_animation $name $imgpath $manu]]
    }

    # LENS part: fill lensTable
    foreach tagLens $tagLenses {
	set name [$tagLens getAttribute name]
	set min [$tagLens getAttribute min]
	set max [$tagLens getAttribute max]
#	puts "list $name $min $max $fixid"
	lappend lensTable [list $name $min $max $fixid]
    }

    # BLADE part: fill bladesTable
    foreach tagBlade $tagBlades {
	set index   [$tagBlade getAttribute id]
	set degree  [$tagBlade getAttribute degree]
	lappend bladesTable [list $index $degree $fixid]
    }

    set tagPower [lindex $tagPowers 0]
    if { $tagPower == "" } {
	set power 300
    } else {
	set power [$tagPower getAttribute wattage]
    }

    set tagWeight [lindex $tagWeights 0]
    if { $tagWeight == "" } {
	set weight 30
    } else {
	set weight [$tagWeight getAttribute weight]
    }
    lappend fixtureTable [list $manu $fixtureName $power $fixid 60 $channelNum false $modid $weight]
    return 1

}

proc get_effectdata { name } {

    global gobopath
    set path $gobopath/effects/$name.prism 
    if { $name == "__P9_3" } { puts  $path }
    if { ![file exists $path] } { return "" }
    
    set f [open $path]
    set data [read $f]
    close $f
    
    # use xml tool parse files
    set doc [dom parse $data]
    set root [$doc documentElement]
    set items [$root childNodes]


    if { "PRISM" != [$root nodeName] } { return "" }
    set rst ""
    foreach item $items {
	set dist    [$item getAttribute dist]
	set angle   [$item getAttribute angle]
	set radius  [$item getAttribute radius]
	append rst "$dist $angle $radius "
    }
    return $rst
}

# add a color record to colorTable and return new id, if colorTable already contain such record, return the exitstance record's id
proc add_color { name r g b manu } {
    global colorTable
    global COLORTBL_IDSEED
    foreach item $colorTable {
	lassign $item id color_name red green blue manufacturer
	if { [string compare $name $color_name] == 0 && [string compare $red $r] == 0 && \
		 [string compare $green $g] == 0 && [string compare $blue $b] == 0 && \
		 [string compare $manu $manufacturer] == 0 } {
	    return $id
	}
    }
    set id $COLORTBL_IDSEED
    lappend colorTable [list $COLORTBL_IDSEED $name $r $g $b $manu]
    incr COLORTBL_IDSEED
    return $id
}

# add a gobo record to goboTable and return new id, if goboTable already contain such record, return the existance record's id
proc add_gobo { name path manu } {
    global goboTable
    global GOBOTBL_IDSEED
    foreach item $goboTable {
	lassign $item id gobo_name image_path manufacturer
	if { [string compare $name $gobo_name] == 0 && [string compare $image_path $path] == 0 && \
		 [string compare $manu $manufacturer] == 0 } {
	    return $id
	}
    }
    set id $GOBOTBL_IDSEED
    lappend goboTable [list $GOBOTBL_IDSEED $name $path $manu]
    incr GOBOTBL_IDSEED
    return $id
}

# add a gobo record to goboTable and return new id, if goboTable already contain such record, return the existance record's id
proc add_effect { name path manu } {
    global effectTable
    global EFFECTTBL_IDSEED
    foreach item $effectTable {
	lassign $item id effect_name image_path manufacturer
	if { [string compare $name $effect_name] == 0 && [string compare $image_path $path] == 0 && \
		 [string compare $manu $manufacturer] == 0 } {
	    return $id
	}
    }
    set id $EFFECTTBL_IDSEED
    lappend effectTable [list $EFFECTTBL_IDSEED $name $path $manu [get_effectdata $name]]
    incr EFFECTTBL_IDSEED
    return $id
}

# add a animation record to animationTable and return new id, if animationTable already contain such record, return the existance record's id
proc add_animation { name path manu } {
    global animationTable
    global ANIMATIONTBL_IDSEED
    foreach item $animationTable {
	lassign $item id animation_name image_path manufacturer
	if { [string compare $name $animation_name] == 0 && 
	     [string compare $image_path $path] == 0 && 
	     [string compare $manu $manufacturer] == 0 } {
	    return $id
	}
    }
    set id $ANIMATIONTBL_IDSEED
#    puts "lappend animationTable [list $id $name $path $manu ]"
    lappend animationTable [list $id $name $path $manu ]
    incr ANIMATIONTBL_IDSEED
    return $id
}

# return a record of this model ( correspond to modelpath), the record format is "modid offx offy offz length radius ratio type filename"
# of return empty list if there have error ocurrs
proc parse_model { modid modelpath } {

    if { [catch {
	set f [open $modelpath]
	fconfigure $f -encoding "utf-8"
	set data [read $f]
	close $f
	
	set doc [dom parse $data]
	set nodes [$doc getElementsByTagName ATTRIBUTE]
	set node [lindex $nodes 0]
	
	set offx [$node getAttribute offx]
	set offy [$node getAttribute offy]
	set offz [$node getAttribute offz]
	set length [$node getAttribute length]
	set radius [$node getAttribute radius]
	set ratio [$node getAttribute ratio]
	set type [$node getAttribute type]
	set filename [$node getAttribute filename]
    } result ] } {
	#	puts $result
	return {}
    } else {
	if { $modid=="" || $offx=="" || $offy=="" || $offz=="" || $length=="" || $radius=="" || $ratio=="" || $type=="" || $filename=="" } {
	    return {}
	}
	return [list $modid $offx $offy $offz $length $radius $ratio $type $filename] 
    }
}

# ======================================================================

proc ConvertToPostgreSQL {} {
    global gobopath
    global libpath
    set gobopath {W:\VirtualTheater\svn\cp\tools\fixtureLibs\Gobo}
    set libpath {W:\VirtualTheater\svn\cp\tools\fixtureLibs\Spots}
    libconvert $libpath

    #after that will insert a row to t_fixturemodelpara and update t_Fixtures's model_id column
    set conn [pg_connect -conninfo { host=localhost port=5432 dbname=vt20 user=postgres password=12345}]
    #pg_exec $conn "INSERT INTO t_fixturemodelpara( offx, offy, offz, length, radius, ratio, \"type\", model_path, id) VALUES (0, 0, -0.46, 0.26, 0.09, 1, 0, 'model/lamp/Mac2000.xml', 2008)"
    pg_exec $conn "UPDATE \"t_Fixtures\" SET thumb='FixtureThumbs/' || manufacturer || '/' || name || '.jpg'"
    pg_disconnect $conn
    puts "done"
}

# todo list
# - need to convert power field for t_fixture1