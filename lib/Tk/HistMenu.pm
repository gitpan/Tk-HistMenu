package Tk::HistMenu;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.01'; #initial release
use base qw(Tk::Derived Tk::Menu);
use Storable;

Construct Tk::Widget 'HistMenu';

sub Populate {
	my ($cw,$args) = @_;
	$args->{'-postcommand'} = sub { $cw->fillMenu };
	my $file = delete $args->{'-filename'};
	$cw->SUPER::Populate($args);
	my $history = [];
	if (defined($file) and ($file ne '')) {
		if (-e $file) {
			$history = retrieve($file)
		}
	} else {
		$file = '';
	}
	$cw->ConfigSpecs(
		-command => [qw/PASSIVE command Command/, sub {}],
		-filename => [qw/PASSIVE filename Filename/, $file],
		-moretext => [qw/PASSIVE moretext Moretext/, 'More ...'],
		-moreside => [qw/PASSIVE moreside Moreside/, 'bottom'],
		-cleartext => [qw/PASSIVE cleartext Cleartext/, 'Clear history'],
		-clearside => [qw/PASSIVE clearside Clearside/, 'top'],
		-clearentry => [qw/PASSIVE clearentry Clearentry/, 1],
		-breaksize => [qw/PASSIVE breaksize Breaksize/, 10],
		-maxhist => [qw/PASSIVE maxhist Maxhist/, 100],
		-history	=> [qw/PASSIVE history History/, $history],
		-sorted	=> [qw/PASSIVE sorted Sorted/, 0],
		DEFAULT => [ $cw ],
	);
}

sub itemAdjust {
	my ($cw, $name, $data) = @_;
	if ($name ne '') {
		my $item = [$name];
		if (defined($data)) { $item = [$name, $data] };
		my $items = $cw->cget('-history');
		#Check if a profile exists, if so remove it;
		my $n = $cw->itemExists($name);
		if (defined($n)) {
			splice(@$items, $n, 1); 
		}
		unshift(@$items, $item);
		my $max = $cw->cget('-maxhist');
		if (@$items > $max) { splice(@$items, $max) };
	#		use Data::Dumper; print Dumper(\@profiles);
	}
}

sub histSave {
	my $cw = shift;
	my $file = $cw->cget('-filename');
	if ($file) { store($cw->cget('-history'), $file) };
}

sub itemExists {
	my ($cw, $name) = @_;
	my $found;
	my $count = 0;
	my $items = $cw->cget('-history');
	while (($count < @$items) and (! defined($found))) {
		if ($items->[$count]->[0] eq $name) {
			$found = $count;
		}
		$count++
	}
	return $found;
}

sub itemList {
	my $cw = shift;
	my $items = $cw->cget('-history');
	my @list = ();
	foreach my $p (@$items) {
		push(@list, $p->[0]);
	};
	my $sort = $cw->cget('-sorted');
	if ($sort) {
		@list = sort @list
	};
	return @list;
}

sub itemData {
	my ($cw, $name, $data) = @_;
	my $items = $cw->cget('-history');
	my $index = $cw->itemExists($name);
	my $return;
	if (defined($index)) {
		if (defined($data)) {
			$items->[$index]->[1] = $data;
		}
		$return = $items->[$index]->[1];
	}
	return $return;
}

sub fillMenu {
	my $cw = shift;
	$cw->delete(0, 'end');
	my @l = $cw->itemList;
	$cw->menuItems(\@l);
	if ($cw->cget('-clearentry')) {
		my $side = $cw->cget('-clearside');
		if ($side eq 'top') {
			$cw->insert(0, 'separator');
			$cw->insert(0, 'command',
				-label => $cw->cget('-cleartext'),
				-command => sub { 
					my $i = $cw->cget('-history');
					@$i = ();
				},
			);
		} elsif ($side eq 'bottom') {
			$cw->add('separator');
			$cw->add('command',
				-label => $cw->cget('-cleartext'),
				-command => sub { $cw->configure('-history' => []) },
			);
		}
	}
}

sub menuItems {
	my ($cw, $list, $menu) = @_;
	unless (defined($menu)) { $menu = $cw }
	my $call = $cw->cget('-command');
	my $count = 0;
	my $size = $cw->cget('-breaksize');
	while ((@$list) and ($count < $size)) {
		my $i = shift @$list;
		my $data = $cw->itemData($i);
		my @args = ($i);
		if (defined($data)) { push(@args, $data) }
		$menu->add('command',
			-label => $i,
			-command => sub { &$call(@args) },
		);
		$count++;
	}
	if (@$list) {
		my $side = $cw->cget('-moreside');
		my $casc = $menu->Menu;
		$cw->menuItems($list, $casc);
		if ($side eq 'top') {
			$menu->insert(0, 'separator');
			$menu->insert(0,  'cascade',
				-label => $cw->cget('-moretext'),
				-menu => $casc,
			);
		} elsif ($side eq 'bottom') {
			$menu->add('separator');
			$menu->add('cascade',
				-label => $cw->cget('-moretext'),
				-menu => $casc,
			);
		}
	}
}

1;

__END__

=head1 NAME

