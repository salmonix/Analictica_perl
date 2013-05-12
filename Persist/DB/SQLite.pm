#!/usr/bin/perl -w
package Persist::DB::SQLite;
use feature ":5.10";

use strict;
use DBI;
use DBD::SQLite;
use Carp;
use Exporter 'import';
our @EXPORT=qw($Schema $Dbh $Sql);
=pod

=head1 NAME

 Persist::DB::SQLite - SQLite specific db module.

=head1 DESCRIPTION

 This module is responsible for the SQLite specific functions.
 Other SQLite specific functions or calls must be implemented here.

=cut

use base qw(Persist::DB);
use AUtils::ArrayUtils qw(:all);

# private. It is called by DB
# It takes a hash of the database structure - tables etc.
# If a mixed database environment is used that must be coordinated via DB.pm. See CONFIGS file.
sub new {
	my $self={};
	$self->{schema} = $_[1];
	bless $self,__PACKAGE__;
	my $database=$self->{schema}->get_databasename || 'default_project.lite';
	my $dbi_part=join( '','dbi:SQLite:dbname=',$self->{schema}->database);
	eval {$self->{dbh}=DBI->connect( $dbi_part,undef,{ AutoCommit=>1, PrintError=>0 } ); };
	if ( $DBI::errstr or not (ref $Dbh) ) {
		$Message->('Problem connecting to the database: '.$DBI::errstr);
	        return undef;
	};
	$self->{sql}=SQL::Abstract->new( array_datatypes=>0, logic=>'and' );
	$Persist::DB::SQLite::Schema=$self->{schema};
	$Persist::DB::SQLite::Dbh=$self->{dbh};
	$Persist::DB::SQLite::Sql=$self->{sql};
	return $self;
};

sub get_columns {
	my %sch=@{ $Dbh->selectcol_arrayref("PRAGMA table_info($_[1])",{Columns=>[2,3]} };
	return \%sch;
}

# get the tables of the database we have handle to
# returns an ARRAY
sub get_tables {
	return $Dbh->selectcol_arrayref("SELECT name FROM sqlite_master WHERE type='table'");
}

# this is a special for SQLite - a cost of speed.
sub drop_column {
	my ($self,$table,$column)=@_;
	if ( $self->check_on_core() ) {   # we are not allowed to remove schema column
		return undef; # XXX TODO normal message, pls!
	}
	my $colstring=$self->table_hash_to_string( $self->get_columns );

	my $sql=<<SQL
BEGIN TRANSACTION;
CREATE TEMPORARY TABLE backup($colstring);
INSERT INTO backup SELECT ($colstring) FROM $table;
DROP TABLE $table;
ALTER TABLE backup RENAME $table;
COMMIT;
SQL
	;
	$self->{dbh}->do($sql);
	$self->_dberror();



# error messages may differ from dbengine to dbengine
# so treated individually.
sub _dberror {
	my $err = $_[1] || $_[0];
	given ( $err ) {
		when ( $err=~/could not connect/ ) {
			carp($err);
			return undef;
		 	};
		when ( $err=~/database .* does not exist/ ) {
			carp($err);
			return undef;
			};
		when ( $err=~/^New DB/ ) {
			carp($err);
			return undef;
		};
		when ( $err =~ /already exists/ ) {
			return 1;
		}
		default { carp('Unknown error. Parameter: %s',$err); };
	}
}


1;
__END__

=pod

head1 TODO

 1. There is an unhandled possibility that the profile conf changes but 
    there exists a database already with similar tablenames but perhaps
    different constraints and fieldnames. This case must be managed preferring
    the existing database over the new schemafile.


=head1 AUTHOR & COPYRIGHT

(C) Laslo Forro salmonix_at_gmail_dot.com
The concept of Analictica and the code is GPLv2. licensed. If you are not familiar
with this license pls. visit the link below to read it:
http://www.gnu.org/licenses/gpl-2.0.html


2010-06-13

