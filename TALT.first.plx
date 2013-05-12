package TALT;

use feature ":5.10";
use warnings;
use strict;
use utf8;
use Carp;
use Getopt::Easy;
use AProfile;
use File::Find;
use Core::Tokens;
use Import::Wordlist;
use Benchmark qw(:all);
use YAML::Tiny qw(DumpFile);
use Encode qw(decode);
use Encode::Detect::Detector qw(detect);
use Export::Tables;
use File::Spec;
use Extensions::Collocations;



our $VERSION='';

=pod

=head1 DESCRIPTION

 Read TALT files from sourcedir and make wordilst, collocation etc.

=cut

get_options "s-sourcedir= w-wordlist=",
            "usage: perl TALT.plx -s sourcedir -w wordlist. If -s is not given, ANALICTICA/Sources is used.",
	    "H";

binmode(STDOUT,':utf8');
# initialize Core
my $Prof=AProfile->new();
my $Conf=$Prof->active_config;
my $toks=Core::Tokens->new();
my $tmo=$toks->get_textobject;
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

if ( ! $O{sourcedir} ) {
	$O{sourcedir}=$Conf->sourcedir;
}

$O{sourcedir}=File::Spec->rel2abs( $O{sourcedir} );

find ( { wanted=>\&read_file,
	preprocess=>sub{ sort (@_)  },
	},
	$O{sourcedir} );
$tmo->count_occurrences(['text']);
my $tlist=$toks->get_frequencies;

# export frequencies function
#my $fr2table=Export::Tables::Frequencies->new();
#$fr2table->set_unit('text');
#my ($header,$table)=$fr2table->generate_table( $toks->get_frequencies );
#$tables->write_data($header,$table);

# TABLES CSV
=pod
my $tables=Export::Tables->new( { file=>'Table.csv',sheet=>'one', from=>'frequencies', unit=>'text', } );
say "Number of tokens is ".$#$tlist;
$tables->generate_table( $tlist );
$tables->close;
=cut

# DECORATOR
=pod
use Export::Decorator;
my $decor=Export::Decorator->new('html');
my $text=$tmo->generate_text(undef,undef,$decor);
=cut 

# make a table where : key->stem , val: forms
# this phase is the perparatory phase of creating a new label.

# STEMMER
my $stem;
my %stemmed;
use Extensions::Stemmer::Hunspell;
my $st=Extensions::Stemmer::Hunspell->new( );
my $path = "/home/salmonix/HUNSPELL/hu_HU-1.6.1/";
$st->set_module({ lang=>'hun',files=>[ $path."hu_HU.aff",$path."hu_HU.dic" ] });
my ($stem,$name);
foreach ( @$tlist ) {
	$name=$_->{name};
	$DB::single=1;
	$stem=$st->stem($name)||$name;
	utf8::decode($stem);
	push @{$stemmed{ $stem }},$_->{name};
}

DumpFile('STEMMED.yml',\%stemmed);

foreach ( @$tlist ) {
	$name=$_->{name};
	$stem=$st->base($name)||$name;
	utf8::decode($stem);
	push @{$stemmed{ $stem }},$_->{name};
}

DumpFile('BASED.yml',\%stemmed);

=pod
my $collobj=Extensions::Collocations->new( $tlist );
my $colled=$collobj->collocate(3,'text');
say "Collocated: ok.";
$tables=Export::Tables->new( { file=>'Collocations.csv',sheet=>'triplets', from=>'frequencies', unit=>'text', } );
$tlist=$toks->get_frequencies;
$tables->generate_table( $colled->get_frequencies );
$tables->close;
=cut

sub read_file {
	return if $_ !~/txt$/;
	my $file=$File::Find::name;
	say "ENCODING NOT KNOWN" unless manage_textfile($file);
	$file=~s/\D//g; # we need the numbers only
	$tmo->start_unit('text');
	foreach $item ( @puff ) {
		$item=~s/\s+/ /; # normal multiple white spaces.
		chomp; # just to be sure
		next unless $item;
		if ( ord($item) < 65 or ord($item) == 176 ) {   # punctuation
			$param->{hide}='#PUNCTUATION';
			make_token($item,$param);
			next;
		}
		if ( ! $wordlist ) {     # no wordlist at all
			$item=~tr/ÃÊÕãêëõŨũ/ÁÉŐáéeőŰű/;
			make_token($item);
		} else { 
			if ( not exists $wordlist->{$item} ) {   # not in list
				say "\t$item  ---> is not in list in $file";
				$item=~tr/ÃÊÕãêëõŨũ/ÁÉŐáéeőŰű/;
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
			$value=~tr/ÃÊÕãêëõŨũ/ÁÉŐáéeőŰű/;
			$item=$value;
			map { make_token($_,$param) if $_ } split(' ',$item);
		}
	}
	$tmo->close_unit('text');
}

sub manage_textfile {
	open FILE,$_[0] or die "$!";
	binmode(FILE);
	my $chset;
	my $line=join('', <FILE>);
	close FILE;
	($chset,$line)=detectit($line);
	@puff=split(/(\s+)/, join ('',$line));  # TOKENIZER HOOK
	return 1 if $chset;
	return undef;
}


sub detectit {
	my ($line)=@_;
	my $chset=detect($line);
	return undef if !$chset;
	if ( $chset eq 'gb18030' ) {
		$chset='windows-1252';
	};
	if ($chset and $chset !~/utf/i) {
		$line=decode($chset,$line);
	};
	return $chset,$line;
}

sub make_token {
	$tok=$toks->aToken($_[0],$_[1]);
	$tmo->add_to_textmatrix($tok);
}

1;

__END__
=pod

=head1 BUGS, WARNINGS and TODO

It is only a procedural skeleton. It shows:

- a processed text is a closed thing in terms of positions. Inserting a new 
  token is expensive and not implemented. Therefore any normalization must take
  place with processing the text defining a pre-processing phase.

