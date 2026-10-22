#!/usr/bin/perl 

# This script should be run as root, through sudo

# Lets see if we can script as much as possible a repetative task
$OLDDB = $ARGV[0];
$NEWDB = $ARGV[1];
$UAT_DB = $ARGV[2];
$CODEPOOL = $ARGV[3];
$ENTR_INI = "/mnt/web/cust/$UAT_DB/conf/entprs.ini";
$ENTPRS_BK = "/mnt/web/cust/$UAT_DB/conf/entprs.ini.20130109.bk";
chomp($CODEPOOL);

print "---Creating new database on $NEWDB\n";
system("/opt/postgresql/bin/psql -h $NEWDB -U postgres -d template1 -c \"create database $UAT_DB\"");
system("/opt/postgresql/bin/psql -h $NEWDB -U postgres -c \"create user $UAT_DB with unencrypted password \'$UAT_DB\' nocreateuser nocreatedb\"");

print "---Truncating $OLDDB\n";
system("/opt/postgresql/bin/psql -h $OLDDB -U postgres -d $UAT_DB -c \"TRUNCATE TABLE sessions\"");

print "---dump $UAT_DB from $OLDDB\n";
sleep(5);
system("/opt/postgresql-8.2/bin/pg_dump -i -v -U postgres -F c -h $OLDDB -X use-set-session-authorization -f /home/marius/backups/$UAT_DB.$OLDDB.dump.20130208 $UAT_DB");
sleep(5);
print "---Restore $UAT_DB to $NEWDB";
system("/opt/postgresql-8.2/bin/pg_restore -X use-set-session-authorization -h $NEWDB -v -U postgres -d $UAT_DB < /home/marius/backups/$UAT_DB.$OLDDB.dump.20130208");

print "---Comparing sequence numbers\n";
system("/opt/postgresql-8.2/bin/psql -U postgres -h $OLDDB -d $UAT_DB -c \'select ordnum from business where ordnum is not null\'");
sleep(1);
system("/opt/postgresql-8.2/bin/psql -U postgres -h $NEWDB -d $UAT_DB -c \'select ordnum from business where ordnum is not null\'");

print "---Analyze $UAT_DB\n";
system("/opt/postgresql-8.2/bin/psql -h $NEWDB -U postgres -d $UAT_DB -c \"analyze\"");

print "---Add $NEWDB to /mnt/web/cust/$UAT_DB/conf/entprs.ini\n";
system("/bin/cp $ENTR_INI $ENTPRS_BK");
open(ENTRSOLD, $ENTPRS_BK);
open(ENTRSNEW, "> $ENTR_INI");
while (<ENTRSOLD>) {
	chomp;
	if($_ =~ /DBHOST=$OLDDB/) {
		print "-----Found DBHOST\n";
		print ENTRSNEW "DBHOST=$NEWDB\n";
	} elsif($_ =~ /DBREPORTSHOST=$OLDDB/) {
		print ENTRSNEW "DBREPORTSHOST=$NEWDB\n";
		print "-----Found DBREPORTHOST\n";
	} else {
		print ENTRSNEW "$_\n";
	}
}
# (Change to new database host)

print "---Check $CODEPOOL\n";
system("/mnt/web/apache/bin/apachectl check $CODEPOOL");
sleep(5);
print "---Restart $CODEPOOL\n";
system("/mnt/web/apache/bin/apachectl graceful $CODEPOOL");

# Verify that http://lff.uat.venda.com  is alive and kicking
# One can check sessions in postgres to verify

print "\n---Please verify that $UAT_DB is alive and kicking\n";

# Drop original database
print "Lets not automatically drop the DB.  When we are sure things are O.K. run:\n";
print "/opt/postgresql/bin/psql -h $OLDDB -U postgres -d template1 -c \"drop database $UAT_DB\"\n";
#system("/opt/postgresql/bin/psql -h $OLDDB -U postgres -d template1 -c \"drop database $UAT_DB\"");
