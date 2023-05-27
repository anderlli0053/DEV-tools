#!perl -w -- (emacs/sublime) -*- tab-width: 4; mode: perl -*-

# Script Summary

=head1 NAME

update-repo - Update repository from mirror

=head1 VERSION

This document describes C<update-repo> ($Version: 0.1_0 $).

=head1 SYNOPSIS

update-repo [B<<option(s)>>]

=begin HIDDEN-OPTIONS

Options:

		--version       version message
	-?, --help          brief help message

=end HIDDEN-OPTIONS

=head1 OPTIONS

=over

=item --version

=item --usage

=item --help, -?

=item --man

Print the usual program information

=back

=head1 DESCRIPTION

B<update-repo> will update the mirrored repository and update the current repository, if needed.

=cut

# spell-checker:ignore (names) CPAN
# spell-checker:ignore (perl) chdir hireswallclock mkpath splitpath sprintf strftime timediff wallclock wantarray
# spell-checker:ignore (modules/vars) Getopt compat datetime filehandle minlevel optdefs retval EACHLINE
# spell-checker:ignore (shell/CMD) LocalAppData
# spell-checker:ignore () substr tempfile tracef debugf infof maint colorstrip
# ref: http://stackoverflow.com/questions/240661/whats-the-best-practice-for-changing-working-directories-inside-scripts/241489#241489

# ToDO: logging
# https://metacpan.org/pod/Log::Any
# levels: trace, debug, info (inform), notice, warning (warn), error (err), critical (crit, fatal), alert, emergency
# https://metacpan.org/pod/Log::Any::For::Std
# https://metacpan.org/pod/Log::Any::App

# minimum perl version: needed for decent Unicode support, minimum tested version
use v5.8.8; our $PERL_MIN_VERSION; BEGIN{ $PERL_MIN_VERSION = '5.008008' };

use strict;
use warnings;
use diagnostics;
use English;

use version 0.77 (); our $VERSION = version->qv('0.1_0'); # VERSION: major.minor.release[.build]]

BEGIN { my %timers; sub mark {
    return if not eval { use Benchmark ':hireswallclock'; 1 };
    return (wantarray ? %timers : \%timers) if wantarray;
    if (defined (my $name = shift)) { my $timer_ref = ($timers{$name} ||= {});
        ${$timer_ref}{stop} = ${$timer_ref}{start} ? ( ${$timer_ref}{stop} ||= Benchmark->new ) : 0;
        ${$timer_ref}{start} ||= Benchmark->new;
        ${$timer_ref}{diff}{raw} = ${$timer_ref}{stop} ? ( ${$timer_ref}{diff}{raw} ||= Benchmark::timediff(${$timer_ref}{stop},${$timer_ref}{start}) ) : 0;
        if (${$timer_ref}{diff}{raw}) { my @times = @{${$timer_ref}{diff}{raw}}; ${$timer_ref}{diff}{calc} = [ $times[0], $times[1]+$times[3], $times[2]+$times[4], $times[1]+$times[3]+$times[2]+$times[4] ]; }
        ${$timer_ref}{duration} = ${$timer_ref}{diff}{raw} ? ( ${$timer_ref}{duration} ||=  sprintf '%0.6f wallclock secs (%0.3f usr + %0.3f sys = %0.3f CPU)', @{${$timer_ref}{diff}{calc}} ) : 0;
        }
    return;
}}
BEGIN { mark('*total') }
BEGIN { mark('init') }
BEGIN { mark('init:load_modules'); }

use File::Glob;
use File::Spec;
use Getopt::Long qw(:config bundling bundling_override gnu_compat no_getopt_compat);
use List::Util; # released within CORE as of 5.007003
use Pod::Usage;
use Term::ANSIColor; $Term::ANSIColor::EACHLINE = "\n"; $^O eq 'MSWin32' && eval {require Win32::Console::ANSI};

