#!/usr/bin/env perl
# =============================================================================
#  NAME:        pwg.pl
#
#  DESCRIPTION: Very basic perl script to generate random password.
#               Uses my current pattern format of three words and a number.
#				One word is a color, and the other two are random.
#				
#  VERSION:     v1.2
#
#  GITHUB: https://github.com/r3v/pwg/issues
#
#  USAGE:
#		pwg.pl
# =============================================================================

use strict;
use warnings;
use List::Util qw(shuffle);

# Settings directory and file location
my $settings_dir  = "$ENV{HOME}/.pwg";
my $settings_file = "$settings_dir/settings";

# Default locations for word and color list files (used to populate a new
# settings file, and as fallback if a setting is missing)
my $default_wordlist_file  = "$settings_dir/pwg-common-words.txt";
my $default_colorlist_file = "$settings_dir/pwg-color-list.txt";
my $default_wordlist_url   = "https://raw.githubusercontent.com/first20hours/google-10000-english/master/20k.txt";

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
    print $fh "wordlist_file=$default_wordlist_file\n";
    print $fh "colorlist_file=$default_colorlist_file\n";
    print $fh "wordlist_url=$default_wordlist_url\n";
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

# Load colors from file
open my $colorlist, '<', $colorlist_file or die "Could not open color list file: $!";
my $content = do { local $/; <$colorlist> };
close $colorlist;
my @colors = split /\s+/, $content;
@colors = grep { $_ ne '' } @colors;  # Remove empty strings

# Fallback to hardcoded list if the file somehow yielded no colors
@colors = @default_colors unless @colors;

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
my @filtered_words;
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

# Function to get a random word
sub get_random_word {
    my ($case) = @_;
    my $word = $filtered_words[rand @filtered_words];
    return uc($word) if $case eq 'upper';
    return lc($word) if $case eq 'lower';
    return $word;
}

# Generate password
my $color = $colors[rand @colors];
my $word1 = get_random_word('upper');
my $word2 = get_random_word('lower');
my $number = int(rand(100));

# Ensure unique words
while ($word1 eq $word2) {
    $word2 = get_random_word('lower');
}

# Print the password
print "$color-$word1-$word2-$number\n";
