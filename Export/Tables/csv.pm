#!/usr/bin/perl
package Export::Tables::csv;

use feature ":5.10";
use strict;
use utf8;
use Carp;
use File::Spec qw(canonpath catfile);
use base 'Export::Tables';

our $VERSION='';

=pod

=head1 NAME

 Write csv table out of the passed AoA.

=head1 DESCRIPTION


=head1 METHODS

=over 4

=item - I<new( name=>'name', path=> 'path_to_write_to')>

 Takes the cvs filename and the sheet, returns an object.

=cut 

sub new {
	bless $_[1],__PACKAGE__;
}

=item - I<add_sheet( 'sheet_name')>

 Adds a sheet to fill it in with data.

=cut

sub add_sheet {
	if ( $_[0]->{data} ) {
		$_[0]->write_data;
	}
	$_[0]->{sheet}=$_[1];
}


=item - I<write_data( $header,$AoA )>

 Takes a $header ARRAY and an AoA of data ( @rows[ @cells ] ).
 Writes the csv.

=cut

sub write_data {
	my ($self,$header,$data)=@_;
	if ( ! $self->{sheet} ) {
		croak "No sheet is passed";
	}
	my $file=$self->{file};
	$self->{file}=~s/\.$self->{type}$//; # remove extension if any for we must recompose filename
	$file=File::Spec->catfile( $self->{path},join('.',$self->{file},$self->{sheet},'csv'));
	open CSV,'>',$file;
	say CSV join(',',@{$self->{header}});
	map { say CSV join(',',@{$_} ) } @{$self->{data}};
	close CSV;
	$self->{data}=$self->{header}=[];
	return 1;
}

=item - I<finish>

 Finish it all.

=cut

# it is more meaningful wiht xls tables
sub close { 
	$_[0]->write_data if ( $_[0]->{data} );
};

1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
