load gs2Extractor.dll

set names [get_chnames "C:\\Program Files\\Martin Professional\\Martin LightJockey\\User\\UserFixtures\\Chauvet_Legend5000_16bit.GS2"]
puts [llength $names]
puts $names