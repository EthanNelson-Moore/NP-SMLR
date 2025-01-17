#!/usr/bin/perl

use strict;
require "getopts.pl";
use vars qw($opt_b $opt_e $opt_o $opt_h);
use Cwd 'abs_path';
use File::Basename;
my $soft_dir = dirname(abs_path(__FILE__));

my $help_message = "--------------------------------------------\n";
$help_message .= "How to use this program:\n";
$help_message
    .= "Command: \t./NP-SMLR.pl -b sorted_bam_file -e event_align_scale -o output_dir\n\n";
$help_message .= "Parameters\n";
$help_message .= "\t-b\tName of the BAM file that records the alignment of reads. The BAM file must be sorted.\n";
$help_message .= "\t-e\tEvent alignment file generated by \"nanopolish eventalign\" (with flag --scale-events)\n";
$help_message .= "\t-o\tName of output folder\n\n";
$help_message .= "--------------------------------------------\n";

&Getopts('b:e:o:h');
if ( $opt_h == 1 || !($opt_b && $opt_e && $opt_o) ) {
    die $help_message;
}
my ( $bam, $event, $output ) = ( $opt_b, $opt_e, $opt_o );
print "[COMMAND]: NP-SMLR.pl -b $bam -e $event -o $output\n";

mkdir $output;

print "Getting forward read names...\n";
my $cmd_fwd_rdname = "samtools view $bam | awk '{if(\$2==\"0\") print \$1}' > $output/fwd_rdname.txt";
if(system($cmd_fwd_rdname) != 0) {
    die "Getting forward read names failed!";
}

print "Calculating likelihood...\n";
my $cmd_likelihood = "$soft_dir/bin/Likelihood $soft_dir/par/parameters_Gaussian.txt $soft_dir/par/parameters_EM.txt $event $output/fwd_rdname.txt > $output/likelihood.txt";
if (system($cmd_likelihood) != 0) {
    die "Likelihood calculation failed!";
}

print "Calculating GpC methylation score...\n";
my $cmd_detection = "$soft_dir/bin/Detection $output/likelihood.txt $soft_dir/par/overlap.txt > $output/detection.txt";
if (system($cmd_detection) != 0) {
    die "GpC methylation score calculation failed!";
}

print "Generating bed file...\n";
my $cmd_bed = "bedtools bamtobed -i $bam > $output/alignment.bed";
if (system($cmd_bed) != 0) {
    die "Bed file generation failed!";
}

print "Calculating nucleosome positioning...\n";
my $cmd_ncls_pos = "$soft_dir/bin/NclsPos $output/detection.txt $output/alignment.bed > $output/ncls_pos.bed";
if (system($cmd_ncls_pos) != 0) {
    die "Nucleosome positioning calculation failed!";
}

print "Finished.\n";
