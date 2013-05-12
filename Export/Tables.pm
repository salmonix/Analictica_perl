#!/bin/perl
package Export::Tables;

use feature ":5.10";
use strict;
use utf8;
use Carp;
use AUtils::LoadModule;
use File::Spec;
use AUtils::Filer qw(mkdir);

=pod

=head1 NAME

Export::Tables - creates a table

=head1 METHODS

=over 4

=item - I<new($args)>

Returns an object. $args is a HASH with the following possibe parameters:

 type - export format: xls, cvs, tabbed. Guessed from extension if not given.
 file - filename to export to (mandatory)
 header - column names for the table
 sheet - name of the sheet (mandatory)

If 'type' is not a spreadsheet type, then the 'file' argument is a prefix, 'sheet' argument
is a suffix for the actual filename and tables are split to files per 'sheet'.

=cut 

my %types = (
	"xls" => "Export::Tables::xls",
	"xlsx" => "Export::Tables::xls",
	"csv" => "Export::Tables::csv",
	"tabbed" => "Export::Tables::tabbed",
);

sub new {
	my ($class,$args)=@_;
	if ( $args->{qw(file sheet from)} ) {
		croak "Mandatory parameters 'file' or 'sheet' or 'from' missing";
	};
	if ( $args->{file} ) {
		( undef, $args->{path}, $args->{file} ) = File::Spec->splitpath($args->{file});
		$args->{path}||='.';
		mkdir($args->{path}) or do {
			warn "Unable to create path $args->{path}. $!\n$@" ;
			return undef;
		} if !-x $args->{path};
		if ( ! $args->{type} ) {
			($args->{type})=($args->{file}=~/(?:\.)(\w+)$/);
		} else {
			$args->{type}=$args->{type};
		};
		load_module($types{$args->{type}}) or do {
			carp "Unknown type $args->{type}";
			return undef; 
		};
	return $types{$args->{type}}->new($args);
	};
}

=item - I<header([header])>

 Sets the column names for the actual sheet.

=cut

sub header {
	if ( ref $_[1] eq 'ARRAY' ) {
		$_[0]->{header}=$_[1];
		carp "Header is set.";
		return 1;
	}
	carp "No header is set.";
	return undef;
}

=item - I<get_header>

 Returns the header ARRAY.

=cut

sub get_header {
	return $_[0]->{header};
}


=item - I<get_data>

 Returns the data AoA.

=cut

sub get_data {
	return $_[0]->{data};
}


=item - I<add_sheet('sheet')>

 Adds a sheet.

=cut 

sub generate_table {
	my %modules=(
		'frequencies'=>'Export::Tables::Frequencies',
	);
	my $self=shift;
	my $module=$modules{$self->{from}};
	$DB::single=1;
	$module=load_new_object($module);
	$module->set_unit( $self->{unit} );
	my ($header,$table)=$module->generate_table(@_);
	$self->{header}||=$header;
	$self->{data}=$table;
}


=item - I<sheet('newsheet')>

B<not sure this is a thing I need.>

Sets a new sheet for the table returning a sheet object.

=cut

sub sheet {
	@{$_[0]->{sheets}}=grep ( !/$_[1]/, @{$_[0]->{sheets}} );
	push @{$_[0]->{sheets}},$_[0]->{sheet};
	$_[0]->{sheet}=pop;
	return;
}

sub close {
	1;
}

1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
