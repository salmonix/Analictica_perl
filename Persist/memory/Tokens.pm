#!/usr/bin/perl
package Persist::memory::Tokens;

BEGIN {
	use Persist::memory::Roles::Freques;
	Persist::memory::Roles::Freques->apply(__PACKAGE__);
	use Persist::memory::Roles::Associates;
	Persist::memory::Roles::Associates->apply(__PACKAGE__);
}

use feature ":5.10";
use strict;
use utf8;
use Carp;
use base qw(Persist::memory);
use AProfile;
use Scalar::Util qw(blessed );

our $VERSION='';
our $AUTOLOAD;

=pod

=head1 NAME

 Persist::memory::Tokens

=head1 DESCRIPTION

 The Tokens object implementation.

=head1 METHODS

=over 4

=cut 

use Class::XSAccessor {#{{{
	getters => {
		get_hide_labels   => '_hide_labels',
		get_ranked_tokens => '_ranked_tokens',
		get_use_labels    => '_use_labels',
		get_relationlist  => '_relations',
		get_name    => 'name',
		get_rank    => '_rank',
		get_sumfreq => '_sum_freq',
		get_myid    => '_id',

	},
	setters => {
		set_unit=>'_units',
		set_rank => '_rank',
		set_sumfreq => '_sum_freq',
		set_id	    => '_id',
		set_name    => 'name',
	},
};
#}}}
our ($real,%puf,$puf); # puffer
our $dummy=DUMMY->new();


sub new {#{{{
	my $self= {
		name         => $_[1],
		_sum_freq    => undef,
		_rank        => undef,
		_id          => undef,
		_frequencies => {}, 
		_associate   => {}, 
		_associate_from => [],
		_hidden       => undef,
		_use_labels   => ['#NORMAL',],
		_tokens         => {},
		_indexes       => [],
		_last_index  => 0,
		_altered     => 1,
		_maxfreq     => undef,
		_lowest_rank => undef,
		_root	     => $AConf->{core_tokens},
	};
	bless $self,__PACKAGE__;
	return $self;
}
#}}}
sub aToken {#{{{
	my ($self,$token,$param)= @_;
	croak "No token parameter" unless $token;
	my $token_obj;
	if ( !$self->{_tokens}{$token} ) {
		$token_obj=$self->_make_object($token);
		push @{$self->{_indexes}},$token_obj;
		$token_obj->{_id}=$self->{_last_index}++;
	} else {
		$token_obj=$self->{_tokens}{$token};
	}
	if ( $param ) {
		if ( $param->{hide} ) { # if it is a hide-label we put it there straight
			my ($reason)=keys %{$param};
			$token_obj->hide( $reason );
			delete $param->{hide};
		}
		if ( $param->{use_labels} ) {
			while ( my($key,$arg)=each %{$param->{use_labels}} ) {
				$token_obj->add_associate( $key,$arg );				    
			}
		}
		return $token_obj;
	}
	$self->{_altered}=1;
	return $token_obj;
}

sub _make_object {
	my ($self,$token)=@_;
	my $puf;
	if ( blessed $token and blessed $token eq 'Persist::memory::Tokens') {
		$puf=$token;
		$token=$puf->{_name};
	} else {
		$puf=Persist::memory::Tokens->new($token);
	}
	$self->{_tokens}{ $token }=$puf;
	return $puf; 
}
#}}}
sub store {#{{{
	$_[0]->{_attribs}{$_[1]}=$_[0]->_add_associate($_[2],$_[3]);;
}

sub get {
	$_[0]->associate($_[1],$_[2]);
}

sub unstore {
	delete $_[0]->{_attribs}{$_[1]};
}#}}}
sub delete_tokens {#{{{
	my ($self,$token)=@_;
	my $hidden=$self->{_hide_labels}{'#DELETED'};
	# remove multiple entries
	if (ref $token eq 'ARRAY') {
		my $tokens=$self->{tokens};
		foreach ( @$token ) {
			my $name=$_->get_name;
			$hidden->{$_}=delete $tokens->{$name};
		}
		$self->build_freq_index;
		return 1;
	}
	# if we delete one item we try to move _ranked_tokens instead of rebuilding it.
	my $rank=$token->get_rank;
	my $idx=$self->_get_idx_rank($rank);
	$hidden->{$token}=delete $self->{tokens}{$token};
	# overwrite the array shrinking with one. 
	# splicing does not help us with iterating the whole for rank and it is unlikely that
	# more than a few tokens have the same frequency.
	my $ranked=$self->{_ranked_tokens}; # avoid hash lookup
	for ( $idx..$#{$ranked}-1 ) {
	 	if (  $ranked->[$idx+1]->get_rank > $idx ) {
			$ranked->[$idx+1]->set_rank($idx+1);
		}
		$ranked->[$idx]=$ranked->[$idx+1];
	}
 	pop; # remove the last item which is duplicate of the one before the last.
}
#}}}
# get_all_indexes, all_tokens, get_members #{{{
sub get_all_indexes {
	return [ @{$_[0]->{_indexes}} ];
}

# reallyall = *
sub get_all_tokens {
	my %ret=();
	my ($name,$obj,$insp);
	while ( ($name,$obj)=each %{$_[0]->{_tokens}} )  {
		next if $obj->{_hidden};
		next if $name =~/^#/;                  # skip # labels
		if ( $_[1] and  $_[1] eq '*' ) {		# reallyall returns really all
			$ret{$obj->{name}}=$obj;
			$insp=$_[2];
		} else {
			$insp=$_[1];
		}
		$obj=$obj->process_use_labels($obj);
		if ( blessed $obj and $obj->{name} ) { # not dummy and object
			if ( keys %{$insp} ) {
				next unless $_[0]->_inspect($obj,$insp);
			}
			$ret{$obj->{name}}=$obj 
		}	
	}
	return \%ret;
}

