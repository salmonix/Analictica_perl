use warnings;
use strict;
use Carp;
use File::Find;
use feature ':5.10';

print " FROM: ";
my $from=<>;
chomp $from;

print " TO: ";
my $to=<>;
chomp $to;

find(\&subi,$ENV{PWD});

sub subi {
	my $name=$File::Find::name;
	return if -d $name;
	return if $name =~/Subi\.plx/;
	open FILE, $name or die "Cannot open";
	my @data=<FILE>;
	close FILE;
	my $ok=undef;
	for ( 0..$#data ) {
		if ( $data[$_]=~s/$from/$to/g ) {
			$ok=1;
		};
	}
	if ( $ok ) {
		open FILE,'>',$name;
		print FILE @data;
		close FILE;
	}
}
