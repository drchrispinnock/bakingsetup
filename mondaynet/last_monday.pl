#!/usr/bin/perl

my $epoc = time();
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($epoc);

$wday=7 if $wday == 0; # Sunday = 0
$epoc = $epoc - ($wday-1)*24*60*60;

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($epoc);
$year = $year+1900;
$mon = $mon+1;
$mon = "0".$mon if $mon < 9;
$mday = "0".$mday if $mday < 10;
print "$year-$mon-$mday\n";

