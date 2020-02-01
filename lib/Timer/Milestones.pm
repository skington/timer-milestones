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
to have the simplest possible interface, so adding timing calls to your code
doesn't make it look unreadable. It can also time execution time of functions
in other modules, as a more informative (and quicker!) alternative to running
everything under Devel::NYTProf.

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
