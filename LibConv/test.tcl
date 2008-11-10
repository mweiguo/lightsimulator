load gs2Extractor.dll
package require tdom
package require Tclx
package require tclodbc

# ------------------------------ something about gs2 --------------------------------------
# convert plain text (map table for gs2 to spt) to xml form data
# filePath is generate by manual, and return is xml form data
proc gen_cnXml { filePath } {
    # para check
    if { ![file exists $filePath] } {
	puts "file not exist"
	return
    }

    # read data
    set f [open $filePath]
    set data [read $f]
    close $f
    set lines [split $data "\n"]
    

    set doc [dom createDocument doc]
    set root [$doc createElement CNROOT]
    
    set folderpath "C:/Program Files/Martin Professional/Martin LightJockey/User/UserFixtures"

    # parse each line
    foreach line $lines {
	if { [regexp {([^ \t].*\.spt)[ \t]+([^ \t].*\.GS2)} $line p f1 f2] } {
	    set f [$doc createElement FIXTURE]
	    set filepath $folderpath/$f2
	    puts "begin parse $filepath..."
	    set names [get_chnames $filepath]
	    puts "names = $names"
	    $f setAttribute SptFile $f1 GS2File $f2 ChannelNumber [llength $names]
	    for { set i 0} {$i < [llength $names]} {incr i} {
		set ch [$doc createElement CHANNEL]
		$ch setAttribute ID $i Name [lindex $names $i]
		$f appendChild $ch
	    }
	    puts "end parse $filepath..."
#	    puts "$filepath :      SptFile $f1 GS2File $f2 ChannelNum [get_channelNumber $filepath]"
	    $root appendChild $f
	}
    }
    set data [$root asXML]
    $doc delete
    return $data
}

if { 0 } {
    set f [open "ttt.xml" "w"]
    puts $f [gen_cnXml compareTable]
    close $f
    puts "finished"
}


# ------------------------------ something about model parameter file --------------------------------------
# generate model index file ( Excel File Version )
# filePath is export from excel, and outlibfolder is the place store model index files
proc build_modelIndexFile { filePath outlibfolder } {
    # para check
    if { ![file exists $filePath] } {
	puts "file not exist"
	return false
    }
    
    # read data
    set f [open $filePath]
    set data [read $f]
    close $f

    set doc      [dom parse $data]
    set root     [$doc documentElement]
    if { [$root nodeName] != "ROOTMOD" } { 
	puts "this file is not correct format"
	return false 
    }

    # parse whole file and save it to fixtures and fixture array.	
    foreach fix [$root childNodes] {
	set id               [$fix getAttribute id ""]
	set manufacturer     [$fix getAttribute Manufacturer ""]
	set name             [$fix getAttribute Name ""]
	set org              [$fix getAttribute Org ""]
	set copy             [$fix getAttribute copy ""]
	set offx             [$fix getAttribute offx ""]
	set offy             [$fix getAttribute offy ""]
	set offz             [$fix getAttribute offz ""]
	set length           [$fix getAttribute length ""]
	set radius           [$fix getAttribute radius ""]

	if { $id == "" || $manufacturer == "" || $name == "" } continue
	if { $copy == "" && $offx == "" } continue

	lappend              fixtures                                 $id
	set                  fixture($id,manufacturer)                [$fix getAttribute Manufacturer ""]
	set                  fixture($id,name)                        [$fix getAttribute Name ""]
	set                  fixture($id,org)                         [$fix getAttribute Org ""]
	set                  fixture($id,copy)                        [$fix getAttribute copy ""]
	set                  fixture($id,offx)                        [$fix getAttribute offx ""]
	set                  fixture($id,offy)                        [$fix getAttribute offy ""]
	set                  fixture($id,offz)                        [$fix getAttribute offz ""]
	set                  fixture($id,length)                      [$fix getAttribute length ""]
	set                  fixture($id,radius)                      [$fix getAttribute radius ""]	

	puts                  "$fixture($id,manufacturer)  $fixture($id,name)  $fixture($id,org)  $fixture($id,copy)  $fixture($id,offx)  $fixture($id,offy)  $fixture($id,offz)  $fixture($id,length)  $fixture($id,radius)"
    }
    gen_modelIndexFile $fixtures fixture $outlibfolder
}

