package Graph::Dependency::Run;
use Any::Moose;
use List::MoreUtils 'any';

my $counter = 0;

has id => (
	is => 'ro',
	isa => 'Int',
	default => sub { ++$counter },
	init_arg => undef,
);

has stash => (
	isa => 'HashRef',
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
		print STDERR $message;
	};
}

sub log {
	my ($self, $message, $severity) = @_;
	$self->logger->($message, $severity) if $severity >= $self->verbosity;
	return;
}

has file_comperator => (
	is => 'ro',
	isa => 'CodeRef',
	builder => '_build_file_comperator',
);

sub _build_file_comperator {
	return sub { 
		my ($destination, @sources) = @_;
		my $timestamp = -M $destination->filename;
		return any { $timestamp < -M $_->filename } grep { $_->can('filename') } @sources;
	};
}

1;
