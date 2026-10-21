#!/usr/local/bin/perl

if(-e "/usr/bin/screen") {
	#print "HELLS YEAH\n";
	system("/usr/bin/screen");
} else {
	print "Running without screen.  You are on your own\n"
}
