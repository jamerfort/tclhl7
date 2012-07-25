namespace eval HL7 {
	# This file contains code for spliting a message into a list-of-lists-of-lists.
	namespace eval Message {
		################################################################################
		# Public methods
		################################################################################
			proc parse {msgdata {segment_separator \r}} {
				# This proc splits a message into a list-of-lists-of-lists...
				# and returns the resulting message data structure.
				
				# get the separators
				set separators [get_separators $msgdata $segment_separator]
	
				# split the message into segments
				set segments [split_segments $msgdata $separators]
	
				return [list $segments $separators "PARSED_MESSAGE"]
			}
	
			proc has_been_parsed {msg} {
				set parsed_message [lindex $msg 2]
	
				return [expr {$parsed_message == "PARSED_MESSAGE"}]
			}
	
		################################################################################
		# Private methods (not meant to be used externally)
		################################################################################
			proc get_separators {msgdata {segment_separator \r}} {
				# This proc returns an array with all of the separators of
				# an HL7 message.
				#
				# The following keys to the array are returned:
				# 	SEGMENT: segment separator
				# 	FIELD: field separator
				# 	REPETITION: repetition separator
				# 	COMPONENT: component separator
				# 	SUBCOMPONENT: subcomponent separator
				# 	ESCAPE: escape character
	
				array set separators {}
	
				set separators(SEGMENT) $segment_separator
				set separators(FIELD) [string index $msgdata 3]
				set separators(REPETITION) [string index $msgdata 5]
				set separators(COMPONENT) [string index $msgdata 4]
				set separators(SUBCOMPONENT) [string index $msgdata 7]
				set separators(ESCAPE) [string index $msgdata 6]
	
				return [array get separators]
			}
	
			########################################################################	
			# Split procs
			########################################################################	
				proc split_segments {msgdata separators} {
					# This proc splits a message into a list of parsed segments
	
					array set seps $separators
					set segments {}
	
					foreach segment [split $msgdata $seps(SEGMENT)] {
						lappend segments [split_fields $segment $separators]
					}
	
					return $segments
				}
	
				proc split_fields {segment separators} {
					# This proc splits a segment into a list of parsed fields
	
					array set seps $separators
					set fields {}
	
					foreach field [split $segment $seps(FIELD)] {
						lappend fields [split_repetitions $field $separators]
					}
	
					return $fields
				}
	
				proc split_repetitions {field separators} {
					# This proc splits a field into a list of parsed repetitions
	
					array set seps $separators
					set repetitions {}
	
					foreach repetition [split $field $seps(REPETITION)] {
						lappend repetitions [split_components $repetition $separators]
					}
	
					return $repetitions
				}
	
				proc split_components {repetition separators} {
					# This proc splits a repetition into a list of parsed components
	
					array set seps $separators
					set components {}
	
					foreach component [split $repetition $seps(COMPONENT)] {
						lappend components [split_subcomponents $component $separators]
					}
	
					return $components
				}
	
				proc split_subcomponents {component separators} {
					# This proc splits a component into a list of parsed subcomponents
	
					array set seps $separators
	
					return [split $component $seps(SUBCOMPONENT)]
				}
	}
	
	
	# This file contains code for turning an HL7 query address into a static address.
	namespace eval Query {
	
		################################################################################
		# Public methods
		################################################################################
			proc query {msg query} {
				# This proc turns an HL7 query address into a list
				# of all matching static addresses.
				#
				# A query address has the following formats:
				# 	- SEGMENT.FIELD.REPETITION.COMPONENT.SUBCOMPONENT
				# 		- returns subcomponent
				# 	- SEGMENT.FIELD.REPETITION.COMPONENT
				# 		- returns component (list of subcomponents)
				# 	- SEGMENT.FIELD.REPETITION
				# 		- returns repetition (list of components)
				# 	- SEGMENT.FIELD
				# 		- returns field (list of repetitions)
				# 	- SEGMENT
				# 		- returns segment (list of fields)
	
				# verify that the "msg" has been parsed
				if { ![HL7::Message::has_been_parsed $msg] } {
					error "The message must be parsed."
				}
	
				# split the query into each part
				set query_parts [split $query "."]
				set num_parts [llength $query_parts]
	
				# verify that the query parts are of the right length
				if { $num_parts > 5 } {
					error "Too many query parts. Between 1 and 5 parts allowed."
				} elseif { $num_parts <= 0 } {
					error "Not enough query parts. Between 1 and 5 parts allowed."
				}
	
	
				return [query_segments $msg $query_parts]
			}
		
		################################################################################
		# Private methods (not intended for external use)
		################################################################################
		
			########################################################################
			# Query procs
			########################################################################
				proc query_segments {msg query_parts} {
					# initialize the list of resulting static addresses
					set addresses {}
	
					# get the segment and field parts of the query
					set seg_part [lindex $query_parts 0]
					set field_part [lindex $query_parts 1]
	
					# get the list of segments in the message
					set segments [lindex $msg 0]
					set num_segments [llength $segments]
	
					for {set i 0} {$i < $num_segments} {incr i} {
						# does this one match?
						if { [match_segment $segments $i $seg_part] } {
							# yes, it matches, thus we process it
	
							if { $field_part != "" } {
								foreach address [query_fields [lindex $segments $i] $query_parts] {
									lappend addresses "$i.$address"
								}
							} else {
								lappend addresses $i
							}
						}
					}
	
					# return the list of accumulated addresses
					return $addresses
				}
	
				proc query_fields {segment query_parts} {
					# initialize the list of resulting static addresses
					set addresses {}
	
					# get the field and repetition parts of the query
					set field_part [lindex $query_parts 1]
					set rep_part [lindex $query_parts 2]
	
					# get the list of fields in the segment
					set num_fields [llength $segment]
	
					foreach i [query_indexes $num_fields $field_part 1] {
						if { $rep_part != "" } {
							set field [lindex $segment $i]
							foreach address [query_repetitions $field $query_parts] {
								lappend addresses "${i}.${address}"
							}
						} else {
							lappend addresses $i
						}
					}
	
					# return the list of accumulated addresses
					return $addresses
	
				}
	
				proc query_repetitions {field query_parts} {
					# initialize the list of resulting static addresses
					set addresses {}
	
					# get the repetition and component parts of the query
					set rep_part [lindex $query_parts 2]
					set comp_part [lindex $query_parts 3]
	
					# get the list of repetitions in the field
					set num_repetitions [llength $field]
	
					foreach i [query_indexes $num_repetitions $rep_part 0] {
						if { $comp_part != "" } {
							set repetition [lindex $field $i]
							foreach address [query_components $repetition $query_parts] {
								lappend addresses "${i}.${address}"
							}
						} else {
							lappend addresses $i
						}
					}
	
					# return the list of accumulated addresses
					return $addresses
	
				}
	
				proc query_components {repetition query_parts} {
					# initialize the list of resulting static addresses
					set addresses {}
	
					# get the component and subcomponent parts of the query
					set comp_part [lindex $query_parts 3]
					set subcomp_part [lindex $query_parts 4]
	
					# get the list of components in the repetition
					set num_components [llength $repetition]
	
					foreach i [query_indexes $num_components $comp_part 0] {
						if { $subcomp_part != "" } {
							set component [lindex $repetition $i]
							foreach address [query_subcomponents $component $query_parts] {
								lappend addresses "${i}.${address}"
							}
						} else {
							lappend addresses $i
						}
					}
	
					# return the list of accumulated addresses
					return $addresses
	
				}
	
				proc query_subcomponents {component query_parts} {
					# initialize the list of resulting static addresses
					set addresses {}
	
					# get the subcomponent parts of the query
					set subcomp_part [lindex $query_parts 4]
	
					# get the list of subcomponents in the component
					set num_subcomponents [llength $component]
	
					foreach i [query_indexes $num_subcomponents $subcomp_part 0] {
						lappend addresses $i
					}
	
					# return the list of accumulated addresses
					return $addresses
	
				}
	
	
				proc query_indexes {count query_part expand} {
					array set addresses {}
	
					foreach query [split $query_part ","] {
						switch -regexp -- $query {
							{^[0-9]+$} {
								if { $expand || $query < $count } {
									set addresses($query) 1
								}
							}
				
							{^\*$} {
								foreach address [range 0 $count 0] {
									set addresses($address) 1
								}
							}
	
							{^[0-9]+-[0-9]+$} {
								regexp {^([0-9]+)-([0-9]+)$} $query {} min max
								foreach address [range $min $max] {
									if { $expand || $address < $count } {
										set addresses($address) 1
									}
								}
							}
						}
					}
	
					return [lsort -integer [array names addresses]]
				}
	
				proc range {start end {inclusive 1}} {
					set rslts {}
	
					if { $inclusive } {
						incr end
					}
	
					for {set i $start} {$i < $end} {incr i} {
						lappend rslts $i
					}
					
					return $rslts
				}
		
			########################################################################
			# Match procs
			########################################################################
				proc match_segment {segments index seg_query} {
					# This proc returns 1 if the segment at the given
					# index matches the given query
	
					# get the segment type
					set seg_type [lindex $segments $index 0 0 0 0]
	
					# split the query
					foreach query [split $seg_query ","] {
						# check on segment type and index
						if { $seg_type == $query || $index == $query } {
							return 1
						}
					}
	
					return 0
				}
	
				proc match_field {fields index field_query} {
					# This proc returns 1 if the field at the given
					# index matches the given query
	
					# split the query
					foreach query [split $field_query ","] {
						# check index
						if { $index == $query } {
							return 1
						}
					}
	
					return 0
	
				}
	
			
	}
	
}

proc hl7 {cmd args} {
	switch -exact -- $cmd {
		parse { return [eval {HL7::Message::parse} $args] }
		query { return [eval {HL7::Query::query} $args] }
		default {
			error "Unknown command: $cmd"
		}
	}
}

