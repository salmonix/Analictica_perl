#!/usr/bin/perl
package Core::Tokens;

use feature ":5.10";
use strict;
use utf8;
use Carp;
use AProfile;
use AUtils::LoadModule;

=pod

=head1 NAME

 Core::Tokens 

=head1 DESCRIPTION

 It simply initiates the real implementation. See Core::Documentation of what.

=cut 

sub new {
	my ($class,$proj)=@_;
	my $conf=AProfile->new()->get_config($proj);
	my $module=$conf->schema()->module;
	load_module($module);
	$conf->core_tokens( $module->new() );
	return $conf->core_tokens;
}

1;
__END__

