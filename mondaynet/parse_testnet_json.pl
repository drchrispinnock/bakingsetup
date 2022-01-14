#!/usr/bin/perl

use strict;
use warnings;

use JSON;
use Data::Dumper;

die unless(@ARGV);

my $file = $ARGV[0];
my $network = $ARGV[1];

my $json_text ="";
open FILE, "$ARGV[0]" or die "cannot open file\n";
while(<FILE>) {
	$json_text = $json_text.$_;
}
close FILE;

my $json = JSON->new->allow_nonref;
my $hd = $json->decode($json_text);

#print Dumper($hd);
#print "\n";

my $build='';
if ($hd->{$network}->{'docker_build'}) {
	$build=$hd->{$network}->{'docker_build'};

	# tezos/tezos:master_d0bf56ce_20220113200826	
	$build =~ m/.*_(.*)_.*/;
	$build = $1;

	print "$build\n";
} else {
	printf "Cannot find $network in Test Network inventory!\n";
	exit 2
}
