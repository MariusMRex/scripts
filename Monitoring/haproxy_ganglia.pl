#!/usr/bin/perl

use strict;
use warnings;

# Example check
# [marius@wtmonitor01 ~]$ /usr/lib64/nagios/plugins/check_haproxy_stats.pl --url http://10.17.24.103/
# Check haproxy OK - checked 9 proxies.|stats-FRONTEND=1;1600;1800;0;2000;stats-BACKEND=0;160;180;0;200;PGBouncer-in-5432-FRONTEND=0;1600;1800;0;2000;pgbouncer-FRONTEND=0;16800;18900;0;21000;pgbouncer-BACKEND=0;1680;1890;0;2100;application-backend-5432-6432=0;5600;6300;0;7000;application-backend-5432-6433=0;5600;6300;0;7000;application-backend-5432-6434=0;5600;6300;0;7000;application-backend-5432-BACKEND=0;16800;18900;0;21000;

# May just need to use the stats interface.  CSV export is available:
# curl http://10.17.24.103/\;csv
# What does this all mean?: http://cbonte.github.io/haproxy-dconv/1.7/management.html#9.1
# Also https://www.datadoghq.com/blog/monitoring-haproxy-performance-metrics/
#
# # pxname,svname,qcur,qmax,scur,smax,slim,stot,bin,bout,dreq,dresp,ereq,econ,eresp,wretr,wredis,status,weight,act,bck,chkfail,chkdown,lastchg,downtime,qlimit,pid,iid,sid,throttle,lbtot,tracked,type,rate,rate_lim,rate_max,check_status,check_code,check_duration,hrsp_1xx,hrsp_2xx,hrsp_3xx,hrsp_4xx,hrsp_5xx,hrsp_other,hanafail,req_rate,req_rate_max,req_tot,cli_abrt,srv_abrt,comp_in,comp_out,comp_byp,comp_rsp,lastsess,last_chk,last_agt,qtime,ctime,rtime,ttime,
# stats,FRONTEND,,,2,5,2000,1533,217931,3130296,0,0,4,,,,,OPEN,,,,,,,,,1,1,0,,,,0,1,0,4,,,,0,1530,0,4,0,0,,1,3,1535,,,0,0,0,0,,,,,,,,
# stats,BACKEND,0,0,0,0,200,0,217931,3130296,0,0,,0,0,0,0,UP,0,0,0,,0,456068,0,,1,1,0,,0,,1,0,,0,,,,0,0,0,0,0,0,,,,,0,0,0,0,0,0,0,,,0,0,0,27,
# PGBouncer-in-5432,FRONTEND,,,0,0,2000,0,0,0,0,0,0,,,,,OPEN,,,,,,,,,1,2,0,,,,0,0,0,0,,,,,,,,,,,0,0,0,,,0,0,0,0,,,,,,,,
# pgbouncer,FRONTEND,,,0,2,21000,2991,148207,170163,0,0,0,,,,,OPEN,,,,,,,,,1,3,0,,,,0,0,0,1,,,,,,,,,,,0,0,0,,,0,0,0,0,,,,,,,,
# pgbouncer,BACKEND,0,0,0,0,2100,0,0,0,0,0,,0,0,0,0,UP,0,0,0,,0,456068,0,,1,3,0,,0,,1,0,,0,,,,,,,,,,,,,,0,0,0,0,0,0,-1,,,0,0,0,0,
# application-backend-5432,6432,0,0,0,1,7000,996,49384,56702,,0,,0,0,0,0,UP,1,1,0,1,1,448441,7627,,1,4,1,,996,,2,0,,1,L4OK,,0,,,,,,,0,,,,0,0,,,,,285,,,0,0,0,18,
# application-backend-5432,6433,0,0,0,1,7000,997,49431,56759,,0,,0,0,0,0,UP,1,1,0,1,1,448455,7612,,1,4,2,,997,,2,0,,1,L4OK,,0,,,,,,,0,,,,0,0,,,,,8,,,0,0,0,18,
# application-backend-5432,6434,0,0,0,1,7000,996,49384,56702,,0,,0,0,0,0,UP,1,1,0,1,1,448450,7616,,1,4,3,,996,,2,0,,1,L4OK,,0,,,,,,,0,,,,0,0,,,,,308,,,0,0,0,18,
# application-backend-5432,BACKEND,0,0,0,2,21000,2991,148207,170163,0,0,,2,0,0,0,UP,3,3,0,,1,448455,7611,,1,4,0,,2989,,1,0,,1,,,,,,,,,,,,,,0,0,0,0,0,0,8,,,0,0,0,2,
# Stats I care about
# FRONTEND req_rate rate bin bout ereq
# BACKEND econ wretr qcur qtime eresp
# application backends: 


# Our configuration of HAproxy opens up the stats page.  This script pulls the CSV data from the stats server and 
# pulls out some interesting data which can be graphged in ganglia.

my $DEBUG = '1';                # Set to '1' to enable debugging
my $GMETRIC = "/usr/bin/gmetric";
my $CURL = '/usr/bin/curl';
my $CURL_OPTIONS = "-s";
my $QUERY = "$CURL $CURL_OPTIONS http://10.17.24.103/\\;csv";
my $CSV_DATA = `$QUERY`;
my @STATS;
my $STATS_LINE;
my $SERVICE_NAME;

