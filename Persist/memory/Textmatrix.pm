package Persist::memory::Textmatrix;
use warnings;
use strict;
use feature ':5.10';
use Carp;
use AProfile;
use Scalar::Util qw(blessed);
use List::MoreUtils qw(natatime);
use base qw(Persist::memory);

# a simple class to recreate the text as it is processed, for input text may suffer 
# rebuilds and other kind of denoisification. This is a snapshot of what we
# work with.

use Class::XSAccessor {
	accessors => [ qw(name last_pos levels unit_in_use units) ],
};

our ($puf,$foo,$bar);

sub new {
	croak "USAGE: Core::Token s instance, not $_[1]" unless blessed $_[1] eq 'Persist::memory::Tokens';
	my $self= {
		text		=> [],    # 1: the text itself
		end_of_text     => 0,     # 2: the last position
		units 		=> {},    # 3: the units hash with st-end positions
		core_tokens	=> $AConf->core_tokens, # 4:root  Core::Tokens instance
		active_units	=> {},    # 5: the active units hash
		unit_in_use     => undef, # 6: the unit the instance uses by default
		id		=> 0,	  # 7: the Id we assign
	};
	bless $self,__PACKAGE__;
	return $self;
};

sub restore {
}

# we think that a unit is not removed, or unlikely
# we also permit overlaps
sub add_unit_in_use {
	$_[0]->{unit_in_use}=$_[1];
}

sub clear_unit_in_use {
	$_[0]->{unit_in_use}=undef;
}

sub start_unit {
	$puf=$_[0]->{units}{$_[1]}{points};
	if ( $puf ) {
		push @$puf,$_[0]->{end_of_text};
	} else {
		$_[0]->{units}{$_[1]}{points}->[0]=$_[0]->{end_of_text};
	};
	$_[0]->{unit_in_use}=$_[1];
	if ( $_[2] ) { 
		push @{$_[0]->{units}{$_[1]}{names}},$_[2];
	}
}

sub get_names {
	$_[1]||=$_[0]->{unit_in_use};
	return $_[0]->{units}{$_[1]}{names};
}

sub close_unit {
	 if ( not exists $_[0]->{units}{$_[1]} ) {
		carp "Attempt to close not opened unit.";
	};
	push @{$_[0]->{units}{$_[1]}{points}},$_[0]->{end_of_text}-1;
	delete $_[0]->{active_units}{$_[1]};
}

sub add_to_textmatrix {
	push @{$_[0]->{text}},$_[1]->{_id};
	return ++$_[0]->{end_of_text};
}


# now, this will need a decorator to pretty-print it
sub generate_text {
	my ($self,$units,$labels,$decorator)=@_;
	my ($indexes,$tokenlist,$core_tokens);
	my ($ret,$nl,$footer)='';
	if ( $decorator) {
		if ($decorator->can('header') ) {
			$ret=$decorator->header;
		}
		if ($decorator->can('newline') ) {
			$nl=$decorator->newline;
		}
		if ($decorator->can('footer') ) {
			$footer=$decorator->footer;
		}
	}
	$units->[0] = 'sen' if ( !$units );
	$indexes=$self->{core_tokens}{_indexes}; # $indexes is the id list in Tokens
	$tokenlist=$self->{core_tokens}{_tokens}; # straight to tokens in Tokens
	$core_tokens=$self->{core_tokens};   # $core_tokens is the Tokens instance
	my $text=$self->{text};
	foreach my $unit ( @$units ) {
		my $twoatime=natatime 2,@{$self->{units}{$unit}{points}};
			while ( my ($st,$end)=$twoatime->() ) {
				my @chunk=@{$text}[ $st..$end ];
				foreach ( @chunk ) {
					$_=$indexes->[$_];
					if ( $_->{_hidden} ) {
 						$_= $decorator->decorate_hidden($_) if $decorator;
					} else {
						$_=$core_tokens->process_use_labels($_,$labels) || $_  if $labels;
 						$_= $decorator->decorate($_) if $decorator;
					}
					if ( blessed $_) {
						$ret=join('',$ret,$_->{name});
					} else {
						$ret=join('',$ret,$_);
					}
				}
			$ret.="\n".$nl;
			}
	}
	return $ret.$footer;
}

#TODO: optimize inner foreach -> map
# this counts for all frequencies
# 1: units? 2:labels?
# Parameters are must.
sub count_occurrences {
	my ($self,$units)=@_;
	$units->[0] = $self->{unit_in_use} if ( !$units );
	$foo=$self->{core_tokens}{_indexes}; # $foo is the id list in Tokens
	$bar=$self->{core_tokens};   # $bar is the Tokens instance
	$bar->clear_freqs($units);
	my $text=$self->{text};
	my ($st,$end,$c);
	foreach my $unit ( @$units ) {
		my $twoatime=natatime 2,@{$self->{units}{$unit}{points}};
		while ( ($st,$end)=$twoatime->() ) {
		 	my @chunk=@{$text}[ $st..$end ];
			$c++;
			foreach ( @chunk ) {
				$_=$foo->[$_];
		 		$_->increment_freqs($unit,$c);
			}
		}
	}
	$foo=undef;
	$bar=undef; 
}

1;

__END__
=pod

=back
=head1 BUGS, WARNINGS and TODO
