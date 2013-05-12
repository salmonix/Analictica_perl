#!/bin/perl -w
use strict;
use warnings;

use Test::More;
use feature ':5.10';

BEGIN {
	my $module='Extensions::Tokenizer::default';
	$__PACKAGE__::module=$module;
	print "Testing $module\n";
	use_ok($module);
}

my $module=$__PACKAGE__::module;
# other uses here


# make object
my $obj=$module->new();
isa_ok($obj,'Extensions::Tokenizer::default');

my $string="One ring to rule them all";
my @arr=[qw(One ring to rule them all)];

my $splitted=$obj->split($string);
is_deeply($splitted,  @arr,"Default: \\s ok."  );

$obj->rex(qr/to/);
$splitted=$obj->split($string);
my $contr=[ split(/to/,$string) ];
is_deeply($splitted,$contr,"Change Regexp ok.");
$splitted=$obj->grep($string);
is_deeply($splitted,['to'],"Grep ok.");

done_testing;
