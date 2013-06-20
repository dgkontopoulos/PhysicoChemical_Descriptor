#!/usr/bin/perl -T

=head1 NAME

B<PhysicoChemical_Descriptor>

=head1 DESCRIPTION

A CGI service for calculation of physicochemical properties of a given 
amino acid sequence.

=head1 USAGE

http://imgt.org/pc_descriptor/properties.pl?sequence="SEQUENCE"

=head1 EXAMPLE

http://imgt.org/pc_descriptor/properties.pl?sequence=RWMDR

=head1 DEPENDENCIES

-the Perl interpreter, >= 5.10

-CGI, >= 3.63 (Perl module)

-DBD::SQLite, >= 1.37 (Perl module)

-DBI, >= 1.622 (Perl module)

=head1 LIMITATIONS

There is a limit of no more than 400 amino acids per sequence.

=head1 AUTHORS

-Dimitrios - Georgios Kontopoulos <<dgkontopoulos@gmail.com>>

-Dimitrios Vlachakis <<dvlachakis@bioacademy.gr>>

-Sophia Kossida <<skossida@bioacademy.gr>>

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
<a href="http://www.gnu.org/licenses/agpl.html" style="text-decoration:none">GNU Affero General Public License</a> for more details.

=cut

use strict;
use warnings;

use feature qw(say);

use CGI;
use DBI;
use utf8;

our $VERSION = 'v1.00';

my $cgi = CGI->new;
print $cgi->header;

my $sequence = $cgi->param('sequence');
my $advanced = $cgi->param('advanced');