# generate model index file ( Access DataBase Version )
# filePath is export from excel, and outlibfolder is the place store model index files
proc build_modelIndexFileFromAccess { filePath outlibfolder } {
    # para check
    if { ![file exists $filePath] } {
	puts "file not exist"
	return false
    }

    # read info to MS Access by tclODBC
    database db "DRIVER=Microsoft Access Driver (*.mdb, *.accdb);DBQ=$filePath"
    set cmd "SELECT id, fixtureName, manuName, org, copy, offsetx, offsety, offsetz, length, radius FROM t_fixtures"

    set rows [db $cmd]

    foreach row $rows {
	lassign $row id name manufacturer org copy offx offy offz length radius
	puts $row

	if { $id == "" || $manufacturer == "" || $name == "" } continue
	if { ($copy == 0 || $copy == "") && $org == "" } continue

	lappend              fixtures                                 $id
	set                  fixture($id,manufacturer)                $manufacturer
	set                  fixture($id,name)                        $name
	set                  fixture($id,org)                         $org
	set                  fixture($id,copy)                        $copy
	set                  fixture($id,offx)                        $offx
	set                  fixture($id,offy)                        $offy
	set                  fixture($id,offz)                        $offz
	set                  fixture($id,length)                      $length
	set                  fixture($id,radius)                      $radius
    }
    puts [db disconnect]
    gen_modelIndexFile $fixtures fixture $outlibfolder
}

proc gen_modelIndexFile { fixtures fix libfolder} {
    upvar $fix fixture
    set falseList {"0" ""}
    
    set effectcnt 0
    foreach id $fixtures {
	if { ![lcontain $falseList $fixture($id,org)] && ![lcontain $falseList $fixture($id,copy)] } {
	    puts "$id : org field or copy field wrong id=$id fixture($id,org)=$fixture($id,org) fixture($id,copy)=$fixture($id,copy)"
	    continue
	}
	# prepare xml text
	set d [dom createDocument doc]
	set root [$d createElement ROOTMOD]
	set attr [$d createElement ATTRIBUTE]
	
	if { ![lcontain $falseList $fixture($id,org)] && [lcontain $falseList $fixture($id,copy)] } {
	    $attr setAttribute offx $fixture($id,offx) offy $fixture($id,offy) offz $fixture($id,offz) length $fixture($id,length) \
		radius $fixture($id,radius) ratio 1 type 0 filename "model/lamp/$fixture($id,manufacturer)/$fixture($id,name).xml"
	} elseif { [lcontain $falseList $fixture($id,org)] && ![lcontain $falseList $fixture($id,copy)] } {
	    set oid $fixture($id,copy)
	    if { ![lcontain $fixtures $oid] }    continue
	    $attr setAttribute offx $fixture($oid,offx) offy $fixture($oid,offy) offz $fixture($oid,offz) length $fixture($oid,length) \
		radius $fixture($oid,radius) ratio 1 type 0 filename "model/lamp/$fixture($oid,manufacturer)/$fixture($oid,name).xml"
	}

	$root appendChild $attr
	set xmlText [$root asXML]

	# prepare file path
	set path $libfolder/$fixture($id,manufacturer)/mod$fixture($id,name).xml
	if { ![file isdirectory $libfolder/$fixture($id,manufacturer)] } {
	    file mkdir $libfolder/$fixture($id,manufacturer)
	}
	# write
	set f [open $path "w"]
	puts $f $xmlText
	puts $xmlText
	close $f
	incr effectcnt
    }
    puts "generate $effectcnt files"
}

if { 0 } {
    build_modelIndexFileFromAccess {W:/VirtualTheater/svn/cp/tools/FLModelManager.accdb} W:/VirtualTheater/svn/cp/tools/fixtureLibs/Spots
#    build_modelIndexFile d:/test/123.xml W:/VirtualTheater/svn/cp/tools/fixtureLibs/Spots
    puts "ok"
}

# ------------------------------ something about making statstics about how many channels in spt library --------------------------------------
proc get_chnum { filename } {
    if { ![file exists $filename] } { return 0 }
    set f [open $filename]
    set doc      [dom parse [read $f]]
    close $f

    set root     [$doc documentElement]
    if { [$root nodeName] != "ROOT" } { return 0 }

    set nodes [$root getElementsByTagName CHANNEL]
    $doc delete
    return [llength $nodes]
}

