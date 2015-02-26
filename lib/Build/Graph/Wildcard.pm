package Build::Graph::Wildcard;

use strict;
use warnings;

use parent 'Build::Graph::Role::FileSet';

use Carp ();

use File::Spec ();

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(%args);
	$self->{matcher} = $args{matcher} || Carp::croak('No matcher is given');
	$self->{dir}     = ref($args{dir}) ? $args{dir} : [ File::Spec->splitdir($args{dir}) ];
	return $self;
}

sub dir {
	my $self = shift;
	return @{ $self->{dir} };
}

sub _dir_matches {
	my ($self, $name) = @_;
	my (undef, $dirs, $file) = File::Spec->splitpath($name);
	my @dirs  = File::Spec->splitdir($dirs);
	my @match = $self->dir;
	return if @dirs < @match;
	return File::Spec->catdir(@dirs[ 0..$#match ]) eq File::Spec->catdir(@match);
}

sub match {
	my ($self, $filename) = @_;
	if ($self->_dir_matches($filename) && $self->{matcher}->($filename)) {
		push @{ $self->{files} }, $filename;
		$_->($filename) for	@{ $self->{substs} };
	}
	return;
}

1;

#ABSTRACT: A Build::Graph pattern

=begin Pod::Coverage

match

=end Pod::Coverage
