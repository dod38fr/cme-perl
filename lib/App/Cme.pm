package App::Cme ;

use strict;
use warnings;
use 5.10.1;

use App::Cmd::Setup -app;

use Config::Model;
use Config::Model::Lister;
#use Config::Model::ObjTreeScanner;
#use Getopt::Long;
#use Pod::Usage;
#use Path::Tiny;
#use POSIX qw/setsid/;

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    if ( $opt->{help} ) {
        my ($command) = $self->command_names;
        $self->app->execute_command(
            $self->app->prepare_command("help", $command)
        );
        exit;
    }

    if ( not $args->application ) {
        my $command = (split('::', ref($self)))[-1] ;

        say "You forgot to specify an application to run cme on. Like 'cme $command stuff'.";
        say "The following applications are available:";

        my ( $categories, $appli_info, $appli_map ) = Config::Model::Lister::available_models;
        foreach my $cat ( keys %$categories ) {
            my $names = $categories->{$cat} || [];
            next unless @$names;
            print "$cat:\n  ", join( "\n  ", @$names ), "\n";
        }
        exit 1;
    }

    $self->validate( $opt, $args );
}



1;

__END__

sub run_shell_ui ($$) {
    my ($root, $root_model) = @_;

    require Config::Model::TermUI;
    my $shell_ui = Config::Model::TermUI->new(
        root   => $root,
        title  => $root_model . ' configuration',
        prompt => ' >',
    );

    # engage in user interaction
    $shell_ui->run_loop;
}

my $ui_type;

my $model_dir;
my $trace = 0;
my $root_dir;

my $man        = 0;
my $help       = 0;
my $force_load = 0;
my $dev        = 0;
my $backend;
my $load;
my @fix_from;
my $fix_filter;
my $force_save = 0;
my $open_item  = '';
my $fuse_dir;
my $fuse_debug  = 0;
my $apply_fixes = 0;
my $search;
my $search_type = 'all';
my $dir_char_mockup;
my $try_application_as_model = 0; # means search a model instead of an application name
my $backup;
my $auto_create;
my $strict = 0;

my %command_option = (
    list    => [],
);


# retrieve the main command, i.e. the first arg without leading dash
my ($command) = grep { !/^-/ } @ARGV;

pod2usage( -message => 'no command specified', -verbose => 0 )
    unless defined $command;

pod2usage( -verbose => 1 ) if $command =~ /help/;
pod2usage( -verbose => 2 ) if $command =~ /man/;

load_cme_extensions ($command, \%command_option);

my $cmd_options = $command_option{$command}
    || pod2usage( -message => "unknown command: $command", -verbose => 0 );

my $result = GetOptions( @global_options, @$cmd_options );

pod2usage( -verbose => 0 ) if not $result;

# @ARGV should be $command, $application, [ $config_file ] [ ~~ ] [ modification_instructions ]

shift @ARGV;
my $application = shift @ARGV;


if ( defined $root_dir && !-e $root_dir ) {
    mkdir $root_dir, 0755 || die "can't create $root_dir:$!";
}



exit 0;

__END__

