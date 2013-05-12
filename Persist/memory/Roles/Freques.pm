#!/usr/bin/perl
package Persist::memory::Roles::Freques;

use base qw(AUtils::Roles);
use feature ":5.10";
use strict;
use utf8;
use Carp;
use Scalar::Util qw(blessed);
use List::MoreUtils qw(indexes firstidx lastidx);

our $VERSION='';

=pod

=head1 NAME

 Persist::memory::Roles::Freques - frequency related rules
 Documentation is in Core::Tokens.

=cut 

sub _get_idx_rank {#{{{
	my ($self,$pos)=@_;
	return $pos if ( $self->{_ranked_tokens}[$pos]->get_rank == $pos );
	if ( $self->{_ranked_tokens}[$pos]->get_rank < $pos ) {
		$pos--;
		return $self->_get_idx_rank($pos);
	};
	# If we are here perhaps something is wrong.
	if ( $self->{_ranked_tokens}[$pos]->get_rank > $pos ) {
		$pos++;
		return $self->_get_idx_rank($pos);
	};
}
#}}}
sub get_frequencies {#{{{
 	my ($self,$min,$max)=@_;
	if ( !$self->{_ranked_tokens} or $self->{_altered} ) {
		$self->build_freq_index();
	}
	return $self->{_ranked_tokens} if !$min;
	if ( $max ) {
		$max=$self->{_maxfreq} if $max > $self->{_maxfreq};
		if ($min>$max) { 
			carp " min>max. Surely you wanted this?";
			return undef;
		}
	}
	if ( $max ) {
		my $maxidx=firstidx { $_->get_sumfreq <= $max } @{$self->{_ranked_tokens}};
		my $minidx=lastidx { $_->get_sumfreq >= $min } @{$self->{_ranked_tokens}};
		return [ @{$self->{_ranked_tokens}}[$maxidx..$minidx] ];
	};
	my @idxs=indexes{ $_->get_sumfreq == $min }  @{$self->{_ranked_tokens}};
	return [ @{$self->{_ranked_tokens}}[ @idxs ] ];
}
#}}}
sub get_ranks {#{{{
	my ($self,$min,$max)=@_;
	if ( !$self->{_ranked_tokens} or !$self->{_altered} ) {
		$self->build_freq_index();
	}
	return $self->{_ranked_tokens} if !$min;
	if ( $max ) {
		$max=$self->{_lowest_rank} if $max > $self->{_lowest_rank};
		if ($min>$max) { 
			carp " min>max. Surely you wanted this?";
			return undef;
		}
	}
	if ( $max ) {
		my $minidx=firstidx { $_->{_rank} >= $min } @{$self->{_ranked_tokens}};
		my $maxidx=lastidx { $_->{_rank} <= $max } @{$self->{_ranked_tokens}};
		return [ @{$self->{_ranked_tokens}}[$minidx..$maxidx] ];
	};
	my @idxs=indexes{  $_->{_rank} == $min }  @{$self->{_ranked_tokens}};
	return [ @{$self->{_ranked_tokens}}[ @idxs ] ];
}
#}}}
sub build_freq_index {#{{{
	my ($self)=@_;
	return 1 if !$self->{_altered};
	$self->{_altered}=undef;
	$self->{_ranked_tokens}=[];
	# here comes a list making for attributing the realities
	my @sorted=sort{ $a->get_freq  <=> $b->get_freq } values %{$self->get_all_tokens};
	my ($token,$rank,@tok,$prevtok);
	# this is the most frequent element we start with
	$token=$prevtok=pop @sorted;
	$rank=1;
	$token->set_rank($rank);
	push @tok,$token;
	# now take the rest
	for (0..$#sorted ) {
		$token=pop @sorted; 
		# do not change rank if prev. has the same freq.
		# print $toklist->{$token}->get_freq." :$token\n";
		if ( $token->get_freq != $prevtok->get_freq ) {
			$rank++;
		}
		$token->{_rank}=$rank;
		$prevtok=$token;
		push @tok,$token;
	}
	$self->{_ranked_tokens}=\@tok;
	# get the highest frequency and no of tokens
	$self->{_maxfreq}=$self->{_ranked_tokens}[0]->get_freq;
	$self->{_lowest_rank}=$rank;
	1;
}
#}}}
# freqs#{{{
sub get_freq{
	return $_[0]->{_sum_freq} unless $_[1];
	return $_[0]->{_frequencies}{$_[1]}{$_[2]};
}

