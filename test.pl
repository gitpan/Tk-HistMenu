#!/usr/bin/perl

use strict;
use blib;
use Tk;
require Tk::MainWindow;
require Tk::HList;
require Tk::HistMenu;
require Tk::LabFrame;
require Tk::Menubutton;

my $main = new MainWindow;

my $mn = $main->Menu;
my $hm = $mn->HistMenu(
#	-tearoff => 0,
#	-sorted => 0,
#	-clearentry => 1,
#	-maxhist => 24,
#	-breaksize => 6,
#	-moreside => 'top',
#	-clearside => 'bottom',	
);
$mn->add('cascade',
	-label => 'History',
	-menu => $hm,
);
$main->configure(-menu => $mn);

my $pl = $main->Scrolled('HList',
	-scrollbars => 'osoe',
	-browsecmd => sub {
		my $i = shift;
		print "adusting '$i'\n";
		$hm->itemAdjust($i);
	},
)->pack(
	-side => 'left', 
	-fill => 'y'
);

my $count = 0;
while ($count < 60) {
	$pl->add("item$count",
		-text => "item$count",
	);
	$hm->itemAdjust("item$count");
	$count++
}


$main->MainLoop;
