#!/usr/bin/perl

# I was not able to export files from the TribeHR database, so I cut and paste.  
# A little text processing can clean this up

open(NEWFILE, '>/Users/marius/sorted.csv');
print NEWFILE "Data Base Name,Data Base Size in MB\n";

while(<>) {
  chomp;
  if($_ =~ /(\w+)\s+,\s+(\d+\.\d+)\s/) {
    print NEWFILE "'$1','$2'\n";
  } else {
    print "Error: $_ did not parse\n";
  }
}
