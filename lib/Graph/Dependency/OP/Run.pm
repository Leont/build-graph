package Graph::Dependency::OP::Run;
use Any::Moose;

my $counter = 0;

has id => (
	is => 'ro',
	isa => 'Int',
	default => sub { ++$counter },
	init_arg => undef,
);

has stash => (
	isa => 'HashRef',
	traits => ['Hash'],
	default => sub { {} },
	handles => {
		set_stash => 'set',
		get_stash => 'get',
	},
);

has verbosity => (
	is => 'ro',
	isa => 'Int',
	default => 0,
);

has logger => (
	is => 'ro',
	isa => 'CodeRef',
	builder => '_build_logger',
);

sub _build_logger {
	return sub {
		my ($message) = @_;
		print STDERR $message, "\n";
	};
}

sub log {
	my ($self, $message, $severity) = @_;
	$self->logger->($message, $severity) if $severity > $self->verbosity;
	return;
}

has file_comperator => (
	is => 'ro',
	isa => 'CodeRef',
	traits => ['Code'],
	builder => '_build_file_comperator',
	handles => {
		compare => 'execute',
	},
);

sub _build_file_comperator {
	return sub { 
		my ($destination, $source) = @_;
		return 0 if -d $source->filename;
		return -M($destination->filename) <=> -M($source->filename);
	};
}

1;

__END__

=method id()

Returns an identifier for the current run.

=method get_stash($key)

Get an element from the stash.

=method set_stash($key, $value)

Set an element from the stash.

=attr verbosity

The verbosity, defaults to C<0>.

=attr logger

A logging subroutine, defaults to a sub printing to STDERR.

=method log($message, $severity)

Log a certain message with a certain severity.

=attr file_comperator(sub($destination, $source))

Set a file comparator function. It is called with the destination file as its dependency.

