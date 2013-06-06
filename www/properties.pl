#!/usr/bin/perl -T

=head1 NAME

B<PhysicoChemical_Descriptor>

=head1 DESCRIPTION

A CGI service for calculation of physicochemical properties of a given 
amino acid sequence.

=head1 USAGE

http://imgt.org/motifs/properties.pl?sequence="SEQUENCE"

=head1 EXAMPLE

http://imgt.org/motifs/properties.pl?sequence=RWMDR

=head1 DEPENDENCIES

-the Perl interpreter, >= 5.10

-CGI, >= 3.63 (Perl module)

-DBD::SQLite, >= 1.37 (Perl module)

-DBI, >= 1.622 (Perl module)

-List::MoreUtils, >= 0.33 (Perl module)

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
use List::MoreUtils qw(uniq);
use utf8;

our $VERSION = 'v1.00';

my $cgi = CGI->new;
print $cgi->header;

my $sequence = $cgi->param('sequence');

# Remove single and double quotes in the sequence, if any. #
$sequence =~ s/["|']//g;

# Stuff to be printed at the end of the page. #
my $bottom_info = << 'ENDHTML';
<hr/><sub>
This tool was primarily developed by D. Vlachakis, D. G. Kontopoulos and <a href='mailto:skossida@bioacademy.gr' style="text-decoration:none">S. Kossida</a> 
from the <a href='http://www.bioacademy.gr/bioinformatics/' style="text-decoration:none">Bioinformatics and Medical Informatics Research Group</a> of the<br>
<a href='http://www.bioacademy.gr/?lang=en' style="text-decoration:none">Biomedical Research Foundation, Academy of Athens, Greece</a> 
in collaboration with the <a href='http://www.imgt.org/IMGTinformation/LIGM.html' style="text-decoration:none">Laboratoire d'ImmunoGénétique Moléculaire</a> of the 
<a href='http://www.igh.cnrs.fr/EN/index.php' style="text-decoration:none">Institut de<br>Génétique Humaine, CNRS (UPR 1142), Montpellier, France</a>.
<br><br>
The <a href='https://github.com/dgkontopoulos/PhysicoChemical_Descriptor' style="text-decoration:none">source code</a> is freely available under the <a href='http://www.gnu.org/licenses/agpl.html' style="text-decoration:none">GNU Affero GPL</a>.
</sub>
ENDHTML

if ( $sequence =~ /^\s*$/ )    # Reject empty sequences. #
{
    print $cgi->start_html( -title => 'PC Descriptor || ERROR!' );

    # Header and error message. #
    print << "ENDHTML";
<center>
<table cols=2 width="100%" >
<tr>

<td align=left nowrap valign=middle width="70%">
<font size="+3" color="#000099"><b>WELCOME
<font size='+2'><br>to PhysicoChemical Descriptor<sup><small>($VERSION)</small></sup>!</b></font>
</td>
</font></td>

<td align=right valign=top width="30%">
<a href="http://www.imgt.org"><img src="http://imgt.org/IMGT_vquest/share/textes/images/logoIMGT.png" alt="IMGT"></a>
</td>
</tr>
</table>
<hr/>
<font face="Ubuntu Mono, Courier New"><b>ERROR!</b><br>No sequence was entered!</font>
</center>
ENDHTML

    print $bottom_info . $cgi->end_html;
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
<font size="+3" color="#000099"><b>WELCOME
<font size='+2'><br>to PhysicoChemical Descriptor<sup><small>($VERSION)</small></sup>!</b></font>
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

    # Header, input sequence and description. #
    print << "ENDHTML";
<center>
<table cols=2 width="100%" >
<tr>

<td align=left nowrap valign=middle width="70%">
<font size="+3" color="#000099"><b>WELCOME
<font size='+2'><br>to PhysicoChemical Descriptor<sup><small>($VERSION)</small></sup>!</b></font>
</td>

<td align=right valign=top width="30%">
<a href="http://www.imgt.org"><img src="http://imgt.org/IMGT_vquest/share/textes/images/logoIMGT.png" alt="IMGT"></a>
</td>
</tr>
</table>
</center>
<hr/>
<font face="Ubuntu Mono, Courier New">Input sequence:<br><b>&nbsp;$input_seq</b>
</font><br><br>
<font face="Ubuntu Mono, Courier New">The following tables display calculations of various physicochemical properties
of the input sequence.
<br>Scroll to the bottom of this page to see an explanation of the codes.</font>
<br><br><center>
ENDHTML

    # List the available properties. #
    my @properties = qw(
      Hydro_IMGT  Vol_IMGT ASA     b_rotR CASA_pos CASA_neg E
      E_sol       E_strain E_tor   E_vdw  logP_o_w logS     PEOE_PC_pos
      PEOE_PC_neg Vdw_area Vdw_vol VSA    Weight
    );

    # Sort properties alphabetically. #
    @properties = sort { lc $a cmp lc $b } @properties;

    # For each property, compute its value. #
    for ( 0 .. $#properties )
    {
        my ( $sequence, $values, $average ) =
          value_calc( $sequence, $properties[$_] );

        my $seq_length = length($sequence) + 1;
        my $property   = $properties[$_];

        $property =~ s/_pos/+/;
        $property =~ s/_neg/-/;
        $property =~ s/_o_w/(o\/w)/;

        # Units. #
        if ( $property eq 'Weight' )
        {
            $property .= '<sub>(g/mol)</sub>';
        }

        # Table name #
        print << "ENDHTML";
<table border='1'>
<tr><th bgcolor=F3E2A9 colspan=$seq_length><font face='Ubuntu Mono, Courier New'>$property</font></th></tr>
ENDHTML

        print '<tr>';
        my $index = 0;

        my @sequence = uniq @{$sequence};
        @sequence = sort { $a cmp $b } @sequence;

        # Column names. #
        for ( 0 .. $#sequence )
        {
            my $tag = $sequence[$_];
            my $occurences = grep { /$tag/ } @{$sequence};

            # Add the number of occurences for amino acids. #
            if ( $occurences > 1 )
            {
                $tag .= '<sub>' . q{(x} . $occurences . q{)} . '</sub>';
            }

            print
"<td bgcolor=FFFFB3 align=center><b><font face='Ubuntu Mono, Courier New'>$tag</font></b></td>\n";
            $index++;
        }
        print << "ENDHTML";

<td bgcolor=FFFFB3 align=center>
<b><font face='Ubuntu Mono, Courier New'>Average</font></b>
</td></tr><tr>
ENDHTML

        # Property values for each amino acid and on average. #
        for ( 0 .. $#sequence )
        {
            my $tag   = uc $sequence[$_];
            my $value = $values->{$tag};
            print
"<td align=center><font face='Ubuntu Mono, Courier New'>$value</font></td>\n";
        }
        print
"\n\n<td align=center><font face='Ubuntu Mono, Courier New'>$average</font></td></table><br>\n";
    }

    # Properties Codebook. #
    print << 'ENDHTML';
<br><hr/>
</center><font face="Ubuntu Mono, Courier New">
<b><u>Properties Codebook</u></b><br>
<ul type="circle">

<li><b>ASA:</b> Water accessible surface area calculated using a radius of 1.4 A for the water molecule.
A polyhedral representation is used for each atom in calculating the surface area.</li><br>

<li><b>b_rotR:</b> Fraction of rotatable bonds.</li><br>

<li><b>CASA-:</b> Negative charge weighted surface area.</li><br>

<li><b>CASA+:</b> Positive charge weighted surface area.</li><br>

<li><b>E:</b> Value of the potential energy.</li><br>

<li><b>E_sol:</b> Solvation energy.</li><br>

<li><b>E_strain:</b> Local strain energy: the current energy minus the value of the energy at a near local minimum.</li><br>

<li><b>E_tor:</b> Torsion (proper and improper) potential energy.</li><br>

<li><b>E_vdw:</b> Van der Waals component of the potential energy.</li><br>

<li><b>Hydro_IMGT:</b> Hydropathy value of amino acids, as reported by IMGT itself.</li><br>

<li><b>logP(o/w):</b> Log of the octanol/water partition coefficient (including implicit hydrogens). This
property is calculated from a linear atom type model.</li><br>

<li><b>logS:</b> Log of the aqueous solubility (mol/L). This property is calculated from an atom
contribution linear atom type model.</li><br>

<li><b>PEOE_PC-:</b> Total negative partial charge: the sum of the negative qi.</li><br>

<li><b>PEOE_PC+:</b> Total positive partial charge: the sum of the positive qi.</li><br>

<li><b>Vdw_area:</b> Area of van der Waals surface calculated using a connection table
approximation.</li><br>

<li><b>Vdw_vol:</b> Van der Waals volume calculated using a connection table approximation.</li><br>

<li><b>Vol_IMGT:</b> Volume value of amino acids, as reported by IMGT itself.</li><br>

<li><b>VSA:</b> Van der Waals surface area. A polyhedral representation is used for each atom in
calculating the surface area.</li><br>

<li><b>Weight:</b> Molecular weight (including implicit hydrogens) in atomic mass units with atomic
weights taken from CRC Handbook of Chemistry and Physics. CRC Press (1994).</li>

</ul></font>
<center><b><font face="Ubuntu Mono, Courier New">Reference:</font></b><br>
<table><td align='center' bgcolor='#F7F8E0'><font face="Ubuntu Mono, Courier New" size='-1'>
Molecular Operating Environment (MOE), 2012.10;<br>
Chemical Computing Group Inc.,<br>
1010 Sherbooke St. West, Suite #910,<br>
Montreal, QC, Canada, H3A 2R7, <b>2012</b>.</font></td></table></center>
ENDHTML
    print $bottom_info;
    print $cgi->end_html;
}
else    # Handle any other sequences. #
{
    print $cgi->start_html( -title => 'PC Descriptor || ERROR!' );

    # Header and error. #
    print << "ENDHTML";
<center>
<table cols=2 width="100%" >
<tr>

<td align=left nowrap valign=middle width="70%">
<font size="+3" color="#000099"><b>WELCOME
<font size='+2'><br>to PhysicoChemical Descriptor<sup><small>($VERSION)</small></sup>!</b></font>
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
    print $bottom_info . $cgi->end_html;
}

#############################################
# S   U   B   R   O   U   T   I   N   E   S #
#############################################

sub value_calc
{
    my ( $seq, $table ) = @_;

    my @sequence = split q{}, uc $seq;
    my %values;
    my $average = 0;

    # Get the value corresponding to each residue. #
    for ( 0 .. $#sequence )
    {
        my $residue          = uc $sequence[$_];
        my $select_statement = << "END";
select Value from $table where Residue = '$residue'
END

      # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
      # The line below must change to the amino acid properties database file. #
      # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #
        my $properties_loc = '/home/ligmdb/share/motifs/amino_acids.db';
        my $properties_db =
          DBI->connect( "dbi:SQLite:$properties_loc", q{}, q{} );

        my $db_sel = $properties_db->prepare($select_statement);
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
    $average /= ( $#sequence + 1 );
    $average = sprintf '%10.4f', $average;
    $average =~ s/\s/&nbsp;/g;

    return \@sequence, \%values, $average;
}
