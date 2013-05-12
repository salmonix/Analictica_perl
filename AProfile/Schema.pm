#!/usr/bin/perl
package AProfile::Schema;

use feature ":5.10";
use strict;
use utf8;
use Carp;
use base qw(Class::Accessor::Fast);
use AUtils::Filer qw(read_config);
use AUtils::LoadModule;

=pod

=head1 NAME

 AProfile::Schema  - Database schema object

=head1 DESCRIPTION

 This object provides information on the database using the configuration 
 file.
 For the schema see CONFIG readme.

=head1 METHODS

=over 4

=item - I<new( 'schema_file.yml'| HASH )>

 Takes one of the arguments above:
 - a YAMLed file or a module with schema info
 - a HASH of the schema info

=cut 


sub new {
	my (undef,$sch)=@_;
	$sch||=load_new_object('AProfile::default_schema');
	my $DBSchema= _initialize( $sch );
	bless $DBSchema,__PACKAGE__;
	__PACKAGE__->mk_accessors( grep (!/tables/, keys %$DBSchema)  );
	$Aconf::Schema=$DBSchema;
	return $DBSchema;

}

sub _initialize {
	my ($schema)=shift;
	given ($schema) {
		when (  /yml$/ and -f ) {
			$schema=read_config($_);
		}
		default {
			$schema= load_new_object('AProfile::default_schema');
		}
	};
	my ($engine,$DBSchema)=each( %$schema ); # there must be one engine only.
	$DBSchema=$schema->{$engine};
	$DBSchema->{persist}=$engine;
	return $DBSchema;
}

# takes 'table', returns HASH of column=>type
sub get_table {
	return $_[0]->{tables}{$_[1]};
};

# takes 'table','column', returns column type.
sub get_column {
	return $_[0]->{tables}{$_[1]}{$_[2]};
}

# takes 'table', returns table column HASH
sub get_columns {
	return $_[0]->{tables}{$_[1]};
}

# takes 'table', returns column names ARRAY
sub get_colum_names {
	return [ keys %{$_[0]->{tables}{$_[1]}} ];
}

# returns tablenames ARRAY
sub get_tablenames {
	return [ keys %{$_[0]->{tables}} ];
}

# make a new entry
sub add_data {
	$_[0]->{$_[1]}=$_[2];
	__PACKAGE__->mk_accessors($_[1]);
};


# this is to build the schema.
sub build_schema {
	my ($self,$Dbh) = @_;



}

1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
