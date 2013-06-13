## NAME

__PhysicoChemical\_Descriptor__

## DESCRIPTION

A CGI service for calculation of physicochemical properties of a given 
amino acid sequence.

## USAGE

http://imgt.org/pc_descriptor/properties.pl?sequence="SEQUENCE"

## EXAMPLE

http://imgt.org/pc_descriptor/properties.pl?sequence=RWMDR

## DEPENDENCIES

\-the Perl interpreter, >= 5.10

\-CGI, >= 3.63 (Perl module)

\-DBD::SQLite, >= 1.37 (Perl module)

\-DBI, >= 1.622 (Perl module)

## LIMITATIONS

There is a limit of no more than 400 amino acids per sequence.

## AUTHORS

\-Dimitrios - Georgios Kontopoulos <<dgkontopoulos@gmail.com>>

\-Dimitrios Vlachakis <<dvlachakis@bioacademy.gr>>

\-Sophia Kossida <<skossida@bioacademy.gr>>

## LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
<a href="http://www.gnu.org/licenses/agpl.html" style="text-decoration:none">GNU Affero General Public License</a> for more details.
