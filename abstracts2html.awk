# Script to convert txt abstracts to html
# Example usage:
#
# cd abstracts/tmp
# for F in `ls`; do gawk -f ../../abstracts2html.awk $F > ../processed/$F ; done
#

BEGIN {
  print "<p>";
}

{
  if (NF>0) {
    print fixbreaks(charencode($0));
  } else {
    print "</p><p>" 
  }  
} 

END {
  print "</p>";
}

function charencode(str) {
  if (match(str, /(.*)\\u([[:xdigit:]]{4})(.*)/, bits) > 0)
    return charencode(bits[1]"&#x"bits[2]";"bits[3])
  else
    return str
}

function fixbreaks(str) {
  if (match(str, /(.*)- (.*)/, bits) > 0)
    return fixbreaks(bits[1]bits[2])
  else
    return str
}
