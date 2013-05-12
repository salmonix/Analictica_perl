package Shared::Config::Initialize;
use strict;

=pod

=head1 NAME
 
 Shared::Config::Initialize

=head1 DESCRIPTION

 This module is an initialization helper. It does:
 1. reads the deps file and checks the  modules listed in it. 
 2. checks for external programs
 3. checks database connection
 
 On failure it returns undef, on success it returns true.

=head1 USAGE & METHODS

=cut

use feature ":5.10";
use utf8;
use POSIX;
use ExtUtils::Installed;
use Shared::Load qw(load);
use Shared::Log;
use YAML::Tiny qw(LoadFile);
use Shared::DB;
use Carp;
my $Log;

=pod

- new()           constructor. It takes the 'deps' file path.
=cut

my $Confdir=$ENV{PWD}.'/KATA/CONF/';

sub new {
	return undef if ! -f $_[1];
	my $self={};
	$Log=Shared::Log->new('Initialize');
	$self->{deps}=$_[1];
	load Shared::Expand;
	Shared::Expand->initialize();
	return bless $self,$_[0];
}

sub initialize {
	# Kata.conf should exist if we are here, but be ignorant to this fact -> check Kata.conf
	my ($self,$profile) = @_;
	if ( ! -f $Confdir.'Kata.conf') {
		KATA::Configure->main_conf() or do {
			$Log->("Exiting.");
			exit;
		};
	}
	if ( ! -f $Confdir.'Deps.conf' ) {
		KATA::Configure->deps_conf() or do {
			$Log->("Exiting");
			exit;
			};
	} else { $self->initialize_deps() };
	$profile ||= 'KATA.profile';
	if ( ! -f $Confdir.$profile ) {
		KATA::Configure->profile_conf() or do {
			$Log->('Exiting.');
			exit;
			}
	} else {
		# this is a database init
		$self->connect_db('trusted') or return undef;
		$self->db_exists(
		$self->check_schema() or return undef;
	};

}




=pod

- initialize_deps()    accepts 'mandatory' | 'optional', defaults to 'mandatory'.
		       Returns true if success, false on any failure.
		       In case of failing to load necessary modules, the ->
=cut
sub initialize_deps {
	my $opt=pop || 'mandatory';
	my $self=shift;
	my $mods=LoadFile($self->{deps});
	return ($self->check_extmodules($mods->{$opt}) );
}
=pod
- check_extmodules()	  takes an arrayref of modules. checks the passed module list 
                          against the installed modules using ExtUtils::Installed. If it fails,
			  the function tries to  eval the module. Returns 1 on 
			  success, undef on failure. Failed modules can be accessed
			  via errors()
=cut

sub check_extmodules  {
	my ($self,$mod) = @_;
	my (@mod,@missing);
	say "Checking module dependency...\t";

	croak "Not an arrayref for keys " if ref($mod) ne 'ARRAY';

	my %installed;
	%installed=map { $installed{$_} } ExtUtils::Installed->new()->modules();
	@missing=grep{ ! $installed{$_} } @mod;
	
	unless (@missing) {
		say "\t...OK.";
		return 1;   	 	# perhaps undef is better and return missing modules if any
	}

	my @to_install;
	if ( @missing ) {
		foreach (@missing) {
			if ( load $_ )  { 		# do a manual check. ExtUtils can be wrong with core modules.
								# well, it was at me. may be my fault but that may happen anywhere
			   	say "\e[34mWarning:\e0m $_ module available but not found by ExtUtils. Check the installation.";	 
				next;
				}
	
			say "\e[31mMissing: $_\e[0m";
			push @to_install,$_;
		}
	}
	print "done.\n";
	return 1 if ! @to_install;
	$self->{failed}=[ @to_install ];
	return undef;
}


=pod

- errors()        method returns the number of failed modules in scalar context, or 
		  a list if wantarray.
=cut

sub errors {
	if (wantarray) {
		return $#{$_[0]->{failed}};
	} else {
		return @{$_[0]->{failed}};
	}
}

=pod

- open_teste     checks temdir workdir erratadir for open.
                 a rather dummy function...
=cut

sub open_tests {
	# directory open tests 
	my $self=shift;
	foreach (tempdir workdir) {
		opendir DIR,$self->{$_} or do {
			croak $!;
		};
		closedir DIR;
	}
	
	# if erratadir is given but can not be read
	if ($self->{erratadir}) {
		opendir DIR,$self->{erratadir} or do {
			croak $!;
		};
	};
}

sub check_schema {
	my ($self,$db)=@_;
	$db=Shared::DB->new('trusted') unless $db;
	if (my @missing = $db->check_schema() ) {
		$Log->('FATAL: schema mismatch - database altered, tables missing');
		$Log->('missing: %s',$_) foreach (@missing);
		$Log->('EXITING.');
		die;
	};
	$db->check_restricted() or die;
};




# CAVEAT: Shared::DB::connect is a non-singleton connection.
sub connect_db {
	my ($self,$user) = @_;
	my $db=Shared::DB->connect($user);
	 unless (ref $db) {
		 $Log->("Unable to connect database.");
		 return undef;
	 };
	return $db;
}

1;
	                
=head1 TODO & WARNING
 
 TODO: optional deps must be implemented.
       check_modules checking method needs rethinking.

 In general system initialization is not doubtlessly settled and demands cleanup.


=head1 AUTHOR & COPYRIGHT

(C) Laslo Forro salmonix_at_gmail_dot.com
The concept of KATA and the code is GPLv2. licensed. If you are not familiar
with this license pls. visit the link below to read it:
http://www.gnu.org/licenses/gpl-2.0.html


2010-06-13

=cut
