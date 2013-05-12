package Import::Source;
use feature ":5.10";
use strict;
use utf8;
use Carp;
use AProfile;
use AUtils::Filer qw(read_config write_config mv);
use File::Slurp;
use AUtils::ArrayUtils qw(array_minus);
use AUtils::LoadModule;

our $VERSION='';

=pod

=head1 NAME

 Import::Soruce - load sourcetext, return source object.

=head1 DESCRIPTION


=head1 METHODS

=over 4

=cut

my $modules='./Import/sourcemodules.yml';
my %modules=%{ read_config($modules) };

=item - I<new>

 Constructor.

=cut 

sub new {
	my @path= read_dir( $AConf->sourcedir );
	@path=map { my $a=join ('',$AConf->sourcedir,$_); $a=Cwd::abs_path( File::Spec->rel2abs($a) );$a; } @path;
	@path=sort @path;
	return bless [ [ @path ] ],__PACKAGE__;
}

=item - I<check_new>

 Reads the again the sourcedir and takes the new elements only.

=cut

sub check_new {
	$_[0]->[0]=array_minus( [ read_dir( $AConf->sourcedir ) ],$_[0]->[1] );
	return $_[0];
}

=item - I<get_next>

 Returns the next source object.

=cut

sub get_next {
	my $file=pop @{$_[0]->[0]};
	return unless $file;
	# do filetest
	my ($ext)=($file=~/(?:\.)(\w+)$/);
	$ext=$_[0]->_reckon_type($file) unless $ext;
	if ( !$ext ) {
		$Extensions::err='unrecognized_filetype';
		#	move( $file,$AConf->bowldir );
		carp $Extensions::err;
		return undef;
	}
	$ext='html' if $ext=~/x?html?/;
	unless ( $modules{$ext} ) {
		$Extensions::err='no_such_module';
		carp $Extensions::err;
		return undef;
	}
	unless ( load_module( $modules{$ext}  )) {
			return undef;
		}
	my $mod=$modules{$ext};
	my $text=$mod->new($file);
	push @{$_[0]->[1]},$file;
	my (undef,undef,$file)=File::Spec->splitpath($file);
	return $file,$text;
}

sub _reckon_type {
	open FILE,$_[0] or do {
		move( $_[0],$AConf->bowldir );
		$Extensions::err=$!;
		return undef;
	};
	close FILE;
}



1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
