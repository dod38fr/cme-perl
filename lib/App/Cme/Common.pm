package App::Cme::Common;
use strict;
use warnings;
use 5.10.1;

use Config::Model;
use Config::Model::Lister;
use XXX ;

sub init_cme {
    my ($self, $opt, $args) = @_;

    my $model = Config::Model->new( model_dir => $opt->{model_dir} );

    my ( $categories, $appli_info, $appli_map ) = Config::Model::Lister::available_models;
    my $application = $args->[0];

    my $root_model = $appli_map->{$application};
    $root_model ||= $application if $opt->{try_application_as_model};

    if ( not defined $root_model ) {
        die "Unknown application: $application. Run 'cme list' to list available applications\n";
    }

    # @ARGV should be [ $config_file ] [ ~~ ] [ modification_instructions ]
    my $config_file;
    if ( $appli_info->{$application}{require_config_file} ) {
        my $command = (split('::', ref($self)))[-1] ;
        $config_file = shift @$args;
        pod2usage(
            -message => "no config file specified. Command should be cme $command $application file",
            -verbose => 0
        ) unless defined $config_file;
    }
    elsif ( $appli_info->{$application}{allow_config_file_override} 
            and $args->[0] and $args->[0] ne '~~' )
        {
            $config_file = shift @$args;
        }

    # else cannot distinguish between bogus config_file and modification_instructions

    # slurp any '~~'
    if ( $args->[0] and $args->[0] eq '~~' ) {
        shift @$args;
    }

    # now @ARGV contains modification_instructions (or bogus
    # config_file) which can only be used by command modify
#    if ( @ARGV and $command ne 'modify' ) {
#    pod2usage(
#        -message => "cannot specify config modification with command $command",
#        -verbose => 0
#    );
#}

    my $inst = $model->instance(
        root_class_name => $root_model,
        instance_name   => $application,
        application     => $application,
        root_dir        => $opt->{root_dir},
        check           => $opt->{force_load} ? 'no' : 'yes',
        auto_create     => $opt->{auto_create},
        skip_read       => $opt->{load} ? 1 : 0,
        backend         => $opt->{backend},
        backup          => $opt->{backup},
        config_file     => $config_file,
    );

    # model and inst are deleted if not kept in a scope
    return ( $model , $inst, $inst->config_root );
}

1;