# Remove single and double quotes in the sequence, if any. #
$sequence =~ s/["|']//g;

# Connect to the amino acids database. #
my $dbh = DBI->connect( 'dbi:SQLite:../amino_acids.db', q{}, q{} );

# Stuff to be printed at the end of the page. #
my $bottom_info = << 'ENDHTML';
<hr/><sub>
This tool was primarily developed by D. Vlachakis, D. G. Kontopoulos and <a href='mailto:skossida@bioacademy.gr' style="text-decoration:none">S. Kossida</a> 
from the <a href='http://www.bioacademy.gr/bioinformatics/' style="text-decoration:none">Bioinformatics and Medical Informatics Research Group</a> of the<br>
<a href='http://www.bioacademy.gr/?lang=en' style="text-decoration:none">Biomedical Research Foundation, Academy of Athens, Greece</a> 
in collaboration with <a href="http://www.imgt.org/" style="text-decoration:none">IMGT®, the international ImMunoGeneTics information system®</a>,<br>
<a href='http://www.imgt.org/IMGTinformation/LIGM.html' style="text-decoration:none">Laboratoire d'ImmunoGénétique Moléculaire</a> of the 
<a href='http://www.igh.cnrs.fr/EN/index.php' style="text-decoration:none">Institut de Génétique Humaine, CNRS (UPR 1142), Montpellier, France</a>.
<br><br>
The <a href='https://github.com/dgkontopoulos/PhysicoChemical_Descriptor' style="text-decoration:none">source code</a> is freely available under the 
<a href='http://www.gnu.org/licenses/agpl.html' style="text-decoration:none">GNU Affero GPL</a>.
</sub>
ENDHTML

if ( $sequence =~ /^\s*$/ )    # Reject empty sequences. #
{
    print $cgi->start_html( -title => 'PC Descriptor || ERROR!' );

    # Header and error message. #
    print << "ENDHTML";
<center>
<table cols=2 width='100%' >
<tr>

<td align=left nowrap valign=middle width='70%'>
<font size='+3' color='#000099'><b>WELCOME</font>
<font size='+2' color='#000099'><br>to PhysicoChemical Descriptor<sup><small>($VERSION)</small></sup>!</b></font>
</td>

<td align=right valign=top width="30%">
<a href="http://www.imgt.org"><img src="http://imgt.org/IMGT_vquest/share/textes/images/logoIMGT.png" alt="IMGT"></a>
</td>
</tr>
</table>
<hr/>
<font face="Ubuntu Mono, Courier New"><b>ERROR!</b><br>No sequence was entered!</font>
</center>
ENDHTML
}
elsif ( $sequence =~ /^[A|R|N|D|C|E|Q|G|H|I|L|K|M|F|P|S|T|W|Y|V]+$/i )
{

    # Reject sequences that are larger than 400 amino acids. #
    if ( length $sequence > 400 )
    {
        print $cgi->start_html( -title => 'PC Descriptor || ERROR!' );
        print << "ENDHTML";
<center>
<table cols=2 width="100%" >
<tr>

<td align=left nowrap valign=middle width="70%">
<font size="+3" color="#000099"><b>WELCOME</b></font>
<font size='+2' color="#000099"><br><b>to PhysicoChemical Descriptor<sup><small>($VERSION)</small></sup>!</b></font>
</td>
</font></td>

<td align=right valign=top width="30%">
<a href="http://www.imgt.org"><img src="http://imgt.org/IMGT_vquest/share/textes/images/logoIMGT.png" alt="IMGT"></a>
</td>
</tr>
</table>
<hr/>
<font face="Ubuntu Mono, Courier New"><b>ERROR!</b><br>Currently there is a limit of 400 amino acids per sequence!</font>
</center>
ENDHTML
        print $bottom_info . $cgi->end_html;
        exit;
    }

    print << "END_HEADER";
<!DOCTYPE html
	PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
	 "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en-US" xml:lang="en-US">
<head>
<title>PC Descriptor || &#39;$sequence&#39;</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<link href='http://fonts.googleapis.com/css?family=Ubuntu+Mono' rel='stylesheet' type='text/css'>
</head>
<body>
END_HEADER

    my $input_seq = $sequence;

    # Change line after every 50 characters. #
    $input_seq =~ s/(\w{50})/$1<br>&nbsp;/g;

    # Header, input sequence. #
    print << "ENDHTML";
<center>
<table cols=2 width='100%' >
<tr>

<td align=left nowrap valign=middle width='70%'>
<font size='+3' color='#000099'><b>WELCOME</b></font>
<font size='+2' color='#000099'><br><b>to PhysicoChemical Descriptor<sup><small>($VERSION)</small></sup>!</b></font>
</td>

<td align=right valign=top width='30%'>
<a href='http://www.imgt.org'><img src='http://imgt.org/IMGT_vquest/share/textes/images/logoIMGT.png' alt='IMGT'></a>
</td>
</tr>
</table>
</center>
<hr/>
<font face='Ubuntu Mono, Courier New'>Input sequence:<br><b>&nbsp;$input_seq</b>
</font><br><br>
ENDHTML

    # Check if we're using the advanced interface. #
    if ( $advanced != 1 )
    {
        print << "ENDHTML";
<font face='Ubuntu Mono, Courier New'>The following table displays calculations of various physicochemical properties
of the input sequence.
<br>Clicking on property codes (first column) will show their description.
<br><br><center>
ENDHTML

        # List the available properties. #
        my @properties = qw(
          Hydro_IMGT  Vol_IMGT ASA     b_rotR CASA_pos CASA_neg E
          E_sol       E_strain E_tor   E_vdw  logP_o_w logS     PEOE_PC_pos
          PEOE_PC_neg Vdw_area Vdw_vol VSA    Weight
        );

        create_results_table( \@properties, $sequence );

        # Properties Codebook. #
        print << 'ENDHTML';
<br><hr/></center><font face="Ubuntu Mono, Courier New">
<b><u>Properties Codebook</u></b><br>
<ul type="circle">

<li><a name="ASA"><b>ASA:</b> Water accessible surface area calculated using a radius of 1.4 A for the water molecule.
A polyhedral representation is used for each atom in calculating the surface area.</a></li><br>

<li><a name="b_rotR"><b>b_rotR:</b> Fraction of rotatable bonds.</a></li><br>

<li><a name="CASA-"><b>CASA-:</b> Negative charge weighted surface area.</a></li><br>

<li><a name="CASA+"><b>CASA+:</b> Positive charge weighted surface area.</a></li><br>

<li><a name="E"><b>E:</b> Value of the potential energy.</a></li><br>

<li><a name="E_sol"><b>E_sol:</b> Solvation energy.</a></li><br>

<li><a name="E_strain"><b>E_strain:</b> Local strain energy: the current energy minus the value of the energy at a near local minimum.</a></li><br>

<li><a name="E_tor"><b>E_tor:</b> Torsion (proper and improper) potential energy.</a></li><br>

<li><a name="E_vdw"><b>E_vdw:</b> Van der Waals component of the potential energy.</a></li><br>

<li><a name="Hydro_IMGT"><b>Hydro_IMGT:</b> Hydropathy value of amino acids, as reported by IMGT itself.</a></li><br>

<li><a name="logP(o/w)"><b>logP(o/w):</b> Log of the octanol/water partition coefficient (including implicit hydrogens). This
property is calculated from a linear atom type model.</a></li><br>

<li><a name="logS"><b>logS:</b> Log of the aqueous solubility (mol/L). This property is calculated from an atom
contribution linear atom type model.</a></li><br>

<li><a name="PEOE_PC-"><b>PEOE_PC-:</b> Total negative partial charge: the sum of the negative qi.</a></li><br>

<li><a name="PEOE_PC+"><b>PEOE_PC+:</b> Total positive partial charge: the sum of the positive qi.</a></li><br>

<li><a name="Vdw_area"><b>Vdw_area:</b> Area of van der Waals surface calculated using a connection table
approximation.</a></li><br>

<li><a name="Vdw_vol"><b>Vdw_vol:</b> Van der Waals volume calculated using a connection table approximation.</a></li><br>

<li><a name="Vol_IMGT"><b>Vol_IMGT:</b> Volume value of amino acids, as reported by IMGT itself.</a></li><br>

<li><a name="VSA"><b>VSA:</b> Van der Waals surface area. A polyhedral representation is used for each atom in
calculating the surface area.</a></li><br>

<li><a name="Weight"><b>Weight:</b> Molecular weight (including implicit hydrogens) in atomic mass units with atomic
weights taken from CRC Handbook of Chemistry and Physics. CRC Press (1994).</a></li>

</ul></font>
<center><b><font face="Ubuntu Mono, Courier New">Reference:</font></b><br>
<table><tr><td align='center' bgcolor='#F7F8E0'><font face="Ubuntu Mono, Courier New" size='-1'>
Molecular Operating Environment (MOE), 2012.10;<br>
Chemical Computing Group Inc.,<br>
1010 Sherbooke St. West, Suite #910,<br>
Montreal, QC, Canada, H3A 2R7, <b>2012</b>.</font></td></tr></table></center>
ENDHTML
    }
    elsif ($advanced == 1
        && $cgi->param('proceed') )    # Advanced interface, show results. #
    {

        # Advanced interface text. #
        print << "ENDHTML";
<font face='Ubuntu Mono, Courier New'>
This is the advanced interface of the tool. To go back to the simple interface (calculating only default properties), click
<a href='http://imgt.org/pc_descriptor/properties.pl?sequence=$sequence' style='text-decoration:none'>here</a>.
<br>To reselect properties to be computed, click
<a href='http://imgt.org/pc_descriptor/properties.pl?sequence=$sequence&advanced=1' style='text-decoration:none'>here</a>.
</font><br><br>
ENDHTML

        # Get a list of parameters and try to find selected properties. #
        my @parameters = $cgi->param;

        for ( 0 .. $#parameters )
        {
            if (   $parameters[$_] eq 'sequence'
                or $parameters[$_] eq 'advanced'
                or $parameters[$_] eq 'proceed' )
            {
                undef $parameters[$_];
            }
        }

        @parameters = grep { defined } @parameters;

        # If no properties were found, exit. #
        if ( $#parameters == -1 )
        {
            print << 'ENDHTML';
<center><font face='Ubuntu Mono, Courier New' size='+1'>
<b>ERROR!</b><br>
No properties have been selected!<br>
Please <a href='javascript:history.go(-1)'>go back</a> and select some properties to be computed.</font>
</center><br>
ENDHTML
            print $bottom_info . $cgi->end_html;
            exit;
        }

        my @properties;
        foreach my $element (@parameters)
        {

            # Substitute illegal characters. #
            $element = string_reformat( $element, 'for_sql' );

            # Query to check if a table exists with that name. #
            my $select_text = << 'END_SQL';
Select name from sqlite_master where type='table' and name = ?;
END_SQL
            my $db_sel = $dbh->prepare($select_text);

            # Bind variable to avoid sql injection attack. #
            $db_sel->execute($element);
            my $result = $db_sel->fetchall_arrayref;

            if ( $result->[0]->[0] )
            {
                push @properties, $result->[0]->[0];
            }
        }

        # If no valid properties were found, exit. #
        if ( $#properties == -1 )
        {
            print << 'ENDHTML';
<center><font face='Ubuntu Mono, Courier New' size='+1'>
<b>ERROR!</b><br>
No properties have been selected!<br>
Please <a href='javascript:history.go(-1)'>go back</a> and select some properties to be computed.</font>
</center><br>
ENDHTML
            print $bottom_info . $cgi->end_html;
            exit;
        }

        print '<center>';
        create_results_table( \@properties, $sequence );
        print '</center><br>';

    }
    elsif ( $advanced == 1 )    # Advanced interface, specify parameters. #
    {

        # Advanced interface text and beginning the form #
        print << "ENDHTML";
<font face='Ubuntu Mono, Courier New'>
This is the advanced interface of the tool. To go back to the simple interface, click
<a href='http://imgt.org/pc_descriptor/properties.pl?sequence=$sequence' style='text-decoration:none'>here</a>.
<br>Otherwise, please select the physicochemical properties to compute for the input sequence.
</font>

<form id = 'submit' method = 'post'
action=http://imgt.org/pc_descriptor/properties.pl?sequence=$sequence&advanced=1>

<input type=hidden name='sequence' value='$sequence'>
<input type=hidden name='advanced' value='1'>
<input type=hidden name='proceed' value='1'>
ENDHTML

        # Get and list the available properties. #
        say '<center><table cellspacing = "5"><tr>';

        my $tables = get_available_properties();

        for ( 0 .. @{$tables} - 1 )
        {
            if ( $_ % 8 == 0 )
            {
                say '</tr><tr></tr><tr></tr><tr>';
            }

            # Create checkbuttons. #
            print << "ENDHTML";
<td><font face='Ubuntu Mono, Courier New' size='2'>
<input type=checkbox name='$tables->[$_]' value='1'>$tables->[$_]
</font></td><td></td>
ENDHTML
        }

        # Create the submit button. #
        print << 'ENDHTML';
</table><br>
<input id='submit' type='submit' value=' Submit '></form></center><br>
ENDHTML
    }
}
else    # Handle any non-protein sequences. #
{
    print $cgi->start_html( -title => 'PC Descriptor || ERROR!' );

    # Header and error. #
    print << "ENDHTML";
<center>
<table cols=2 width="100%" >
<tr>

<td align=left nowrap valign=middle width="70%">
<font size="+3" color="#000099"><b>WELCOME</b></font>
<font size='+2' color="#000099"><br><b>to PhysicoChemical Descriptor<sup><small>($VERSION)</small></sup>!</b></font>
</td>
</font></td>

<td align=right valign=top width="30%">
<a href="http://www.imgt.org"><img src="http://imgt.org/IMGT_vquest/share/textes/images/logoIMGT.png" alt="IMGT"></a>
</td>
</tr>
</table>
<hr/>
<font face="Ubuntu Mono, Courier New"><b>ERROR!</b><br>This does not look like an amino acid sequence!</font>
</center>
ENDHTML
}

# Print bottom text and details. #
print $bottom_info . $cgi->end_html;

#############################################
# S   U   B   R   O   U   T   I   N   E   S #
#############################################

# Just what the function name reads. #
sub create_results_table
{
    my ( $properties, $sequence ) = @_;

    # Sort properties alphabetically. #
    my @properties = sort { lc $a cmp lc $b } @{$properties};

    print << "ENDHTML";
<table border="1" id="properties"><thead><tr><th></th>
ENDHTML

    my @seq_full = split q{}, uc $sequence;

    # Print the first row. #
    for ( 0 .. $#seq_full )
    {
        my $tag = $seq_full[$_];
        say
"<th bgcolor=FFEEC0 align=center><b><font face='Ubuntu Mono, Courier New'>$tag</font></b></th>";
    }
    print << "ENDHTML";
<th bgcolor=FFEEC0 align=center>
<b><font face='Ubuntu Mono, Courier New'>Average</font></b>
</th></tr></thead><tfoot></tfoot><tbody>
ENDHTML

    # For each property, compute its value. #
    for ( 0 .. $#properties )
    {
        my ( $values, $average ) =
          value_calc( \@seq_full, $properties[$_] );

        my $property = string_reformat( $properties[$_], 'from_sql' );
        my $old_property = $property;

        # Units. #
        if ( $property eq 'Weight' )
        {
            $property .= '<sub>(g/mol)</sub>';
        }

        # Alternate row colors. #
        my ( $trcolor, $tdcolor );
        if ( $_ % 2 == 0 )
        {
            $trcolor = 'FFF2D7';
            $tdcolor = 'FFF0CD';
        }
        else
        {
            $trcolor = 'E1F1FF';
            $tdcolor = 'E6F4FF';
        }

        # Property cell. #
        print << "ENDHTML";
<tr bgcolor=$trcolor><td bgcolor=$tdcolor><font face='Ubuntu Mono, Courier New'>
<center><b><a href='#$old_property' style='text-decoration:none;color: rgb(0,0,0)'>$property</a></b>
</center></font></td>
ENDHTML

        # Property values for each amino acid and on average. #
        for ( 0 .. $#seq_full )
        {
            my $tag   = uc $seq_full[$_];
            my $value = $values->{$tag};
            say
"<td align=center><font face='Ubuntu Mono, Courier New'>$value</font></td>";
        }
        say
"<td align=center><font face='Ubuntu Mono, Courier New'>$average</font></td></tr>\n\n";
    }
    print '</tbody></table>';
    return 0;
}

# Get the names of the properties within the database. #
sub get_available_properties
{

    # Connect to the database and get a list of tables. #
    my $sql = << 'ENDSQL';
Select name from sqlite_master where type = "table"
ENDSQL
    my $result = $dbh->selectall_arrayref($sql);

    my $iterator = 0;
    my @tables;
    while ( $result->[$iterator]->[0] )
    {

        # Perform aesthetic conversions and store table names. #
        push @tables, string_reformat( $result->[$iterator]->[0], 'from_sql' );
        $iterator++;
    }

    @tables = sort { lc $a cmp lc $b } @tables;
    return \@tables;
}

# Remove illegal characters and vice versa. #
sub string_reformat
{
    my ( $string, $mode ) = @_;

    if ( $mode eq 'from_sql' )    # After receiving SQL output. #
    {
        $string =~ s/_pos_?/+/g;
        $string =~ s/_neg_?/-/g;
        $string =~ s/_o_w_?/(o\/w)/g;
    }
    elsif ( $mode eq 'for_sql' )    # For an SQL statement. #
    {
        $string =~ s/[+]/_pos_/g;
        $string =~ s/[-]/_neg_/g;
        $string =~ s/[(]o\/w[)]/_o_w/g;
        $string =~ s/_$//;
    }

    return $string;
}

sub value_calc
{
    my ( $sequence, $table ) = @_;

    my %values;
    my $average = 0;

    # Get the value corresponding to each residue. #
    for ( 0 .. @{$sequence} - 1 )
    {
        my $residue          = uc $sequence->[$_];
        my $select_statement = << "END";
select Value from $table where Residue = '$residue'
END

      # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
      # The line below must change to the amino acid properties database file. #
      # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
        my $properties_loc = '../amino_acids.db';

        my $db_sel = $dbh->prepare($select_statement);
        $db_sel->execute();

        my $result = $db_sel->fetchall_arrayref;
        if ( defined $result->[0]->[0] )
        {
            $average += $result->[0]->[0];
            $residue = uc $residue;
            $values{$residue} //= sprintf '%10.4f', $result->[0]->[0];
            $values{$residue} =~ s/\s/&nbsp;/g;
        }
        else
        {

            # In case of non-allowed character, stop. #
            return 'NA';
        }
    }

    # Return the average value for the whole sequence. #
    $average /= @{$sequence};
    $average = sprintf '%10.4f', $average;
    $average =~ s/\s/&nbsp;/g;

    return \%values, $average;
}
