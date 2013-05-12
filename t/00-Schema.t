#!/bin/perl -w
use strict;
use warnings;

use Test::More;

BEGIN {
	use feature ':5.10';
	say "\nTesting AProfile::Schema";
	use_ok('AProfile::Schema');
}

my $sch=AProfile::Schema->new('memory');
isa_ok($sch,'AProfile::Schema');
is($sch->get_engine, 'memory');
$sch=AProfile::Schema->new();

subtest 'Accessors' => sub {
	can_ok($sch,'get_order');
	is(ref $sch->get_table('tokens'),'HASH');
	is( $sch->get_column('tokens','frequency'),'int');
	is( $sch->get_dbengine,'SQLite');
};


done_testing();

1;

__END__

=pod 

Need more testing!!
