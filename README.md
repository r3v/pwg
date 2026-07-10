# pwg
Password Generator using dictionary words.

Using multiple dictionary words along with symbols and numbers generally results in a strong password. It also has the benefit of being readable (and speakable when needed). 

I was tired of coming up with word combos for every new site, so... pwg. 

It has been updated with 2.0 to allow the user to customize the forumla using a "shorthand" code. 

```
  USAGE:
       pwg.pl
       pwg.pl -f FORMULA

  FORMULA CODES:
       W = uppercase word
       w = lowercase word
       C = uppercase color
       c = lowercase color
       n = random number; repeat for more digits, zero-padded (nn, nnn, etc).
           Case insensitive (n or N).
       Any other character in the formula is used as a literal separator.
       Allowed separator characters: _ - ! ? . @ * / & # % + = $

  FORMULA EXAMPLES:
       w-w-C/nn  =>  carpet-vehicle-MAROON/19
       W/w/w/n   =>  BROTHER/tree/locals/6
       nnn-w!C!  =>  687-fish!BLACK!

  The default formula is stored in the settings file (~/.pwg/settings) and
  can be changed there. Use -f to override it for a single run, e.g.:
       pwg.pl -f w-W-c!nn
```