# -*- cperl -*-
use strict;
use warnings;
use File::Path;
use Probe::Perl;

use Test::Command 0.08;
use Test::More;
use Test::File::Contents;

if ( $^O !~ /linux|bsd|solaris|sunos/ ) {
    plan skip_all => "Test with system() in build systems don't work well on this OS ($^O)";
}

## testing exit status

# pseudo root where config files are written by config-model
my $wr_root = 'wr_root';

# cleanup before tests
rmtree($wr_root);

my $test1     = 'popcon1';
my $wr_dir    = $wr_root . '/' . $test1;
my $conf_file = "$wr_dir/etc/popularity-contest.conf";

my $path = Probe::Perl->find_perl_interpreter();

my $perl_cmd = $path . ' -Ilib ' . join( ' ', map { "-I$_" } Probe::Perl->perl_inc() );

# debian continuous integ tests run tests out of source. Must use system cme
my $cme_cmd = -e 'bin/cme' ? "$perl_cmd bin/cme" : 'cme' ;
note("cme is invoked with: '$cme_cmd'" );

# test minimal modif (re-order)
my $list_ok = Test::Command->new(
    cmd => "$cme_cmd list"
);
exit_is_num( $list_ok, 0, 'list command went well' );

my $oops = Test::Command->new(
    cmd => "$cme_cmd modify popcon -root-dir $wr_dir PARITICIPATE=yes"
);

exit_cmp_ok( $oops, '>', 0, 'missing config file detected' );
stderr_like( $oops, qr/cannot find configuration file/, 'check auto_read_error' );

# put popcon data in place
my @orig = <DATA>;

mkpath( $wr_dir . '/etc', { mode => 0755 } )
    || die "can't mkpath: $!";
open( CONF, "> $conf_file" ) || die "can't open $conf_file: $!";
print CONF @orig;
close CONF;

# test minimal modif (re-order)
my $ok = Test::Command->new(
    cmd => "$cme_cmd modify popcon -save -root-dir $wr_dir"
);
exit_is_num( $ok, 0, 'all went well' );

file_contents_like $conf_file,   qr/cme/,       "updated header";
file_contents_like $conf_file,   qr/yes"\nMY/, "reordered file";
file_contents_unlike $conf_file, qr/removed/,   "double comment is removed";

$oops = Test::Command->new(
    cmd => "$cme_cmd modify popcon -root-dir $wr_dir PARITICIPATE=yes"
);
exit_cmp_ok( $oops, '>', 0, 'wrong parameter detected' );
stderr_like( $oops, qr/unknown element/, 'check unknown element' );

# use -save to force a file save to update file header
$ok = Test::Command->new(
    cmd => "$cme_cmd modify popcon -save -root-dir $wr_dir PARTICIPATE=yes"
);
exit_is_num( $ok, 0, 'all went well' );

file_contents_like $conf_file,   qr/cme/,      "updated header";
file_contents_unlike $conf_file, qr/removed`/, "double comment is removed";

my $search = Test::Command->new(
    cmd => "$cme_cmd search popcon -root-dir $wr_dir -search y -narrow value"
);
exit_is_num( $search, 0, 'search went well' );
stdout_like( $search, qr/PARTICIPATE/, "got PARTICIPATE" );
stdout_like( $search, qr/USEHTTP/,     "got USEHTTP" );

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

