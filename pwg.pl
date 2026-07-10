#!/usr/bin/env perl
# =============================================================================
#  NAME:        pwg.pl
#
#  DESCRIPTION: Perl script to generate random passwords using a customizable
#               formula of words, colors, digits, and separator characters.
#               
#  VERSION:     v2.0
#
#  GITHUB: https://github.com/r3v/pwg
#
#  USAGE:
#       pwg.pl
#       pwg.pl -f FORMULA
#
#  FORMULA CODES:
#       W = uppercase word
#       w = lowercase word
#       C = uppercase color
#       c = lowercase color
#       n = random number; repeat for more digits, zero-padded (nn, nnn, etc).
#           Case insensitive (n or N).
#       Any other character in the formula is used as a literal separator.
#       Allowed separator characters: _ - ! ? . @ * / & # % + = $
#
#  FORMULA EXAMPLES:
#       w-w-C/nn  =>  carpet-vehicle-MAROON/19
#       W/w/w/n   =>  BROTHER/tree/locals/6
#       nnn-w!C!  =>  687-fish!BLACK!
#
#  The default formula is stored in the settings file (~/.pwg/settings) and
#  can be changed there. Use -f to override it for a single run, e.g.:
#       pwg.pl -f w-W-c!nn
# =============================================================================

use strict;
use warnings;
use List::Util qw(shuffle);
use Getopt::Long qw(GetOptions);

# Settings directory and file location
my $settings_dir  = "$ENV{HOME}/.pwg";
my $settings_file = "$settings_dir/settings";

# Default locations for word and color list files (used to populate a new
# settings file, and as fallback if a setting is missing)
my $default_wordlist_file  = "$settings_dir/pwg-common-words.txt";
my $default_colorlist_file = "$settings_dir/pwg-color-list.txt";
my $default_wordlist_url   = "https://raw.githubusercontent.com/first20hours/google-10000-english/master/20k.txt";
my $default_formula        = "w-w-C/nn";

# Parse command-line options
my $cli_formula;
GetOptions("f=s" => \$cli_formula) or die "Usage: pwg.pl [-f formula]\n";

# Ensure the settings directory exists
unless (-d $settings_dir) {
    mkdir $settings_dir or die "Could not create settings directory $settings_dir: $!";
}

# Create a default settings file if one doesn't exist yet
unless (-e $settings_file) {
    open my $fh, '>', $settings_file or die "Could not create settings file: $!";
    print $fh "# pwg settings file\n";
    print $fh "# Edit the paths below to change where pwg looks for its word\n";
    print $fh "# and color list files, or change wordlist_url to download the\n";
    print $fh "# word list from a different source.\n";
    print $fh "#\n";
    print $fh "# 'formula' controls the password pattern. Codes:\n";
    print $fh "#   W = uppercase word   w = lowercase word\n";
    print $fh "#   C = uppercase color  c = lowercase color\n";
    print $fh "#   n = a random digit (repeat for more, e.g. nn, nnn)\n";
    print $fh "# Any other character is used as a literal separator.\n";
    print $fh "# Allowed separators: _ - ! ? . \@ * / & # % + = \$\n";
    print $fh "wordlist_file=$default_wordlist_file\n";
    print $fh "colorlist_file=$default_colorlist_file\n";
    print $fh "wordlist_url=$default_wordlist_url\n";
    print $fh "formula=$default_formula\n";
    close $fh;
}

# Read settings from the settings file
my %settings;
open my $sfh, '<', $settings_file or die "Could not open settings file: $!";
while (<$sfh>) {
    chomp;
    next if /^\s*#/;      # Skip comments
    next if /^\s*$/;      # Skip blank lines
    if (/^\s*(\w+)\s*=\s*(.*?)\s*$/) {
        $settings{$1} = $2;
    }
}
close $sfh;

# Resolve word list and color list paths from settings, falling back to
# the defaults if a setting is missing or blank
my $wordlist_file  = $settings{wordlist_file}  || $default_wordlist_file;
my $colorlist_file = $settings{colorlist_file} || $default_colorlist_file;
my $wordlist_url   = $settings{wordlist_url}   || $default_wordlist_url;
my $formula        = $cli_formula || $settings{formula} || $default_formula;

# Allowed literal separator characters in a formula
my $allowed_separators = '_\-!?.@*/&#%+=$';

