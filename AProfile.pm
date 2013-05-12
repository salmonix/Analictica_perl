#!/usr/bin/perl
package AProfile;
use AProfile::Config;

use feature ":5.10";
use strict;
use utf8;
use Carp;
use Exporter 'import';


=pod

=head1 NAME

 AProfile - A Feather for the project config objects.

=head1 DESCRIPTION

 The module manages the different possibly parallel configurations.
 By default it exports the 'active' project in a $AConf variable.
 
=head1 METHODS

=over 4

=item - I<new()>

 The constructor. It reads the projectlist.

=cut 

our @EXPORT=qw($AConf);
my $self;
my $Projectlist="$ENV{PWD}/AProfile/Projects.lst";

sub new {
	return $self if $self;
	$self={};
	bless $self,__PACKAGE__;
	return $self;
}


=item - I<active_config( 'project' )>

 Sets/gets the active project to 'project'. If does not exist reads its 
 path from AProfile/Projects.lst file, which is a simple key:'value' config file.
 Returns the 'project' configuration object or the active project if nothing is passed.
 object.

=cut

sub active_config {
	if ( !$self->{projectlist} ) { 
		if ( -f $Projectlist ) {
			$self->{projectlist} = $self->_read_projectlist();
		} else { # we have no Projectslist, so this is a first run
			$_[1] = 'default_project';
		}
	}
	$_[1]||='default_project';
	$self->{active}=$self->get_config($_[1]);
	$AProfile::AConf=$self->{projects}{$_[1]};
	return $self->{projects}{$_[1]};
}

=item - I<get_config( 'project' )>

 Gets the project named 'project' but keeps 'active' untouched. If does not exist reads its 
 path from AProfile/Projects.lst file, which is a simple key:'value' config file.
 Returns the 'project' configuration object. If nothing is passed the active project config 
 is returned.

=cut

sub get_config {
	my ($self,$project)=@_;
	return $self->{active} unless $project;
	given ( $self->{projects}{$project} ) {
		when ( defined ) {  # we have it, so it must be registered in Projectlist.lst
			1;  # TODO: load config and initialize all the data there
		}
		# we have no registry in the Projectlist.lst, so make a new file and
		# register that.
		default {
			my $file=$self->{projectlist}{$project};
			my $conf=AProfile::Config->new({ name=>$project, file=>$file });
			# add the new entry
			$self->{projects}{$project}=$conf;
			$self->_write_projectlist();
		}
	};
	return $self->{projects}{$project};
}

=item - I<schema( 'project'? )>

 Returns the schema for the active project config, or when a project name is 
 passed, the schema belonging to that project. If project profile is not yet
 loaded, it gets loaded.

=cut

sub get_schema {
	my ($self,$proj) =@_;
	return $self->{active}->schema unless $proj;
	if ( !$self->{projectlist}{$proj} ) {
		$self->get_config($proj);
	}
	$self->{projectlist}{$proj}->get_schema;
}

=item - I<get_projectnames>

 Returns an ARRAY of projectnames.

=cut

sub get_projectnames {
	return keys %{$_[0]->{projects}};
}

sub _write_projectlist {
	my ($self,$file)=@_;
	open PROJ,'>',$Projectlist or do {
		carp "Cannot open or create AProfile/Projects.lst";
		return undef;
	};
	foreach (  keys  %{$self->{projects}} ) {
			my $file=$self->{projects}{$_}->projectfile;
			my $line="'$_':'$file'";
			print PROJ $line;
		}
	close PROJ;	

}

sub _read_projectlist {
	open PROJ,$Projectlist or do {
		carp "No AProfile/Projects.lst";
		return undef;
	};
	my $data;
	while ( <PROJ> ) {
		chomp;
		next if /^\s*\n$ | ^\s*#/; # empty lines and comments skip
		s/'//g;
		my ($k,$v)=split(/\s?:\s?/);
		$data->{$k}=$v;
	}
	close PROJ;
	return $data;
}

1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO

 1. The module stores the project singletons but does not do great reference counting management.
 It means that dead configs may wander about. These configs are comparatively 
 small amounts of data this is unlikely a harm, but nevertheless, not too elegant solution.
