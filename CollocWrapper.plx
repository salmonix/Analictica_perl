#!/bin/perl -w
use strict;
use warnings;
use Carp;

use feature ':5.10';
use Data::Structure::Util qw( unbless get_refs);


my $module='Persist::memory::Textmatrix';
use AProfile;
my $proj=AProfile->new();	 
my $conf=$proj->active_config;
use Core::Tokens;
use Persist::memory::Textmatrix;
use Extensions::Collocations;


my $obj=Core::Tokens->new(); # the token 'server'

my %text=( 
	text1 => [ 
	{ sen => 'three rings for the elven kings under the sky' },
	{ sen => 'seven for the dwarf lords in their halls of stone'},
	{ sen => 'nine for mortal man doomed to die'},
	{ sen => 'one for the dark lord on his dark throne'},
	{ sen => 'in the land of Mordor where the shadows lie'},
	{ sen => 'one ring to rule them all, one ring to find them' },
	{ sen => 'one ring to bring them all and in the darkness bind them'},
	{ sen => 'in the land of Mordor where the shadows lie'},
	],
);


my $tmo=Persist::memory::Textmatrix->new($obj);


	# fill the tokens list and textmatrix with objects.#{{{
	#
my $tok;
my @STOPS= qw(all his in to the and of where for on);
my %NORMAL=(
	lands=>'land',
	rings=>'ring',
	lords=>'lord',
	kings=>'king',
	shadows=>'shadow',
);
foreach my $aunit ( qw(text1) ){#{{{
$tmo->start_unit($aunit);
	foreach my $entry ( @{$text{$aunit}} ) {
		my ($bunit,$text)=each %$entry;
		$tmo->start_unit($bunit);
		my @tokens=split(/(\s)+/,$text);
		foreach ( @tokens ) {
			chomp;
			my %param;
			given ( $_ ) {
				when (/,|\s/) {
					$param{hide}='#PUNCTUATION';
				}
				when ( @STOPS ) {
				$param{hide}='#PUNCTUATION';
				}
				when ( %NORMAL ) {
					$param{use_labels}={ '#NORMAL'=> $NORMAL{$_} };
				}
				default {
					%param=();
			 	}
			}
			if ( $_ ) {
				$tok=$obj->aToken($_,{%param});
				$tmo->add_to_textmatrix( $tok );
			} 
		}
		$tmo->close_unit($bunit);
	}
	$tmo->close_unit($aunit);
} #}}}
# get some returns.
  #}}}
#
## Start testing Extensions::Collocations
#

$tmo->add_unit_in_use('sen');
$obj->get_token('ring')->add_associate('#RING');
$obj->get_token('rings')->add_associate('#RING');
$obj->add_use_label('#RING');
$obj->get_token('shadows')->add_associate('#SAURON');
$obj->get_token('#RING')->add_associate('#SAURON');  # we expect all 'ring' and 'rings' tokens to associate to #SAURON
$obj->get_token('Mordor')->add_associate('#SAURON');
my $ring=$obj->get_token('ring');
$obj->add_use_label('#SAURON');

$tmo->count_occurrences(['sen']);

my @tokens;
my @list;
if ( $ARGV[0] and $ARGV[0] eq 'k' ) {
	@list=( qw( one kings lord Mordor shadows lie bind ) );
} else {
	@list=( qw( one #SAURON land king dark) );
}
say $obj->get_token('kings')->get_name;

my $tlist=$obj->get_token( [ @list ]);
my $decor=Decorator->new( [ map { $_->get_name } @$tlist ] );
my $text=$tmo->generate_text(undef,undef,$decor);
@list= map { $_->get_name } @$tlist;
# 
# Tell user info
#
say "\nUSED: ".join(' ', @list)."\n";
say "Stopwords: ".join(' ',@STOPS);
say "\n".$text;
say "List contains: ".join(', ', @list);
say "Normaled:";
map { say "\t$_ -> $NORMAL{$_}"} keys %NORMAL;
print "\n";
say " >>>>> duplet";
my $coll=Extensions::Collocations->new($tlist);
$obj->build_freq_index;

my $ret=$coll->collocate(2,'sen');
printit( $ret->get_frequencies );

=pod
$obj->del_use_label('#NORMAL');
say "deleted #NORMAL";
$tlist=$obj->get_token( [ @list ]);
@list= map { $_->{name} } @$tlist;
$coll=Extensions::Collocations->new($tlist);

say "\nUSED: ".join(' ', @list)."\n";
$tmo->count_occurrences(['sen']);
$ret=$coll->collocate(2,'sen');
printit( $ret->get_frequencies );
=cut


sleep 1;


sub printit {
	no warnings;
	given ( ref $_[0] ) {
		when ('ARRAY') {
			map { say $_->{name}."\tR:".$_->{_rank}."\tF:".$_->{_sum_freq}} @{$_[0]};
		}
		when ('HASH') {
			map { say $_->{name}."\tR:".$_->{_rank}."\tF:".$_->{_sum_freq}} values%{$_[0]};
		}
	}
}

package Decorator;
use warnings;
use strict;

use feature ':5.10';

sub new { 
	return bless {
		used => "\033[033m\#@@#\033[0m",
		used_list=>$_[1],
	}, __PACKAGE__;
}

sub decorate {
	if ( $_[1]->{name} ~~ @{$_[0]->{used_list}} ) {
		my $used=$_[0]->{used};
		$used=~s/#@@#/$_[1]->{name}/;
		return $used;
	}
	return $_[1]->{name};
}

sub decorate_hidden {
	return  "\033[034m".$_[1]->{name}."\033[0m";
}