# required non-CORE modules
BEGIN {
use Module::CoreList;
my $ME = do {$_ = (File::Spec->splitpath($0))[2]; s/(?<=.)\.[^.]*$//; $_};
my @modules = qw[ DateTime::Format::Flexible Config::General PadWalker Data::Dump Log::Any Log::Any::Adapter Log::Any::Adapter::Dispatch Log::Dispatch File::chdir IPC::Run3 Path::Iterator::Rule Path::Tiny ];
my @missing_modules = qw();
foreach my $module (@modules) {
    if (not eval "require $module; 1;") { push @missing_modules, $module; }
    if (Module::CoreList::is_core($module, undef, $PERL_MIN_VERSION)) { warn "$ME: WARNING: '$module' is CORE; testing for availability is not necessary\n"; }
    }
if (@missing_modules) {
    warn "$ME: ERROR: Missing required modules (to install, use `cpan @missing_modules`)\n";
    exit -1;
    }
}
use Config::General;   # config file keys will all be lowercase
use File::chdir;            # improved CWD for localization uses
use IPC::Run3;
use Log::Any;
use Log::Any::Adapter ('Stderr', log_level => 'warn');
use Log::Any::Adapter::Util qw//;
use Log::Any::Adapter::Dispatch;
use Log::Dispatch;
use Path::Iterator::Rule;
use Path::Tiny;

mark('init:load_modules');

###

mark('init:logging');
my $ME = path($0)->basename(qr/(?<=.)\.[^.]*/);
my $ME_dir = path($0)->parent;

my $colorize = 0;
my %color = ( success => 'green', debug => 'yellow', info => 'cyan', notice => q//, warning => 'magenta', error => 'red' );

my %log = ( default => { level => 'debug' }, console => { level => 'info' } );

my $log = Log::Any->get_logger(category => $ME);

my @log_dir_default_locations = ( '~/.logs', '~/.log' );
if ($^O eq 'MSWin32' && defined $ENV{LOCALAPPDATA}) { @log_dir_default_locations = ( @log_dir_default_locations, "$ENV{LOCALAPPDATA}/logs", "$ENV{LOCALAPPDATA}/log" ) };
@log_dir_default_locations = ( @log_dir_default_locations, "$ME_dir" );
my $log_file = path(List::Util::first { -e path($_)->child(q{.}) } @log_dir_default_locations)->child("$ME.log");

my $s_colorize = sub { my %p = @_; return colorize($p{level}, $p{message}) };
my $s_prefix_timestamp = sub { use DateTime; use Time::HiRes; my %p = @_; return '['.DateTime->from_epoch(epoch=>Time::HiRes::time)->set_time_zone('local')->strftime('%FT%H:%M:%S.%3N%z').'] '.$p{message} };
my $s_prefix_ME = sub { my %p = @_; return $ME.': '.$p{message} };
my $s_prefix_id = sub { my %p = @_; return "$ME ($PID)".': '.$p{message} };
my $s_prefix_level = sub { my %p = @_; return (uc $p{level}).': '.$p{message} };
my $s_colorstrip = sub { use Term::ANSIColor; my %p = @_; return Term::ANSIColor::colorstrip($p{message}) };
my $s_newline = sub { my %p = @_; return $p{message}."\n"; };
my $s_colorize_or_prefix_level = sub { my %p = @_; if ($colorize) { $p{message} = &$s_colorize(%p) } else { $p{message} = &$s_prefix_level(%p)}; return $p{message} };
sub s_tee { my $level = lc $_[0]; my $fh = exists($_[1]) ? $_[1] : \*STDOUT; return sub { my %p = @_; if ($p{level} eq $level) { print $fh $p{message}; $p{message} = q// }; return $p{message} }; }
sub s_minlevel { my $name = exists($_[0]) ? lc $_[0] : 'default'; return sub { my %p = @_; my $min_level = exists($log{$name}{level}) ? $log{$name}{level} : 'debug'; if (Log::Any::Adapter::Util::numeric_level($p{level}) > Log::Any::Adapter::Util::numeric_level($min_level)) { $p{message} = q// }; return $p{message} }; }
# ToDO: look into https://metacpan.org/pod/Log::Dispatch::FileWriteRotate as a replacement for Log::Dispatch::File
my $dispatcher = Log::Dispatch->new(
    outputs => [
        [ 'File', name => 'file', min_level => 'debug', filename => "$log_file", mode => 'append', callbacks => [ $s_colorstrip, $s_prefix_level, $s_prefix_id, $s_prefix_timestamp, $s_newline, s_minlevel(), ] ],
        [ 'Screen', name => 'console', min_level => 'debug', stderr => 1, callbacks => [ $s_colorize_or_prefix_level, $s_newline, s_minlevel('console'), s_tee('notice'), ], ],
        ],
    # callbacks => $s_prefix_timestamp,
    );
Log::Any::Adapter->set('Dispatch', dispatcher => $dispatcher );

$log->debug('*** starting');
mark('init:logging');

###

mark('init:variables');
$log->debug('initializing');

my $repo_path = $ME_dir->parent;
my $mirror_path = $repo_path->child('.#mirror');

my $in_mirror_source = './bucket';
my $in_repo_dest = '.';

my $commit_summary_length = 80;

mark('init:variables');

###

mark('init:args_opts');

@ARGV = Win32::CommandLine::argv() if eval { require Win32::CommandLine };

{ my @ARGV = @ARGV; $ARGV{trace} && $log->trace( dump_var( q{@ARGV} ) ); }

# options
my %ARGV = ();
# * defaults
$ARGV{color} = 'auto';
# * build color and log options
my @color_optdefs;
@color_optdefs = ('color:s');
foreach (keys %color) { push @color_optdefs, "color-$_|color.$_=s" => sub { my ($name, $val) = @_; $name =~ s/^color.//i; $color{lc $name}=lc $val;} };
my @log_optdefs;
@log_optdefs = ('quiet:s' => sub { $log{console}{level} = 'warning' if opt_bool_normalize($_[1]) }, 'silent:s' => sub { $log{console}{level} = 'error' if opt_bool_normalize($_[1]) }, 'verbose:s' => sub { $log{console}{level} = 'info' if opt_bool_normalize($_[1]) }, 'debug:s' => sub { $log{console}{level} = 'debug' if opt_bool_normalize($_[1]) }, 'trace:s' => sub { if (opt_bool_normalize($_[1])) { $ARGV{trace}=1; $log{console}{level} = 'debug' } });
foreach (keys %log) { push @log_optdefs, "log-$_-level|log.$_.level=s" => sub { my ($name, $val) = @_; $name =~ s/^log.(.*).level/$1/i; $name = lc $name; $val = lc $val; $log{$name}{level}=lc $val; if ($val eq 'trace') { $ARGV{trace} = 1} } };
my @optdefs = (@color_optdefs, @log_optdefs, "force:s" => sub { $ARGV{$_[0]} = opt_bool_normalize($_[1]) });
my @help_optdefs = ('help|h|?|usage', 'man', 'version|ver|v',);
# * load & parse config file
my @config_file_default_locations = ( "$ME_dir/$ME.config", "$ME_dir/$ME.conf", "$ME_dir/$ME.cfg", "~/.$ME.config", "~/.$ME.conf", "~/.$ME.cfg", "~/.config/$ME.config", "~/.config/$ME.conf", "~/.config/$ME.cfg", "~/.config/.$ME.config", "~/.config/.$ME.conf", "~/.config/.$ME.cfg", );
my $config_file = List::Util::first { -e path($_)->child(q{.}) } @config_file_default_locations;
if (defined $config_file) { $config_file = path($config_file)->child(q{.}) };
my @config_opts;
my %config;
my $s_config_to_args = sub {
    my $prefix = q//; $prefix = q{-} if $_[0]=~/^[^-]/; $prefix = q{--} if $_[0]=~/^[^-][^-]/;
    my $suffix = q//; $suffix = qq{=$_[1]} if defined $_[1];
    push @config_opts, ( $prefix.$_[0].$suffix ) if not $_[0]=~/^[-][-]?$/;
    return (1, @_)
    };
if (defined $config_file and -s $config_file) { Config::General->new(-ConfigFile => $config_file, -AutoTrue => 1, -LowerCaseNames => 1, -NormalizeValue => sub{ my $v = shift; $v = 'true' if not defined $v; return 'T' }, -Plug => { pre_parse_value => $s_config_to_args }) };
Getopt::Long::GetOptionsFromArray (do { my @t = @config_opts; \@t }, \%ARGV, @optdefs) or pod2usage(2);
# * load & parse environment defaults ($ME.'_OPTIONS', then, if not found, check $ME.'_OPTS')
(my $env_options_basename = uc $ME) =~ s/[^_A-Z0-9]/_/;
my $env_options_name = $env_options_basename.'_OPTIONS';
$env_options_name = $env_options_basename.'_OPTS' if not exists($ENV{$env_options_name});
$env_options_name = q// if not exists($ENV{$env_options_name});
my $env_options = $ENV{$env_options_name};
$env_options = q// if not defined $env_options;
Getopt::Long::GetOptionsFromString ($env_options, \%ARGV, @optdefs) or pod2usage(2);
# * ARGV
Getopt::Long::GetOptions (\%ARGV, @optdefs, @help_optdefs) or pod2usage(2);

#

if (defined $log_file) { $log->debug(qq{log file located at "$log_file"}) };
if (defined $config_file) { $log->debug(qq{configuration loaded from "$config_file"}) };
$ARGV{trace} && $log->trace( dump_var(qw(@config_file_default_locations)) );
$ARGV{trace} && $log->trace( dump_var(qw($config_file)) );
if ($env_options ne q//) { $log->debug("environment options loaded from \$ENV{$env_options_name}") };
$ARGV{trace} && $log->trace( dump_var(qw($env_options_name)) );

#

$ARGV{color} = lc $ARGV{color};
$colorize = opt_bool_normalize( $ARGV{color} );
if (($ARGV{'color'} eq 'auto') && !-t STDOUT) { $colorize = 0 };
if ($colorize && $^O eq 'MSWin32' && not defined $Win32::Console::ANSI::VERSION) {
    eval {require Win32::Console::ANSI};
    if (not defined $Win32::Console::ANSI::VERSION) {
        $colorize = 0;
        %color = ();
        $log->warn('Output colorization is enabled, but the required Win32 module is missing (to install, use `cpan Win32::Console::ANSI`).');
        }
    }
if (!$colorize) { %color = () };

#

mark('init:args_opts');
mark('init');

# * help / usage
pod2usage(-verbose => 99, -sections => '__NONE__', -message => "$ME $::VERSION") if $ARGV{'version'};
pod2usage(1) if $ARGV{'help'};
pod2usage(-verbose => 2) if $ARGV{'man'};

###

$ARGV{trace} && $log->trace( dump_var(qw($ME)) );
$ARGV{trace} && $log->trace( dump_var(qw($ME_dir)) );
$ARGV{trace} && $log->trace( dump_var(qw($repo_path)) );
$ARGV{trace} && $log->trace( dump_var(qw($mirror_path)) );
$ARGV{trace} && $log->trace( dump_var(qw($in_mirror_source)) );
$ARGV{trace} && $log->trace( dump_var(qw($in_repo_dest)) );

$ARGV{trace} && $log->trace( dump_var(qw(@config_opts)) );
$ARGV{trace} && $log->trace( dump_var(qw($env_options)) );
$ARGV{trace} && $log->trace( dump_var(qw(%ARGV)) );

$ARGV{trace} && $log->trace( dump_var(qw(%log)) );
$ARGV{trace} && $log->trace( dump_var(qw(%color)) );

# #
# $log->trace('trace text');
# $log->debug('debug text');
# $log->info('info text');
# $log->notice('notice text');
# $log->notice( colorize('success', 'notice:success text') );
# $log->warn('warning text');
# $log->error('error text');

my $output;

mark('network_pull');
mark('network_pull:update_repo');
$log->debug( 'Clean and update local repository ... started' );
my $repo_branch;
my ($initial_repo_id, $updated_repo_id);
my $repo_updated = 0;
{
    local $CWD = $repo_path;  # NOTE: must be absolute path if changing between volumes (eg, `File::Spec->rel2abs($mirror_path)`)?; ToDO: add issue noting *intermittent* GPF when chdir from 'd:\...' to 'c:\...' unless target is absolute path @ https://github.com/dagolden/File-chdir/issues
    # NOTE: `D:\...>perl -e "use File::chdir; { local $CWD='C:..\\.mirror'; };"` DOESN'T reproduce the issue
    chomp( $repo_branch = Term::ANSIColor::colorstrip(`git rev-parse --quiet --abbrev-ref HEAD`) ); ## note: detached HEAD state => retval = 'HEAD'
    $log->debug( dump_var( q{$repo_branch} ) );
    $log->info( qq{Active local repository branch is "${repo_branch}"} );
    chomp( $initial_repo_id = Term::ANSIColor::colorstrip( `git rev-parse --quiet HEAD` ) );
    $log->debug( dump_var( q{$initial_repo_id} ) );
    $output = Term::ANSIColor::colorstrip(`git clean --quiet -fd`); $ARGV{trace} && $log->trace( $output );
    $output = Term::ANSIColor::colorstrip(`git pull --quiet`); $ARGV{trace} && $log->trace( $output );
    chomp( $updated_repo_id = Term::ANSIColor::colorstrip(`git rev-parse --quiet HEAD`) );
    $log->debug( dump_var( q{$updated_repo_id} ) );
}
$repo_updated = ($updated_repo_id ne $initial_repo_id);
$log->debug( dump_var( q{$repo_updated} ) );
$log->info( 'Local repository'.($repo_updated ? ' changes pulled from origin remote':' already up-to-date with origin remote') );
mark('network_pull:update_repo');

mark('network_pull:update_mirror');
$log->debug( 'Update mirror submodule ... started' );
my ($initial_mirror_id, $updated_mirror_id);
my $mirror_updated = 0;
my $last_mirror_commit_date;
my $mirror_commit_date;
my $interval_log = q//;
my $interval_log_summary = q//;
{
    local $CWD = $mirror_path;  # NOTE: must be absolute path if changing between volumes (eg, `File::Spec->rel2abs($mirror_path)`)?; ToDO: add issue noting *intermittent* GPF when chdir from 'd:\...' to 'c:\...' unless target is absolute path @ https://github.com/dagolden/File-chdir/issues
    # NOTE: `D:\...>perl -e "use File::chdir; { local $CWD='C:..\\.mirror'; };"` DOESN'T reproduce the issue
    $last_mirror_commit_date = q{1970-01-01};  # earliest possible time (within the unix epoch)
    chomp( $last_mirror_commit_date = Term::ANSIColor::colorstrip(`git --no-pager log -1 --date=iso --format="%cd"`) );
    $log->debug( dump_var( q{$last_mirror_commit_date} ) );
    chomp( $initial_mirror_id = Term::ANSIColor::colorstrip( `git rev-parse --quiet HEAD` ) );
    $log->debug( dump_var( q{$initial_mirror_id} ) );
    $output = Term::ANSIColor::colorstrip(`git fetch --quiet`); $ARGV{trace} && $log->trace( $output );
    $output = Term::ANSIColor::colorstrip(`git checkout --quiet origin/master`); $ARGV{trace} && $log->trace( $output );
    chomp( $updated_mirror_id = Term::ANSIColor::colorstrip(`git rev-parse --quiet HEAD`) );
    $log->debug( dump_var( q{$updated_mirror_id} ) );

    $mirror_updated = ($updated_mirror_id ne $initial_mirror_id);
    $log->debug( dump_var( q{$mirror_updated} ) );

    $mirror_commit_date = $last_mirror_commit_date;
    if ($mirror_updated) {
        my $log_date = DateTime::Format::Flexible->parse_datetime( $last_mirror_commit_date )->add( seconds => 1 )->strftime(q{%FT%H:%M:%S%z});
        $log->trace( dump_var( q{$log_date} ) );
        $interval_log = Term::ANSIColor::colorstrip(`git --no-pager log --pretty=format:"%h @ %cI  %s" --no-merges --since "$log_date" -- $in_mirror_source`);
        $interval_log =~ s/(\d{4}-\d\d-\d\d)(?:T|\s+)(\d\d\:\d\d:\d\d)\s*([+-]\d\d:?\d\d)/$1.$2$3/gm; # cosmetic reformat of date/time fields
        $interval_log_summary = join( '; ', (split /\n/, Term::ANSIColor::colorstrip(`git --no-pager log --pretty=format:"%s" --no-merges --since "$log_date" -- $in_mirror_source`)));
        chomp( $mirror_commit_date = Term::ANSIColor::colorstrip(`git --no-pager log -1 --date=iso --format="%cd"`) );
        }
    if ($interval_log eq q//) { $interval_log_summary = '* no changes; (mirror code changes only)'; }
    $log->debug( dump_var( q{$interval_log} ) );
    $log->debug( dump_var( q{$mirror_commit_date} ) );
}
$log->info( 'Mirror submodule'.($mirror_updated ? ' changes pulled from upstream remote ('.scalar(split /\n/, $interval_log).' commits pulled)':' already up-to-date with upstream remote') );
mark('network_pull:update_mirror');
mark('network_pull');

if ( $mirror_updated || $ARGV{force} ) {
    if ( !$mirror_updated ) {
        $interval_log = '* forced commit; (no mirror changes)';
    }

    mark('io');
    my @files;

    # erase all repo files except ., .., .git*, .#mirror, and the directory containing this script
    mark('io:scrub_repo');
    $log->debug( 'Cleaning local repository ... started' );
    @files = grep { !/(?:\.|\.\.|\.git.*|\.#mirror)$/ and index($ME_dir->absolute, $_) != 0 } File::Glob::bsd_glob $repo_path->absolute.'/{.,}*';
    my $no_removed_dirs = 0;
    foreach my $file (@files) {
        $ARGV{trace} && $log->trace( 'removing '.$file );
        -d $file and do {path($file)->remove_tree; $no_removed_dirs++} or path($file)->remove;
    }
    $log->infof( 'Local repository scrubbed (%s file%s, including %s director%s, removed)', scalar(@files), (scalar(@files) == 1 ? q//:'s'), $no_removed_dirs, ($no_removed_dirs == 1 ? 'y':'ies') );
    mark('io:scrub_repo');

    my $file_rule;
    my $source_dir;

    # copy all files recursively from $mirror_source (default == $mirror_path) ignoring .git* files to REPO_DIR (default == '.')
    mark('io:copy_mirror');
    $log->debug( 'Copying from mirror ... started' );
    $file_rule = Path::Iterator::Rule->new->file;
    $source_dir = path($mirror_path)->child($in_mirror_source);
    @files = $file_rule->all( $source_dir, {relative => 1} );
    foreach my $file (@files) {
        # # copy
        my $t = $repo_path->child(path($file));
        $ARGV{trace} && $log->trace( "$file => $t" );
        $t->parent->mkpath;
        $source_dir->child($file)->copy($repo_path->child(path($file)->child(q{.})));
    }
    $log->infof( 'Copied %s file%s from mirror submodule into local repository', scalar(@files), (scalar(@files) == 1 ? q//:'s') );
    mark('io:copy_mirror');

    # copy .#maint/file_overrides/* to REPO_DIR (rename any collisions as filename.(mirror).ext)
    ## $source_dir = (($ME_dir, relative to $repo_path) => 1st topmost dir); $src = $source_dir/README*
    mark('io:copy_overrides');
    $log->debug( 'Copying from overrides ... started' );
    $file_rule = Path::Iterator::Rule->new->file;
    $source_dir = path($ME_dir)->child('file-overrides');
    @files = $file_rule->all( $source_dir, {relative => 1} );
    my $no_renamed_files = 0;
    foreach my $file (@files) {
        # # copy
        my $t = $repo_path->child(path($file));
        $ARGV{trace} && $log->trace( "$file => $t" );
        $t->parent->mkpath;
        if (-e $t) {
            my $basename = $t->basename(qr/(?<=.)\.[^.]*/);
            my $suffix = $t->basename; $suffix =~ s/^\Q$basename\E//;
            my $new_name = $t->parent->child($basename.'.(mirror)'.$suffix);
            $t->move($new_name);
            $no_renamed_files++;
            $ARGV{trace} && $log->trace( "file renamed ($t => $new_name)" );
        }
        $source_dir->child($file)->copy($repo_path->child(path($file)->child(q{.})));
    }
    $log->infof( 'Copied %d override file%s (renaming %s conflicting file%s)', scalar(@files), (scalar(@files) == 1 ? q//:'s'), $no_renamed_files, ($no_renamed_files == 1 ? q//:'s')  );
    mark('io:copy_overrides');
    mark('io');

    mark('network_push');
    if ( $mirror_updated || $ARGV{force}) {
        $log->debugf( 'Committing changes to local repository %s... started', $mirror_updated ? '(forced) ':q// );

        local $CWD = $repo_path;  # NOTE: must be absolute path if changing between volumes (eg, `File::Spec->rel2abs($mirror_path)`)?; ToDO: add issue noting *intermittent* GPF when chdir from 'd:\...' to 'c:\...' unless target is absolute path @ https://github.com/dagolden/File-chdir/issues

        my $tag = DateTime->now()->strftime('0.%Y.%m%d.%H%M');
        my $tempfile = Path::Tiny->tempfile( TEMPLATE => "$ME.($PID).XXXXXXXX", SUFFIX => '.txt' );
        my $fh = $tempfile->filehandle('>');

        my $commit_summary = "update:($tag): $interval_log_summary";
        if ((length $commit_summary) > $commit_summary_length) { my $ellipsis='...'; $commit_summary = (substr $commit_summary, 0, $commit_summary_length-(length $ellipsis)) . $ellipsis; }

        my $commit_msg = "$commit_summary\n\n* mirror of github.com/ScoopInstaller/Main:bucket".(($interval_log ne q//) ? "\n\n.# Summary (changes by commit)\n\n$interval_log":q//);

        $ARGV{trace} && $log->trace( dump_var('$commit_msg') );

        print $fh $commit_msg;

        $log->debug( dump_var(q/$tag/) );
        $log->debug( dump_var(q/$tempfile/) );

        $output = Term::ANSIColor::colorstrip(`git add -A .`); $ARGV{trace} && $log->trace( $output );
        $output = Term::ANSIColor::colorstrip(`git commit --quiet --file="$tempfile"`); $ARGV{trace} && $log->trace( $output );
        $output = Term::ANSIColor::colorstrip(`git tag "$tag"`); $ARGV{trace} && $log->trace( $output );

        $log->info( 'Update committed to local repository' );
    }
    mark('network_push');
}

$log->debug('normal completion');

mark('*total');
# ref: http://perlmaven.com/how-to-sort-a-hash-in-perl @@ https://archive.is/mtrNc
my %timers = mark();
if (%timers) {
    foreach (sort { $timers{$a}{start}->real <=> $timers{$b}{start}->real or $a cmp $b } keys %timers) {
        if ( m/^.*?:/msx ) {
            $ARGV{trace} && $log->tracef( 'duration (%s): '.$timers{$_}{duration}, $_ );
        } else {
            $log->debugf( 'duration (%s): '.$timers{$_}{duration}, $_ );
            }
        }
    $log->infof( 'duration: '.$timers{'*total'}{duration} );
    };

####

sub sys_execute {
    my (@cmd_and_args) = @_;
    my $return_code  = 0;
    my $error_string = q//;
    # my $status = system(@cmd_and_args);
    IPC::Run3::run3( \@cmd_and_args, { return_if_system_error => 0 } );
    my $status = $?;
    if ($status == -1) {
        $return_code  = -1;
        $error_string = "Failed to execute due to $!\n";
    }
    elsif ($status & 127) {
        $return_code = $status & 127;
        $error_string = sprintf('Child died with signal %d, %s core dump',
                                $return_code, ($status & 128) ? 'with' : 'without');
    }
    else {
        $return_code = $status >> 8; if ( $return_code == 255 ) { $return_code = -1; }
        $error_string = q//;
    }
    return ($return_code, $error_string);
}

sub dump_var
{
    use Data::Dump;
    use PadWalker;
    my $name = $_[0];
    my $val = undef;
    my $ref;
    my $ref_type;
    $ref = PadWalker::peek_our(1)->{ $name };
    if (not defined $ref) { $ref = PadWalker::peek_my(1)->{ $name } };
    if (defined $ref) {
        $ref_type = ref($ref);
        if ( $ref_type eq 'SCALAR' ) { $val = Data::Dump::dump( ${$ref} ) };
        if ( $ref_type eq 'ARRAY' ) { $val = Data::Dump::dump( @{$ref} ) };
        if ( $ref_type eq 'HASH' ) { $val = Data::Dump::dump( %{$ref} ) };
        if ( $ref_type eq 'CODE' ) { $val = Data::Dump::dump( &{$ref} ) };
        if ( $ref_type eq 'GLOB' ) { $val = Data::Dump::dump( *{$ref} ) };
        if (not defined $val) { $val = Data::Dump::dump ($ref) };
        }
    if (not defined $val) { $val = 'undef' };
    $val =~ s/\n(\s*\s|)//mg;
    return "$name = $val";
}

sub colorize { use Term::ANSIColor; my $color = exists($color{lc $_[0]})?$color{lc $_[0]}:q//; if ($color eq q//) { return $_[1] } else { return Term::ANSIColor::colored([$color], $_[1]) } }

sub opt_bool_normalize { my $b = lc shift; if ($b eq q//) {$b = 1}; if ($b eq 'f' || $b eq 'false' || $b eq 'off' || $b eq 'never' || $b eq 'no') {$b = 0}; if ($b) {$b = 1} else {$b = 0}; return $b }
