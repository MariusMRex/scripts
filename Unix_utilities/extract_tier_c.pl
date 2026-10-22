#!/usr/bin/perl
use strict;
use warnings;

# Read Tier_C.txt emails into a hash
my %tier_c;
open my $tier_fh, '<', 'Tier_C.txt' or die "Cannot open Tier_C.txt: $!";
while (my $email = <$tier_fh>) {
    chomp $email;
    $tier_c{$email} = 1 if $email ne '';
}
close $tier_fh;

# Open output file
open my $out_fh, '>', 'Tier_C_with_names.csv' or die "Cannot write to output: $!";

# Process the CSV input
open my $csv_fh, '<', 'GC_Names_email_consolidated.csv' or die "Cannot open CSV: $!";
my $header = <$csv_fh>;
print $out_fh $header;

while (my $line = <$csv_fh>) {
    chomp $line;
    my @fields = split /,/, $line, 3; # Only split first 3 fields
    my $email = $fields[2] // '';
    $email =~ s/^\s+|\s+$//g;
    print $out_fh "$fields[0],$fields[1],$fields[2]\n" if $tier_c{$email};
}
close $csv_fh;
close $out_fh;
