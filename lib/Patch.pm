#!/usr/bin/env perl
package Patch;

use strict;
use warnings;

use Cwd;
use Encode;
use File::Copy;
use Getopt::Long;
use LWP::UserAgent;
use Net::FTP;
use YAML::Syck;

my $ua;
my $opt;
$|++;

sub new {
    my $class = shift;
    $opt = shift;
    $ua = LWP::UserAgent->new;
    sub ftp;
    return bless {}, $class;
}
    
# # The hat effect data source file is only in the kRO grf file. Grab a copy from github.
# my $hat_url  = 'https://raw.githubusercontent.com/ROClientSide/kRO-RAW-Mains/master/data/luafiles514/lua%20files/hateffectinfo/hateffectinfo.lua';
# my $hat_data = $ua->get( $hat_url );
# if ( $hat_data && $hat_data->is_success && $hat_data->content ) {
    # open FP, '>', "$extract_dir/hateffectinfo.lua";
    # print FP $hat_data->content;
    # close FP;
    # $extracted->{'data\luafiles514\lua files\hateffectinfo\hateffectinfo.lua'} = $hat_url;
# }
# YAML::Syck::DumpFile( "$opt->{download_dir}/extracted_files.yml", $extracted );

# # Convert the hat effect data into the files we need for OpenKore.
# if ( -f "$extract_dir/hateffectinfo.lua" ) {
    # convert_hat_effect_file( "$extract_dir/hateffectinfo.lua", "$extract_dir/hateffect_id_handle.txt", "$extract_dir/hateffect_name.txt" );
# }

# # Copy the files into the git directory.
# my $map = {
    # 'idnum2itemdesctable.txt'        => 'itemsdescriptions.txt',
    # 'idnum2itemdisplaynametable.txt' => 'items.txt',
    # 'itemslotcounttable.txt'         => 'itemslotcounttable.txt',
    # 'mapnametable.txt'               => 'maps.txt',
    # 'questid2display.txt'            => 'quests.txt',
    # 'resnametable.txt'               => 'resnametable.txt',
    # 'skillnametable.txt'             => 'skillnametable.txt',
    # 'hateffect_id_handle.txt'        => '../../hateffect_id_handle.txt',
    # 'hateffect_name.txt'             => '../../hateffect_name.txt',
# };
# foreach ( sort keys %$map ) {
    # next if !-f "$extract_dir/$_";
    # printf "Copying [%s] to [%s].\n", $_, $map->{$_};
    # File::Copy::cp "$extract_dir/$_" => "$opt->{git_dir}/$map->{$_}";
# }


# The way we do this is by wrapping the lub in a piece of lua code which loads the lub, then writes out the data structures the lub sets up.
# We use https://github.com/ROClientSide/Translation/tree/master/Dev/Tools/SeperateItemInfo to extract the files.
sub convert_iteminfo_lub {
    my ($self, $current_dir) = @_;
    my $extract_dir = $current_dir."$opt->{download_dir}/system";

    return if !-f "$extract_dir/iteminfo.lub";

    # SeparateItemInfo.lua requires:
    #   1. Must be run with a 32-bit lua.
    #   2. iteminfo.lub must be named (case sensitive!).
    my @args = ('lua', $current_dir.'/scripts/SeperateItemInfo.lua', $extract_dir, $extract_dir);
    system @args;

    # Move all of the files from $extract_dir/idnum into $extract_dir, and delete the now-empty directory.
    opendir DIR, "$extract_dir/";
    rename "$extract_dir/$_" => $current_dir."$opt->{download_dir}/$_" foreach grep { -f "$extract_dir/$_" } readdir DIR;
    closedir DIR;

    # Replace all spaces with underscores in the item name table.
    local $/;
    open FP, '<', $current_dir.$opt->{download_dir}."/idnum2itemdisplaynametable.txt";
    my $txt = <FP>;
    close FP;
    $txt =~ s/ /_/gos;
    open FP, '>', $current_dir.$opt->{download_dir}."/idnum2itemdisplaynametable.txt";
    print FP $txt;
    close FP;

    # Fix unicode characters.
    fix_unicode_file( $current_dir.$opt->{download_dir}."/idnum2itemdisplaynametable.txt" );
    fix_unicode_file( $current_dir.$opt->{download_dir}."/idnum2itemdesctable.txt" );

    # Remove unnecessary zero-slot entries from itemslotcounttable.txt.
    local $/;
    open FP, '<', $current_dir.$opt->{download_dir}."/itemslotcounttable.txt";
    $txt = <FP>;
    close FP;
    $txt =~ s/^(\d+)#0#\n//gmos;
    open FP, '>', $current_dir.$opt->{download_dir}."/itemslotcounttable.txt";
    print FP $txt;
    close FP;
}

