#!/usr/bin/env perl
# You can get a report from Timer::Milestones.

use strict;
use warnings;

use Carp;
use Test::Fatal;
# Prototype disagreement between Test::More and Test2::Tools::Compare, so
# explicitly use the Test2::Tools::Compare versions.
use Test::More import => [qw(!is !like)];
use Test2::Tools::Compare qw(is like);

use Timer::Milestones qw(:all);

test_generate_report();
test_report_notification();

done_testing();

# Calling generate_report produces a report. Then it does nothing until we
# add more milestones, at which point a completely new report is returned.

sub test_generate_report {
    # Set up date mocking.
    my @times = (
         77904000, # 12pm Washington time
         77904323, # roughly 5 minutes later
         77905110, # 18 1/2 minutes after the start
        118166400, # 12pm months later when the problem is "discovered"
             time, # Now, when some bright spark thinks of something new
    );
    my $localtime_start = localtime($times[0]);
    my $localtime_end   = localtime($times[-2]);
    my $get_time
        = sub { my $time = shift @times or croak 'Ran out of times!'; $time };
    my $timer = Timer::Milestones->new(get_time => $get_time);

    # Before any milestones have been recorded, there's no report.
    ok(
        !defined $timer->generate_intermediate_report,
        'No report before any milestones'
    );

    # Add a milestone; now there's a report.
    # \s{4} and \s rather than \s{5} because (a) there's a leading 4-space
    # indent, and then (b) because you can have up to 60 minutes, there's a
    # one-space indent for the seconds.
    $timer->add_milestone('Something completely innocuous');
    my $intermediate_report = $timer->generate_intermediate_report;
    like($intermediate_report,
        qr{
            ^
            START: \s \Q$localtime_start\E \n
            \s{4} \s 5 \s min \s 23 \s s \s [(] 100[.]00% [)] \n
            \QSomething completely innocuous\E \n
            $
        }xsm,
        'The report so far mentions when it started, milestone and elapsed time'
    );

    # We don't get another report if nothing else has happened.
    ok(!defined $timer->generate_intermediate_report,
        'If we ask again, nothing');

    # But if we add another milestone, we do.
    $timer->add_milestone('Something equally innocuous, honest');
    my $updated_report = $timer->generate_intermediate_report;
    like($updated_report,
        qr{
            ^
            START: \s \Q$localtime_start\E \n
            \s{4} \s 5 \s min \s 23 \s s \s [(] \s 29[.]10% [)] \n
            \QSomething completely innocuous\E \n
            \s{4} 13 \s min \s \s 7 \s s \s [()] \s 70[.]90% [)] \n
            \QSomething equally innocuous, honest\E \n
            $
        }xsm,
        'The report now has a new milestone and recalculated percentages',
    );

    # Eventually we can generate a final report.
    my $final_report = $timer->generate_final_report;
    like($final_report,
        qr{
            ^
            START: \s \Q$localtime_start\E \n
            \s{4} \s 5 \s min \s 23 \s s \s [(] \s{2} 0[.]00% [)] \n
            \QSomething completely innocuous\E \n
            \s{4} 13 \s min \s \s 7 \s s \s [()] \s{2} 0[.]00% [)] \n
            \QSomething equally innocuous, honest\E \n
            \s{4} 11183 \s h \s 41 \s min \s [()] 100[.]00% [)] \n
            END: \s \Q$localtime_end\E \n
            $
        }xsm,
        'Eventually we get an end time, and more recalculated percentages',
    );
    ok(
        !defined $timer->generate_final_report,
        'If we ask for a "final" report again, nothing'
    );

    # Once we have a final report, we cannot add more milestones.
    ok(
        exception { $timer->add_milestone('The truth, revealed!') },
        'We cannot add more milestones after a final report'
    );    
}

# When an object stops, or goes out of scope, we notify the caller of its
# final report.

sub test_report_notification {
    my $automatic_report;

    # If we explicitly say stop_timing, a report is generated.
    my $verbose_timer
        = Timer::Milestones->new(
        notify_report => sub { $automatic_report = shift });
    $verbose_timer->add_milestone('Done something');
    $verbose_timer->stop_timing;
    like(
        $automatic_report,
        qr{
            ^
            START: \s [^\n]+ \n
            \s{4} [^\n]+ \n
            \QDone something\E \n
            \s{4} [^\n]+ \n
            END: \s .+
            $
        }xsm,
        'Stopping timing generated a report'
    );

    # (But if we'd already generated a report, nothing happens.)
    my $quiet_timer
        = Timer::Milestones->new(
        notify_report => sub { $automatic_report = shift });
    $automatic_report = 'Nothing to see here';
    $quiet_timer->add_milestone('Nobody needs to know');
    my $quiet_report = $quiet_timer->generate_final_report;
    like(
        $quiet_report,
        qr{Nobody needs to know},
        'We got a report from generate_final_report'
    );
    $quiet_timer->stop_timing;
    is(
        $automatic_report,
        'Nothing to see here',
        'Because we generated a report explicitly, nothing else got reported'
    );

    # This also happens if our object goes out of scope.
    my $out_of_scope_report;
    my $temporary_timer = Timer::Milestones->new(
        notify_report => sub { $out_of_scope_report = shift });
    $temporary_timer->add_milestone(
        'Confront the bad guy without having told anybody else'
    );
    undef $temporary_timer;
    like(
        $out_of_scope_report,
        qr/Confront the bad guy/,
        'Going out of scope also triggers a final report'
    );
}

1;
