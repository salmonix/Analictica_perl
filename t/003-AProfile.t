#!/bin/perl -w
use strict;
use warnings;

use Test::More;
use feature ':5.10';

BEGIN {
	my $module='AProfile';
	$__PACKAGE__::module=$module;
	print "Testing $module\n";
	use_ok($module);
}

my $module=$__PACKAGE__::module;

say "TODO: make a new profile passing the name";
# control parameters here.


# make and initialize object
use AProfile::Config;
my $obj=$module->new();
isa_ok($obj,'AProfile');
my $conf=$obj->active_config;
isa_ok($conf,'AProfile::Config');
my $schema=$conf->schema;
isa_ok($schema,'AProfile::Schema');

# initiate a new object
my $iconf=inited->new();
isa_ok($iconf->{conf},'AProfile::Config');
# check if that is ok.
is_deeply($conf,$iconf->{conf});
# check if we have the default config
my $def_conf=AProfile::Config->new();
is_deeply($def_conf,$conf);
my $schema2=$obj->get_schema;
is_deeply($schema,$schema2);



done_testing();


1;
package inited;
use strict;
use warnings;
use AProfile;

sub new {
	my $self={ conf=>$AConf };
	bless $self,__PACKAGE__;
	return $self;
};
1;
