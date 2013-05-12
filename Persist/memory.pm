#!/usr/bin/perl
package  Persist::memory;

use feature ":5.10";
use strict;
use utf8;
use Carp;
# we serialize with Storable
#
use Storable qw(store retrieve);
$Storable::Deparse=1;
$Storable::Eval=1;
use AProfile;
use Scalar::Util qw(blessed);
use List::MoreUtils qw( firstidx lastidx indexes uniq );
use base 'AUtils::Roles';
use Persist::memory::Textmatrix;

=pod

=head1 NAME

 Persist::memory - memory module to store and retrieve objects.

=head1 DESCRIPTION

 It stores aToken objects in a hash internally. At this moment of development
 it is not clear whether the corpora are opened - that is subject to extending -,
 or closed, that is created once and used from on. 
 The frequency retrieval is expensive first for a cache is built.
 I<WARNING!> Shall not be used directly!
 The module must be addressed via Core::Tokens and Core::aToken classes.

=head1 METHODS

=over 4

=item - I<new()>

 Returns the memory object.

=cut 

use Persist::memory::Tokens;
use Persist::memory::Roles::Freques;
Persist::memory::Roles::Freques->apply(__PACKAGE__);


sub new {
	if ( caller eq 'Core::Tokens' ) {
		my $datafile=$AConf->datafile;
		if ( -f $datafile ) {
			my $obj=restore();
			return bless $obj,"Persist::memory::Tokens";
		}
		return Persist::memory::Tokens->new();
	};
	return undef;
}


sub get_textobject {
	return $_[0]->{textmatrix} if $_[0]->{textmatrix};
	if ( blessed  $_[0] eq 'Persist::memory::Tokens' ) {
		$_[0]->{textmatrix}=Persist::memory::Textmatrix->new($_[0]);
	} else { 
		croak "Caller must be a Persist::memory::Instance";
	}
	return $_[0]->{textmatrix};
}

# 
# these are private methods creating initial datafile and writing out/reading in.
#
sub save {		
	store($_[0],$AConf->datafile);
}

sub restore {
	return retrieve($AConf->datafile);
}

# for Persist::memory commit is to save data structure on disk
sub commit {
	if ( my $datafile=$AConf->get_schema->get_datafile ) {
		return _write_data($datafile,$_[0]);
	};
	croak "Why \$state is not inited?";
}

sub add_class_method{	
	my ($self,$method_name,$method)=@_;
	if ( !$self->can($method_name) ) {
		if ( ref $method eq 'CODE' ) {
			carp "$method is overwritten in ".__PACKAGE__ if __PACKAGE__->can($method);
			no strict 'refs';
			*{__PACKAGE__."::$method_name"}=$method;
			return 1;
		};
	croak "NOT CODE";
	}
	carp "CLASS ALREADY CAN $method_name";
	undef;
 }

# This is a kind of instance method making.

sub _add_associate {
	my ($self,$value,$arg)=@_;
	given ( ref $value ) {    # the cases when user puts something clever in the slot
		when ( 'CODE' ) {
			return $value->($arg)
		};
		when ( blessed $value and $arg ) {
			return $value->($arg);
		}
		when ( blessed $value ) {
			return $value;
		}
		default {         # this is a simple label creation
			my $obj=$self->{_tokens}{$value}||$self->_make_object($value);
			return $obj;
		}
	}
	return 1;
}

sub _associate {
	my (undef,,$associate,$param)=@_;
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

# associate=>label | relation => [type,label]
sub if_has {
	my ($key,$par)=each %{$_[1]};
	given ( $key ) { 
		when ( 'associate' ) {
			return 1 if $_[0]->{_associate}{$par};
		}
		when ( 'relations' ) {
			return 1 if $_[0]->{_relations}{$par->[0]}{$par->[1]};
		}
		default { undef; }
	};
};

1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
