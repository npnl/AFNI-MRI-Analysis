#!/usr/bin/perl
# 
# Reads the motion files generated by 3dvolreg and writes out a .1D file for censoring w/ 3dDeconvolve
# .1D file has 1's for valid timepoints and 0's for invalid (motion) timepoints.
# Brock Kirwan
# 2/10/2005
#
# updates:
# assumes that the the motion files generated by 3dvolreg are named motion_X where X is the run number.
# changed the default values to something more plausible (from 2mm & 3 degrees to .6mm and .3 degrees)

use Getopt::Long;
if ($ARGV[0] =~ /help/) { 
   die "syntax: move_censor.pl [-mm_thresh n] [-deg_thresh n]\n defaults: mm_thresh = .6, deg_thresh = .3\n"; }
$result = GetOptions("mm_thresh:f" => \$mmthresh, "deg_thresh:f" => \$degthresh);
unless ($result) { die "Invalid command line options.  Try move_censor.pl -help\n"; }

unless ($mmthresh) { $mmthresh = .6; }
unless ($degthresh) { $degthresh = .3; }

opendir THISDIR, "." or die "Ummm... what the... $!\n";
@files = sort(grep /motion_\d/, readdir THISDIR);
closedir THISDIR;

$num_invalid = 0;
open VECTOR, ">censor_motion.txt";

foreach $file (@files){
    print "working on file $file\n";

    #count the number of timepoints (lines in motion file).
    $length = 0;
    open(MOTION,$file)or die "file problem: $file $!";
    while(<MOTION>) {
	$length++;
    }
    close(MOTION);

    $valid = 1;
    open(MOTION,$file)or die "file problem: $file $!";
    while(<MOTION>) {
	chomp;
	@vects = (substr($_,0,9), substr($_,9,9), substr($_,18,9), substr($_,27,9), substr($_,36,9), substr($_,45,9));
	if ($. > 1) {
	    for($i = 0; $i < 3; $i++) {
		if (abs ($vects[$i] - $old_vects[$i]) > $degthresh) {
		    $censor[$.-1] = 0;
		    $censor[$.] = 0;
		    if ($.<$length) {$censor[$.+1] = 0;}
		    $valid = 0;
		    $num_invalid++;
		    print ( "motion event at timepoint $.\n");
		}
	    }
	    for($i = 3; $i < 6; $i++) {
		if (abs ($vects[$i] - $old_vects[$i]) > $mmthresh) {
		    $censor[$.-1] = 0;
		    $censor[$.] = 0;
		    if ($.<$length) {$censor[$.+1] = 0;}
		    $valid = 0;
		    $num_invalid++;
		    print ( "motion event at timepoint $.\n");
		}
	    }
	    if ($valid == 0) {
		 $valid = 1; #last one was invalid, but this one is okay.
	    }
	    else {
		$censor[$.]=1;
	    }
	}
	else {
	    $censor[$.] =1;
	}
	@old_vects = @vects;
    }
    close(MOTION);
    shift(@censor);
    $size = scalar(@censor);
    print "timepoints: $size\n";
    foreach $timepoint (@censor) {
	print VECTOR "$timepoint\n";
    }
}
if ($num_invalid > 8) {
    open FOO, ">THERE_ARE_A_LOT_OF_MOTION_EVENTS.txt";
    print FOO "there are more than 8 motion events.  Take a look at your data.";
}
close VECTOR;
