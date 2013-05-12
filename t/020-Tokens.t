#!/bin/perl -w
use strict;
use warnings;
use Carp;

use Test::More;
use feature ':5.10';
use Data::Structure::Util qw( unbless get_refs);


BEGIN {
	my $module='Core::Tokens';
	$__PACKAGE__::module=$module;
	print "Testing $module\n";
	use AProfile;
	my $proj=AProfile->new();	 
	my $conf=$proj->active_config;
	isa_ok($conf,'AProfile::Config');
	use_ok($module);
}


my $module=$__PACKAGE__::module;


say "\n>>> Testing aToken instances\n";

my $list=$module->new();
my $tmo=$list->get_textobject;
isa_ok($tmo,'Persist::memory::Textmatrix');
is_deeply($AConf->core_tokens,$list,'Put in AProfile->config ok');
isa_ok($list,'Persist::memory::Tokens');

my $Ghani=$list->aToken('Ghani');
isa_ok($Ghani,'Persist::memory::Tokens');

my ($Tabr,$Alia,$Knife,$Object);

subtest 'Base methods' => sub {#{{{
	plan tests => 7;
	is($Ghani->get_name,'Ghani','Access: get_name() ok');
	is_deeply($list->get_by_name('Ghani'),$Ghani,'Tokens: get_by_name()');
	is_deeply($list->get_by_id(0),$Ghani,'Tokens: get_by_id()');  # we start from 256
	is($list->get_token('Ghani'),$Ghani,'Tokens get_token() ok');
	is($list->get_id(0),$Ghani,'Tokens get_id() ok');
	is($list->get_token('Ghani','transform'),undef,'get_token->can() ok');
	is($list->get_id(0,'transform'),undef,'Tokens get_id()->can ok');
};
#}}}
subtest 'Testing base labels and associates' => sub {#{{{
	plan tests=>12;
	# 
	# test hide, #NORMAL, default use_labels and add/remove methods individually
	$Tabr=$list->aToken('Tabr',{ hide => '#STOPWORD' });
	is($list->get_token('Tabr'),undef,'Hide ok.');
	$Alia=$list->aToken('Alia',{ use_labels => { '#NORMAL' =>'Alia of The Knife'} });
	$Knife=$Alia->associate('#NORMAL');
	is($Alia->associate('#NORMAL')->get_name,$Knife->get_name,'method NORMAL ok.');
	is($list->get_token('Alia')->get_name,$Knife->get_name,'get_token returns NORMAL');
	is($list->get_by_name('Alia')->get_name,'Alia','get_by_name returns real name');
	$Alia->add_associate('#GENDER','female');
	is( $Alia->associate('#GENDER')->get_name,'female','simple value method ok.');
	is_deeply( $Alia->associate('#GENDER')->get_associate_from,[ $Alia ],'associate_from list ok. in container object.');
	$list->destroy_associate('#GENDER');
	is( $Alia->associate('#GENDER')->get_name,'Alia','simple value method ok.');
	$Alia->del_associate('#GENDER');
	is( $Alia->associate('#GENDER')->get_name,'Alia','del_associate ok.');
	$Object=Object->new('testobj','foo');
	$Alia->add_associate('#Length',$Object);
	# Do not expect #NORMAL here - we call Alia straight 
	is($Alia->associate('#Length',{ length_of_string => $Alia } ),4,'Object->associate(arg) syntax ok.'); 
	$Alia->del_associate('#Length');
	is($Alia->associate('#Length'),$Alia,"Non-existant associate ok.");
	TODO: {
		local $TODO=" Passing subs have a bug in associate -> process_use_labels perhaps.";
		$Alia->add_associate('#Idback',sub { return $Alia->get_myid });
		is($Alia->associate('#Idback'), $Alia->get_myid,'CODE returns ok.');
		$list->add_use_label('#Idback');
		say " >> I am unsure if it should return this value";
		is($list->get_token('Alia'),2,'Call: Normal->Idback is ok.');
	}
};
#}}}   

# remove numeric return labels
$list->destroy_associate('#Idback');
$list->destroy_associate('#Length');

subtest 'Testing Tokens methods: retrieve lists' => sub {#{{{
	plan tests =>3;
	# 
	# get everything we have passed
	#
	my (@tks)= sort ( keys %{$list->get_all_tokens('*')} );
	is_deeply(\@tks,['Alia','Alia of The Knife','Ghani'],'get_all_tokens ok.');
	my $foo=$list->get_all_indexes;
	(@tks)= sort ( map { $_->get_name } @$foo );
	is_deeply(\@tks,['Alia','Ghani','Tabr'],'get_all_indexes ok.');
	$foo=$list->get_token(['Ghani','Alia']);
	is_deeply($foo,[$Ghani,$Knife],'get_token(ARRAY) ok.');
};
 #}}}

subtest 'Adding more associates and checking increment_freq.' => sub {#{{{
	$Alia->add_associate('#SAINT');
	$Ghani->add_associate('#SAINT');
	is($Alia->associate('#SAINT')->get_name,'SAINT');
	is($Ghani->associate('#SAINT')->get_name,'SAINT');
	my $saint=$list->get_token('#SAINT');
	subtest 'increment frequencies' => sub {
		$Alia->increment_freqs(['sen'],2);
		$Ghani->increment_freqs(['sen'],2);
		is($saint->get_token('SAINT')->get_freq,2,'Label object incremented');
		is($saint->get_freq,'2','Label incremented.');
		is($saint->get_freq,$list->{_tokens}{'#SAINT'}{_sum_freq},'LABEL -> single object freq identical');
	};
	subtest 'label members' => sub {
		is_deeply($saint->get_members,[ $Alia, $Ghani ],'label members ok.');
	};
	$list->get_token('Alia')->add_associate('#SAINT');
	$list->add_use_label('#SAINT');
	is($list->get_token('Alia')->get_name,$list->get_token('Ghani')->get_name,'use supercategory by label ok.');
	subtest 'clearing freqs' => sub {
		say "Clearing all.";
		$list->clear_freqs;
		is($Alia->get_freq,undef);
		is($Alia->get_freq,undef);
		is($saint->get_token('SAINT')->get_freq,undef,'Super is cleared.');
	};


};
#}}}

done_testing();

1;

package Object;
use Class::XSAccessor {
	accessors => [ qw( label title) ], };

sub new {
	return bless { label=>$_[1], title=>$_[2] },__PACKAGE__;
}

sub length_of_string {
	my (undef, $token)=@_;
	return length $token->get_name;
}

sub give_idback {
	return sub { $_[0]->get_myid };
}
1;
