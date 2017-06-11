# -*- cperl -*-
use strict;
use warnings;
use utf8;
use 5.10.1;
use open ':std', ':encoding(utf8)';

use Encode;

use Path::Tiny;
use Probe::Perl;

use Test::Command 0.08;
use Test::More;
use Test::File::Contents;

use App::Cmd::Tester;
use App::Cme ;

if ( $^O !~ /linux|bsd|solaris|sunos/ ) {
    plan skip_all => "Test with system() in build systems don't work well on this OS ($^O)";
}

my $arg = shift || '';
my ( $log, $show ) = (0) x 2;

my $trace = $arg =~ /t/ ? 1 : 0;

Config::Model::Exception::Any->Trace(1) if $arg =~ /e/;

## testing exit status

# pseudo root where config files are written by config-model
my $wr_root = path('wr_root');

# cleanup before tests
$wr_root -> remove_tree;

my $test1     = 'popcon1';
my $wr_dir    = $wr_root->child($test1);

my $conf_dir = $wr_dir->child('/etc');
$conf_dir->mkpath;

my $conf_file = $conf_dir->child("popularity-contest.conf");

my $perl_path = Probe::Perl->find_perl_interpreter();

my $perl_cmd = $perl_path . ' -Ilib ' . join( ' ', map { "-I$_" } Probe::Perl->perl_inc() );

# debian continuous integ tests run tests out of source. Must use system cme
my $cme_cmd = -e 'bin/cme' ? "$perl_cmd bin/cme" : 'cme' ;
note("cme is invoked with: '$cme_cmd'" );

subtest "list command" => sub {
    my @test_cmd = qw/list/;
    my $result = test_app( 'App::Cme' => \@test_cmd );
    say "-- stdout --\n", $result->stdout,"-----"  if $trace;
    is($result->error, undef, 'threw no exceptions');
};

subtest "modification without config file" => sub {
    my $test_cmd = [
        qw/modify popcon/,
        '-root-dir' => $wr_dir->stringify,
        "PARTICIPATE=yes"
    ];

    my $oops = test_app( 'App::Cme' => $test_cmd );
    is ($oops->exit_code, 2, 'error detected' );
    like($oops->error, qr/cannot find configuration file/, 'missing config file detected' );
};

# put popcon data in place
my @orig = <DATA>;

$conf_file->spew_utf8(@orig);

subtest "minimal modification" => sub {
    # test minimal modif (re-order)
    my @test_cmd = (qw/modify popcon -save -root-dir/, $wr_dir->stringify);
    my $ok = test_app( 'App::Cme' => \@test_cmd );
    is ($ok->exit_code, 0, 'all went well' ) or diag("Failed command cme @test_cmd");
    is($ok->error, undef, 'threw no exceptions');

    file_contents_like $conf_file->stringify,   qr/cme/,       "updated header";
    file_contents_like $conf_file->stringify,   qr/yes"\nMY/, "reordered file";
    file_contents_unlike $conf_file->stringify, qr/removed/,   "double comment is removed";
};

subtest "modification with wrong parameter" => sub {
    my @test_cmd = (qw/modify popcon -root-dir/, $wr_dir->stringify, qq/PARITICIPATE=yes/);
    my $oops = test_app( 'App::Cme' => \@test_cmd );
    is ($oops->exit_code, -1, 'error detected' );
    like($oops->error.'' , qr/object/, 'check unknown element' );
    is( $oops->exit_code, -1, 'wrong parameter detected' );

};

