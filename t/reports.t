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
test_divide_by_zero();
test_human_elapsed_time();

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

    # Before any milestones have been recorded, we just report that timing
    # started, but there are no interval times.
    like($timer->generate_intermediate_report,
        qr{
            ^
            START: \s \Q$localtime_start\E \n
            $
        }xsm,
        'Just a blank report before any milestones'
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

# If e.g. we don't have Time::HiRes, or time passed *really quickly*
# (it happened once when running these tests), we still manage to carry on
# even though the total elapsed time is 0.
sub test_divide_by_zero {
    my $timer = Timer::Milestones->new;
    $timer->{milestones} = [
        {
            name    => 'START',
            started => 12345,
            ended   => 12345,
        }
    ];
    $timer->{timing_stopped} = 1;
    like(
        $timer->_generate_report,
        qr{
            ^
            START: \s [^\n]+ \n
            \s{4} \s{2} 0 \s ms \s [(] [^)]+ [)] \n
            END: \s [^\n]+ \n
            $
        }xsm, 'We generated a report even though no time elapsed'
    );
}

# Various intervals, in fractions of seconds, seconds, minutes or hours,
# are reported in a way that makes sense to human beings.

sub test_human_elapsed_time {
    my %expect_human_elapsed_time = (
        # Anything below 1 second: milliseconds
        0.001 => '  1 ms',
        0.010 => ' 10 ms',
        0.234 => '234 ms',
        0.999 => '999 ms',
        # Anything below 1 minute: seconds
        1     => ' 1 s',
        30    => '30 s',
        59    => '59 s',
        # Less than an hour: minutes and seconds
        60    => ' 1 min  0 s',
        61    => ' 1 min  1 s',
        123   => ' 2 min  3 s',
        999   => '16 min 39 s',
        3599  => '59 min 59 s',
        # Beyond that, hours and minutes; hours aren't padded as there's
        # no upper limit to fit into.
        3600  => '1 h  0 min',
        3601  => '1 h  0 min',
        4000  => '1 h  6 min', # Rounded down
        7195  => '1 h 59 min',
        86400 => '24 h  0 min',
    );
    my $timer = Timer::Milestones->new(notify_report => sub {});
    for my $elapsed_time (sort { $a <=> $b } keys %expect_human_elapsed_time)
    {
        is(
            $timer->_human_elapsed_time($elapsed_time),
            $expect_human_elapsed_time{$elapsed_time},
            "Correct value for $elapsed_time"
        );
    }
}

1;
