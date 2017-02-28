# -*- cperl -*-
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(utf8)';

use Path::Tiny;
use Probe::Perl;

use Test::Command 0.08;
use Test::More;
use Test::File::Contents;

if ( $^O !~ /linux|bsd|solaris|sunos/ ) {
    plan skip_all => "Test with system() in build systems don't work well on this OS ($^O)";
}

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

subtest "modification without config file" => sub {
    my $list_ok = Test::Command->new(
        cmd => "$cme_cmd list"
    );
    exit_is_num( $list_ok, 0, 'list command went well' );

    my $oops = Test::Command->new(
        cmd => "$cme_cmd modify popcon -root-dir $wr_dir PARITICIPATE=yes"
    );

    exit_cmp_ok( $oops, '>', 0, 'missing config file detected' );
    stderr_like( $oops, qr/cannot find configuration file/, 'check auto_read_error' );
};

# put popcon data in place
my @orig = <DATA>;

$conf_file->spew_utf8(@orig);

subtest "minimal modification" => sub {
    # test minimal modif (re-order)
    my $ok = Test::Command->new(
        cmd => "$cme_cmd modify popcon -save -root-dir $wr_dir"
    );
    exit_is_num( $ok, 0, 'all went well' );

    file_contents_like $conf_file->stringify,   qr/cme/,       "updated header";
    file_contents_like $conf_file->stringify,   qr/yes"\nMY/, "reordered file";
    file_contents_unlike $conf_file->stringify, qr/removed/,   "double comment is removed";
};

subtest "modification with wrong parameter" => sub {
    my $oops = Test::Command->new(
        cmd => "$cme_cmd modify popcon -root-dir $wr_dir PARITICIPATE=yes"
    );
    exit_cmp_ok( $oops, '>', 0, 'wrong parameter detected' );
    stderr_like( $oops, qr/unknown element/, 'check unknown element' );

};

subtest "modification with good parameter" => sub {
    # use -save to force a file save to update file header
    my $ok = Test::Command->new(
        cmd => "$cme_cmd modify popcon -save -root-dir $wr_dir PARTICIPATE=yes"
    );
    exit_is_num( $ok, 0, 'all went well' );

    file_contents_like $conf_file->stringify,   qr/cme/,      "updated header";
    file_contents_unlike $conf_file->stringify, qr/removed`/, "double comment is removed";
};

subtest "search" => sub {
    my $search = Test::Command->new(
        cmd => "$cme_cmd search popcon -root-dir $wr_dir -search y -narrow value"
    );
    exit_is_num( $search, 0, 'search went well' );
    stdout_like( $search, qr/PARTICIPATE/, "got PARTICIPATE" );
    stdout_like( $search, qr/USEHTTP/,     "got USEHTTP" );
};

subtest "modification with utf8 parameter" => sub {
    my $utf8_name = "héhôßœ";
    my $ok = Test::Command->new(
        cmd => qq!$cme_cmd modify popcon -root-dir $wr_dir MY_HOSTID="$utf8_name"!
    );
    exit_is_num( $ok, 0, 'all went well' );

    file_contents_like $conf_file->stringify,   qr/$utf8_name/,
        "updated MY_HOSTID with weird utf8 hostname" ,{ encoding => 'UTF-8' };
};

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

