#!/usr/bin/env perl

# load perl Default Libs
use strict;
use warnings;
use Cwd qw(getcwd);
use Config::IniFiles;
use FindBin qw( $RealBin );

# load custom lib
use lib "$RealBin/lib";
use CommandParser qw(get_options);
use Patch;

# Dump / log lib
use Data::Dumper;

# define current dir
my $current_dir = getcwd();

# parse config.ini file
my %config_ini;
tie %config_ini, 'Config::IniFiles', (  -file => $current_dir."/config/config.ini" );

# parse command line arguments
my $command_line_arguments = CommandParser::get_options(
	{
		skip      => 0,
	}, {
	    'server=s'            => 'server name in config.ini',
		'skip=s'              => 'skip steps in script',
		'check_files'         => 'force re-check of previously downloaded files',
		'force|f'             => 'force download even if the allow-url says we are not allowed to',
	}
);

# define config variable
my $config;

if($command_line_arguments->{'server'}) {
	$config = $config_ini{$command_line_arguments->{'server'}};
} elsif ($config_ini{'app'}{'default_server'}) {
	$config = $config_ini{$config_ini{'app'}{'default_server'}};
} else {
	print "[SCRIPT] I can't find 'default_server' in config and argument 'server' not filled";
	exit;
}

if(!$config) {
	print "[SCRIPT] ERROR while try to use config{'server'}, server name is wrong. Check default_server in config.ini or --server arg.";
	exit;
}

if ( !Patch::patch_allowed($config) ) {
	print "Patching is not currently allowed. You may use --force to force patching.\n";
	exit;
}

exit;