#!/usr/bin/perl
package Export::Tables::Frequencies;

use feature ":5.10";
use strict;
use utf8;
use Carp;

our $VERSION='';

=pod

=head1 NAME

 Export::Tables::Frequencies - make frequency tables from tokens

=head1 METHODS

=over 4

=item - I<new>

=cut 

sub new { return bless {},__PACKAGE__; };

=item - I<get/set_unit('unit')>

 Get/set which units to insert into the table

=cut 

sub set_unit {
	$_[0]->{unit}=$_[1];
}

sub get_unit {
	return $_[0]->{unit};
}


=item I<generate_table(ARRAY_of_tokens)>

 Make the table and return it as an ARRAY and an AoA, where ARRAY is the header.

=cut

sub generate_table {
	my (@header,@table,$pos,@row,$length);
	my $tokens=$_[1];
	if ( ! $tokens->[0]->get_positions( $_[0]->{unit} ) ) {
		warn "This unit is not set in the tokens list.";
		return undef;
	}
	push @header,$_[0]->{unit}; # 0,0 cell: unit name
	foreach my $token ( @{$tokens} ) {
		$pos=$token->get_positions( $_[0]->{unit} );
		$row[0]=$token->get_name;
		map { $row[$_]=$pos->{$_} } keys %$pos;  # read the $pos position=>frequency HASH into list
		push @table,[ @row ];
		@row=();
	}
	map { $length=$#{$_} if $length < $#{$_} } @table;  # find width
	$header[$_]=$_ for (1..$length+1);
	return [ @header ],[ @table ];
}



1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
