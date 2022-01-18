#!/usr/bin/perl

use strict;
use warnings;

use JSON;
use Data::Dumper;

die unless(@ARGV);

my $file = $ARGV[0];
my $stub = $ARGV[1];
my $network = $stub;

my $json_text ="";
open FILE, "$ARGV[0]" or die "cannot open file\n";
while(<FILE>) {
	$json_text = $json_text.$_;
}
close FILE;

my $json = JSON->new->allow_nonref;
my $hd = $json->decode($json_text);

my %h = %$hd;
#print "Available networks in json file:\n"; 
foreach my $k (keys(%h)) {
#	warn "\t$k\n";
	$network = $k if $k =~ m/^$stub/;
}

my $build='';
if ($hd->{$network}->{'docker_build'}) {
	$build=$hd->{$network}->{'docker_build'};

	# tezos/tezos:master_d0bf56ce_20220113200826	
	$build =~ m/.*_(.*)_.*/;
	$build = $1;

} else {
	printf "Cannot find $network in Test Network inventory!\n";
	exit 2
}
#warn "\nUsing:\t$network with $build\n";
print "$build\n";
