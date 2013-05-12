package Persist::DB;

=pod

=head1 NAME 

 Persist::DB - database Factory/Facade module

=head1 DESCRIPTION

 This module is responsible for the creation and access of a database object.
 It is possible to make mixed environment, but until there is explicite demand for it
 it is undone. To do this AProfile/Schema _initialize must also be rewritten.
 Any database module must be subclassed to this one.

 
=head1 METHODS

=over 4

=cut

use strict;
use feature ':5.10';
use Carp;
use AUtils::LoadModule;
use DBI;
use SQL::Abstract;
use AUtils::ArrayUtils qw(:all);

=item - I<new( $schema )>

 Constructor. Returns the appropriate database profile object.
 It takes the appropriate Schema object or croaks.
 If succeeds it places $self->{dbh} and $self->{schema} in the namespace of the 
 created object as Class globals. Or it will. :-)
 
=cut

sub new {
	my $self={};
	croak 'Usage: new( $AConfig::Schema_object? ), not '.$_[1] if ref $_[1] ne 'AProfile::Schema';
	my $schema = $_[1];
	my $engine_class=$schema->get_dbengine;
	my $dbo=load_new_object( $engine_class,$schema ) or do {
		carp( 'database_does_not_connect');
		return undef;
	};

	return $dbo;
};


=item - I<create_tables( $tablenames, $self->{dbh}?)>

 Creates the tables using $self->{schema}. It follows creational_order if any.
 SQLite does not have ADD CONSTRAINTS so it may be important for we use 
 I<foreign_keys> pragma.

=cut
sub create_tables {
	my ($self)=@_;
	my @order=@{ $self->{schema}->creational_order } || $self->{schema}->get_tablenames;
	foreach ( @order ) {
			my (@fields,$row);
			foreach $row ( keys(%{$Schema->get_tablenames} ) ) {
				my %cols=%{ $Schema->get_cols};
				};
			my $sql='CREATE TABLE '.$_.' ( '.join(' , ',@fields).' );';
		unless ( $self->{dbh}->do($sql) )  {
			return unless $self->_dberror( $DBI::errstr);
		};
		carp("Table $_ created.");
	}
};

=item - I<create_constraints()>

 Creates the constraints for the SQL database. SQLite does not support
 ADD CONSTRAINT.

=cut
sub create_constraints {
	my ($self)=@_;
	foreach ( @{ $self->{schema}->get_constraints } ) {
		eval {$self->{dbh}->do($_) } or do {
			carp("$DBI::err : $DBI::errstr\n$_");
			return undef;
		};
	}
}

=item - I<insert($table,$params)>

 A standard sql insertion. Standard means anything that goes through SQL::Abstract

=cut

sub insert {
	my ($self,$table,$params)=@_;
	my ($stm,@bind)=$Sql->insert($table,$params);
	my $sth=$self->{dbh}->prepare($stm) or carp("Problem at preparation:$stm");
	$sth->execute(@bind) or do { 
		carp("Problem at execution: $DBI::errstr\n$stm \n @bind");
		return undef;
	};
	return 1;
}


sub check_for_array {
	my ($self,$table,$data)=@_;
	foreach ( keys %$data ) {
		if ( $self->{schema}->get_table($table)=~/ARRAY/i and ref $data->{$_} eq 'ARRAY' ) {
		 	 if ($self->{dbaction} eq 'write' ) {
				 $data->{$_} = $self->manage_array( $data->{$_} )
		 	}
			next;
		}
		if ( ref $data->{$_} ne 'ARRAY' and $self->{schema}->get_table($table) eq 'ARRAY') {
			if ($self->{dbaction} eq 'read') {
				$data->{$_} = [ Load($data->{$_}) ];
					next;
			}
			if ($self->{dbaction} eq 'write') {
				$self->manage_array($data->{$_});
				next;
			}
		}
		# TODO Messages to be revisited!!
		if ( ref $data->{$_} eq 'ARRAY' and $self->{schema}->get_table($table) ne 'ARRAY' ) {
			carp('%s field is ARRAY but not array type in database.',$_);
			$data->{$_}=join( '',@{$data->{$_}});
			next;
		};
		if ( !$self->{schema}->get_table($table) ) {
			carp('%s field does not exist in %s table',$_,$table);
			return undef;
		};
		croak "$data->{$_} skipped check_for_array !";
	}
	return $data;
};


=item - I<select($table,$field,$where)>

 A standard sql selection with selectrow arrayref. Standard is anything that
 goes through SQL::Abstract.

=cut

sub select {
	my ($self,$table,$field,$where)=@_;
	my ($stm,@bind)=$self->{table}{sql}->select($table,$field,$where);
	return $self->{dbh}->selectrow_arrayref($stm,undef,@bind);
};

=item - I<check_schema>
tries to check the schema against the database. Returns undef if everything is OK.
If tables are missing, the missing tables are returned in an ARRAY.
If columns are missing, a table=>column is returned.


=cut

# TODO: finish it
sub check_schema {
	my ($self,$user)=@_;
	my @sch_tables = keys( %{$self->{schema}->get_tables} );
	my @db_tables=$self->get_tables();
	return array_minus(@sch_tables,@db_tables);
}


sub get_handle {
	return $self->{dbh};
}

sub DESTROY {
	$_[0]->disconnect;
	$_[0]=undef;
}

1;
__END__

=head1 TODO

 1. implement different profiles. Analictica uses text and metadata datasets built by corpus. 
    It means that text and metadata files must be initialized separately and massed up in an
    instance.
