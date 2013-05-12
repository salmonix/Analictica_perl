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
		memory=> {
			module => 'Persist::memory',
			datafile=>'',
		},
	}; # end of data
	DumpFile('./AProfile/default.yml',$data) or die $!;
	return $data;

};





1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