Tk::HistMenu - a Menu widget with history capabilities

=head1 SYNOPSIS

=over 4

 use Tk;
 require Tk::HistMenu;

 my $m = new MainWindow;

 my $r = $m->HistMenu(
 	-command => \&fileopen
 );
 my $u = $m->Menu(
    -menuitems => [
       ['cascade' => 'Hist',
          -menu => $r,
       ]
    ],
 );
 
 $m->configure(-menu => $u);
 $m->MainLoop;

 sub fileopen {
    my $file = shift;
    #what would you do to open a file?
 }
 
 sub fileclose {
    my $file = shift;
    #put here your code
    $r->itemAdjust($file)
 }

or

 use Tk;
 require Tk::HistMenu;

 my $m = new MainWindow;

 my $r = $m->HistMenu(
     -command => \&fileopen,
 );
 my $u = $m->Menu(
    -menuitems => [
       ['cascade' => 'Recent',
          -menu => $r,
       ]
    ],
 );
 
 $m->configure(-menu => $u);
 $m->MainLoop;

 sub fileopen {
    my $file = shift;
    if (my $data = $r->itemData($file)) {
       #do something with those data
    }
    #what would you do to open a file?
 }
 
 sub fileclose {
    my ($file, $data) = @_;
    #put your code here
    $r->itemAdjust($file, $data;
 }

=back

=head1 DESCRIPTION

Tk::HistMenu inherits Tk::Menu and all its options and methods. The options
B<-postcommand> and B<-menuitems>, and the B<add> method however cannot be used
anymore.

When the method B<itemAdjust> is called at the proper times in your application,
it stores a history, together with accompanying data inside an internal list
(the B<-history> option). The history can be stored on and retrieved from disk.

=head1 OPTIONS

Note: Although you can run a B<cget> on these options at run time, you cannot
do a B<configure> at run time. Haven't got a clue why.

=over 4

=item Name: B<breaksize>

=item Class: B<Breaksize>

=item Switch: B<-breaksize>

Specifies the size of a menu section. If the primary section becomes this size,
every entry added with B<itemAdjust> will put in a cascade section. By default
set to 10.


=item Name: B<clearentry>

=item Class: B<Clearentry>

=item Switch: B<-clearentry>

Boolean. Specifies if the user should be able to clear the menu.
By default set to true.

=item Name: B<cleartext>

=item Class: B<Cleartext>

=item Switch: B<-cleartext>

If an entry that clears the menu should be created, this is the text
of it's label. By default set to 'Clear history'.

=item Name: B<command>

=item Class: B<Command>

=item Switch: B<-command>

The callback to be executed when an item in the menu is selected. The entryname
and the attached data are provided as parameters to this callback. By default
and empty callback is executed.

=item Name: Not available

=item Class: Not available

=item Switch: B<-filename>

By default ''. If set, an attempt is made to
retrieve the history from disk.

=item Name: Not available

=item Class: Not available

=item Switch: B<-history>

Keeps a reference to the list of history items. This list looks like:

 [
    ['name1', $dataref1],
    ['name2', $dataref2],
 ]

or, if the $dataref is not used,

 [ [$name1], [$name2] ]

=item Name: B<maxhist> 

=item Class: B<Maxhist>

=item Switch: B<-maxhist>

By default 100. Specifies the maximum size of the history list. The item on which
the B<itemAdjust> method has not been called for the longest time will be dropped
from the list if it has reached this maximum size.

=item Name: B<moreside> 

=item Class: B<Moreside>

=item Switch: B<-moreside>

Specifies wether the 'More ...' entry should be placed on the B<top> or on the
B<bottom> of a menusection.

=item Name: B<moretext> 

=item Class: B<Moretext>

=item Switch: B<-moretext>

Specifies the text of a 'More ...' entry, by default set to ... 'More ...'.

=item Name: B<sorted>

=item Class: B<Sorted>

=item Switch: B<-sorted>

By default 0. Sorting is done on item name and only inside a menusection. 
If set to 0, sorting is done on the following order in which the 
B<itemAdjust> method has been called on the items in the past.

=cut

=head1 METHODS

=over 4

=item B<fillMenu>

Called when the menu is posted.

=item B<histSave>

Saves the current history on disk, using the B<-filename> option.

=item B<itemAdjust>(I<$itemname>, ?I<$itemdata>?);

Puts $itemname on top of the history list, and relates $itemdata to it.

=item B<itemData>(I<$itemname>, ?I<$itemdata>?);

Sets and returns the data related to $itemname.

=item B<itemExists>(I<$itemname>);

Checks if $itemname is present in the history, if so, returns its place in
the list.

=item B<itemList>

Returns a list of item names, sorted pending on the B<-sorted> option.

=back

=cut

=head1 AUTHOR

=over 4

=item Hans Jeuken (haje@toneel.demon.nl)

=back

=cut

=head1 BUGS

=over 4

It seems not possible to do a B<configure> at run time for the options
that were added to Tk::Menu by this module. This seems to be related to the
nature of the Tk::Menu widget.

=back

=cut

=head1 SEE ALSO

=over 4

=item B<Tk::Menu>

=back

=cut