sub get_positions {
	return $_[0]->{_frequencies}{$_[1]};
}

sub add_freq {
	$_[0]->{_sum_freq}++; 
	$_[0]->{_frequencies}{$_[1]}{$_[2]}++;
}

# return bool: 1 if any increment is done, undef if none
# recursively.
sub increment_freqs {
	return $_[0]->_do_freques($_[1],$_[2]);
}

# it is a brute-force method
sub clear_freqs {
	my $root;
	if (!$_[0]->{_root}) {
		$root=$_[0];
	} else {
		$root=$_[0]->{_root};
	}
	foreach ( @{$root->{_indexes}} ) {
		next if $_->{name} =~/^#/; # skip labels (they should be visited nevertheless)
		$_->_do_freques;
	}
}

# when nothing is passed, it clears mercylessly. 
# TODO: check circular dependency using visitor flag with rand!
# the problem is that we enter here into traversing the associates
# which is a more general problem than simply clearing frequencies.
# This crawling and all should go into some Rule.
sub _do_freques {
 	my ($self,$unit,$c)=@_;
	my @labels=keys %{$self->{_associate}};   # save it now for at deletion undefed
	if ( $unit ) {
		no warnings;
        	$self->add_freq($unit,$c);
	} else { 
		$self->{_frequencies} = undef;
		$self->{_sum_freq} = undef;
	};
	my $puf=undef;
	foreach ( @labels ) {	                 # do recursively
		$self->{_root}{_tokens}{$_}->increment_freqs($unit,$c) if $self->{_root};
		$puf=$self->associate($_); # get the associate
		next unless blessed $puf;        # next if not object
		if ( $puf->can('increment_freqs')) {   # and call increment recursively if possible
			$puf->increment_freqs($unit,$c);
		}
	}
}

sub add_freq_hash {
	$_[0]->{_frequencies}{$_[1]}=$_[2];
	my $freq=0;
	map { $freq+=$_[2]->{$_} } keys %{$_[2]};
	$_[0]->{_sum_freq}=$freq;
}

#}}}
# freq adding-smallest and etc.#{{{
sub smallest_and {
	my ($self,$list1,$unit)=@_;
	$list1=$list1->{_frequencies}{$unit} if ref $list1 eq ref $self;
	my $list2=$self->{_frequencies}{$unit};
	my ($iterit,$checkit);
	# we iterate on the smaller hash for some speed
	if ( keys %$list1 < keys %$list2 ) {
		$iterit  = $list1;
		$checkit = $list2;
	} else {
		$iterit  = $list2;
		$checkit = $list1;
	}
	my %return;
	while ( my($pos,$val)=each %$iterit ) {
		next unless $checkit->{$pos};
		if ( $checkit->{$pos} > $val ) {
			$return{$pos}=$val;
			next;
		}
		$return{$pos}=$checkit->{$pos};
	}
	#printit($list1);
	#printit($list2);
	#printit(\%return);
	return \%return if keys %return;
	return undef;
}

#}}}

sub positions_subset {#{{{
	my ( $self,$list1,$unit)=@_;
	$list1=$list1->{_frequencies}{$unit} if ref $list1 eq ref $self;
	my $list2=$self->{_frequencies}{$unit};
	return 1 and map { exists $list1->{$_} } keys %$list2;
}
#}}}

1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
