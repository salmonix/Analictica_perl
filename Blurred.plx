#!/bin/perl -w
use strict;
use Carp;

package Frame;
use ALingua::Chunks;
use UI::Wx::Translate;

use Wx qw/ :everything /;
use Wx::Event qw/ :everything /;
use Wx::XRC;
use Wx::FS;
use feature ':5.10';
use base qw(Wx::Frame );

sub new {
	my ($class,$name)=@_;
	my $tr=UI::Wx::Translate->new();
	my $self=$class->SUPER::new();
	# Load chunk, now hard coded
	my $chunks=ALingua::Chunks->new('Testapp.xrc');
	my $xml=$chunks->output($name,{ },);
	$tr->translate($xml);
	say $xml;
	exit;

	# make a memory FH ( see demo XRCCustom) 
	Wx::FileSystem::AddHandler( Wx::MemoryFSHandler->new );
	Wx::MemoryFSHandler::AddTextFile('project_open',$xml);
	# make XmlResource object
		my $xr = Wx::XmlResource->new();
		$xr->InitAllHandlers();
		$xr->Load('memory:project_open');

		# get frame object from XmlResource 
		my $frame = $xr->LoadFrame(undef, '_start_lucer');
		my $XID = \&Wx::XmlResource::GetXRCID;
		my $sizer=&$XID('combo_sizer');
		$sizer=$frame->FindWindow($sizer);
		my $comboID=&$XID('project_chooser');
		my $combo=$frame->FindWindow($comboID);
		$combo->Clear();
		$combo->Append($_) for  qw(NEWLY TOTALLY SPARKLY);
		

		# bind events
		EVT_MENU($frame,&$XID('new'),\&_new_profile);
		EVT_MENU($frame,&$XID('edit'),\&_edit_profile);

		EVT_COMBOBOX($frame, $comboID,\&_combo_event);

	return $frame;
};

sub _new_profile {
	my $frame=shift;
	say "New event is done.";
	say @_;
	my $dirpick=Wx::DirDialog->new( $frame );
	if (  $dirpick->ShowModal == wxID_CANCEL ) {
		say "Cancelled";
	} else {
		say $dirpick->GetPath;
	}
	$dirpick->Destroy;

}
sub _edit_profile {
	say "Edit event is done.";
	say @_;

}

sub _combo_event {
	say "Project chooser";
	say @_;
}
1;

package MyApp;
use base 'Wx::App';

sub OnInit {
		# tell frame object to show up and set frame as top window
		my $frame=Frame->new('project_open');
		$frame->Show(1);              
		1;
}
1;


package main;

my $app=MyApp->new();
$app->MainLoop();

