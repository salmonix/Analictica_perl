#!/bin/perl -w
use strict;
use warnings;

use Test::More;
use feature ':5.10';

BEGIN {
	my $module='Extensions::Stemmer::Hunspell';
	$__PACKAGE__::module=$module;
	print "Testing $module\n";
	use_ok($module);
}

my $module=$__PACKAGE__::module;
# other uses here


# make object
my $obj=$module->new();
my $path='/home/salmonix/HUNSPELL/hu_HU-1.6.1/';
isa_ok($obj,'Extensions::Stemmer::Hunspell');
# set module
$obj->set_module({ lang=>'hun',files=>[ $path."hu_HU.aff",$path."hu_HU.dic" ] });
# start testing
ok($obj->stem('megfogta'),'megfog');
ok($obj->base('megfogta'),'fog');



done_testing;
