#!/usr/bin/perl

=pod

=head1 NAME 
 
 KATA::Configure

=head1 DESCRIPTION

 Configurator module for KATA. The module contains the KATA specific 
 defaults and values and uses Shared::Config::Tools otherwise.
 The module writes a config files with YAML::Tiny.
 KATA dependencies are mandatory.
 NOTE: A messy module, glueing functions specific to KATA.

=head1 USAGE & METHODS

 KATA::Configure->configure() does it all. It returns the filepath for 
config file.

=cut

package KATA::Configure;
use feature ':5.10';
use warnings;
use strict;
use utf8;

use Carp;
use Shared::Load qw(load);
use Shared::Config::Tools;
use Term::ReadLine;
use Term::UI;
use YAML::Tiny qw(DumpFile LoadFile);
use Shared::Filer;
use Shared::Lingua;
use Shared::Log;
my $Filer=Shared::Filer->new();
my $Lin=Shared::Lingua->new();
my $Log=Shared::Log->new();
my $VERSION='0.1.1';

my $tool = Shared::Config::Tools->new();

# 
# Config static
#
my $root=$ENV{HOME}.'KATA/';
# set them first. These are the defaults
my %Config = (
 	workdir => $root.'UPLOAD/',
	tempdir => $root.'.temp/',
	erratadir => $root.'ERRATA/',
	configs => $ENV{PWD}.'/KATA/CONF/',
	default_schema => $ENV{PWD}.'/KATA/CONF/default_schema.conf',
	CGI=>$ENV{PWD}.'/KATA/CGI/',
	initfile=>$ENV{PWD}.'/KATA/CONF/KATA.conf',
	deps=>$ENV{PWD}.'/KATA/CONF/Deps.conf',
	logfile=>$ENV{PWD}.'/KATA.log',
	schema_in_use=>$ENV{PWD}.'/KATA/CONF/KATA.profile',

);


# The configuration order is important otherwise strange options appear
# in the user input. This is a messy module.
# TODO: in case of existing conf files ask user to reconfigure them.
# Separate global and profile configuration. Tidy up.

sub configure {
	$Log->file($Config{logfile});
	# we have an initfile
	if ( -f $Config{initfile} ) {
		return undef unless check_paths();
		%Config = %{ $Filer->read_config($Config{initfile}) }; # update to already existing init
	} else {		
	# no initfile
		say " \nCONFIGURING KATA. Quit: type 'q' when prompted.";
		say " Please not that the config files are in $ENV{PWD}/KATA/CONF and can also be edited manually.";
		make_configs() or return undef;  # create the KATA.conf config file
	}
	# dependencies here
	if ( -f $Config{deps} ) {
		my $deps=$Filer->read_config($Config{deps});
		! $tool->check_extmodules( $deps->{mandatory} ) or return undef; # XXX TODO: check if deps->mandatory ok!
	} else {
		create_dependency_list() or return undef; 
	}
	check_database() or return undef; # database connection check
}

# here the configuration files are created
sub make_configs {
	# create paths to workdirs
		for ( qw(workdir tempdir erratadir configs)) {
			$Config{$_}=$tool->set_path($_,$Config{$_} ) ;
		}
	# some this and that
		$Config{admin}=$tool->get_reply(prompt=>"\e[33mAdministrator e-mail:\e[0m",default=>'salmonix@gmail.com') or exit;
		$Config{logfile}=$tool->get_reply(prompt=>"\e[33mlogfile - type screen for printing the messages on the screen. \e[0m", default=>$Config{logfile}) or exit;
	# write it
		say "Writing KATA.conf configuration file to $Config{initfile}.";
		DumpFile($Config{initfile},\%Config) || die "Problem writing file. $!";
		return $Config{initfile};
}
	
# this should probably be a common configuration function
sub check_paths {
	for ( qw(workdir tempdir erratadir configs)) {
		use Shared::Filer;
		Shared::Filer->mkdir($_) or return undef if ( -R and -W and -X ); # try to be ACL proof
	}
	1;
}
=pod
 
 - create_dependency_list      writes deps file testing the availability of 
 			       modules.

=cut
sub create_dependency_list {
	say "Check dependency.";
	$tool->dependencies( { dir => '.'} );
	my $modules={ mandatory => [] };
	if ( my @missing=$tool->get_deps('missing') ) {
		say " The following modules are missing:";
		map { say $_ } @missing;
		say $Lin->missing_module();
		exit 255;
	} else {
	     push @{$modules->{mandatory}}, $tool->get_deps('found');
        }
	
	DumpFile($ENV{PWD}.'/KATA/CONF/Deps.conf',$modules);
	say "Dependency files are written.";
}


# KATA uses PostgreSQL
# The function now initializes Pg database connection only using
# the hcoded data from default_schema.

sub check_database {
		my $Schema=$Filer->read_config( $Config{schema_in_use} );
		say "Checking database";
		load ("Shared::Expand");
		Shared::Expand->initialize();
		load ('Shared::DB');
		my $user='trusted';
		my ($dbo,$dbname);
		unless ( $dbo=Shared::DB->new($user) ) {			# connect to db
			db_fatal();
			exit;
		};

		$dbname=$dbo->{users}{$user}{database}; # trusted and restricted use the same db
		if ( my @missing=$dbo->check_tables($user) ) {   	# check tables
			$Log->('Missing tables');
			map { $Log->("$_") } @missing;
			$dbo->create_tables(@missing) or do {		# and make them or die
				db_fatal();
				return undef;
				};
		}
		foreach my $table ( keys(%{$dbo->{tables}}) ) {
			if ( my @missing=$dbo->check_fields($table) ) {
				map { $Log->("ALTER $table FIELD $_") } @missing;
				map {$dbo->{dbh}->do("ALTER TABLE $table ADD COLUMN $_ $dbo->{tables}{$table}{$_}")} @missing;
			}
		}
		$dbo->check_restricted() or do {			# check restricted user
			say "Problem with cecking restricted.";
			db_fatal();
			die;
			};
}

sub db_fatal {
	say "\n\e[31m!!! Problem setting the database !!!\e[0m \nPls.check the $Config{logfile} for details.\n";
}

1;
__END__
=head1 AUTHOR & COPYRIGHT

(C) Laslo Forro salmonix_at_gmail_dot.com
The concept of KATA and the code is GPLv2. licensed. If you are not familiar
with this license pls. visit the link below to read it:
http://www.gnu.org/licenses/gpl-2.0.html


2010-06-13

