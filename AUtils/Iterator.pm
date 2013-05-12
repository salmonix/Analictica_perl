#!/bin/perl
package AUtils::SetCallback ;

use feature ":5.10";
use strict;
use utf8;
use Carp;

=pod

=head1 NAME

Funtions::SetCallback - setting callbacks in the passed object.


=head1 DESCRIPTION

The method C<callback> puts callbacks into the passed object. The main reason of this simple
module is that it can provide a unified method to insert callbacks into the code that is otherwise the same boring chunk.
This module implements iterators, too.
The methods usually take after the pattern below:

I<method($obj,$name,sub{ CODE }|some REF?>

=head1 METHODS

=over 4

=item - I<callback($obj,$name,sub{ CODE }?>

The arguments are:
- $obj     : the object the iterator goes into
- $name    : the name for the iterator in the passed object
- $iterator: the code for the iterator. Optional.

eg. AUtils::SetCallbacks->new($myobj,'filter',sub{ #my filtering code }) will
make a $myobj->{filter}=sub{# my filtering code} to the object, that can be used as
my $foo=$myobj->{filter}($bar); # according to the filtering code.

=cut 

sub callback {
		
}


1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO

=head1 AUTHOR & COPYRIGHT

(C) Laslo Forro salmonix_at_gmail_dot.com
License is same as Perl itself. 
I you are lucky, for the license just type 
'perldoc perlartistic' and 'perldoc perlgpl' from the console.
