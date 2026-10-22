!/usr/bin/perl -w 
use strict; 

# Simple script to test that the oncall addresses are going through to the pagers.
# This sctipt is intended to be deployed on the nagios host, so it is using the
# same mail architecture as nagios would to page.
# marius@venda.com  2013-01-26

my $sendmail = "/usr/sbin/sendmail -t"; 
my $FROM_ADDRESS = "From: sys-alerts\@venda.com\n";
my $subject = "Subject: verify Oncall\n"; 
my $TO_ADDRESS;
my $PRIMARY = 'venda_oncall_primary@mail.aql.com';
my $SECONDARY = 'venda_oncall_secondary@mail.aql.com';


if (exists $ARGV[0]) {
        if($ARGV[0] eq 'primary') {
                $TO_ADDRESS = $PRIMARY;
        } elsif($ARGV[0] eq 'secondary') {
                $TO_ADDRESS = $SECONDARY;
        } else {
                useage();
        }
} else {
                useage();
}

print "Emailing $TO_ADDRESS\n";
open(SENDMAIL, "|$sendmail") or die "Cannot open $sendmail: $!"; 
                print SENDMAIL $FROM_ADDRESS; 
                print SENDMAIL $subject; 
                print SENDMAIL "To: $TO_ADDRESS\n"; 
                print SENDMAIL "Content-type: text/plain\n\n";
                print SENDMAIL "This is a test message\n";
close(SENDMAIL);
print "You should be paged shortly.\n";


sub useage {
        print "Error: No augment given.\n";
        print "Usage: ./check_oncall (primary|secondary)\n";
        exit 1;
}
}
}
}
}
}
}
