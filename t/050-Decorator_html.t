#!/bin/perl -w
use strict;
use warnings;

use Test::More;
use feature ':5.10';

BEGIN {
	my $module='Export::Decorator';
	$__PACKAGE__::module=$module;
	print "Testing $module\n";
	use_ok($module);
}

my $module=$__PACKAGE__::module;
# other uses here


# make object
my $obj=$module->new('html');
isa_ok($obj,'Export::Decorators::HTML');

# start testing
my $text=join("",$obj->header,$obj->decorate_hidden('hidden'),$obj->decorate('Ghani','green','em'),$obj->footer);
say $text;