sub get_members {
	return undef if $_[0]->{name} !~/^[#_]/; # these are labels
	return [ grep { $_->{_associate}{ $_[0]->{name} } } values %{$_[0]->{_root}{_tokens}}] ;
}

#}}}
# get_token_names get_token get_id get_by_name get_by_id#{{{
sub get_token_names {
	$_[0]->build_freq_index unless $_[0]->{_ranked_tokens};
	$_[1]||=$_[0]->{_ranked_tokens};
	return [  map { $_->get_name } @{$_[1]} ];
}

sub get_token {
	my $puf;
	if ( ! ref $_[1] ) {
		my $token=$_[0]->get_by_name($_[1]) || return undef;
		$puf=$_[0]->process_use_labels($token);
		if ( $_[2] ) {
			return undef unless $_[0]->_inspect($puf,$_[2]);
		}
		return $puf;
	}
	if ( ref $_[1] eq 'ARRAY' ) {
		my ($token,@ret);
		map {
			$token=$_[0]->get_by_name($_) || undef if $_;
			$puf=$_[0]->process_use_labels($token);
			if ( $_[2] ) {
				push @ret,$puf if $_[0]->_inspect($puf,$_[2]);
			} else {
				push @ret,$puf if $token;
			}
		} @{$_[1]};
		return \@ret;
	}
}

sub get_id {
	my $token=$_[0]->get_by_id($_[1]) || return undef;
	my $puf;
	$puf=$_[0]->process_use_labels($token);
	if ( $_[2] ) {
		return undef if !$puf->{name};
		return $puf if $_[0]->_inspect($puf,$_[2]);
		return undef;
	}
	return $puf;
}

sub get_by_name {
	return $_[0]->{_tokens}{$_[1]} if $_[0]->{_tokens}{$_[1]};
	return $dummy;
}

sub get_by_id {
	return $_[0]->{_indexes}[$_[1]];
	return $dummy;
}
#}}}
sub _inspect {#{{{
	return 1 if $_[1]->can($_[2]);
	return undef;
}

#}}}
# labels  destroy#{{{
sub destroy_labels {
	$_[0]->destroy_relations;
	foreach ( (undef,$puf)= each %{$_[0]->{_tokens}} ) {
		$puf->destroy_labels($_[1]);
	};
	$puf=undef;
}
 
sub destroy_relations {
	$real=$_[0]->{_relations};
	map { delete $real->{$_}{$_[1]} } keys %$real;
	foreach ( (undef,$puf)= each %{$_[0]->{_tokens}} ) {
		$puf->destroy_relations($_[1]);
	};
	$real=$puf=undef;
}
#}}}
sub delete_me {#{{{
	$_[0]->delete_tokens( $_[0] );
}
#}}}

#
# LABELS, ASSOCIATES
#

# use labels #{{{
sub process_use_labels {
 	my ($self,$token,$labels)=@_;
	my $puf;
	return undef if $token->{_hidden};
	$labels||=$self->{_use_labels};
	foreach ( @$labels ) {
		$puf=$token->associate($_);
		return $puf unless blessed $puf;
		if ( ! $puf->{name} ) {
			$puf=undef;
			return $token;
		}
		$token=$puf;
	}
	return $puf;
}

sub add_use_label {
	push @{$_[0]->{_use_labels}},$_[1];
	$_[0]->{_altered}=undef;
}

sub del_use_label {
	$_[0]->{_use_labels} = [ grep ( !/$_[1]/, @{$_[0]->{_use_labels}} ) ];
	$_[0]->{_altered}=undef;
}
 #}}}
# hide_label#{{{
sub add_hide_label {
	$_[0]->add_associate('_hide_labels',$_[2]);
	while ( my ($token)=values %{ $_[0]->{tokens} } ) {
		my $puf=$token->process_use_labels;
		next unless $puf;
		$puf->hide($_[2]);
	}
	$_[0]->{_altered}=1;
}

sub show_hide_labels {
	my $puf=$_[0]->{_selected}=[];
	while ( my ($name,$token)=each %{ $_[0]->{_tokens} } ) {
		next unless $token->{_hidden}{$_[1]};
		push @{$puf},$name;
	}
	return $puf;
}

sub del_hide_labels {
	$_[0]->show_hide_labels($_[1]);
	$_[0]->del_associate('_hide_labels',$_[1]);
	return $real;
}
#}}}
# hide#{{{
sub hide {
	$_[0]->{_hidden}=$_[1]||1;
	$_[0]->{_altered}=1;
}

sub if_hidden {
	return $_[0]->{_hidden};
}

sub hide_label { 
	$_[1]||=1;
	return $_[1] if $_[0]->{_hidden} eq $_[1];
	return undef;
}

sub unhide {
	$_[0]->{_hidden}=undef;
	$_[0]->{_altered}=1;
}
#}}}
# debug tools#{{{
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
	
#}}}

sub DESTROY {
	1;
}

sub AUTOLOAD {
	carp "Exception: $AUTOLOAD was called" ;
	return undef;
};

1;

package DUMMY;
use base 'Persist::memory::Tokens';
1;

sub new {
	my $dum=__PACKAGE__->SUPER::new();
	return bless $dum,__PACKAGE__;
}


__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
