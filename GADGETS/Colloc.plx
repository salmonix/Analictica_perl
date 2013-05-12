#!/bin/perl -w
use strict;
use feature ':5.10';

my @list;
for (0..200) {
	push @list,$_;
}
#@list=qw(A B C D E F G H I J K L M N O P Q R S T U V Z);
say $#list;
#my @list=qw(A B C D );
my $n=3;
my $nplet=$n;
my $ret=colloc($n);

no warnings;
say join(' ',@list);
say "-"x($#list*2-1);
my $c=0;
if ($#{$ret} > 2000) {
	say $#{$ret};
} else {
	map { say join(' ',$c++,@$_) } @$ret;
}




# we have to check the initial condition.
# Nplets must be smaller then the list.
sub colloc {
	my ($nplet)=@_;
	$nplet--;
	return [ @list ] if ( $nplet == $#list );
	return undef if ( $nplet > $#list );
	return _colloc(0,$nplet); # the first parameter is the first position of the list
}


sub _colloc {
	my ($pos,$nplet)=@_;
	return [ [ $list[$#list] ] ] if $pos == $#list;
	my $it=$list[$pos];
	my $ret;
	if ( ! $nplet or $nplet == 0 ) {
		map { push @$ret,[ $_ ] } @list[$pos..$#list];
		return $ret;
	}
	for (1..$#list-$pos-$nplet+1) { 
		$pos++;
		my @plets= @{ _colloc($pos,$nplet-1) };
		map { push @$ret,[$it,@$_] } @plets;
		$it=$list[$pos];
	}

	return $ret;
}