sub convert_hat_effect_file {
    my ( $lua_file, $id_file, $name_file ) = @_;

    return if !open FP, '<', $lua_file;
    local $/;
    binmode FP;
    my $data = <FP>;
    close FP;

    # Parse out the ids.
    my ( $enum_block ) = $data =~ /HatEFID = \{(.*?)\}/os;
    return if !$enum_block;
    my $ids = {};
    $ids->{$1} = $2 while $enum_block =~ /(\w+)\s*=\s*(\d+)/g;

    # Write the hat effect id file.
    open FP, '>', $id_file;
    print FP "$ids->{$_} $_\n" foreach sort { $ids->{$a} <=> $ids->{$b} } keys %$ids;
    close FP;

    # Also write a default name file, which is just the effect id without HAT_EF.
    open FP, '>', $name_file;
    foreach ( sort { $ids->{$a} <=> $ids->{$b} } keys %$ids ) {
        my $name = $_;
        $name =~ s/HAT_EF_//os;
        print FP "$_ $name\n";
    }
    close FP;
}

sub patch_allowed {
    $opt->{force} || $ua->get( $opt->{allow_url} )->content eq 'allow';
}

sub ftp {
    our $ftp;
    if ( !$ftp ) {
        my $uri = URI->new( $opt->{download_base_url} );
        $ftp = Net::FTP->new( $uri->host, Debug => 1, Passive => 1 );
        if(!$ftp) {
            print "Error while connecting to FTP (check connection or URL)\n";
        }
        $ftp->login;
        $ftp->binary;
        $ftp->cwd( $uri->path );
    }
    $ftp;
}

sub ftp_data {
    our $ftp_data_cache ||= {};
    $ftp_data_cache->{ $_[0] } ||= {    #
        time => ftp->mdtm( $_[0] ) || 0,
        size => ftp->size( $_[0] ) || 0,
    };
}

sub backticks {
    my ( @cmd ) = @_;

    my $pid = open( my $fp, '-|' );
    
    if ( !$pid ) {
        ( $>, $) ) = ( $<, $( );

        exec( @cmd ) || die "Unable to exec program @cmd: $!\n";
    }

    local $/;
    my $output = <$fp>;
    close( $fp );

    $output;
}

sub fix_unicode_file {
    my ( $file ) = @_;

    # Read the GRF file.
    local $/;
    open FP, '<', $file;
    binmode FP;
    my $data = <FP>;
    close FP;

    $data = fix_unicode( $data );

    # Ensure exactly one trailing newline.
    $data =~ s/\n*$/\n/os;

    # Write the file out.
    open FP, '>', $file;
    binmode( FP, ':utf8' );
    print FP $data;
    close FP;
}

