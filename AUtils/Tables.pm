package AUtils::Tables;

use feature ":5.10";
use strict;
use utf8;
use Carp;
use Exporter 'import';

our $VERSION='';

=pod

=head1 NAME

 AUtils::Tables - some table related functions.

=head1 DESCRIPTION

 The module exports the following functions on request:

 hash2array
 array2hash
 hash2tree
 tree2hash

=head1 METHODS

=over 4

=cut 

# it does not traverse the full data tree!
sub hash2array {
	my ( %cols,@ret );  # using a hash for columns instead of an array
	my $c=0;            # is overhead if array has less than 3 keys.
	foreach ( keys %{$_[0]} ) {
		given ( ref $_[0]->{$_} ) {
			when ( 'ARRAY' ) {
				push @{$ret[$c]},$_;
			}
		}
	}
	return \@ret;
}
1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
