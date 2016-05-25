package Build::Graph::Util;

use strict;
use warnings;

use Exporter;
use Carp 'croak';

our @ISA = 'Exporter';
our @EXPORT_OK = qw/glob_to_regex/;

sub glob_to_regex {
    my $regex = _glob_to_regex_string(shift);
    return qr/^$regex$/;
}

sub _glob_to_regex_string
{
    my $glob = shift;
    my $in_curlies;
    local $_ = $glob;

    my $regex = !/\A(?=\.)/ ? '(?=[^\.])' : '';
    while (!/\G\z/mgc) {
        if (/\G([^\/.()|+^\$@%\\*?{},\[\]]+)/gc) {
            $regex .= $1;
        }
        elsif (m{\G/}gc) {
            $regex .= !/\G(?=\.)/gc ? '/(?=[^\.])' : '/'
        }
        elsif (/ \G ( [.()|+^\$@%] ) /xmgc) {
            $regex .= quotemeta $1;
        }
        elsif (/ \G \\ ( [*?{}\\,] ) /xmgc) {
            $regex .= quotemeta $1;
        }
        elsif (/\G\*/mgc) {
            $regex .= "[^/]*";
        }
        elsif (/\G\?/mgc) {
            $regex .= "[^/]";
        }
        elsif (/\G\{/mgc) {
            $regex .= "(";
            ++$in_curlies;
        }
        elsif (/\G \[ ( [^\]]+ ) \] /xgc) {
            $regex .= "[\Q$1\E]";
        }
        elsif ($in_curlies && /\G\}/mgc) {
            $regex .= ")";
            --$in_curlies;
        }
        elsif ($in_curlies && /\G,/mgc) {
            $regex .= "|";
        }
        elsif (/\G([},]+)/gc) {
            $regex .= $1;
        }
        else {
			croak sprintf "Couldn't parse at %s|%s", substr($_, 0 , pos), substr $_, pos;
        }
    }

    return $regex;
}

1;

__END__

#ABSTRACT: Helper functions for Build::Graph

=method glob_to_regex($glob)

This converts the glob pattern C<$glob> into a regex. The following metacharacters and rules are respected.

=over

=item C<*> - match zero or more characters

C<a*> matches C<a>, C<aa>, C<aaaa> and many many more.

=item C<?> - match exactly one character

C<a?> matches C<aa>, but not C<a>, or C<aaa>

=item Character sets/ranges

C<example.[ch]> matches C<example.c> and C<example.h>

C<demo.[a-c]> matches C<demo.a>, C<demo.b>, and C<demo.c>

=item alternation

C<example.{foo,bar,baz}> matches C<example.foo>, C<example.bar>, and
C<example.baz>

=item leading . must be explictly matched

C<*.foo> does not match C<.bar.foo>.  For this you must either specify
the leading . in the glob pattern (C<.*.foo>).

=item C<*> and C<?> do not match /

C<*.foo> does not match C<bar/baz.foo>.  For this you must either
explicitly match the / in the glob (C<*/*.foo>).

=back

=head1 SEE ALSO

L<Text::Glob>, glob(3)

=cut
