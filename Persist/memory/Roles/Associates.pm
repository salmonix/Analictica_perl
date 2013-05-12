#!/usr/bin/perl
package Persist::memory::Roles::Associates;

use base qw(AUtils::Roles);
use feature ":5.10";
use warnings;
use strict;
use utf8;
use Scalar::Util qw(blessed );
use AProfile;

our $VERSION='';
our ($ass_puf);

=pod

=head1 NAME

Persist::memory::Roles::Associates - Associate related functions

=cut 

# add_associate   #{{{ 
# 0: token 1: what label 2: what value
sub add_associate {
	my ($container,$value);
	$value = $_[2];
	$container=$_[0]->{_root}{_tokens}{$_[1]};
	if ( ! $container )  { 			   # if container object does not exist
		$container=$_[0]->{_root}->_make_object($_[1]); # make a container token
	};
	if ( !$value ) {			           # got not value to associate with
		$value||= substr $_[1],1; 	           # make one from container name
		($value)=$container->{_tokens}{$value};    # and try to get that from the container
		$value||= substr $_[1],1 if !$value; 	   # or fallback to the first idea
	}
	if ( !ref $value ) {		                         # if our parameter is not ref, ask container
		my $value_obj=$container->_make_object( $value );# to create the value token
		$_[0]->{_associate}{$_[1]}=$value_obj;   	 # and make return that object
		push @{$value_obj->{_associate_from}},$_[0];   # and add in object the associate from
	} else {					# we are an object ( may be a CODE, but we do not document it )
		if ( ! $container->{_tokens}{$_[1]} ) {   # and label is not in container
			$container->{_tokens}{$_[1]}=$value;   # put it there
		}
		if ( blessed $value and $value->can('add_associate_from') ) { # if we can add associate from
			$value->add_associate_from($_[0]);  	            # do it to keep associate links healthy
		}
		$_[0]->{_associate}{$_[1]}=$_[0]->_add_associate($value,$_[3]);		
	}
}

sub _add_associate {#{{{
	given ( ref $_[1] ) {    # the cases when user puts something clever in the slot
		when ( 'CODE' ) {
			return $_[1]->($_[2])
		};
		when ( blessed $_[1] and $_[2] ) {
			return $_[1]->($_[2]);
		}
		when ( blessed $_[1] ) {
			return $_[1];
		}
		default {         # this is a simple label creation
			return $_[1];
		}
	}
	return 1;
}#}}}
 #}}}
#{{{ associate
sub associate {
	return $_[0] if !$_[0]->{_associate}{$_[1]};
	return $_[0]->_associate( $_[0]->{_associate}{$_[1]},$_[2] );
}

sub _associate {
	my (undef,$associate,$param)=@_;
	if ( blessed $associate and $param ) {
		my ($method,$arg)=each %$param;
		return undef unless $associate->can($method);
		return $associate->$method($arg);
	};
	if ( ref $associate eq 'CODE' ) {
		return  $associate->($param);
	};
		return $associate;
}
#}}}
#{{{ list associate
sub list_associates {
	return [ keys %{$_[0]->{_associate}} ];
}

sub get_associate_from {
	return $_[0]->{_associate_from};
}

sub get_who_associate {

}

sub has_associate {
	return exists $_[0]->{_associate}{$_[1]};
}
#}}}
#  destroy associate #{{{ 

# destroy container : remove from the root
# del associate: decrement the associates list of the object but KEEP the object marked as 'non_associated'
# NEED functions abstact:
#   1. take object and learn the container 
#   2. take container and iterate its elements
#   3. iterate a token's associates
#   List CAN destroy container
#   object can drop associate


# only deletes associate and decrements associate_from list in associate.
# Returns the number of  associates ( use defined to check for 0 ), or undef if object can't del_associate_from
sub del_associate {
	$ass_puf=delete $_[0]->{_associate}{$_[1]};     # get associate object
	return unless $ass_puf;
	if ( $ass_puf->can('del_associate_from')) {  # ask object to delete me from the associates list
		if ( $ass_puf->del_associate_from( $_[0] )==0 ) {      # it is a kind of reference counting
			warn "\t  We have a zombie named '".$ass_puf->{name}."' in $_[1]";
			}
	} # XXX here may come the case when we drop zombies.
	  # also manage empty containers when item is deleted.

	return undef;
}

sub del_associate_from {
	$_[0]->{_associate_from} = [ map { $_ if $_ == $_[1] } @{$_[0]->{_associate_from}} ] ;
	return $#{$_[0]->{_associate_from}};
}

sub add_associate_from {
	push @{$_[0]->{_associate_from}},$_[1];
}

# only root has the right to do it but we do not check.
# takes a label
sub destroy_associate {
	my $root=$_[0]->{_root} || $_[0];
	given ( $_[1] ) {
		when ( /^[#_]/ ) { 	 # we delete a label reading associates
			while ( my (undef,$obj)=each %{ $_[0]->{_tokens}{$_[1]}{_tokens}} ) {   # read per entry
				next unless blessed $obj and  $obj->can('del_associate');
				map {
					$_->del_use_label($_[1]); 
					$_->del_associate($_[1]);
				                                  } @{$obj->{_associate_from}};
			}
			$root->del_use_label($_[1]);
		}
		default {
			my $obj=$_[0]->{_associate}{$_[1]};
			map { $_->del_associate( $_[1] ) }  @{ $obj->{_associate_from} }; # delete associates backward
			# find the token name in the container
			my $name;
			while ( ($name,$ass_puf)=each %{$_[0]->{_root}{_tokens}{$_[1]}{_tokens}} ) {
				last if $ass_puf==$obj;
			}
			delete $root->{_tokens}{$_[1]}{_tokens}{$name};			
		}
	}
}

sub _destroy_labels {
	$_[0]->destroy_associates($_[1]);
}

sub del_use_level {
	return delete $_[0]->{_use_levels}{$_[1]};
}

#}}}


1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
