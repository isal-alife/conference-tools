# process-raw-schedule.awk
#
# Usage:
# gawk -f process-raw-schedule.awk raw-schedule.txt 
#
# NB It is wise to preprocess the raw-schedule.txt file with
# native2ascii to convert all characters to Unicode-endcoded
# See http://docs.oracle.com/javase/1.5.0/docs/tooldocs/windows/native2ascii.html
#

BEGIN {
  FS="\"";
  SID=0;
  AID=1;
  
  DB = "ecalprog.db";
  DBCMD = "sqlite3 " DB " ";
  
  if (system("[ -f " DB " ]") == 0 )
  {
    print "Database file already exists!";
    exit 1
  }

  #cmd = DBCMD " '.quit'";
  #system(cmd);
  cmd = DBCMD "\"CREATE TABLE sessions(id INTEGER PRIMARY KEY, title VARCHAR(100), date VARCHAR(30), time VARCHAR(10), roomid INTEGER DEFAULT 0)\"";
  system(cmd);
  cmd = DBCMD "\"CREATE TABLE talks(id INTEGER PRIMARY KEY, title VARCHAR(100), sessionid INTEGER, sessionpos INTEGER, time VARCHAR(10), videourl VARCHAR(60), paperurl VARCHAR(120))\"";
  system(cmd);
  cmd = DBCMD "\"CREATE TABLE talkauthors(talkid INTEGER, authorid INTEGER, authorpos INTEGER)\"";
  system(cmd);
  cmd = DBCMD "\"CREATE TABLE authors(id INTEGER PRIMARY KEY, name VARCHAR(50) UNIQUE NOT NULL)\"";
  system(cmd);
  cmd = DBCMD "\"CREATE TABLE rooms(id INTEGER PRIMARY KEY, number VARCHAR(10), desc VARCHAR(20))\"";
  system(cmd);
  cmd = DBCMD "\"CREATE TABLE idmap(ecid INTEGER PRIMARY KEY, mitid INTEGER)\"";
  system(cmd);  
  cmd = DBCMD "\"INSERT INTO rooms VALUES(1,'RCH/037','Lecture theatre')\"";
  system(cmd);
  cmd = DBCMD "\"INSERT INTO rooms VALUES(2,'RCH/248','Lakehouse 1')\"";
  system(cmd);
  cmd = DBCMD "\"INSERT INTO rooms VALUES(3,'RCH/250','Lakehouse 2')\"";
  system(cmd);
  cmd = DBCMD "\"INSERT INTO rooms VALUES(4,'RCH/017','Teaching room')\"";
  system(cmd);
  cmd = DBCMD "\"INSERT INTO rooms VALUES(5,'RCH/204','Seminar room')\"";
  system(cmd);
  cmd = DBCMD "\"INSERT INTO rooms VALUES(6,'RCH/103','Teaching room')\"";
  system(cmd);
  cmd = DBCMD "\"INSERT INTO rooms VALUES(7,'RCH/Atrium','Atrium')\"";
  system(cmd);
}


# Day and time
/.*July.*/ {
  match($0, /^([[:alpha:]]+)[[:space:]]+([[:digit:]]+)[[:space:]]+(July)[[:space:]]+([[:digit:]]{2}:[[:digit:]]{2})/, arr);  
  day = arr[1] " " arr[2] " " arr[3];
  time = arr[4];
  daytime=1;
  print "Processed Day/time line '" $0 "': day=" day ", time=" time;
}

# Location
/^(RCH|Atrium)/ {
  # Do nothing.. we'll do this manually at the end
  print "Processed location line '"$0"'";
  location=1;
}


# Select session titles
/^[^0-9]/ {
  #print

  if (location==0 && daytime==0) {
    SID++;
    TPOS = 1;

    title = charencode($0);
    print title;
   
    cmd = DBCMD "\"INSERT INTO sessions VALUES('" SID "','" title "','" day "','" time "', 0)\"";
    system(cmd);
    print cmd;
  }
  
  daytime=0;
  location=0;
}


