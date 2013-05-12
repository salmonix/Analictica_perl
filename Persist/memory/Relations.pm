#!/usr/bin/perl
package Persist::memory::Relations;

use feature ":5.10";
use strict;
use utf8;
use Carp;

our $VERSION='';

=pod

=head1 NAME

 Persist::memory::Relations - relations class

=head1 DESCRIPTION

 This class manages the relations for aTokens. Tokens may have multiple relations.
 Here an attempt to manage it.

=head1 METHODS

=over 4

=item - I<new( $tokens )>

 Returns the object, receiving a Core::Tokens instance.

=cut 

sub new {
	croak "USAGE: new ( \$core_tokens_instance ) , not $_[1]" unless ref $_[1] eq 'Persist::memory::Tokens';
	return bless {
		_tokens => $_[1],
		isa => [],
		hasa => [],
	};
}

=item - I<add_new_type('type')>

 Add a new type of relations. By default we have ISA and HASA.

=cut




1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
