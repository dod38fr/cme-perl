use strict;
use warnings;

use App::Cme::Command::run;
use Test::More;

subtest "parse_script" => sub {
    my $content = <<'EOS';
app:  popcon
---var
$var{change_it} = qq{
s/^(a)a+/ # comment
\$1.\\"$args{fooname}\\" x2
/xe}
---
load: ! MY_HOSTID=~"$change_it"
EOS

    my %user_args = (fooname => 'foo');

    my $data = App::Cme::Command::run::parse_script('test', $content, \%user_args);

    is($data->{load}[0], '! MY_HOSTID=~" s/^(a)a+/  $1.\"foo\" x2 /xe"', "test parsed script");
};

subtest "process_script_vars" => sub {
    my $data = {
        app => 'dpkg-copyright',
        doc => [ 'test $foo $bar'],
        load => [ 'load $foo $bar'],
        commit_msg => 'commit $foo $bar',
        default => {},
    };
    $ENV{bar}='BAR';
    App::Cme::Command::run::process_script_vars({ foo=> 'FOO' }, $data);

    is($data->{doc}[0],'test FOO BAR',"doc var replacement" );
    is($data->{load}[0],'load FOO BAR',"load var replacement" );
    is($data->{commit_msg},'commit FOO BAR',"commit msg var replacement" );
};

done_testing;
