use strict;
use warnings;
use feature qw( say );
use FindBin qw( $Bin );
use lib "$Bin";
use Task;
use AnyEvent;
use Proc::Queue size => 10;

my @tasks;
push(@tasks, Task->new({ id => 1, depends => [] }));
push(@tasks, Task->new({ id => 2, depends => [] }));
push(@tasks, Task->new({ id => 3, depends => [1] }));
push(@tasks, Task->new({ id => 4, depends => [2,3] }));
push(@tasks, Task->new({ id => 5, depends => [4] }));

my %watchers;
my @finished;
run_eligible();
AnyEvent->condvar->recv;

sub run_task {
    my ($task) = @_;

    my $pid = fork;

    # Child proc
    if ($pid == 0) {
        $task->run();
        exit(0);
    }
    # Parent proc
    $task->{pid} = $pid;
    my $w = AnyEvent->child(
        pid => $pid,
        cb  => sub {
            my @args = @_; # pid and status
            say "child=$pid (id=$task->{id}) finished\n";
            push(@finished, $task->{id});
            run_eligible();
            delete $watchers{$pid};
        }
    );

    $watchers{$pid} = {
        child => $w # "watchers"
    };
}

sub run_eligible {

    exit(0) if scalar @tasks == scalar @finished;

    my @eligible;
    TASK: foreach my $task (@tasks) {
        if (!$task->{pid}) {
            foreach my $depend (@{$task->{depends}}) {
                if (!grep{ $_ == $depend } @finished) {
                    next TASK;
                }
            }
            push(@eligible, $task);
        }
    }

    foreach my $task (@eligible) {
        say "Starting to run task=$task->{id}...";
        run_task($task);
    }
}

