package Core;

use Moo;
with 'Build::Graph::Role::CommandProvider';

use Carp qw/croak/;

sub configure_commands {
	my ($self, $command_set) = @_;
	$command_set->add('basic', module => 'Core', commands => {
		'spew' => sub { my $info = shift; ::next_is($info->name); spew($info->name, $info->arguments) },
		'poke' => sub { ::next_is('poke') },
		'noop' => sub { ::next_is($_[0]->name) },
	});
}

sub spew {
	my ($filename, $content) = @_;
	open my $fh, '>', $filename or croak "Couldn't open file '$filename' for writing: $!\n";
	print $fh $content;
	close $fh or croak "couldn't close $filename: $!\n";
	return;
}

1;
