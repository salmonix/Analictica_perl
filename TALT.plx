package TALT;

use feature ":5.10";
use warnings;
use strict;
use utf8;
use Carp;
use Getopt::Easy;
use AProfile;
use Core::Tokens;
use Import::Wordlist;
use Benchmark qw(:all);
use YAML::Tiny qw(DumpFile);
use Encode qw(decode);
use Encode::Detect::Detector qw(detect);
use Export::Tables;
use File::Spec;
use Extensions::Collocations;
use Extensions;



our $VERSION='';

=pod

=head1 DESCRIPTION

 Read TALT files from sourcedir and make wordilst, collocation etc.

=cut

get_options "s-sourcedir= w-wordlist=",
            "usage: perl TALT.plx -w wordlist",
	    "H";

binmode(STDOUT,':utf8');
# initialize Core
my $Prof=AProfile->new();
my $Conf=$Prof->active_config;
my $toks=Core::Tokens->new();
my $tmo=$toks->get_textobject;
say $tmo;
my (@puff,$tok,$item,$param,$sigil,$value);

my $wordlist;
if ( $O{wordlist} and -f $O{wordlist} ) {
	$wordlist=Import::Wordlist->new($O{wordlist});
	$wordlist=$wordlist->get_wordlist;
	#DumpFile( 'RELOADED.XLS.yml',$wordlist);
	#exit;
	
} else {
	warn "No wordlist of wordlist did not pass -f test" ;
}

# Load source & Tokenize
use Import::Source;
my $source=Import::Source->new();
my $tokenizer=Extensions->new( {type=>'tokenizer',module_name=>'default'} );
my $rex= qr/.*?\[(.*?)\]/;
$tokenizer->rex($rex);
my @tokens;
while ( my ($file,$text)=$source->get_next ) {
	#($file)=($file=~/^(.*?)\s/);
	@tokens=@{ $tokenizer->grep($text) };
	@tokens= map { 
			my @a=split(','); 
			map{ 
			s/^\s//; 
			s/\s+/./g;
			s/\.{2,}/./g;
			tr/I/1/ } @a; 
			@a } @tokens; # this is for ATU
#	say $file;
#	say join('   ',@tokens);
#	<>;
	$tmo->start_unit('text',$file);
	process_tokens(\@tokens);
	$tmo->close_unit('text');
}


$tmo->count_occurrences(['text']);
my $tlist=$toks->get_frequencies;

# TABLES CSV
=pod
my $tables=Export::Tables->new( { file=>'Table.csv',sheet=>'one', from=>'frequencies', unit=>'text', } );
$tables->header( $tmo->get_names('text'));
say "Number of tokens is ".$#$tlist;
$tables->generate_table( $tlist );
$tables->close;
=cut

# TABLES XLS
=pod
my $tables=Export::Tables->new( { file=>'Table_dupl.xlsx',sheet=>'one', from=>'frequencies', unit=>'text', } );
$tables->header( $tmo->get_names('text'));
say "Number of tokens is ".$#$tlist;
$tables->generate_table( $tlist );
$tables->close;
#$tables->close;
=cut

#COLLOCATION
=pod
for my $no ( 4 ) {
	my $tables=Export::Tables->new( { file=>"Table_${no}let.xlsx",sheet=>"Colloc ${no}", from=>'frequencies', unit=>'text', } );
	my $collobj=Extensions::Collocations->new( $tlist );
	carp "Collocating: $no";
	my $colled=$collobj->collocate($no,'text',10);
	last unless $colled;
	# $tables->add_sheet("Colloc $no");
	$tlist=$colled->get_frequencies;
	$tables->header( $tmo->get_names('text'));
	$tables->generate_table( $tlist );
	$tables->close;
}
=cut 

# DECORATOR
=pod
use Export::Decorator;
my $decor=Export::Decorator->new('html');
my $text=$tmo->generate_text(undef,undef,$decor);
=cut 

# STEMMER
=pod
my $stem;
my %stemmed;
use Extensions::Stemmer::Hunspell;
my $st=Extensions::Stemmer::Hunspell->new( );
my $path = "/home/salmonix/HUNSPELL/hu_HU-1.6.1/";
$st->set_module({ lang=>'hun',files=>[ $path."hu_HU.aff",$path."hu_HU.dic" ] });
my ($stem,$name);

foreach ( @$tlist ) {
	$name=$_->{name};
	$stem=$st->stem($name)||$name;
	utf8::decode($stem);
	push @{$stemmed{ $stem }},$_->{name};
}

DumpFile('STEMMED.yml',\%stemmed);

%stemmed=();
foreach ( @$tlist ) {
	$name=$_->{name};
	$stem=$st->base($name)||$name;
	utf8::decode($stem);
	push @{$stemmed{ $stem }},$_->{name};
}

DumpFile('BASED.yml',\%stemmed);
=cut



sub process_tokens {
	foreach my $item ( @{$_[0]} ) {
		$item=~s/\s+/ /; # normal multiple white spaces.
		next unless $item;
		chomp $item;
		if ( ord($item) < 65 or ord($item) == 176 ) {   # punctuation
				$param->{hide}='#PUNCTUATION';
				make_token($item,$param);
				next;
		}
		if ( ! $wordlist ) {			        # no wordlist at all
			make_token($item);
			next;
		}
		# we have a wordlist
		if ( not exists $wordlist->{$item} ) {   # not in list
			say "\t$item  ---> is not in list";
			make_token($item);
			next;
		}
		no warnings;
		($sigil,$value)=( $wordlist->{$item}[0]=~/^([#|]*)(.*)/ ); # process from list
		given ( $sigil ) {
			when ( '#' ) {
				$param->{hide}='#STOPWORD';
			}
			when ( '|' ) {
				1;
			}
			default {
				$value=lc $value || lc $item;
				$value=~s/\s+/ /;
			}
		}
		$item=$value;
		make_token($_,$param);
	}
}


sub make_token {
	map {
		$tok=$toks->aToken($_,$_[1]);
		$tmo->add_to_textmatrix($tok);
	} split (' ',$_[0]);
}

1;

__END__
=pod

=head1 BUGS, WARNINGS and TODO

It is only a procedural skeleton. It shows:

- a processed text is a closed thing in terms of positions. Inserting a new 
  token is expensive and not implemented. Therefore any normalization must take
  place with processing the text defining a pre-processing phase.