proc chnums_calculate { folderpath } {
    set dirs [glob -types d $folderpath/*]

    foreach dir $dirs {
	set files [glob -nocomplain -types f $dir/*.xml]
	foreach file $files {
	    set chnum [get_chnum $file]
	    if { $chnum == 0 } continue 

	    if { [info exists fixture($chnum)] } {
		incr fixture($chnum)
	    } else {
		set fixture($chnum) 1
		lappend fixture(CHANNELS) $chnum
	    }
	}
    }

    set cnt 0
    foreach key $fixture(CHANNELS) {
	puts "CHANNEL: $key\t\tFIXTURE NUMBER: $fixture($key)"
	incr cnt $fixture($key)
    }
    puts "TOTAL FIXTURE NUMBER : $cnt"
}

if { 0 } {
    chnums_calculate {W:/VirtualTheater/svn/cp/tools/fixtureLibs/Spots}
}

# ------------------------------ something about making fixture list --------------------------------------

# compareTable(.spt) .gs2
proc makelist { compareTablePath folderpath } {
    # load gs2/spt file compare table
    set f [open $compareTablePath]
    set data [read $f]
    close $f
    set lines [split $data "\n"]
    foreach line $lines {
	if { [regexp {([^ \t].*\.spt)[ \t]+([^ \t].*\.GS2)} $line p f1 f2] } {
	    set compareTable($f1) $f2

	}
    }
    
    # iterate each path
    set dirs [glob -types d $folderpath/*]
    foreach dir $dirs {
	set files [glob -nocomplain -types f $dir/*.spt]
	set type [file tail $dir]
	foreach file $files {
	    set supportgs2 0

	    if { [regexp {(.*)\.spt} $file p name] } {
		if { [file exists $name.xml] } {
		    set chnum [get_chnum $name.xml ]
		}

		set name [file tail $name]
		if { [info exists compareTable($name.spt)] } {
		    set supportgs2 1
		}
	    
		lappend fixture [list $type $name $supportgs2 $chnum]
	    }
	}
    }

    # output
    foreach line $fixture {
	lassign $line type name supportgs2 chnum
	puts [format "%-40s%-80s%-20s%-20s" $type $name $supportgs2 $chnum]
	
    }
    puts ok
}

if {0} {
    makelist {W:/VirtualTheater/svn/cp/tools/spt_parser/compareTable} {W:/VirtualTheater/svn/cp/tools/fixtureLibs/Spots}
}

# ------------------------------ convert Old fixture model library to new form ( from Excel file to MS Access Database --------------------------------------

proc convertWangLiExcelToAccess excelExportXMLPath {
    # para check
    if { ![file exists $excelExportXMLPath] } {
	puts "file not exist"
	return false
    }
    
    # read data
    set f [open $excelExportXMLPath]
    set data [read $f]
    close $f

    set doc      [dom parse $data]
    set root     [$doc documentElement]
    if { [$root nodeName] != "ROOTMOD" } { 
	puts "this file is not correct format"
	return false 
    }

    # parse whole file and save it to fixtures and fixture array.	
    foreach fix [$root childNodes] {
	set id               [$fix getAttribute id ""]
	set manufacturer     [$fix getAttribute Manufacturer ""]
	set name             [$fix getAttribute Name ""]
	set org              [$fix getAttribute Org ""]
	set copy             [$fix getAttribute copy ""]
	set offx             [$fix getAttribute offx ""]
	set offy             [$fix getAttribute offy ""]
	set offz             [$fix getAttribute offz ""]
	set length           [$fix getAttribute length ""]
	set radius           [$fix getAttribute radius ""]
	if { $id == "" || $manufacturer == "" || $name == "" } continue
	if { ($copy == 0 || $copy == "") && $org == "" } continue
	lappend              fixtures                                 $id
	set                  fixture($id,manufacturer)                $manufacturer
	set                  fixture($id,name)                        $name        
	set                  fixture($id,org)                         $org         
	set                  fixture($id,copy)                        $copy        
	set                  fixture($id,offx)                        $offx        
	set                  fixture($id,offy)                        $offy        
	set                  fixture($id,offz)                        $offz        
	set                  fixture($id,length)                      $length      
	set                  fixture($id,radius)                      $radius      
    }

    # write info to MS Access by tclODBC
    database db "DRIVER=Microsoft Access Driver (*.mdb, *.accdb);DBQ=W:/VirtualTheater/svn/cp/tools/FLModelManager.accdb"
    set i 0
    foreach id $fixtures {
	if { $fixture($id,copy) != "" } continue
	set cmd "UPDATE t_fixtures SET org=$fixture($id,org), manuName='$fixture($id,manufacturer)', offsetx=$fixture($id,offx), offsety=$fixture($id,offy), offsetz=$fixture($id,offz), length=$fixture($id,length), radius=$fixture($id,radius) WHERE fixtureName='$fixture($id,name)'"
	db $cmd
	set cmd "SELECT id From t_fixtures WHERE fixtureName='$fixture($id,name)'"
	set fixture($id,dbid) [db $cmd]
	incr i
    }

    foreach id $fixtures {
	if { $fixture($id,copy) == "" || $fixture($id,copy) == 0 } continue
	set cmd "UPDATE t_fixtures SET copy=$fixture($fixture($id,copy),dbid), manuName='$fixture($id,manufacturer)' WHERE fixtureName='$fixture($id,name)'"
	db $cmd
	incr i
    }

    puts [db disconnect]
    puts "effect $i items"

    $doc delete
}

if { 0 } {
    puts {begin...}
    convertWangLiExcelToAccess {d:/test/need to be converted to access.xml}
    puts ok
}