namespace eval TclInclude {
	proc process {infilename outfilename {path {}}} {
		if { $infilename == "" } {
			# read from stdin
			set in stdin
			lappend path [pwd]
		} else {
			set indir [file dirname $infilename]
			set in [open $infilename]
			
			# add the input file's directory to the path
			lappend path $indir
		}


		if { $outfilename == "" } {
			set out stdout
		} else {
			set out [open $outfilename w]
		}

		return [process_file_handles $in $out $path]
	}

	proc process_file_handles {in out path} {
		# process each
		while { ![eof $in] } {
			# get the next line
			set line [gets $in]

			# parse the line
			process_line $line $out $path
		}

		close $in
		close $out

	}

	proc process_line {line out path {orig_leading ""}} {
		# parse the line for tags
		if { [regexp {^(\s*)(#\s*)?%{([^\s]*)\s+(.*)}} $line whole_match leading comment cmd args] } {
			if { [regexp {^[_\s]} $cmd] } {
				error "ERROR: Cannot call hidden command '$cmd'"
			}

			set leading "${orig_leading}${leading}"

			eval {TclInclude::Commands::$cmd $out $path $leading $comment} $args
		} else {	
			# no include tag
			puts $out "${orig_leading}${line}"
		}
	}

	namespace eval Commands {
		proc include {outfile path leading comment args} {
			foreach filename $args {
				include_file $outfile $path $leading $comment $filename
			}
		}

		proc include_file {outfile path leading comment filename} {
			set final_filename [__find_file $filename $path]
			
			set f [open $final_filename]

			while { ![eof $f] } {
				set line [gets $f]

				TclInclude::process_line $line $outfile $path $leading
			}
			
			close $f
		}

		proc comments {outfile path leading comment args} {
			foreach filename $args {
				set final_filename [__find_file $filename $path]

				set f [open $final_filename]
				
				while { ![eof $f] } {
					set line [gets $f]

					set output_line "${leading}${comment}${line}"
					
					puts $outfile $output_line
				}
				
				close $f
			}
		}

		proc __find_file { filename paths } {
			set normal_paths {}
			
			foreach path $paths {
				set normal_path [file normalize $path]
				lappend normal_paths $normal_path
				set full_path [file join $normal_path $filename]

				if { [file isfile $full_path] } {
					return $full_path
				}
			}

			error "ERROR in find_file: Cannot find '$filename' in: \n\t[join $normal_paths \n\t]"
		}
	}
}

if { ! $tcl_interactive } {
	set infile [lindex $argv 0]
	set outfile [lindex $argv 1]
	set path {}

	if { [info exists ::env(TCL_INCLUDE_PATH)] } {
		set path [split $::env(TCL_INCLUDE_PATH) ":"]
	}

	TclInclude::process $infile $outfile $path
}
