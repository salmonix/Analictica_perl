#!/bin/perl -w
use strict;
use warnings;
use feature ':5.10';

use Test::More;

BEGIN {
	use_ok('AProfile::default_schema');
}
my $sch=AProfile::default_schema->new();
isa_ok($sch,'AProfile::Schema');
