set interface_first $argv
set row [ list ]
set syslog [open "syslog:" w+]
puts $syslog "%EEM-TRIGGERED-IDF"
foreach line [ split [ exec show ip interface brief | inc $interface_first ] \n ] {
	puts $syslog "%EEM-TRIGGERED-IDF"
	
	if {[ regexp -nocase {GigabitEthernet.*} $line ]!= 0 } {
		set interface [ lindex $line 0 ]
		lappend row $interface
		set status [ lindex $line 4 ]
		lappend row $status
		puts "\t"
		puts "\t$interface"
		puts "====================================="

		if {$status=="up"} {
			puts "Interface Up on $interface"
			
			foreach line [ split [ exec show lldp neighbors $interface | inc Total ] \n ] { 
				set phone_count [ lindex $line 3 ]
					
				if { $phone_count == "0" } {
					puts "Phone not found"
					set array [ list ]
					set fields [ split $interface "t" ]
					foreach field $fields {
						lappend array 
					}
					
					foreach line [ split [ exec show interface status | inc $field ] \n ] {
						set speed [ lindex $line 5 ]
						set speed_1 [ lindex $line 6 ]
						set speed_2 [ lindex $line 7 ]
						
						if { $speed == "auto" || $speed == "a-10" || $speed == "a-100" || $speed == "a-1000" || $speed_1 == "auto" || $speed_1 == "a-10" || $speed_1 == "a-100" || $speed_1 == "a-1000" || $speed_2 == "auto" || $speed_2 == "a-10" || $speed_2 == "a-100" || $speed_2 == "a-1000" } {
							puts "Speed is fine "
							break
						} else {
							puts "Speed Need to be autoed"
							#########################################################################################################           		
							#######				ios_config "enable" "conf t" "int $interface" "speed auto" "end" 			#########
							#######					puts $syslog "%INTERFACE-SPEED-AUTOED-EEM : $interface" 				#########
							#########################################################################################################
							
							foreach line [ split [ exec show interface status | inc $field ] \n ] {
								set speed_new [ lindex $line 5 ]
								
								if { $speed_new == "auto" || $speed_new == "a-10" || $speed_new == "a-100" || $speed_new == "a-1000" } {
									puts "Speed set successfully"
								} else {
									puts "After speed set to auto, Still it seems \"$speed_new\""
									puts \n
								}
							}
						}
					}
					
					foreach line [ split [ exec show interface status | inc $field ] \n ] {
						set duplex [ lindex $line 4 ]
						set duplex_1 [ lindex $line 5 ]
						set duplex_2 [ lindex $line 6 ]
							
						if { $duplex == "auto" || $duplex == "a-half" || $duplex == "a-full" || $duplex_1 == "auto" || $duplex_1 == "a-half" || $duplex_1 == "a-full" || $duplex_2 == "auto" || $duplex_2 == "a-half" || $duplex_2 == "a-full" } {
							puts "Duplex is fine"
						} else {
							puts "Duplex Need to be autoed"
							#########################################################################################################           		
							#######				ios_config "enable" "conf t" "int $interface" "duplex auto" "end" 			#########
							#######					puts $syslog "%INTERFACE-DUPLEX-AUTOED-EEM : $interface" 				#########
							#########################################################################################################
							
							foreach line [ split [ exec show interface status | inc $field ] \n ] {
								set duplex_new [ lindex $line 4 ]
								
								if { $duplex_new == "auto" || $duplex_new == "a-half" || $duplex_new == "a-full" } {
									puts "Duplex set successfully"
									
								} else {
									puts "After Duplex set to auto, Still it seems \"$duplex_new\""
									puts \n
								}
							}
						}
						break
					}
					#####################################################################
					#######					typeahead "y"  		  				#########
					#######	ios_config "clear counters $interface"				#########
					#######	puts $syslog "%INTERFACE-CLEARED-EEM : $interface"	#########
					#####################################################################
					
				} else {
					foreach line [ split [ exec show lldp neighbors $interface | inc AV ] \n ] { 
						#####################################################################
						#######					typeahead "y"  		  				#########
						#######	ios_config "clear counters $interface"				#########
						#######	puts $syslog "%INTERFACE-CLEARED-EEM : $interface"	#########
						#####################################################################
					
						if {[ regexp -nocase {^AV.*} $line ]!= 0 } {
							set phone_name [ lindex $line 0 ]
							puts "Phone found $phone_name"
						} 
					}
					
					set array [ list ]
					set fields [ split $interface "t" ]
					foreach field $fields {
						lappend array 
					}
					
					foreach line [ split [ exec show interface status | inc $field ] \n ] { 
						set speed [ lindex $line 6 ]
						set duplex [ lindex $line 5 ]
						puts "Speed is fine : $speed"
						puts "Duplex is fine : $duplex"
						break
					}
					
				}
				
				puts "Clear counters on $interface"
				puts "====================================="
				break
			}
			
		} elseif {$status=="down"} {
			puts "Interface Down on $interface"
					
			foreach line [ split [ exec show int $interface | inc Last input ] \n] {
				set last_login [ lindex $line 2 ]
							
				if { $last_login == "never," || $last_login == "never" } {
					puts "Last Login is $last_login"	
					puts "Check Splunk"	
					
				} else {
						
					foreach line [ split [ exec show int $interface | inc Last input ] \n] {
						set last_login [ lindex $line 2 ]
					
						set fields [ split $last_login "w" ]
						set i 0
						foreach field $fields {
							set week($i) $field
							set i 1
						}
						
						set week_new $week(0)

						set fields [ split $last_login "w" ]
						foreach field $fields {
							set day_h(0) $field
						}
						
						set day_half $day_h(0)
						set fields [ split $day_half "d" ]
						set i 0
						
						foreach field $fields {
							set day($i) $field
							set i 1
						}
						
						set day_new $day(0)
						set in_days_half [ expr $week_new * 7 ]
						set in_days [ expr $in_days_half + $day_new ]
				
						if {$in_days >= 120} {
							puts "Last Login - \[ $in_days days back]"
							puts "Interface need to be shutdown"
							#################################################################################
							#######   "ios_config "enable" "conf t" "int $interface" "shut" "end"	#########
							#######		puts $syslog "%INTERFACE-SHUTDOWN-EEM : $interface" 		#########
							#################################################################################
						} else {
							puts "Last Login - \[ $in_days days back]"
						}
					}	
				}
			}
			
			puts "Clear counters on $interface"
			puts "====================================="
			
			#####################################################################
			#######					typeahead "y"  		  				#########
			#######	ios_config "clear counters $interface"				#########
			#######	puts $syslog "%INTERFACE-CLEARED-EEM : $interface"	#########
			#####################################################################

		} elseif {$status=="administratively"} {
			puts "Interface Administratively Down on $interface"
			puts "Clear counters on $interface"
			puts "====================================="
			puts "\t"

			#####################################################################
			#######					typeahead "y"  		  				#########
			#######	ios_config "clear counters $interface"				#########
			#######	puts $syslog "%INTERFACE-CLEARED-EEM : $interface"	#########
			#####################################################################
			
		}

	}
	break
}