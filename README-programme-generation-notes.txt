*** Extracting paper info from Programme Word Doc ***

Cut and paste sessions and talk info from ECAL (draft) Programme.docx file
Save to raw-schedule.txt
Search and replace weird double quotes (open and close) with standard ones
Search and replace tabs with spaces
Search and remove full stops at end of titles (.")
Convert strange characters to Unicode: native2ascii raw-schedule.txt raw-schedule.txt.new

====================================================

*** Extracting video info and adding to database ***

# process raw video abstract CSV file downloaded from Google Drive to print the 
# paper numbers and URLs of papers with videos

> gawk -F',' '$1 != "" {match($2,/\"([0-9]{1,3}) /, arr); print arr[1] ", " $1;}' video-abstract-URLs-Sheet2.csv | sort -nk1 > video-list.txt

# NB to embed videos, URLs should be of the form https://www.youtube.com/embed/....  (this correction is done in genpages script)

# having created video-list.txt, use it to add the details to database by running:

> add-videourls-to-db


====================================================

*** Processing Abstracts ***

cd abstracts/raw
> for F in `ls`; do native2ascii $F ../tmp/$F; done

cd abstracts/tmp
> for F in `ls`; do gawk -f ../../abstracts2html.awk $F > ../processed/$F ; done

====================================================

*** Addinge ID Map to database ***

> add-idmap-to-db

====================================================

*** For papers which are no longer able to be presented (but will stay in proceedings) ***

Set time to "0" in database

> UPDATE talks set time="0" WHERE id=123;
> UPDATE talks set time="0" WHERE id=158;

====================================================

*** SUMMARY of sequence to regenrate everything ***
rm -f ecalprog.db
gawk -f process-raw-schedule.awk raw-schedule.txt
./add-idmap-to-db
./add-videourls-to-db [remove Mizuki's video (paper 159)?]
./genpages
