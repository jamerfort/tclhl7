# This file contains procs for getting data from and modifying HL7 messages.
namespace eval GetSet {
	################################################################################
	# Public Methods
	################################################################################
		proc get {msg query} {
			# This proc pulls the values from the parsed message that match
			# the given query.
			#
			# The results are a list of "value-address" pairs.  Thus, for
			# the following message:
			# 	MSH|....|
			# 	PID|||123456~abcdef
			# and the query "PID.3.*", you get the following results:
			# 	{ {123456 1.3.0} {abcdef 1.3.1} }
			#
			# The address returned is a "static address" that can be
			# used to address a given field, repetition, component, etc.
			# specifically.
			# 
			# You would usually use this proc in the following manner:
			# 	set msg [hl7 parse $msgdata \r]
			# 	
			# 	foreach rslt [hl7 get $msg PID.3.*.0.0] {
			#		set value [lindex $rslt 0]
			#		set address [lindex $rslt 1]
			#
			#		# do something
			#		puts "$address ==> $value"
			# 	}
			set results {}

			foreach address [HL7::Query::query $msg $query] {
				set value [eval {lindex $msg 0} [split $address "."]]
				lappend results [list $value $address]
			}

			return $results
		}

		proc _set {msg query value {expand 1}} {
			# This proc sets the value of a segment, field, etc.

			# get the segments in the message
			set segments [lindex $msg 0]

			foreach address [HL7::Query::query $msg $query $expand] {
				set indexes [split $address "."]
				set segments [lexpand $segments $indexes]
				lset segments $indexes $value
			}

			# add the segments back into the message
			set msg [lreplace $msg 0 0 $segments]

			return $msg
		}

		proc each {msg query value_var address_var body} {
			proc __each_proc [list $value_var $address_var] $body

			foreach rslt [get $msg $query] {
				set value [lindex $rslt 0]
				set address [lindex $rslt 1]
				__each_proc $value $address 		
			}
		}

	################################################################################
	# Private Methods (not meant to be used externally)
	################################################################################
		proc lexpand {l indexes} {
			# short-circuit if we don't have any indexes to expand to.
			if { [llength $indexes] <= 0} {
				return $l
			}

			# pop off the next index
			set i [lindex $indexes 0]
			set indexes [lrange $indexes 1 end]

			# get the length of the current list
			set len [llength $l]

			# do we need to add more at this level?
			if { $i >= $len } {
				# yes...add more
				
				set count [expr {$i + 1 - $len}]
				while { $count > 0 } {
					lappend l {}
					incr count -1
				}
			}

			# do we need to process deeper?
			if { [llength $indexes] > 0 } {
				# yes
				set l [lreplace $l $i $i [lexpand [lindex $l $i] $indexes]]
			}

			return $l
		}
}
