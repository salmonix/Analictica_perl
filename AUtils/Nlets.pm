#!/usr/bin/perl
package AUtils::Nlets;

use feature ":5.10";
use strict;
use utf8;
use Carp;

require Exporter;
our @ISA=qw(Exporter);
our @EXPORT_OK=qw(nlet);

=pod

=head1 NAME

 AUtils::Nlets - make Nlets of the passed list.

=head1 DESCRIPTION

 Nlets are the possible combinations (subsets) of k elements of a list
 (set) of n items.
 The number of combinations can be calculated with the formula of
 n! / k!(n-k)!  if 0<k<=n. n is the total number of elements, 
 k is the number of elements in the subsets.

=head1 USAGE & METHODS

 If no OO is required, simply put

   use AUtils::Nlets qw(:all);

 and the function B<nlets> is exported. This function takes an ARRAY/HASH and the 
 nlet number, and returns an AoA of the possible combinations.

=over 4

=item - I<new($list)>

 Takes an ARRAY or HASH. When a HASH is passed, its keys are processed.
 NOTE: When an ARRAY is passed it is not checked whether the ARRAY contains
 unique elements.

=cut 

sub new {
	my $class=shift;
	my $self={};
	bless $self,$class;
	given ( ref $_[0] ) {
		when ( 'ARRAY' ) {
			$self->{list}= $_[0];
		}
		when ( 'HASH' ) {
			$self->{list}= [ keys %{$_[0]} ];
		}
		default {
			croak "Usage: \$ARRAY or \$HASH not @_";
		}
	};
	$self->{size}=$#{$self->{list}};
	return $self;
}

=item - I<make_nlets($Nlet)>

 Takes an integer for making Nlets. (2 - duplets, 3 - triplets, 4 - quadruplets etc. ),
 returns an AoA of possible combinations.

=cut

sub make_nlets {
	my ($self,$nlet)=@_;
	$nlet=int($nlet); #sanity for 0<k
	croak "Nlet must be an integer greater than 0!" if ! $nlet or $nlet == 0;
	$nlet--;
	return $self->{list} if ( $nlet == $self->{size} ); # if k=n, we are done
	if ( $nlet > $self->{size} ) { # sanity for k<n
		carp "$nlet Nlet is greater than the size $self->{size} of the list.";
		return undef;
	}
	return $self->_nlets(0,$nlet); # the first parameter is the starting position
}

# a complicated non-oo call wrapper for the module.
sub nlets {
	return __PACKAGE__->new($_[0])->make_nlets($_[1]);
}

# it builds the combinations with a tail recursive function (although Perl seems not to
# optimize for tail recursion.)

sub _nlets {
	my ($self,$pos,$nlet)=@_;
	my $it=$self->{list}[$pos];
	my $ret;
	if ( ! $nlet or $nlet == 0 ) {
		map { push @$ret,[ $_ ] } @{$self->{list}}[$pos..$self->{size}];
		return $ret;
	}
	for (1..$self->{size}-$pos-$nlet+1) { 
		$pos++;
		my @plets= @{ $self->_nlets($pos,$nlet-1) };
		map { push @$ret,[$it,@$_] } @plets;
		$it=$self->{list}[$pos];
	}
	return $ret;
}

1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO

It may happen that this module goes into our ArrayUtils or into a separate
sets utils.

=head1 AUTHOR & COPYRIGHT

(C) Laslo Forro salmonix_at_gmail_dot.com
License is same as Perl itself. 
I you are lucky, for the license just type 
'perldoc perlartistic' and 'perldoc perlgpl' from the console.