# Parse the formula into a sequence of tokens:
#   { type => 'gen',   code  => 'w'|'W'|'c'|'C' }   - a word or color slot
#   { type => 'digit', count => N }                 - N zero-padded digits
#   { type => 'sep',   char  => X }                 - a literal character
sub parse_formula {
    my ($formula) = @_;
    die "Error: Formula cannot be empty.\n" unless length $formula;

    my @chars = split //, $formula;
    my @tokens;
    my $i = 0;
    my $len = scalar @chars;

    while ($i < $len) {
        my $ch = $chars[$i];

        if ($ch =~ /^[wWcC]$/) {
            push @tokens, { type => 'gen', code => $ch };
            $i++;
        }
        elsif ($ch =~ /^[nN]$/) {
            my $j = $i;
            $j++ while ($j < $len && $chars[$j] =~ /^[nN]$/);
            push @tokens, { type => 'digit', count => ($j - $i) };
            $i = $j;
        }
        elsif (index($allowed_separators, $ch) >= 0) {
            push @tokens, { type => 'sep', char => $ch };
            $i++;
        }
        else {
            die "Error: Invalid character '$ch' in formula '$formula'.\n"
              . "Allowed codes: W w C c N n\n"
              . "Allowed separators: _ - ! ? . \@ * / & # % + = \$\n";
        }
    }

    return @tokens;
}

my @formula_tokens = parse_formula($formula);

# Determine whether the formula actually needs the word list and/or color list
my $needs_words  = grep { $_->{type} eq 'gen' && $_->{code} =~ /^[wW]$/ } @formula_tokens;
my $needs_colors = grep { $_->{type} eq 'gen' && $_->{code} =~ /^[cC]$/ } @formula_tokens;

# Default color list, used to populate the color list file if it doesn't exist
my @default_colors = qw(
    amethyst black blue brass brown canary cerulean charcoal chestnut chrome
    cobalt copper eggplant emerald fuchsia gold gray green indigo jade khaki
    lavender lemon magenta maroon mint navy neon olive onyx orange orchid peach
    periwinkle pink plum purple red rose ruby salmon sapphire scarlet sepia
    silver tan teal violet white yellow
);

# Create a default color list file if one doesn't exist yet
unless (-e $colorlist_file) {
    open my $cfh, '>', $colorlist_file or die "Could not create color list file: $!";
    print $cfh "$_\n" for @default_colors;
    close $cfh;
}

my @colors;
if ($needs_colors) {
    # Load colors from file
    open my $colorlist, '<', $colorlist_file or die "Could not open color list file: $!";
    my $content = do { local $/; <$colorlist> };
    close $colorlist;
    @colors = split /\s+/, $content;
    @colors = grep { $_ ne '' } @colors;  # Remove empty strings

    # Fallback to hardcoded list if the file somehow yielded no colors
    @colors = @default_colors unless @colors;
}

my @filtered_words;
if ($needs_words) {
    # Ensure the word list exists
    unless (-e $wordlist_file) {
        print "Downloading common word list...\n";
        system("curl -s -o $wordlist_file $wordlist_url");
    }

    # Ensure the file exists and is not empty
    if (-z $wordlist_file) {
        die "Error: Word list file is empty!\n";
    }

    # Load words into an array, forcing lowercase
    open my $wordlist, '<', $wordlist_file or die "Could not open word list file: $!";
    while (<$wordlist>) {
        chomp;
        $_ = lc($_);  # Force lowercase
        $_ =~ s/^\s+|\s+$//g;  # Trim spaces
        next unless /^[a-z]{3,8}$/;  # Keep only words with 3-8 lowercase letters
        push @filtered_words, $_;
    }
    close $wordlist;

    # If no words are left, exit with error
    if (!@filtered_words) {
        die "Error: No valid words found after filtering! Check word list format.\n";
    }
}

# Generate a password by walking the parsed formula tokens. Words are kept
# distinct from one another (as are colors) if the formula uses more than one.
sub generate_password {
    my (@tokens) = @_;
    my @used_words;
    my @used_colors;
    my $result = '';

    for my $tok (@tokens) {
        if ($tok->{type} eq 'sep') {
            $result .= $tok->{char};
        }
        elsif ($tok->{type} eq 'digit') {
            my $count = $tok->{count};
            my $max = 10 ** $count;
            my $num = int(rand($max));
            $result .= sprintf("%0${count}d", $num);
        }
        elsif ($tok->{type} eq 'gen') {
            my $code = $tok->{code};
            if ($code eq 'w' || $code eq 'W') {
                my $word;
                do {
                    $word = $filtered_words[rand @filtered_words];
                } while (grep { $_ eq $word } @used_words);
                push @used_words, $word;
                $result .= ($code eq 'W') ? uc($word) : lc($word);
            }
            elsif ($code eq 'c' || $code eq 'C') {
                my $color;
                do {
                    $color = $colors[rand @colors];
                } while (grep { $_ eq $color } @used_colors);
                push @used_colors, $color;
                $result .= ($code eq 'C') ? uc($color) : lc($color);
            }
        }
    }

    return $result;
}

# Print the password
print generate_password(@formula_tokens), "\n";