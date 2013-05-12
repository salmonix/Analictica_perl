#!/usr/bin/perl -w
package Persist::DB::Pg;
use feature ":5.10";

use strict;
use DBI;
use DBD::Pg;
use Carp;

=pod

=head1 NAME

 DB::Pg - Postgresql specific db module.

=head1 DESCRIPTION

 This module is responsible for the Postgresql specific functions. These are
 mainly reading the information_schema table, and checking for ARRAY type.
 Other Pg specific functions or calls must be implemented here.

=cut



use base qw(Shared::DB);
use Array::Utils qw(:all);
use Shared::Config;
use Shared::Log;
use Shared::Lingua;

our ($Log,$Sql,$Config,$Lin);
$Log=Shared::Log->new('DB::Pg');
my $Dbh;

# private. It is called by DB
# It takes a hash of the database structure - tables etc.
# If a mixed database environment is used that must be coordinated via DB.pm. See CONFIGS file.
sub new {
	croak "Invalid call" unless caller eq "DB" ;
	$Config=Shared::Config->new();
	my $self=$Config->schema('Pg');
	$Lin=Shared::Lingua->new();
	bless $self,__PACKAGE__;
	my $user=pop;
	my $dbi_part=join( '','dbi:Pg:dbname=',$self->{users}{$user}{database} );
	eval {$Dbh=DBI->connect( $dbi_part,$self->{users}{$user}{username},undef,{ AutoCommit=>1, PrintError=>0 } ); };
	if ( $DBI::errstr or not (ref $Dbh) ) {
		$Log->('Problem connecting to the database: ',$self->{users}{$user}{username},$self->{users}{$user}{database});
	        return _dberror($DBI::errstr);
	};
	$self->{dbh}=$Dbh;
	$self->{sql}=$Sql=SQL::Abstract->new( array_datatypes=>1, logic=>'and' ); # Postgres has array datatype
	return $self;
};

=pod

 - insert	     check if data is array according to the schema and call SUPER->insert()

=cut

sub insert {
	my ($self,$table,$data)=@_;
	unless ($self->{tables}{$table}) {
		$Log->('%s table does not exist.',$table);
		return undef;
	}
	$data=$self->check_for_array($table,$data) or return undef;
	return $self->SUPER::insert($table,$data);
}

sub update {
	my ($self,$table,$what,$where)=@_;
	unless ($self->{tables}{$table}) {
		$Log->('%s table does not exist.',$table);
		return undef;
	}
	$what=$self->check_for_array($table,$what) or return undef;
	return $self->SUPER::update($table,$what,$where);
}

=pod

 - manage_array     returns the ARRAY type 
=cut

# XXX TODO Check against the parent ! 
sub manage_array {
	return pop @_;
};


=pod

 - check_schema      tries to check the schema against the Pg database using its information_schema.tables
                     table on current database name in table_catalog. Returns undef if each table exists
		     in the database (no difference), returns the missing tables otherwise.

=cut
sub check_schema {
	my ($self,$user)=@_;
	my @sch_tables = keys(%{$self->{tables}});
	my $where={ table_name=>[ @sch_tables ] ,				# look for table names of schema
		    table_catalog=>$self->{users}{$user}{database} };		# in the database of the (trusted) user
	my ($stm,@bind) = $Sql->select('information_schema.tables','table_name',$where);
	my @db_tables=@{ $Dbh->selectcol_arrayref($stm,{ Columns=>[1] },@bind) }  or return @sch_tables; # if empty everything is missing
	return array_minus(@sch_tables,@db_tables);
}

# check if db exists. can be useful perhaps
sub db_exists {
	my $db=pop;
	my @databs = DBI->data_sources('Pg');
	return grep ( /$db/, @databs );
};


# error messages may differ from dbengine to dbengine
# so treated individually.
sub _dberror {
	my $err = $_[1] || $_[0];
	given ( $err ) {
		when ( $err=~/could not connect/ ) {
			$Log->('Check if database is up and running. Full error message:');
			$Log->($err);
			return undef;
		 	};
		when ( $err=~/database .* does not exist/ ) {
			$Log->($err);
			return undef;
			};
		when ( $err=~/^New DB/ ) {
			$Log->($err);
			return undef;
		};
		when ( $err =~ /already exists/ ) {
			return 1;
		}
		default { $Log->('Unknown error. Parameter: %s',$err); };
	}
}


=pod 

 - check_restricted	checks the privileges of the restricted user, if any

=cut 

# for Pg the privilege table is not created unless some GRANT is executed. An empty privilege table means that
# the owner has all privileges and we think that if connection is established we are the owners.
# XXX THIS IS NOT SURE! TODO: check for the privileges of the trusted user against the db. lucer

sub check_restricted {
	my ($self)=@_;
	my $user="restricted";
	my @user;
	unless ( @user = $Dbh->selectrow_array("SELECT usename FROM pg_user WHERE usename = ?",undef,$self->{users}{$user}{username} ) ) {
			$Dbh->do("CREATE ROLE $self->{users}{$user}{username} WITH LOGIN") or do {
				$Log->($Dbh->errstr() );
				return undef;
			};
			$Log->(sprintf '%s user created',$self->{users}{$user}{username});

	}; # create restrcicted user if does not exist
	foreach (keys %{$self->{users}{$user}{grant}} ) {		# read each table from restricted -> grant
			my ($stm,@bind)=$Sql->select('information_schema.table_privileges','privilege_type',{ grantee => $user,table_name => $_ });
			my @granted = @{ $Dbh->selectcol_arrayref($stm,undef,@bind) };
			if (my @not_granted = array_minus( @{$self->{users}{$user}{grant}{$_}} , @granted ) ) {
				return undef unless $self->grant($_,[@not_granted],$self->{users}{$user}{username});
			};
	}
	return 1;
}

sub grant {
	my ($self,$table,$grantit,$user) = @_;
	foreach ( @$grantit ) {
	eval { $Dbh->do("GRANT $_ ON $table TO $user") };
		if ($Dbh->errstr()) {
			$Log->('Problem grant %s privilege on %s table to %s',$_,$table,$user);
			$Log->($Dbh->errstr());
			return undef;
		} else {
			$Log->('Granted %s privilege on %s table to %s user',$_,$table,$user);
		}
	}
	return 1;
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

