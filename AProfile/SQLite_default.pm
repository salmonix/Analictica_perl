#!/usr/bin/perl
package  AProfile::default_schema;

use feature ":5.10";
use strict;
use utf8;
use Carp;
use YAML::Tiny qw(DumpFile);

=pod

=head1 NAME

 AProfile::default_schema - default schema file for SQLite database.

=over 4

=cut 


sub new {
	my $data= {
	SQLite => {
	  connection=> {},
	  databasename=>'default_project.lite',
	  rules=> [],
 	 order=> [ qw(tokens attributes _tok_attrib) ],
	  tables=> {
	      tokens=> {
 	         token=> 'text NOT NULL UNIQUE', # SQLite3 does not support ADD CONSTRAINT
	          frequency=> 'int',
	          positions=> 'text',
		  rank => 'int'
    	  },
	      classes=> {
	          name=> 'text NOT NULL UNIQUE',
		  method =>'text',
		  isa => 'text'     # this will generate small redundancy but that is acceptable with max 1000 items
	      },
  	    _tok_attrib=> {
		  token=>'int REFERENCES tokens(__ROWID__)',
		  attribute=>'int REFERENCES attributes(__ROWID__)',
	  },
	  triggers=> [],
	  },
	}, # end of SQLite
	}; # end of data
	DumpFile('./AProfile/default.yml',$data) or die $!;
	return $data;

};





1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
