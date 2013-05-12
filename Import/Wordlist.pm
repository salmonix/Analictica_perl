package Import::Wordlist;

use feature ":5.10";
use strict;
use utf8;
use Carp;
use AUtils::LoadModule;
use AUtils::Filer 'read_config';

our $VERSION='';

=pod

=head1 NAME

 Import::Wordlist - imports a wordlist from a file.

=head1 DESCRIPTION

 The module imports a wordlist from a file returning a HASH of words.
 The type is extension checked.

=head1 METHODS

=over 4

=item - I<new>
 
 Takes a filename and returns class instance.
  
=cut 

my %modules=%{ read_config('./Import/modules.yml') };


sub new {
	my $self={};
	croak "No file is passed. " unless $_[1];
	my ($ext)=($_[1]=~/(?:\.)(\w+)$/i);
	$ext=lc $ext;
	my $class=$modules{$ext};
	load_module($class);
	bless $self,$class;
	$self->set_file( $_[1] ) or return undef;
	return $self;
}

=item - I<set_file('FILE')>

 Sets the filename to read. Returns undef if file does not exists.

=cut

sub set_file {
	if (-f $_[1]) {
		$_[0]->{file}=$_[1];
	} else {
		$_[0]->{file}=undef;
	}
	return $_[0]->{file};
};




1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