# Create variables for each field in the CSV file
my $pxname;
my $svname;
my $qcur;
my $qmax;
my $scur;
my $smax;
my $slim;
my $stot;
my $bin;
my $bout;
my $dreq;
my $dresp;
my $ereq;
my $econ;
my $eresp;
my $wretr;
my $wredis;
my $status;
my $weight;
my $act;
my $bck;
my $chkfail;
my $chkdown;
my $lastchg;
my $downtime;
my $qlimit;
my $pid;
my $iid;
my $sid;
my $throttle;
my $lbtot;
my $tracked;
my $type;
my $rate;
my $rate_lim;
my $rate_max;
my $check_status;
my $check_code;
my $check_duration;
my $hrsp_1xx;
my $hrsp_2xx;
my $hrsp_3xx;
my $hrsp_4xx;
my $hrsp_5xx;
my $hrsp_other;
my $hanafail;
my $req_rate;
my $req_rate_max;
my $req_tot;
my $cli_abrt;
my $srv_abrt;
my $comp_in;
my $comp_out;
my $comp_byp;
my $comp_rsp;
my $lastsess;
my $last_chk;
my $last_agt;
my $qtime;
my $ctime;
my $rtime;
my $ttime;

# Split out the data line by line
@STATS = split /\n/, $CSV_DATA;

# Define the fields
foreach $STATS_LINE(@STATS) {
        chomp($STATS_LINE);
        if($STATS_LINE =~ /^#/) {
                next;
        }
        if($DEBUG) {
                print "$STATS_LINE\n";
        }
        # Ignore the field definitions lines
        ($pxname,$svname,$qcur,$qmax,$scur,$smax,$slim,$stot,$bin,$bout,$dreq,$dresp,$ereq,$econ,$eresp,$wretr,$wredis,$status,$weight,$act,$bck,$chkfail,$chkdown,$lastchg,$downtime,$qlimit,$pid,$iid,$sid,$throttle,$lbtot,$tracked,$type,$rate,$rate_lim,$rate_max,$check_status,$check_code,$check_duration,$hrsp_1xx,$hrsp_2xx,$hrsp_3xx,$hrsp_4xx,$hrsp_5xx,$hrsp_other,$hanafail,$req_rate,$req_rate_max,$req_tot,$cli_abrt,$srv_abrt,$comp_in,$comp_out,$comp_byp,$comp_rsp,$lastsess,$last_chk,$last_agt,$qtime,$ctime,$rtime,$ttime) = split /,/, $STATS_LINE;
        if($pxname eq 'stats' && $svname eq 'FRONTEND') {
                $SERVICE_NAME = 'HAproxy_Frontend_Combined';
                if($DEBUG) {
                        print "$SERVICE_NAME: Request_rate: $req_rate Sessions Per Second: $rate Bytes In: $bin Bytes Out: $bout Error Requests: $ereq\n";
                        print "$GMETRIC --name=$SERVICE_NAME -type=int32 --value=$req_rate --units=Requests/s";
                        print "$GMETRIC --name=$SERVICE_NAME -type=int32 --value=$rate --units=Sessions/s";
                }
        }
        if($pxname eq 'stats' && $svname eq 'BACKEND') {
                $SERVICE_NAME = 'HAproxy_Backend_Combined';
                if($DEBUG) {
                        print "$SERVICE_NAME: Connection Errors: $econ Connection Retries: $wretr Current Queued Requests: $qcur Average Queue Time: $qtime Resonse Errors: $eresp\n";
                }
        }
        if($pxname eq 'pgbouncer' && $svname eq 'FRONTEND') {
                $SERVICE_NAME = 'HAproxy_Pgbouncer_Frontend';
                if($DEBUG) {
                        print "$SERVICE_NAME: Request_rate: $req_rate Sessions Per Second: $rate Bytes In: $bin Bytes Out: $bout Error Requests: $ereq\n";
                }
        }
        if($pxname eq 'pgbouncer' && $svname eq 'BACKEND') {
                $SERVICE_NAME = 'HAproxy_Pgbouncer_Backend';
                if($DEBUG) {
                        print "$SERVICE_NAME: Connection Errors: $econ Connection Retries: $wretr Current Queued Requests: $qcur Average Queue Time: $qtime Resonse Errors: $eresp\n";
                }
        }
        if($pxname eq 'application-backend-5432' && $svname =~ /^\d+$/) {
                $SERVICE_NAME = "HAproxy_Pgbouncer_Backend_Port$svname";
                if($DEBUG) {
                        print "$SERVICE_NAME: Connection Errors: $econ Connection Retries: $wretr Current Queued Requests: $qcur Average Queue Time: $qtime Resonse Errors: $eresp\n";
                }
        }
        if($pxname eq 'application-backend-5432' && $svname eq 'BACKEND') {
                $SERVICE_NAME = 'HAproxy_Pgbouncer_Backend_Combined';
                if($DEBUG) {
                        print "$SERVICE_NAME: Connection Errors: $econ Connection Retries: $wretr Current Queued Requests: $qcur Average Queue Time: $qtime Resonse Errors: $eresp\n";
                }
        }
        if($DEBUG) {print "\n";}
}
