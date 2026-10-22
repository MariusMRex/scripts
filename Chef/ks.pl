#!/usr/bin/perl

# For an unknown reason knife block is just failing.  This is just a work-around to save me time

my $ENV = $ARGV[0];
my $CHEF_HOME = "/Users/marius/.chef";
my $KNIFE_CONFIG = "$CHEF_HOME/knife.rb";


# remove the old link
if( -e "$KNIFE_CONFIG") {
	unlink("$CHEF_HOME/knife.rb");
} 

# Make sure we have an augment
chomp($ENV);
unless($ENV =~ /\w.*/) {
	$ENV = "snowman";
}

# Make the new symlink
if($ENV =~  /^dev$/) {
	symlink("$CHEF_HOME/knife-dev.rb","$KNIFE_CONFIG"); 
} 
elsif($ENV =~ /ec2/) {
	symlink("$CHEF_HOME/knife-ec2.rb","$KNIFE_CONFIG"); 
} 
elsif($ENV =~ /opst/) {
	symlink("$CHEF_HOME/knife-openstackpoc.rb","$KNIFE_CONFIG"); 
} 
elsif($ENV =~ /qa/) {
	symlink("$CHEF_HOME/knife-qa.rb","$KNIFE_CONFIG"); 
} 
elsif($ENV =~ /snowman/) {
	symlink("$CHEF_HOME/knife-snowman.rb","$KNIFE_CONFIG"); 
} 
elsif($ENV =~ /uat/) {
	symlink("$CHEF_HOME/knife-uat.rb","$KNIFE_CONFIG"); 
} 
elsif($ENV =~ /wt/) {
	symlink("$CHEF_HOME/knife-wt.rb","$KNIFE_CONFIG"); 
}
elsif($ENV =~ /64/) {
	symlink("$CHEF_HOME/knife-64bit.rb","$KNIFE_CONFIG"); 
}
