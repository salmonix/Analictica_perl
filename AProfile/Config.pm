#!/bin/perl

package AProfile::Config;
use Carp;
use utf8;
use warnings;
use strict;
use feature ':5.10';
use AUtils::LoadModule;
use AUtils::Filer qw( open_tests read_config );
use AProfile::Schema;
use Persist;
use base qw(Class::Accessor::Fast AProfile);

=head1 NAME
 
 AProfile::Config - generate a Config object for the Profile.

=head1 METHODS

=over 4

=item - I<new( PARAMETERS )>

 Constructor. PARAMETERS is a HASH as
 file => 'myconfig.yml'	 # the object is configured with the file
 name=> 'project_name' # the name of the project.

 If projectname is passed only, the default profile is used unless the profile is 
 found int the Project.lst file. (See AProfil module.)
 If no projectname - or nothing - is passed the 'defaulf_project' projectname and default
 profile is used.

=cut 

use Class::XSAccessor {
	accessors => [ qw(  sourcedir
			    datadir  
			    datafile 
			    exportdir
			    textmatrix
			    projectfile
			    projectname
			    stack    
			    schema  
			    ui     
			    core_tokens
			    textmatrix
			    active_unit
			    dbh 	  
			    lang    
			    reserved_ID
	) ],
};


sub new {
    my ( $class, $params ) = @_;
    my $project = {};
    $params->{name} ||= 'default_project';
    given ($params) {
        when ( -f $params->{file} ) {
            carp "Reading $params->{file} projectfile.";
            $project = read_config( $params->{projectname} )
              or croak "Cannot read data $params->{project}: $!";
        }
        default {
            $project = AProfile::default->new();
        }
    }

    # make paths ( in case missing )
    map { mkdir $project->{$_} if (/dir$/) } keys %{ $project->{paths} };
    open_tests( values %$project ) or croak;

    # get schemafile
    $project->{schema} = AProfile::Schema->new( $project->{profile} );

    # set profile file for later use and register it in projectlist.
    $project->{projectfile} = $project->{datadir} . 'default_project.proj';
    $project->{projectname} = $params->{name};
    bless $project, __PACKAGE__;
    return $project;
}

# make a new entry
sub add {
    $_[0]->{ $_[1] } = $_[2];
    __PACKAGE__->mk_accessors( $_[1] );
}

sub noserial {
    push @{ $_[0]->{noserial} }, $_[1]
      unless ( @{ $_[0]->{noserial} } ~~ $_[1] );
    1;
}

1;

package AProfile::default;
use strict;
use warnings;
use feature ':5.10';
use YAML::Tiny qw(DumpFile);

sub new {
    my $work = '../ANALICTICA/';
    my $data = {
        sourcedir => $work . 'Sources/',
        datadir   => $work . 'Data/',
        datafile  => $work . 'Data/data.mat',
	exportdir => $work . 'Exports',          # to write export material to
	bowldir   => $work . 'Bowl',             # put there everything that is not alible
        textmatrix  => $work . 'Data/textmatrix.mat',
        projectname => 'default_project',
        stack       => [],           # undo stack
        schema      => '',           # schema object
        ui          => '',           # feed with the ui object if any
        core_tokens => '',           # active Core::Tokens instance
        textmatrix  => '',           # active Textmatrix instance (if any)
        active_unit => '',	     # the text unit in use
	dbh 	    => '', 	     # active database handler (if any)
        lang        => 'magyar',     # UI language
        noserial => [qw( core_tokens 
	                 textmatrix )], # these are entries that are not to be serialized (eg. core_tokens, dbh)
    };
    DumpFile( './AProfile/default.yml', $data );
    return $data;
}

1;

__END__

=pod

=back

=head1 BUGS, WARNINGS and TODO
