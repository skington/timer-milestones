package Timer::Milestones;

use strict;
use warnings;

# Have you updated the version number in the POD below?
our $VERSION = '0.001';
$VERSION = eval $VERSION;

=head1 NAME

Timer::Milestones - measure code execution time succinctly

=head1 VERSION

This is version 0.001.

=head1 SYNOPSIS

 use Timer::Milestones qw(start_timing mark_milestone stop_timing time_method);

 start_timing();
 time_method('Some::ThirdParty::Module::do_slow_thing');
 my @objects = _set_up_objects();
 mark_milestone('Everything set up');
 for my $object (@objects) {
     _do_something_potentially_slow($object);
 }
 mark_milestone('Telling the user')
 for my $object (@objects) {
     _inform_user($object);
 }
 ...
 stop_timing();

=head1 DESCRIPTION

At its simplest, Timer::Milestones is yet another timer module. It is designed
to have the smallest possible interface, so adding timing calls to your code
doesn't make it look unreadable. It can also time execution time of functions
in other modules, as a more informative (and quicker!) alternative to running
everything under Devel::NYTProf.

=head2 Functional vs OO interface

You can use Timer::Milestones via a functional interface:

 use Timer::Milestones qw(start_timing mark_milestone stop_timing);
 start_timing();
 ...;
 mark_milestone('Half-way through');
 ...;
 end_timing();

Or via an OO interface:

 use Timer::Milestones;
 {
     my $timer = Timer::Milestones->new;
     # $timer->start_timing automatically called
     ...;
     $timer->mark_milestone('Half-way through');
     ...;
 }
 # $timer->end_timing automatically called when $timer is destroyed

The OO interface is simpler if you're timing a monolithic block of code. If you
need to add timing calls throughout code scattered across multiple files, you're
better off with the functional interface as you don't need to pass a
Timer::Milestone object around.

=head2 Basic functionality

=head3 new

 Out: $timer

Creates a new Timer::Milestones object, and calls L</start_timing> on it.

=head3 start_timing

If timing hadn't already been started, starts timing. Otherwise does nothing.
Automatically called by L</new>, but you'll need to call it explicitly when
using the functional interface.

=head3 add_milestone

 In: $name (optional)

Adds another milestone. If supplied with a name, uses that name for the 
milestone; otherwise, generates a name from the place it was called from
(package, function, line number).

Throws an exception if a timing report has already been generated by
L</generate_report>.

=head3 end_timing

Stops timing, and call L</generate_report>. This is called automatically
in OO mode when the object goes out of scope.

=head3 generate_report

 Out: $report (optional)

If no report has been generated yet, generates a timing report, and either
prints it to STDERR (in void context) or returns it (scalar or list context).
If a report has already been generated, does nothing.

=head1 SEE ALSO

L<Timer::Simple>, which is simpler but more verbose.

L<Devel::Timer>, which does similar things.

=head1 AUTHOR

Sam Kington <skington@cpan.org>

The source code for this module is hosted on GitHub
L<https://github.com/skington/timer-milestones> - this is probably the
best place to look for suggestions and feedback.

=head1 COPYRIGHT

Copyright (c) 2020 Sam Kington.

=head1 LICENSE

This library is free software and may be distributed under the same terms as
perl itself.

=cut

1;
