#!/usr/bin/perl 
#===============================================================================
#
#         FILE: display_switch.pl
#
#        USAGE: ./display_switch.pl  
#
#  DESCRIPTION: Switch between dual monitors and single laptop display
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Marius Rex (marius@venda.com), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 08/19/2013 11:04:48 AM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;

# Edit ~/.kde/share/config/krandrrc
# -rw-------. 1 marius marius 570 Aug 18 21:06 /home/marius/.kde/share/config/krdrrc

# cat ~/.kde/share/config/krandrrc.laptop 
# [Display]
# ApplyOnStartup=true
# StartupCommands=xrandr --output LVDS1 --pos 0x0 --mode 1366x768 --refresh 60.1616\nxrandr --output LVDS1 --primary
#
# [Screen_0]
# OutputsUnified=false
# UnifiedRect=0,0,0,0
# UnifiedRotation=1
#
# [Screen_0_Output_HDMI2]
# Active=false
# Rect=1600,0,-1,-1
# RefreshRate=0
# Rotation=1
#
# [Screen_0_Output_LVDS1]
# Active=true
# Rect=0,0,1366,768
# RefreshRate=60.1616096496582
# Rotation=1
#
# [Screen_0_Output_VGA1]
# Active=false
# Rect=0,0,-1,-1
# RefreshRate=0
# Rotation=1

# cat ~/.kde/share/config/krandrrc.desktop 
# [Display]
# ApplyOnStartup=true
# StartupCommands=xrandr --output LVDS1 --off\nxrandr --output VGA1 --pos 0x0 --mode 1440x900 --refresh 59.8874\nxrandr --output HDMI2 --pos 1440x0 --mode 1440x900 --refresh 74.9844\nxrandr --output LVDS1 --primary
#
# [Screen_0]
# OutputsUnified=false
# UnifiedRect=0,0,0,0
# UnifiedRotation=1
#
# [Screen_0_Output_HDMI2]
# Active=true
# Rect=1600,0,1600,900
# RefreshRate=60
# Rotation=1
#
# [Screen_0_Output_LVDS1]
# Active=true
# Rect=0,0,1366,768
# RefreshRate=60.1616096496582
# Rotation=1
#
# [Screen_0_Output_VGA1]
# Active=false
# Rect=0,0,-1,-1
# RefreshRate=0
# Rotation=1

my $FILE = "~/.kde/share/config/krandrrc";
my $CHOICE = $ARGV[0];

if($CHOICE) {
	chomp $CHOICE;
	if($CHOICE eq "laptop") {
		system('cp ~/.kde/share/config/krandrrc.laptop ~/.kde/share/config/krandrrc');
		print "Upon reboot, the laptop display only will be enabled.\n";
	} elsif($CHOICE eq "desktop") {
		system('cp ~/.kde/share/config/krandrrc.desktop ~/.kde/share/config/krandrrc');
		print "Upon reboot, the desktop monitors will be enabled, and the laptop display disabled.\n";
	} else {
		print "This script needs augments to function.  Viable options are 'desktop' and 'laptop'\n";
	}
} else {
	print "This script needs augments to function.  Viable options are 'desktop' and 'laptop'\n";
}



