#!/usr/bin/perl
package Extensions::Collocations;

use feature ":5.10";
use strict;
use utf8;
use Carp;
use AProfile;

=pod

=head1 NAME

Extensions::Collocations - find collocations and alikes using a AUtils::WordCount object


=head1 DESCRIPTION

Takes a list of token objects or tokens and returns their collocations.
In our terms collocations are the combinations of N elements.
If combinations are needed for a simple list, see AUtils::Nlets.
The return value is a Core::Tokens instance of collocations.

=head1 METHODS

=over 4

=item - I<new( $token_instances ) >

 Takes a list of tokens and returns the instance.

=cut 


our ($tokens,$size,$stack,$nlet_number,$diff,$core_tokens,$unit,$found);
sub new {
	my ($class,$list) = @_;
	given ( ref $list ) {
		when ( 'HASH' ) {
			$list=[ values %$list ];
		}
		when ( 'ARRAY' ) {
			1;
		}
		default {
			croak " USAGE: ARRAY|HASH, not $list";
		}
	}
	my $self={};
	bless $self, __PACKAGE__;
	$self->{list}=$tokens=$list;
	$self->{size}=$size=$#{$tokens};
	return $self; 
}

=item - I<collocate($nlet,$unit,$max)>

Find the collocations of $nlet tokens trying the possible combinations in the $unit.
If $max is given, it stops at $max found elements.

=cut

sub collocate {
	my ($self,$nlet,$aunit,$max)=@_;
	$self->{core_tokens}=Core::Tokens->new();
	$self->{max}=$max;
	$tokens=$self->{list};
	$self->{size}=$size=$#{$tokens};
	$unit=$aunit or croak "unit missing. USAGE: int, unit."; 
	$nlet_number=$nlet=int($nlet); # reals only
	$self->{nlet}=$nlet;
	croak "Nplet must be an integer greater than 0!" if ! $nlet or $nlet == 0;
	$nlet--; # because array counting starts at 0 not 1 we may have a 0th element, but 0 nlet is senseless
	return $self->{list} if ( $nlet == $self->{size} );
	if ( $nlet > $self->{size} ) { 
		carp "$nlet Nlet is greater than the size $self->{size} of the list.";
		return undef;
	}
	# make globals
	$core_tokens=$self->{core_tokens};
	$DB::single=1;
	$self->_collocate(0,$nlet);
	($tokens,$size,$stack,$diff,$nlet_number,$core_tokens)=undef;
	return delete $self->{core_tokens};
}

# $tokens is the list of tokens we check the combination for
# $stack contains the list of valid combinations.
# the combinations - keys of the return HASH - are made joining the content of the stack
# with #.
# TODO: implement an 'all-match' case with *
sub _collocate {
	my ( $self,$pos,$nlet,$list )=@_;
	return undef if $self->{max} and $self->{max}==$found;
	if ( $nlet==0) {
		# if we are the last element iterate through the array
		for ( $pos..$size ) {
			$diff = $tokens->[$_]->smallest_and($list,$unit);
			#		$self->debugstate($_,$diff);
			if ( $diff ) {
				push @{$stack}, $tokens->[$_];
				my $newtoken="Coll:$nlet_number(".join( ' ', map { $_->get_name } @{$stack} ).')';
				$newtoken=$core_tokens->aToken($newtoken);
				$newtoken->add_freq_hash($unit,$diff);
				pop @{$stack};
				$found++;
			}
		}
		return; # and back
	}
	# we are not the last, so call recursive if cond.A is true
	for ( $pos..$size-$nlet ) {
		# initial state OR empty stack is good for none
		if ( !$list or !@$stack ) {		  
			unless ( $list=$tokens->[$_]->get_positions($unit) ) {
				# if undef is returned something is wrong with $unit probably
				carp "token->get_positions( 'unit' ) returned undef";
				return undef;
			}
		} else {
			# the passed and present position lists must have some value at least at one position
			unless ( $list =  $tokens->[$_]->smallest_and($list,$unit) ) {
				#	say " iterating on no value for list. $_";
				next;
			}
		}
		# if we have value in list then add token to the stack as valid
		push @{$stack}, $tokens->[$_];
		$self->_collocate($_+1,$nlet-1,$list); # scan the next position
		pop @{$stack};
	}
}

sub debugstate {
	say "stack in last : ".join('#',map { $_->get_name}  @{$stack})."#".$tokens->[$_[1]]->get_name;
	say "-----------";
}

sub printit {
	my ($self,$list)=@_;
	my ($head,$pos);
	no warnings;
	while ( my ($k,$v)=each %$list ) {
		$head.="  ".$k;
		$pos.="  ".$v;
	};
	if ( $head ) {
		say ":".$head;
		say " ".$pos;
	}
}
	


1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO

1. The number of combinations can be calculated with the formula of
n! / k!(n-k)!  if 0<k<=n. n is the total number of elements, 
k is the number of elements in the subsets, ( 2 if duplet, 3 if triplet etc.)
BEWARE!
The greater is k, the smaller is the divider, that is the greater number of
possible combinations is returned with the factor of some ! and 
we neither use big numbers module nor check for overflow!!!!!

2. If no wordlist is defined the list of all the tokens in the WordCount object
is copied. That is a waste but also a silly thing if the tokens are many. However,
this possibility is not excluded.

3. A slight room for performance is to rewrite the object into array internally.
That is a gain for speed but a loss for readibility. However, once the module is 
properly tested unlikey will anyone touch it.
