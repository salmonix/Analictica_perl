#!/usr/bin/perl
package Persist::memory::Search;

use feature ":5.10";
use strict;
use utf8;
use Carp;
use Scalar::Util qw(blessed);

our $VERSION='';

=pod

=head1 NAME

 Persist::memory::Search - see doc in Core::Tokens.

=over 4

=cut 

sub new {
	if ( blessed  $_[1] eq 'Persist::memory::Tokens' ) {
	return bless {
			tokens => $_[1],
		},__PACKAGE__;
	};
	croak "Usage: Tokens instance pls., not a $_[1]";
}

sub select {
	my ($self,$param)=@_;
	croak "USAGE: HASH " unless ref $param eq 'HASH';
	my $list=$self->{tokens}->get_ranked;
	foreach ( @$list ) {
	}
}


1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