sub fix_unicode {
    my ( $str ) = @_;

    # Regular expressions to match the full UTF-8 spec and the Hangul part of the UCS-2 part of UTF-16BE.
    my $ascii = qr/[\x00-\x7E]/;
    my $utf8  = qr/
          [\x00-\x7E]                        # ASCII
        | [\xC2-\xDF][\x80-\xBF]             # non-overlong 2-byte
        |  \xE0[\xA0-\xBF][\x80-\xBF]        # excluding overlongs
        | [\xE1-\xEC\xEE\xEF][\x80-\xBF]{2}  # straight 3-byte
        |  \xED[\x80-\x9F][\x80-\xBF]        # excluding surrogates
        |  \xF0[\x90-\xBF][\x80-\xBF]{2}     # planes 1-3
        | [\xF1-\xF3][\x80-\xBF]{3}          # planes 4-15
        |  \xF4[\x80-\x8F][\x80-\xBF]{2}     # plane 16
    /x;
    my $ucs2 = qr/
          [\x7F-\xD7\xE0-\xFF][\x00-\xFF]    # 2-byte
    /x;
    my $ucs2_hangul = qr/
          [\xAC-\xD7][\x00-\xFF]    # 2-byte
    /x;
    my $cp949 = qr/
           \xA1\xA6   # Horizontal Ellipsis
          |\xA1\xAE   # Single Turned Comma Quotation Mark
          |\xA1\xAF   # Single Comma Quotation Mark
          |\xA3\xC7   # Fullwidth Capital G
          |\xA5\xB0   # Roman Numeral One
          |\xA5\xB1   # Roman Numeral Two
          |\xA5\xB2   # Roman Numeral Three
          |\xA5\xB3   # Roman Numeral Four
          |\xA5\xB4   # Roman Numeral Five
    /x;
    my $cp1252 = qr/
          #[\xA0\B0\xBA\xC0-\xD6\xD9-\xDD\xE0-\xF6\xF9-\xFF] # commonly used diacriticals, this overlaps with Hangul (U+AC00 to U+D7A3)
          [\x80-\xFF]
    /x;
    my $iso8859 = qr/
          #[\xA0\B0\xBA\xC0-\xD6\xD9-\xDD\xE0-\xF6\xF9-\xFF] # commonly used diacriticals, this overlaps with Hangul (U+AC00 to U+D7A3)
          [\xA0-\xFF]
    /x;

    # Eat the leading BOM, if any.
    $str =~ s/^[\xFF\xFE]{2}//gos;

    # Convert CRLF to just LF.
    $str =~ s/\r\n/\n/gos;

    # Convert bare CR to LF.
    $str =~ s/\r/\n/gos;

    $str = join "\n", map {

        # Eat trailing whitespace.
        s/\s+$//os;

        # UCS-2 mode: Convert sequences of Hangul until we run out of them.
        # This only triggers if there are at least two consecutive Hangul
        # characters in the line, to avoid accidentally converting CP-1252
        # data.
        if ( /^$utf8*((?!$utf8)$ucs2_hangul*$utf8*)*(?!$utf8)$ucs2_hangul{2}/os ) {
            my $out = '';
            while ( /\G(?=.)($ascii*)($ucs2*)/gos ) {
                $out .= Encode::encode( 'utf8', Encode::decode( 'UTF-8', "$1" ) . Encode::decode( 'UTF-16BE', "$2" ) );
            }
            $_ = $out;
        }

        # Windows Code Page 949 mode: Convert CP-949 until we run out of it.
        # CP-949 is huge. Only a few characters are mapped.
        # CP-949: ftp://ftp.unicode.org/Public/MAPPINGS/VENDORS/MICSFT/WindowsBestFit/bestfit949.txt
        if ( /^$utf8*(?!$utf8)$cp949/os ) {
            while ( s/(^$utf8*)(?!$utf8)($cp949+)/Encode::encode( 'utf8', Encode::decode( 'UTF-8', "$1" ) . Encode::decode( 'cp949', "$2" ) )/eos ) { }
        }

        # Windows Code Page 1252 mode: Convert CP-1252 until we run out of it.
        if ( /^$utf8*(?!$utf8)$cp1252/os ) {
            while ( s/(^$utf8*)(?!$utf8)($cp1252+)/Encode::encode( 'utf8', Encode::decode( 'UTF-8', "$1" ) . Encode::decode( 'cp1252', "$2" ) )/eos ) { }
        }

        $_;
    } split "\n", $str;

    Encode::decode( 'UTF-8', $str );
}


sub check_patch_list {
    print 'Checking patch list... ';
    my $patches = [ grep {$_} map { m{^(\d+)\s+([^/\s]+)$} && $2 } split /[\r\n]+/, $ua->get( $opt->{list_url} )->content ];
    printf "done. Found [%d] patches.\n", scalar @$patches;
    return $patches;
}

sub compare_local_and_ftp_files {
        my ($self, $patches) = @_;
        print "Checking whether files have changed on the server.\n";
        foreach ( @$patches ) {
        my $file = "$opt->{download_dir}/$_";

        next if !-f $file;

        if ( ftp_data( $_ )->{size} && -s $file != ftp_data( $_ )->{size} ) {
            print "File [$_] has changed size. Renaming to [$_.bak] and downloading a new copy.\n";
            rename $file => "$file.bak";
            unlink "$file.yml";
        } elsif ( ftp_data( $_ )->{time} && ftp_data( $_ )->{time} != ( stat( $file ) )[9] ) {
            print "File [$_] has changed modification date. Renaming to [$_.bak] and downloading a new copy.\n";
            rename $file => "$file.bak";
            unlink "$file.yml";
        }
    }
}

