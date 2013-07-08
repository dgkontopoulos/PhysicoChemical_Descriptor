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

use feature qw(say switch);

use CGI;
use DBI;
use utf8;

our $VERSION = 'v1.01';

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
<a href="http://www.imgt.org"><img style="border:none;" src="http://imgt.org/IMGT_vquest/share/textes/images/logoIMGT.png" alt="IMGT"></a>
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
<a href="http://www.imgt.org"><img style="border:none;" src="http://imgt.org/IMGT_vquest/share/textes/images/logoIMGT.png" alt="IMGT"></a>
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
<a href='http://www.imgt.org'><img style="border:none;" src='http://imgt.org/IMGT_vquest/share/textes/images/logoIMGT.png' alt='IMGT'></a>
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
<br>To use the advanced interface, click
<a href='http://imgt.org/pc_descriptor/properties.pl?sequence=$sequence&advanced=1' style='text-decoration:none'>here</a>.
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
        codebook( \@properties );
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
        print '</center><br><font face="Ubuntu Mono, Courier New">';

        # Properties Codebook. #
        codebook( \@properties );
    }
    elsif ( $advanced == 1 )    # Advanced interface, specify parameters. #
    {

        # Advanced interface text and beginning the form #
        print << "ENDHTML";
<font face='Ubuntu Mono, Courier New'>
This is the advanced interface of the tool. To go back to the simple interface, click
<a href='http://imgt.org/pc_descriptor/properties.pl?sequence=$sequence' style='text-decoration:none'>here</a>.
<br>Otherwise, please select the physicochemical properties to compute for the input sequence.
<br>To download the complete Properties Codebook, click
<a href='http://tinyurl.com/pc-descriptor-codebook' style='text-decoration:none'>here</a>.
</font>

<form id = 'submit' method = 'post'
action=http://imgt.org/pc_descriptor/properties.pl?sequence=$sequence&advanced=1>

<input type=hidden name='sequence' value='$sequence'>
<input type=hidden name='advanced' value='1'>
<input type=hidden name='proceed' value='1'>
ENDHTML

        my ( $tables, $categories, $colors ) = get_available_properties();

        # Get and list the available properties. #
        say '<center><table cellspacing = "5"><tr>';
        for ( 0 .. @{$tables} - 1 )
        {
            if ( $_ % 8 == 0 )
            {
                say '</tr><tr></tr><tr></tr><tr>';
            }

            # Create checkbuttons. #
            print << "ENDHTML";
<td align="left"><font face='Ubuntu Mono, Courier New' size='2'
color = '$colors->{$categories->{$tables->[$_]}}'>
<input type=checkbox name='$tables->[$_]' value='1'>$tables->[$_]
</font></td><td></td>
ENDHTML
        }

        # Create the submit button. #
        print << 'ENDHTML';
</table><br>
<input id='submit' type='submit' value=' Submit '></form></center><br>
<font face="Ubuntu Mono, Courier New">
ENDHTML

        say << 'ENDHTML';
<center>
<table frame = 'box'><tr bgcolor='#FAFAD2'><td></td>
<td><center><b>LEGEND</b></td><td></td></tr><tr>
ENDHTML

        # Legend table. #
        my $legend_counter = 0;
        foreach ( keys %{$colors} )
        {
            if ( $legend_counter == 3 )
            {
                say '</tr><tr>';
                $legend_counter = 0;
            }
            say << "ENDHTML";
<td><center>
<font face='Ubuntu Mono, Courier New' size='2' 
color = '$colors->{$_}'>$_</font>
</center></td>
ENDHTML
            $legend_counter++;
        }
        say '</center></td></tr></table></center></br>';
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
<a href="http://www.imgt.org"><img style="border:none;" src="http://imgt.org/IMGT_vquest/share/textes/images/logoIMGT.png" alt="IMGT"></a>
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

# Add units to properties, where available. #
sub add_units
{
    my ($property) = @_;

    for ($property)
    {
        $property .= '<sub>(g/mol)</sub>' when 'Weight';
        $property .= '<sub>(amu/Å<sup>3</sup>)</sub>' when 'density';
        $property .=
          '<sub>(Å<sup>2</sup>)</sub>' when
/^TPSA|vdw_area|vsa_acc|vsa_acid|vsa_base|vsa_don|vsa_hyd|vsa_other|vsa_pol$/;
        $property .= '<sub>(Å<sup>3</sup>)</sub>' when 'vdw_vol';
        $property .=
          '<sub>(kcal/mol)</sub>' when
/^AM1_E|AM1_Eele|AM1_HF|AM1_IP|MNDO_E|MNDO_Eele|MNDO_HF|MNDO_IP|PM3_E|PM3_Eele|PM3_HF|PM3_IP$/;
        $property .=
          '<sub>(eV)</sub>' when
          /^AM1_LUMO|AM1_HOMO|MNDO_LUMO|MNDO_HOMO|PM3_LUMO|PM3_HOMO$/;
        default {};
    }
    return $property;
}

sub codebook
{
    my ($properties) = @_;

    print << 'ENDHTML';
</center><br><hr/><font face="Ubuntu Mono, Courier New">
<b><u>Properties Codebook</u></b><br>
<ul type="circle">
ENDHTML

    foreach my $element ( @{$properties} )
    {
        my $select_text = << 'END_SQL';
Select Description from Descriptions where Code = ?;
END_SQL
        my $db_sel = $dbh->prepare($select_text);

        # Bind variable to avoid sql injection attack. #
        $db_sel->execute($element);
        my $result = $db_sel->fetchall_arrayref;

        if ( $result->[0]->[0] )
        {
            $element = string_reformat( $element, 'from_sql' );
            my $description = string_reformat( $result->[0]->[0], 'from_sql' );
            print << "ENDHTML";
<li><a name="$element"><b>$element:</b> $description</a></li><br>
ENDHTML
        }
    }
    print << 'ENDHTML';
</ul></font>
<center><b><font face="Ubuntu Mono, Courier New">Reference:</font></b><br>
<table><tr><td align='center' bgcolor='#F7F8E0'><font face="Ubuntu Mono, Courier New" size='-1'>
Molecular Operating Environment (MOE), 2012.10;<br>
Chemical Computing Group Inc.,<br>
1010 Sherbooke St. West, Suite #910,<br>
Montreal, QC, Canada, H3A 2R7, <b>2012</b>.</font></td></tr></table></center>
ENDHTML
    return 0;
}

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
        $property = add_units($property);

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
Select name, Category from sqlite_master, Descriptions where type = "table" and name = Code
ENDSQL
    my $result = $dbh->selectall_arrayref($sql);

    my $iterator = 0;
    my ( @tables, %categories, %colors );
    my @colors = (
        '#FF0000', '#1E90FF', '#FF8C00', '#8B008B', '#167D77', '#DB7093',
        '#5C4306', '#191919', '#006400', '#0000FF', '#7FFF00',
    );
    while ( $result->[$iterator]->[0] )
    {
        # Perform aesthetic conversions and store table names. #
        my $property = string_reformat( $result->[$iterator]->[0], 'from_sql' );
        push @tables, $property;

        my $category = $result->[$iterator]->[1];
        $categories{$property} = $category;

        unless ( defined $colors{$category} )
        {
            $colors{$category} = $colors[0];
            undef $colors[0];
            @colors = grep { defined } @colors;
        }
        $iterator++;
    }

    @tables = sort { lc $a cmp lc $b } @tables;
    return \@tables, \%categories, \%colors;
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
        $string =~ s/\^(\d+)(\W)/<sup>$1<\/sup>$2/g;
        $string =~ s/\[(.+?)\]/<b>[<\/b><i>$1<\/i><b>]<\/b>/g;
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

        my $db_sel = $dbh->prepare($select_statement);
        $db_sel->execute();

        my $result = $db_sel->fetchall_arrayref;
        if ( defined $result->[0]->[0] )
        {
            $average += $result->[0]->[0];
            $residue = uc $residue;
            $values{$residue} //= sprintf '%12.4f', $result->[0]->[0];
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
