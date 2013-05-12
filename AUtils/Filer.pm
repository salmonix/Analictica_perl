package AUtils::Filer;

=pod

=head1 NAME

 AUtils::Filer

=head1 DESCRIPTION

 A coverage module for File::Copy::Recursive and File::Remove methods. 
 This package is responsible for all the file-related actions: 
 reading config files, archiving and unarchiving, moving, deleting, etc.
 Exports the following functions by default:

 copy empty_dir findme has_file mv mkdir open_tests rm read_config write_config unarch
 
=head1 METHODS

=cut

use feature ":5.10";
use strict;
use utf8;
use File::chdir;
use YAML::Tiny qw(DumpFile LoadFile);
use File::Spec;
use Carp;

require Exporter;
our @ISA=qw(Exporter);
our @EXPORT_OK=qw( copy 
		   empty_dir 
		   findme 
		   has_file 
		   mv 
		   mkdir 
		   open_tests
		   read_config
		   write_config
		   rm 
		   unarch 
		   );
our %EXPORT_TAGS = ( ':all' => [ @EXPORT_OK ] );

use File::Copy::Recursive qw(fcopy fmove pathempty dirmove pathmk);


=pod

 - empty_dir                  cleans up the given directory.

=cut

sub empty_dir {
	my ($dir)=@_;
	carp "Empty dir:$dir";
	pathempty($dir) or undef;
}

=pod

 - rm                         removes a file or a directory. This mehod calls the system rm
                              and truly not portable. TODO: File::Remove instead.
=cut

sub rm {
	my ($file) =pop;
	#carp "\tRemove file: ".$file;
	system ('rm',$file,'-r');
}

# these are unpublic methods.
sub _mv_dir {
	my ($source,$target)=@_;
	carp "Moving dir:$source -> $target";
	dirmove($source,$target) or undef;
}

sub _mv_file {
	my ($source,$target)=@_;
	carp "Moving file:$source -> $target";
	fmove($source,$target) or undef;
}
=pod

 - mkdir                      makes dir ( mkdir -p )         

=cut

sub mkdir {
	my ($path) =@_;
	carp "Making path:$path";
	pathmk($path) or undef;
}

=pod

 - read_config($file)         reads a config file. Presently we use YAMLed data. Returns data as-is.

=cut

sub read_config {
	my ($file)=pop;
	if (-f $file ) {
		return LoadFile($file); # YAML 
	} else {
		croak  "File does not exists.";
	};
	return undef;
}

=pod

 - write_config($path,$data)

 Writes a YAMLed config file to $path.

=cut

sub write_config {
	my (undef,$path,$data)=@_;
	my (undef,$dir,undef)=File::Spec->splitpath($path);
	return undef if !-d $dir;
	DumpFile($path,$data);
}

=pod

 - move($source,$target)      moves file or directory. if target exists then the passed
                              target is prefixed with '_', eg. if foo.bz2 exists, then the 
			      target is _foo.bz2. NOTE: if targetpath does not exists, then
			      it is created. Now: if a file is about to move into a directory,
			      then $target must end a '/' indicating that we are about to move
			      $source to a target directory. Otherwise $target is understood as 
			      a file.
=cut

sub mv {
	my ($source,$target)=@_;
	carp 'No target defined for Filer->move' & return undef unless $target;
	if ( $target =~ /\/$/) {		# directories end with /
		if ( ! -e $target ) {
			pathmk($target);
		} else {
			$target.=$source;
		};
	};
 	$target =~s/(.*\/)?(.*)/$1_$2/ if ( -e $target );
	given ($source) {
		when (-d $source) {
			return _mv_dir($source,$target);
		} 
		when ( -f $source ) {
			return _mv_file($source,$target);
		}
	}
}

=pod

 - has_file($dir)             checks given directory recursively for -f . returns true if -f true.

=cut

sub has_file {
	my ($dir)=@_;
	do { carp "$dir does not extist." & return undef }  unless -d $dir;
	local $CWD=$dir;
	opendir (my $DIR, $CWD);
	my @dive;
	while (my $entry=readdir($DIR) ) {
		carp $entry;
		next if $entry =~/^\.+/;
		next if $entry =~/~$/;
		return 1 if -f $entry;
		push @dive, $entry if -d $entry;
	}
	foreach ( @dive ) {
		return 1 if has_file($_);
	}
	return undef;
}

sub open_tests {
	foreach ( @_ ) {
		if ( -d ) {
			opendir DIR,$_ or do {
				carp $!;
				return;
			};
			closedir DIR;
			next;
		}
		if ( -f ) {
			open FILE,'>',$_ or do {
				carp $!;
				return;
			};
			close FILE;
			next;
		}
		return 1;
	}
}



=pod 

 - findme($pattern,$dir)      recurs directory tree and returns the first match on pattern.
 			      it filters out .* *~ and _* files as being irrelevant.
			      TODO: not portable. And maybe not necessary.

=cut

sub findme {
	if ( ! -d $_[1] ) {
		carp " $_[1] is non existing directory.";
		return undef;
	};
	my ($dir,$pattern)=@_;
	my ($DIRH,@dirs);
	$dir.='/' unless $dir=~/\/$/;   # dirs end /
	opendir $DIRH,$dir;
	while ( my $item = readdir $DIRH ) {
		next if $item=~/^[.|_]|~$/;
		return "$dir$item" if $item =~/$pattern/;
		push @dirs,$item if -d $item;
	}
	foreach ( @dirs ) {
		my $return = findme("$dir$_");
		return $return if $return;
	};
	return undef;
}

=pod

 - unarch($file,$target)    

=cut
sub unarch {
	return if $_[1] !~ /zip$/i;
	my ($zipfile,$expath)=@_;
	croak "Can't write $expath" if ! -w $expath;

		my $ziperr=system("tar -xaft $zipfile");
		if  ($ziperr==0) {
			carp 'Unarching %s',$zipfile;
			if (system("unzip -xaf $zipfile -d $expath") == 0) {
				rm($zipfile);
				return 1;
			} else {
				carp 'Problem during extraction.';
				return undef;
			};
		} else {
			my $err="$zipfile : tar error. Code: ".$ziperr."Info: man unzip\n";
			carp $err;
			return undef;
		};
}

1;
__END__

=head1 AUTHOR & COPYRIGHT

(C) Laslo Forro salmonix_at_gmail_dot.com
The concept of Analictica and the code is GPLv2. licensed. If you are not familiar
with this license pls. visit the link below to read it:
http://www.gnu.org/licenses/gpl-2.0.html


2010-06-13


