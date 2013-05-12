#!/bin/perl -w
use strict;
use warnings;
use Carp;

use Test::More;
use feature ':5.10';
use Data::Structure::Util qw( unbless get_refs);


BEGIN {
	my $module='Persist::memory::Textmatrix';
	$__PACKAGE__::module=$module;
	print "Testing $module\n";
	use AProfile;
	my $proj=AProfile->new();	 
	my $conf=$proj->active_config;
	isa_ok($conf,'AProfile::Config');
	use_ok('Core::Tokens');
	use_ok('Persist::memory::Textmatrix');
}

my $module=$__PACKAGE__::module;

my $obj=Core::Tokens->new(); # the token 'server'
my $decor=Decorator->new();

my %text=( 
	text1 => [
	{ sen => 'one ring to rule them all, one ring to find them' },
	{ sen => 'one ring to bring them all and in the darkness bind them'},
	{ sen => 'in the land of Mordor where the shadows lie'},
	],
);

my $tmo=Persist::memory::Textmatrix->new($obj);
is_deeply($tmo->{core_tokens},$AConf->core_tokens,'Core tokens root ok'); 

isa_ok($tmo,'Persist::memory::Textmatrix');
my @STOPS= qw(all in to the and of where);


# Fill the Tokens list and Textmatrix with objects.#{{{
#
my $tok;
foreach my $aunit ( qw(text1) ){
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
						$param{hide}='#STOPWORD';
					}
					when (/land/) {
						$param{use_labels}={ '#NORMAL'=>'Land' };
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
}#}}}

subtest 'Using Textmatrix' => sub {#{{{
	plan tests => 6;
	# Get some returns.
	$tmo->add_unit_in_use('sen');
	my $ring=$obj->get_token('ring');
	$tmo->count_occurrences(['sen']);
	is($ring->get_freq,3,'Freq for token "ring" ok.');
	is($obj->get_token('Mordor')->get_freq(),1,'Freq for Mordor ok.');
	is($obj->get_token('all'),undef,'Freq for STOPWORD ok');
	is($obj->get_token('ring')->get_freq('sen',1),2," Freq in unit->position ok.");
	my $text=$tmo->generate_text();
	my $ctext='';
	map { $ctext.=$_->{sen}."\n" } @{$text{text1}};
	is($text,$ctext,'Text generation OK.');
	$text=$tmo->generate_text(undef,['#NORMAL']);
	$ctext=~s/land/Land/;
	is($text, $ctext,'Using NORMAL ok.');
	$ring=$obj->get_token('ring');
	$ring->get_positions('sen');

};
#}}}
say "\nSTOPS (in green) ".join(', ',@STOPS),"\n";
my $text=$tmo->generate_text(undef,undef,$decor);
say "\n".$text;
say "Build freq_index";
$obj->build_freq_index;

subtest 'Token list: making ranks and freqlists' => sub {#{{{
	plan tests=> 4;
	#printit("\nALL TOKENS", [ values %{$obj->get_all_tokens} ]);
	#printit("\nRANKED TOKENS",$obj->{_ranked_tokens});
	printit("\nGET RANKS",$obj->get_ranks());
	is($obj->get_by_name('land')->get_freq,1,"freq ok.");
	my $Land=$obj->get_by_name('#NORMAL')->get_by_name('Land');
	is($Land->get_freq,1,"label \#NORMAL freq ok.");
	my @rank=map{ $_->{name} } @{$obj->get_ranks(1,2)};
	@rank=sort @rank;
	is_deeply(\@rank,[qw(one ring them)],'get_ranks(1,2) OK.');
	@rank=map{ $_->{name} } @{$obj->get_frequencies(2,4)};
	@rank=sort @rank;
	is_deeply(\@rank,[qw(one ring them)],'get_frequencies(2,4) OK.');

};
#}}}
subtest 'Token: frequencies adding, smallest_and etc.' => sub {#{{{
	plan tests=>5;
	my $land=$obj->get_by_name('land'); 
	my $ring=$obj->get_by_name('ring');
	my $find=$obj->get_by_name('find');
	printit($ring->get_positions('sen'),'RING');
	printit($land->get_positions('sen'),'land');
	printit($find->get_positions('sen'),'one');
	  # do not appeare in the same unit
	is($ring->smallest_and($land->get_positions('sen'),'sen'),undef,'smallest_and 1 ok');
	is_deeply($ring->smallest_and($find->get_positions('sen'),'sen'),{ 1=>1},'smallest_and 2 ok'); # appeare once at 1
	is($ring->positions_subset($ring,'sen'),1,'positions_subset identical ok.');
	is($ring->positions_subset($find,'sen'),1,'positions_subset ok.');
	is($ring->positions_subset($land,'sen'),undef,'positions_subset noshare ok.');

};
#}}}

subtest 'Create new labels and count frequencies' => sub {
	plan tests=>1;
	$obj->get_token('one')->add_associate('#RING');
	$obj->get_token('ring')->add_associate('#RING');
	$obj->add_use_label('#RING');
	$tmo->count_occurrences(['sen']);
	is($obj->get_token('#RING')->get_freq,6,'Label RING is ring+one ok');
	printit($obj->get_token('one')->get_positions('sen'),'one');
	printit($obj->get_token('ring')->get_positions('sen'),'ring');
	printit($obj->get_token('#RING')->get_positions('sen'),'RING' );
};

done_testing();

sub printit {#{{{
	no warnings;
	say $_[1] if $_[1];
	given ( ref $_[0] ) {
		when ('ARRAY') {
			map { say $_->{name}."\tR:".$_->{_rank}."\tF:".$_->{_sum_freq}} @{$_[0]};
		}
		when ('HASH') {
			my ($head,$pos);
			no warnings;
			while ( my ($k,$v)=each %{$_[0]} ) {
				$head.="  ".$k;
				$pos.="  ".$v;
			};
			if ( $head ) {
				say "pos:".$head;
				say "frq:".$pos;
			}
			say "....";
		}
	}
}
#}}}
package Decorator;
use warnings;
use strict;

use feature ':5.10';

sub new { 
	return bless {
		hidden => '\033[032m\#\033[0m',
	}, __PACKAGE__;
}

sub decorate {
	return $_[1]->{name};
}

sub decorate_hidden {
	return  "\033[032m".$_[1]->{name}."\033[0m";
}