sub download_ftp_files {
    my ($self, $recent_patches, $current_dir) = @_;
    my $downloaded = 0;
    foreach ( reverse @$recent_patches ) {
        my $url  = "$opt->{download_base_url}/$_";
        my $file = $current_dir."$opt->{download_dir}/$_";

        next if -f $file;

        unlink "$file.yml";

        print "Downloading file [$file]... ";
        ftp->get( $_ => $file );
        print "done.\n";

        my $time = ftp_data( $_ )->{time};
        utime $time, $time, $file;
        $downloaded++;
    }
    print "No new files found.\n" if !$downloaded;
}

sub extract_all_rgz_files {
    my ($self, $recent_patches, $current_dir) = @_;
    # Extract file lists from each rgz.
    my $download_dir = $current_dir . $opt->{'download_dir'};
    foreach ( reverse @$recent_patches ) {
        my $file = $current_dir."$opt->{download_dir}/$_";

        next if $file !~ /\.rgz$/o;
        next if !-f $file;
        next if -f "$file.yml";

        # Extract file list.
        print "[SCRIPT] Extracting ".$file.".\n";

        my $data = backticks( $current_dir.'/scripts/rgz.pl', $download_dir, $file, '-x', '--verbose' );
        my @lines = split /\n/, $data;

        my $files = { map { /^f\s+(\d+)\s+(.*)$/o ? ( $2 => $1 ) : () } @lines };
        YAML::Syck::DumpFile( "$file.yml", $files );
    }
}

sub extract_all_gpf_files {
    my ($self, $recent_patches, $current_dir) = @_;
    
    # Extract file lists from each gpf.
    my $download_dir = $current_dir . $opt->{'download_dir'};
    foreach ( reverse @$recent_patches ) {
        my $file = $current_dir."$opt->{download_dir}/$_";
        next if $file !~ /\.g[pr]f$/o;
        next if !-f $file;
        next if -f "$file.yml";
        
        # Extract file list.
        
        my $data = backticks( $current_dir.'/scripts/grf_extract/grf_extract_64', $file );
        my @lines = split /\n/, $data;
        shift @lines;
        shift @lines;
        my $files = { map {/^  (.*) \((\d+)\)/o} @lines };
        YAML::Syck::DumpFile( "$file.yml", $files );
    }

    # Merge the gpf file lists together to find the latest version of each file.
    my $latest = {};
    foreach my $p ( reverse @$recent_patches ) {
        my $yml = $current_dir."$opt->{download_dir}/$p.yml";

        next if !-f $yml;

        my $files = YAML::Syck::LoadFile( $yml );
        $latest->{$_} ||= $p foreach keys %$files;
    }
    YAML::Syck::DumpFile( $current_dir."$opt->{download_dir}/latest.yml", $latest );

    # Extract the latest version of interesting files.
    my $extracted = eval { YAML::Syck::LoadFile( $current_dir."$opt->{download_dir}/extracted_files.yml" ) } || {};
    my $extract_dir = $current_dir."$opt->{download_dir}/extracted_files";
    mkdir $extract_dir if !-d $extract_dir;
    foreach ( sort keys %$latest ) {
        next if !/\.(txt|lua|lub|gat|gnd|rsw)$/;

        my ( $base ) = m{([^/\\]+)$};
        next if $extracted->{$_} && $latest->{$_} eq $extracted->{$_} && -f "$extract_dir/$base";

        if ( $latest->{$_} =~ /\.g[pr]f$/ ) {
            print "[SCRIPT] Extracting ".$latest->{$_}.".\n";
            system $current_dir.'/scripts/grf_extract/grf_extract_64', $current_dir."$opt->{download_dir}/$latest->{$_}", $_ => "$extract_dir/$base";
        } elsif ( $latest->{$_} =~ /\.rgz$/ ) {
            system  $current_dir.'/scripts/rgz.pl',  $download_dir, '-x', $current_dir."$opt->{download_dir}/$latest->{$_}", $_ => "$extract_dir/$base";
        }

        # GRF files typically have a screwed up mix of UCS-2 and UTF-8. Fix them.
        fix_unicode_file( "$extract_dir/$base" ) if $base =~ /txt$/;

        $extracted->{$_} = $latest->{$_};
    }
}

1;