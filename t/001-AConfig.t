#!/bin/perl -w
use strict;
use feature ':5.10';
use Test::More;

BEGIN {
	print "\nTesting AProfile::Config\n";
	use_ok('AProfile::Config');
}

my $def_work='../ANALICTICA/';
my $def={
	sourcedir=>$def_work.'Sources/',
	datadir=>$def_work.'Data/',
	projectfile=>$def_work.'Data/default_project.proj',
	db=>'',
	state=>0,
	schema=>'',
	ui=>'',
	lang=>'test',

};

my $conf=AProfile::Config->new();
isa_ok($conf,'AProfile::Config');

# some getters
subtest 'getters' => sub {
	can_ok( $conf,'get_datadir' );
	is( $conf->get_projectfile(),$def->{projectfile} );
	isa_ok( $conf->get_schema,'AProfile::Schema' );
};



done_testing();

1;
