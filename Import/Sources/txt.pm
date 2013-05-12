package Import::Sources::txt;

use feature ":5.10";
use strict;
use utf8;
use Carp;
use Encode qw(decode);
use Encode::Detect::Detector qw(detect);
use File::Slurp;

our $VERSION='';

=pod

=head1 NAME

 Import::Sources::Textfile - read textfiles.

=head1 DESCRIPTION

 This module simply scans the passed path and reads the textfiles it finds there.

=head1 METHODS

=over 4

=item - I<new('path_of_file')>

 Constructor. Takes a file path, returns the file read.

=cut 

sub new {
	my (undef,$path)=@_;
	if ( ! -e $path ) { 
		carp "$path is missing.";
		return undef;
	}
	return ${ _read_file($path) };

}


# XXX We do not check if the file is huge or not. For decode 30 normal line is normally
# enough, so decoding 3000 lines is needless.
sub _read_file { 
	my $line=read_file( $_[0], binmode=>':raw',err_mode=>'carp');
	$Extensions::err="cant_open_file $_[0]" && return undef unless $line;
	my $chset=detect($line);
#	return undef if !$chset;
	if ( $chset eq 'gb18030' ) {
		$chset='windows-1252';
	};
	if ($chset and $chset !~/utf/i) {
		$line=decode($chset,$line);
	};
	$line=~tr/ÃÊÕãêëõŨũ/ÁÉŐáéeőŰű/; # these are Hungarian characters and unsure we need it.
	return \$line;
}

1;

__END__
=pod

=back

=head1 BUGS, WARNINGS and TODO
