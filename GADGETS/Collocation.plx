#!/usr/bin/perl -w 
use strict;
use feature ':5.10';
use Carp;
use Core::Matrix;
use Core::Collocations;
use Export::Tables;
use Carp;
use Getopt::Easy;

my $usage="Usage: perl prog -s source -o outputfile\n\t [ -t filetype ] [ -c collocate] -H";

get_options( "s-source= o-outfile= t-type= c-collocate=",$usage,"H");

my @filelist;

if ( -f $O{source} ) {
	push @filelist,$O{source};
} elsif ( -d $O{source} ) {
	@filelist=read_directory();
} else {
	say $usage;
	exit 1;
}

if ( ! $O{outfile} ) {
	say "No output file is given with option -o ";
	say $usage;
	exit;
}

my $mat=Core::Matrix->new(\&iterat_files);
$mat->build_matrix();
my $colloc=Core::Collocations->new( $mat->get_matrix() );
my $colls= $colloc->collocate(2);
my $table=Export::Tables->new( header => $mat->get_cols() );


sub iterat_files {	
	my $c=0;
	return sub {
		if ($filelist[$c]) {
			open FILE, $filelist[$c] or carp $!;
			my $file=join('',<FILE>);
			$c++;
			return $file,$c-1;
		}
		return;
	};
}

sub read_directory {
	opendir DIR,$O{source} or die $!;
	while ( readdir DIR ) {
		next if /^\.|~$/;
		next if -d;
		next if ! -T;
		push @filelist,$_
	}
	return @filelist;
}


1;

__END__

=pod

=head1 
Collocations - reads a source and generates a some statistics.

Parameters:

 -s :	source file or directory. Note: If a directory is passed, 
	the script does not traverse the directory tree only 
	the passed directory is scanned for text files.
 -o : 	the output-file prefix.
 -t : 	the output filetype. A tab-separated textfile if not defined.
	Other option: xls - MSExcel xls file.
 -c :	Number of combinations to calculate. ( 2 token duplets, 3 triplets etc.)
	If not defined, collocation is not calculated.

=cut
