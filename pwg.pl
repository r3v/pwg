#!/usr/bin/env perl
# =============================================================================
#  NAME:        pwg.pl
#
#  DESCRIPTION: Very basic perl script to generate random password.
#               Uses my current pattern format of three words and a number.
#				One word is a color, and the other two are random.
#				
#  VERSION:     v1.1
#
#  GITHUB: https://github.com/r3v/pwg/issues
#
#  USAGE:
#		pwg.pl
# =============================================================================

use strict;
use warnings;
use List::Util qw(shuffle);

# Define word list location
my $wordlist_file = "$ENV{HOME}/Documents/pwg-common-words.txt";

# Define color list location
my $colorlist_file = "$ENV{HOME}/Documents/pwg-color-list.txt";

# Load colors from file
my @colors;
if (-e $colorlist_file) {
    open my $colorlist, '<', $colorlist_file or die "Could not open color list file: $!";
    my $content = do { local $/; <$colorlist> };
    close $colorlist;
    @colors = split /\s+/, $content;
    @colors = grep { $_ ne '' } @colors;  # Remove empty strings
} else {
    # Fallback to hardcoded list if file doesn't exist
    @colors = qw(
        amethyst black blue brass brown canary cerulean charcoal chestnut chrome
        cobalt copper eggplant emerald fuchsia gold gray green indigo jade khaki
        lavender lemon magenta maroon mint navy neon olive onyx orange orchid peach
        periwinkle pink plum purple red rose ruby salmon sapphire scarlet sepia
        silver tan teal violet white yellow
    );
}

# Ensure the word list exists
unless (-e $wordlist_file) {
    print "Downloading common word list...\n";
    system("curl -s -o $wordlist_file https://raw.githubusercontent.com/first20hours/google-10000-english/master/20k.txt");
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
