# conference-tools
Scripts and tools that may be useful for conference organisers


Introduction
---
The scripts in this directory were used to generate the interactive programme pages for the ECAL 2015 website (see https://www.cs.york.ac.uk/nature/ecal2015/schedule-overview.html). They are provided here as a service to future conference organisers. Additional work will be required to make these tools suitable for other conferences.

Generation of the interactive HTML programme pages is essentially a 2-step process:

1. Process a source ASCII document that contains the conference schedule info in plain text format, using the process-raw-schedule.awk AWK script, to generate a SQLite database.

2. Run the genpages BASH script to generate the HTML pages, using the previously generated database.

For further details about using the scripts, see the file README-programme-generation-notes.txt
