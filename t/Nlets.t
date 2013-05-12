#!/bin/perl -w
use strict;
use feature ':5.10';

use Test::More;

BEGIN {
	use_ok('AUtils::Nlets');
	use AUtils::Nlets;
}
#my @text=qw(aa bb cc dd ee rr tt zz);
my @text=qw(aa bb cc dd);
my $mat=AUtils::Nlets->new( [@text]);

is( ref($mat),'AUtils::Nlets','Ref, got.');
my $lets=$mat->make_nlets(2);
print_arrays($lets);
say "Variations:".($#{$lets}+1);

sub print_arrays {
	no warnings;
	foreach(@_) {
		map {say join(' :',@{$_})} @$_;;
	}
}
