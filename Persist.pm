#!/usr/bin/perl
package Persist;

use feature ":5.10";
use strict;
use utf8;
use Carp;
use AUtils::LoadModule;

=pod

=head1 NAME

 Persist - mother of all storage modules.

=head1 DESCRIPTION

 This module returns the storage object as defined in the project profile.

=head1 METHODS

=over 4

=item - I<new($Config)>

 Takes a configuration object and returns the storage object setting the Config->db slot.

=cut 

sub new {
	my ($class,$conf)=@_;
	croak "USAGE: AProfile::Config object, not $conf !" unless ref $conf eq 'AProfile::Config';
	my $schema=$conf->get_schema;
	my $module=$schema->get_module;
	my $persist_obj=load_new_object($module,$schema);
	$conf->set_db( $persist_obj );
	return $persist_obj;
}


1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
