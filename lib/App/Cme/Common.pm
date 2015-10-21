#ABSTRACT: Common methods for App::Cme

package App::Cme::Common;

use strict;
use warnings;
use 5.10.1;

use Config::Model 2.063;
use Config::Model::Lister;
use Pod::POM;
use Pod::POM::View::Text;
use Scalar::Util qw/blessed/;
use Path::Tiny;

sub cme_global_options {
  my ( $class, $app ) = @_;

  my @global_options = (
      [ "model-dir=s"        => "Specify an alternate directory to find model files"],
      [ "try-app-as-model!"  => "try to load a model using directly the application name "
                              . "specified as 3rd parameter on the command line"],
      [ "dev!"               => "test a model under development"],
      [ "force-load!"        => "Load file even if error are found in data. Bad data are discarded"],
      [ "create!"            => "start from scratch."],
      [ "root-dir=s"         => "Change root directory. Mostly used for test"],
      [ "backend=s"          => "Specify a read/write backend"],
      [ "stack-trace|trace!" => "Provides a full stack trace when exiting on error"],
      [ "quiet!"             => "Suppress progress messages" ],
      # no bundling
      { getopt_conf => [ qw/no_bundling/ ] }
  );

  return (
      @global_options,
  );
}

sub process_args {
    my ($self, $opt, $args) = @_;

    my ( $categories, $appli_info, $appli_map ) = Config::Model::Lister::available_models;
    my $application = shift @$args;

    my $root_model = $appli_map->{$application};
    $root_model ||= $application if $opt->{try_application_as_model};
    say "cme: using $root_model model" unless $opt->{quiet};

    Config::Model::Exception::Any->Trace(1) if $opt->{trace};

    if ( not defined $root_model ) {
        die "Unknown application: $application. Run 'cme list' to list available applications\n";
    }

    if ($opt->{dev}) {
        # ignore $dev if run as root
        if ( $> ) {
            unshift @INC, 'lib';
            $opt->{model_dir} = 'lib/Config/Model/models/';
        }
        else {
            warn "-dev option is ignored when run as root\n";
        }
    }

    my $command = (split('::', ref($self)))[-1] ;

    # @ARGV should be [ $config_file ] [ ~~ ] [ modification_instructions ]
    my $config_file;
    if ( $appli_info->{$application}{require_config_file} ) {
        $config_file = shift @$args;
        $self->usage_error(
            "no config file specified. Command should be 'cme $command $application configuration_file'",
        ) unless $config_file;
    }
    elsif ( $appli_info->{$application}{allow_config_file_override} 
            and $args->[0] and $args->[0] ne '~~' )
        {
            $config_file = shift @$args;
        }

    # else cannot distinguish between bogus config_file and modification_instructions
    my $warn_msg;
    if ($config_file and not -e $config_file) {
        $warn_msg = "Warning: file '$config_file' does not exists.";
    }
    if ($warn_msg and $appli_info->{$application}{allow_config_file_override}) {
        $warn_msg .=" You may need to write this command with '~~' argument. I.e. try "
            ."something like 'cme $command $application ~~ $config_file'";
    }
    if ($warn_msg) {
        warn $warn_msg."\n";
    }

    # slurp any '~~'
    if ( $args->[0] and $args->[0] eq '~~' ) {
        shift @$args;
    }

    $opt->{_application} = $application ;
    $opt->{_config_file} = $config_file;
    $opt->{_root_model}  = $root_model;
}


sub model {
    my ($self, $opt, $args) = @_;

    return $self->{_model}
        ||= Config::Model->new( model_dir => $opt->{model_dir} );
}

sub instance {
    my ($self, $opt, $args) = @_;

    return
        $self->{_instance}
        ||= $self->model->instance(
            root_class_name => $opt->{_root_model},
            instance_name   => $opt->{_application},
            application     => $opt->{_application},
            root_dir        => $opt->{root_dir},
            check           => $opt->{force_load} ? 'no' : 'yes',
            auto_create     => $opt->{create},
            skip_read       => $opt->{load} ? 1 : 0,
            backend         => $opt->{backend},
            backup          => $opt->{backup},
            config_file     => $opt->{_config_file},
        );

}

sub init_cme {
    my $self = shift;
    # model and inst are deleted if not kept in a scope
    return ( $self->model(@_) , $self->instance(@_), $self->instance->config_root );
}

sub save {
    my ($self,$inst,$opt) = @_;

    $inst->say_changes unless $opt->{quiet};

    # if load was forced, must write back to clean up errors (even if they are not changes
    # at semantic level, i.e. removed unnecessary stuff)
    $inst->write_back( force => $opt->{force_load} || $opt->{save} );

}

sub run_tk_ui {
    my ($self, $root, $opt) = @_;

    require Config::Model::TkUI;
    require Tk;
    require Tk::ErrorDialog;
    Tk->import;

    no warnings 'once';
    my $mw = MainWindow->new;
    $mw->withdraw;

    # Thanks to Jerome Quelin for the tip
    $mw->optionAdd( '*BorderWidth' => 1 );

    my $cmu = $mw->ConfigModelUI(
        -root       => $root,
    );

    $root->instance->on_message_cb(sub{$cmu->show_message(@_);});

    if ($opt->{open_item}) {
        my $obj = $root->grab($opt->{open_item});
        $cmu->force_element_display($obj);
    }

    &MainLoop;    # Tk's
}

sub run_shell_ui ($$) {
    my ($self, $root, $root_model) = @_;

    require Config::Model::TermUI;
    my $shell_ui = Config::Model::TermUI->new(
        root   => $root,
        title  => $root_model . ' configuration',
        prompt => ' >',
    );

    # engage in user interaction
    $shell_ui->run_loop;
}

sub get_documentation {
    my ($self) = @_;

    my $parser = Pod::POM->new();
    my $pkg = blessed ($self);
    $pkg =~ s!::!/!g;
    my $pom = $parser->parse_file($INC{$pkg.'.pm'})
        || die $parser->error();

    my $sections = $pom->head1();
    my @ret ;
    foreach my $s (@$sections) {
        push (@ret ,$s) if $s->title() =~ /DESCRIPTION|EXIT/;
    }
    return join ("", map { Pod::POM::View::Text->print($_)} @ret) . "Options:\n";;
}

1;

__END__

=head1 SYNOPSIS

 # Internal. Used by App::Cme::Command::*

=head1 DESCRIPTION

Common methods for all cme commands


=cut