subtest "modification with good parameter" => sub {
    # use -save to force a file save to update file header
    my @test_cmd = (qw/modify popcon -save -root-dir/, $wr_dir->stringify, qq/PARTICIPATE=yes/);
    my $ok = test_app( 'App::Cme' => \@test_cmd );
    is( $ok->exit_code, 0, 'all went well' ) or diag("Failed command @test_cmd");
    file_contents_like $conf_file->stringify,   qr/cme/,      "updated header";
    file_contents_unlike $conf_file->stringify, qr/removed`/, "double comment is removed";
};

subtest "search" => sub {
my @test_cmd = (qw/search popcon -root-dir/, $wr_dir->stringify, qw/-search y -narrow value/);
    my $search = test_app( 'App::Cme' => \@test_cmd );
    is( $search->error, undef, 'threw no exceptions');
    is( $search->exit_code, 0, 'search went well' ) or diag("Failed command @test_cmd");
    like( $search->stdout, qr/PARTICIPATE/, "got PARTICIPATE" );
    like( $search->stdout, qr/USEHTTP/,     "got USEHTTP" );
};

subtest "modification with utf8 parameter" => sub {
    my $utf8_name = "héhôßœ";
    my @test_cmd = ((qw/modify popcon -root-dir/, $wr_dir->stringify),
        encode('UTF-8',qq/MY_HOSTID="$utf8_name"/) );
    my $ok = test_app( 'App::Cme' => \@test_cmd );
    is( $ok->error, undef, 'threw no exceptions');
    is( $ok->exit_code, 0, 'all went well' ) or diag("Failed command @test_cmd");

    file_contents_like $conf_file->stringify,   qr/$utf8_name/,
        "updated MY_HOSTID with weird utf8 hostname" ,{ encoding => 'UTF-8' };
};

my @script_tests = (
    {
        label => "modification with a script and args",
        script => [ "app:  popcon", 'load ! MY_HOSTID=\$name$name'],
        args => qq!--arg name=foobar!,
        test => qr/"\$namefoobar"/
    },
    {
        label => "modification with a script and var section",
        script => [ "app:  popcon", 'var: $var{name}="foobar2"','load ! MY_HOSTID=\$name$name'],
        args => '',
        test => qr/"\$namefoobar2"/
    },
    {
        label => "modification with a script and var section which uses args",
        script => [ "app:  popcon", 'var: $var{name}=$args{fooname}."bar2"','load ! MY_HOSTID=\$name$name'],
        args => '--arg fooname=foo',
        test => qr/"\$namefoobar2"/
    },
    {
        label => "modification with a Perl script run by cme run with args",
        script => [
            "use Config::Model qw(cme);",
            'my ($opt,$val,$name) = @ARGV;',
            'cme(application => "popcon", root_dir => $val)->modify("! MY_HOSTID=\$name$name");'
        ],
        args => 'foobar3',
        test => qr/"\$namefoobar3"/
    },
);


# test cme run real script with arguments
foreach my $test ( @script_tests) {
    subtest $test->{label} => sub {
        my $script = $wr_dir->child('my-script.cme');
        $script->spew_utf8( map { "$_\n"} @{$test->{script}});

        my $cmd = qq!$cme_cmd run $script -root-dir $wr_dir !. $test->{args};
        note("cme command: $cmd");
        my $ok = Test::Command->new(cmd => $cmd);
        exit_is_num( $ok, 0, "all went well" ) or diag("Failed command: $cmd");

        file_contents_like $conf_file->stringify, $test->{test},
            "updated MY_HOSTID with script" ,{ encoding => 'UTF-8' };
    };
}

# todo: test failure case for run script

my @bad_script_tests = (
    {
        label => "modification with a Perl script run by cme run with missing arg",
        script => [ "app:  popcon", 'load ! MY_HOSTID=\$name$name'],
        args => '',
        error_regexp => qr/use option '-arg name=xxx'/
    },
    {
        label => "modification with a Perl script run by cme run with 2 missing args",
        script => [ "app:  popcon", 'load ! MY_HOSTID=$name1$name2'],
        args => '',
        error_regexp => qr/use option '-arg name1=xxx -arg name2=xxx'/
    },
    {
        label => "modification with a Perl script run by cme run with  missing args in var line",
        script => [
            "app:  popcon",
            'var: $var{name} = $args{name1}.$args{name2}',
            'load: ! MY_HOSTID=$name'],
        args => '',
        error_regexp => qr/use option '-arg name1=xxx -arg name2=xxx'/
    },
);
foreach my $test ( @bad_script_tests) {
    subtest $test->{label} => sub {
        my $script = $wr_dir->child('my-script.cme');
        $script->spew_utf8( map { "$_\n"} @{$test->{script}});

        my $cmd = qq!$cme_cmd run $script -root-dir $wr_dir !. $test->{args};
        note("cme command: $cmd");
        my $oops = Test::Command->new(cmd => $cmd);
        exit_cmp_ok( $oops, '>', 0, 'wrong command detected' );
        my $re = $test->{error_regexp};
        stderr_like( $oops, $re , 'check error message with '.$re );
    };
}

done_testing;

__END__
# Config file for Debian's popularity-contest package.
#
# To change this file, use:
#        dpkg-reconfigure popularity-contest

## should be removed

MY_HOSTID="aaaaaaaaaaaaaaaaaaaa"
# we participate
PARTICIPATE="yes"
USEHTTP="yes" # always http
DAY="6"

