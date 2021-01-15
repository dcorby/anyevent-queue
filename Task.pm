package Task;

sub new {
    my $class = shift;
    my ($args) = @_;
    my $self = bless {};
    $self->{id} = $args->{id};
    $self->{depends} = $args->{depends};
    bless $self, $class;
}

sub run {
    my $rand = int(rand(3)) + 3;
    print "Running task (sleeping for $rand) ...\n\n";
    sleep $rand;
    exit;
}

1;
