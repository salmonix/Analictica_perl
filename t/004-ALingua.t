#!/bin/perl -w
use strict;

use Test::More;

BEGIN {
	use feature ':5.10';
	use warnings;
	say "\nTesting ALingua";
	use AProfile::Config;

}
AProfile->new();
AProfile->active_config;
use_ok('ALingua');

my $test={
	test1=>'Kék',
	test2=>'Piros',
};

my $conf=ALingua->new('test');

isa_ok($conf,'ALingua');

subtest 'default' => sub {
	can_ok($conf,keys %$test);
	is($conf->test1,$test->{test1});
	is($conf->test2,$test->{test2});
};

# initiate a new object
my $iconf=inited->new();
isa_ok($iconf->{ling},'ALingua');
# check if that is ok.
is_deeply($conf,$iconf->{ling});

# TODO: need example to change language.

done_testing();

1;
package inited;
use strict;
use warnings;
BEGIN {
	use ALingua;
}

sub new {
	my $self={ ling=>$ALin };
	bless $self,__PACKAGE__;
	return $self;
};
1;