# Talk within a session (has start-time in first column)
/^[0-9]{2}:[0-9]{2}/ {
  #print

  match($0, /^[0-9]{2}:[0-9]{2}/, arr);
  starttime = arr[0];
  
  match($0, /^[0-9]{2}:[0-9]{2}[[:space:]]+([0-9]+)/, arr);
  paperid = arr[1];
  #print paperid;
  
  match($0, /"(.*)"/, arr);
  title = charencode(arr[1]);
  print title;
  
  match($0, /[^\"]+$/, arr); #"
  authors = charencode(arr[0]);
  print authors;
  
  nauth = split(authors, arr, /(, | and )/);
  for (i=1; i<=nauth; i++) {
    author = arr[i];
    sub(/^ */, "", author);
    sub(/ *$/, "", author);
    #print author;
    
    authorid = -1;
    # the following three lines are AWK idiom for storing the result of a system command 
    # in an AWK variable. See https://www.gnu.org/software/gawk/manual/gawk.html#Getline_002fPipe
    cmd = DBCMD "\"SELECT id FROM authors WHERE name='" author "'\"";
    while ( ( cmd | getline authorid ) > 0 ) {}
    close(cmd)
     
    if (authorid < 0 ) {
      authorid = AID;
      AID++;
      cmd = DBCMD "\"INSERT INTO authors VALUES('" authorid "','" author "')\"";
      system(cmd);
      print cmd;
    }
    
    cmd = DBCMD "\"INSERT INTO talkauthors VALUES('" paperid "','" authorid "','" i "')\"";
    system(cmd);
    print cmd;  
  }
  
  cmd = DBCMD "\"INSERT INTO talks VALUES('" paperid "','" title "','" SID "','" TPOS "','" starttime "','','')\"";
  system(cmd);
  print cmd;  
  
  TPOS++;
}


# Poster session item (has no start-time)
/^[0-9]{1,3} / {
  #print
  
  match($0, /^[0-9]+/, arr);
  paperid = arr[0];
  #print paperid;
  
  match($0, /"(.*)"/, arr);
  #title = arr[1];
  title = charencode(arr[1]);
  #sub(/^\"/, "", title);
  #sub(/\"$/, "", title);
  print title;
  
  match($0, /[^\"]+$/, arr); #"
  #authors = arr[0];
  authors = charencode(arr[0]);
  print authors;
  
  nauth = split(authors, arr, /(, | and )/);
  for (i=1; i<=nauth; i++) {
    author = arr[i];
    sub(/^ */, "", author);
    sub(/ *$/, "", author);
    #print author;
    
    authorid = -1;
    # the following three lines are AWK idiom for storing the result of a system command 
    # in an AWK variable. See https://www.gnu.org/software/gawk/manual/gawk.html#Getline_002fPipe
    cmd = DBCMD "\"SELECT id FROM authors WHERE name='" author "'\"";
    while ( ( cmd | getline authorid ) > 0 ) {}
    close(cmd)
    
    #print cmd;
    #print "'" authorid "'";    
    if (authorid < 0 ) {
      authorid = AID;
      AID++;
      cmd = DBCMD "\"INSERT INTO authors VALUES('" authorid "','" author "')\"";
      system(cmd);
      print cmd;
    }
    
    cmd = DBCMD "\"INSERT INTO talkauthors VALUES('" paperid "','" authorid "','" i "')\"";
    system(cmd);
    print cmd;  
  }
  
  cmd = DBCMD "\"INSERT INTO talks VALUES('" paperid "','" title "','" SID "','" TPOS "','','','')\"";
  system(cmd);
  print cmd;  
  
  TPOS++;
}

END {
  cmd = DBCMD "\"UPDATE sessions SET roomid=1 WHERE id=1\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=2 WHERE id=2\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=1 WHERE id=3\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=2 WHERE id=4\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=3 WHERE id=5\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=1 WHERE id=6\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=2 WHERE id=7\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=3 WHERE id=8\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=1 WHERE id=9\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=2 WHERE id=10\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=3 WHERE id=11\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=7 WHERE id=12\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=1 WHERE id=13\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=2 WHERE id=14\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=3 WHERE id=15\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=1 WHERE id=16\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=2 WHERE id=17\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=3 WHERE id=18\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=1 WHERE id=19\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=2 WHERE id=20\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=1 WHERE id=21\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=2 WHERE id=22\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=3 WHERE id=23\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=1 WHERE id=24\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=2 WHERE id=25\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=3 WHERE id=26\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=1 WHERE id=27\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=2 WHERE id=28\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=1 WHERE id=29\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=2 WHERE id=30\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=3 WHERE id=31\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=1 WHERE id=32\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=2 WHERE id=33\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=1 WHERE id=34\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=3 WHERE id=35\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=1 WHERE id=36\"";
  system(cmd);
  cmd = DBCMD "\"UPDATE sessions SET roomid=3 WHERE id=37\"";
  system(cmd);
}

#####

function charencode(str) {
    if (match(str, /(.*)\\u([[:xdigit:]]{4})(.*)/, bits) > 0)
      return charencode(bits[1]"&#x"bits[2]";"bits[3])
    else {
      gsub(/^[ \t]+/,"",str);
      gsub(/[ \t]+$/,"",str);
      gsub(/\.$/,"",str);
      return str;
    }
}
