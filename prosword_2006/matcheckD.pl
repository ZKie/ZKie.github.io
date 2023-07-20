use strict;
use warnings;
use List::Util qw(first max maxstr min minstr reduce shuffle sum);
use Text::Levenshtein qw(distance);

#My attempt to implement Baayen & al.'s MATCHECK model

#"BSS"
#Harald Baayen, Robert Schreuder, and Richard Sproat (2000).
#Modeling morphological segmentation in a parallel dual route
#framework for visual word recognition.
#In Frank van Eynde & David Gibbon (eds.)
#Lexicon Development for Speech and Language Processing.  Pp. 267-293.
#"B&S"
#Harald Baayen & Robert Schreuder (2000).
#Towards a psycholinguistic computational model
#for morphological parsing.
#Transactions of the Royal SocietyLondon A 358: 1281-1293.


#SETTING UP VARIABLES

#read in lexical entries and frequencies from a file
#format should be one item per line, frequency-tab-string:
#1  apple
#100 avocado
#etc.
open (LEXICONFILE, "EngLexBetterWithPrefixes.txt") || die "can't open lexicon file: $!";
my %frequencies = ();
my $line;
while(defined($line = <LEXICONFILE>)) {
  chomp($line);
  my @contents=split(/\t/,$line);
  $frequencies{$contents[1]} = $contents[0];
}
close (LEXICONFILE) || die "couldn't close lexicon file: $!";

my %probability = ();
my $time_steps = 50;
my $v_num_of_nodes = scalar keys %frequencies;

my $theta_threshold = 0.3; #free parameter, (0,1]
my $alpha_spike = 1; #free parameter
my $delta_baseline_decay = 0.3; #free parameter , (0,1)
my $zeta_forest = 2; #free parameter
my $epsilon_system_noise = 0; #free parameter--see BSS pp. 276-277

my %r_reached_threshold = ();
my @list_of_threshold_morphs;
my $target;
my $t_time;
my @spans_reached;
my %initial_activations = ();
my %activations = ();
my %delta_decay_rate = ();
my %similarities = ();
my %substrings = ();

#LOOP THROUGH TARGETS

#get, from an input file, list of words to parse and, for each word,
#lexical entries of interest to track
#format should be target-tab-itemtotrack1-tab-itemtotrack2-tab etc.
#unpleasant un  pleasant  unpleasant
#ungrammaticality un  grammatical grammatic al  ical  ungrammaticality  grammaticality
open (TARGETFILE, "RaffelsiefenWords.txt") || die "can't open targets file: $!";
my %targets = ();
while(defined($line = <TARGETFILE>)) {
  chomp($line);
  my @contents=split(/\t/,$line);
  $target = shift(@contents);
  $targets{$target} = [@contents]; #the rest of the line should be
  #the ones to track in the output file
}
close (TARGETFILE) || die "couldn't close lexicon file: $!";

open (BUFFEROUTPUTFILE, ">RaffelsiefenBUFFER.txt") || die "can't open file to put buffer results in: $!";
open (OUTPUTFILE, ">RaffelsiefenOUT.txt") || die "can't open file to put results in: $!";
  
foreach $target (keys(%targets)) {

  #TIME-STEP-ZERO ACTIVITIES
  #copy resting activations
  %initial_activations = %frequencies;
  %activations = %initial_activations;

  #initialize threshold-reaching: no one has reached
  foreach my $w (keys(%initial_activations)) {
     $r_reached_threshold{$w} = 0;
  }
  @list_of_threshold_morphs = ();

  #determine decay rates
  foreach my $w (keys(%initial_activations)) {
     $delta_decay_rate{$w} = f_forest_before_trees(
       g_short_and_frequent($delta_baseline_decay, $alpha_spike, $w),
       $zeta_forest, $w);
  }

  #precompile similarity of each item to target
  foreach my $w (keys(%initial_activations)) {
    $similarities{$w} = similarity($w,$target);
  }

  #decide ahead of time whether each item is a substring of the target
  #this means fewer edge-alignments need to be calculated
  %substrings = ();
  foreach my $w (keys(%initial_activations)) {
    if ($target =~ /$w/) {
      $substrings{$w} = 1;
    }
  }

  #set up output files
  print (OUTPUTFILE "target $target\n");
  print (BUFFEROUTPUTFILE "target $target\n");
  my @array_to_print = @{$targets{$target}};
  foreach my $w (@array_to_print) {
    print (OUTPUTFILE "$w\t");
  }
  foreach my $w (@array_to_print)  {
    print (OUTPUTFILE "$w\t");
  }
  print (OUTPUTFILE "\n");
  foreach my $w (@array_to_print) {
    if (defined $activations{$w}) {
      print (OUTPUTFILE "$activations{$w}\t");
    }
  }
  print (OUTPUTFILE "\n");

  #STEP THROUGH TIME
  for($t_time=1; $t_time<=$time_steps; $t_time++)
  {
   update_activations();
   update_probabilities();
   #print activations and probabilities to file
   print_timestep(@array_to_print);
   #determine if a spanning has occurred
   foreach my $w (@list_of_threshold_morphs) {
    parse('', 0, $target, @list_of_threshold_morphs);
   }
  }
}
close (BUFFEROUTPUTFILE) || die "couldn't close buffer results file: $!";
close (OUTPUTFILE) || die "couldn't close results file: $!";

#SUBROUTINES
sub parse {
  my $prefix = shift;
  my $prefix_length = shift;
  my $current_target = shift;
  my @candidates = @_;
  my $span = '';

  foreach my $w (@candidates) {
    if($current_target eq $w) {
      $span = $prefix.$w;
      unless (grep { "$_" eq "$span" } @spans_reached) {
        print(BUFFEROUTPUTFILE "$span at $t_time\n");
        push (@spans_reached, $span);
      }
    }
    elsif($current_target =~ /^$w/) {
      my $length_of_w = length($w); #an attempt to speed up the program
      $prefix = $prefix.$w.'+';
      $prefix_length += $length_of_w;
      my $new_target = substr($current_target,$length_of_w);
      #recursive call to parse()!!
      parse($prefix,$prefix_length,$new_target,@candidates);
      #pop this morpheme off the prefix string
      $prefix = substr($prefix,0,length($prefix)-$length_of_w-1);
    }
  }
}

sub print_timestep{  #should get passed the array of items
#that have been selected (in an input file) for tracking in
#the output file
    my @selected_items = @_;
    foreach my $w (@selected_items) {
      if(defined $activations{$w}) {
        print (OUTPUTFILE "$activations{$w}\t");
      }
      else {
        print (OUTPUTFILE "0\t");
      }
    }
    foreach my $w (@selected_items) {
      if(defined $probability{$w}) {
        print (OUTPUTFILE "$probability{$w}\t");
      }
      else {
        print (OUTPUTFILE "0\t");
      }
    }
    print (OUTPUTFILE "\n");
    if($t_time/5 == int($t_time/5)) {
      print("time step is $t_time\n");
    }
}

sub g_short_and_frequent { #B&S eq. (2.3)
   my $delta = shift;
   my $alpha = shift;
   my $w_node = shift;
   my $g;
   my $length_of_w = length($w_node); #an attempt to speed up the program
   $g = $delta * $length_of_w/($length_of_w+
     ($alpha/$length_of_w)*log($frequencies{$w_node}));
   return $g;
}
sub f_forest_before_trees { #B&S (2.4)
   my $delta = shift;
   my $zeta = shift;
   my $w_node = shift;
   my $f;
   my $length_of_w = length($w_node);  #an attempt to speed up the program
   my $length_of_target = length($target); #an attempt to speed up the program
   if($zeta>0) {
     $f = $delta+(1-$delta)*(abs($length_of_w-$length_of_target)/
       max($length_of_w,$length_of_target))**$zeta
   }
   else {
   $f = $delta;  #not sure if this is correct;
   #B&S's equation looks like it has a typo, referring
   #to delta sub i--but this function is being used
   #to determine delta sub i...so I guessed that they
   #meant delta
   }
   return $f;

}

sub update_probabilities {   #B&S eq. (2.1)
  my $w;
  my $sum_of_activations = 0;
  foreach $w (keys(%initial_activations)) {
    $sum_of_activations += $activations{$w};
  }
  foreach $w (keys(%initial_activations)) {
    $probability{$w} = $activations{$w} /
      ($sum_of_activations + $epsilon_system_noise);
  }
  foreach $w (keys(%initial_activations)) {
    if($r_reached_threshold{$w} == 0 && $probability{$w} > $theta_threshold) {
      $r_reached_threshold{$w} = 1;
      push (@list_of_threshold_morphs, $w);
      print (BUFFEROUTPUTFILE "$w reached threshold $theta_threshold at time $t_time\n");
    }
  }
}

sub update_activations {    #B&S eq. (2.2)
  foreach my $w (keys(%initial_activations)) {
    my $on_hold_value = on_hold($w);  #an attempt to speed up the program
    my $decay_rate_of_w = $delta_decay_rate{$w}; #an attempt to speed up the program
    my $activation_of_w = $activations{$w};
    my $initial_activation_of_w = $initial_activations{$w};
    $activations{$w} = $on_hold_value*$activation_of_w/$decay_rate_of_w
      + (1-$on_hold_value)*($initial_activation_of_w+$decay_rate_of_w*
      abs($activation_of_w-$initial_activation_of_w));
      #I'm guessing that there's a typo, because in B&S
      #the last term has the potential to be negative.
      #In their text it has curly brackets around it;
      #maybe that was supposed to be absolute value?
  }
}

sub on_hold {   #indicator function
#a node is on hold if its activation weight is still
#being allowed to increase
#BSS pp. 288-289 (in def. of 'activation weight')
    my $w_node = shift;
    my $indicator;
    if($r_reached_threshold{$w_node}==1) {
      $indicator = 0;
    }
    elsif($similarities{$w_node}>=$t_time) {
      $indicator = 1;
    }
    elsif(defined $substrings{$w_node}) {
      if (edge_aligned($w_node,$target)) {
        $indicator = 1;
      }
      else {
        $indicator = 0;
      }
    }
    else {
      $indicator = 0;
    }
    return $indicator;
}

sub similarity {  #BSS p. 288, under 'similarity metric'
  my $w1 = shift;
  my $w2 = shift;
  my $similarity;
  my $match = $w1=~/$w2/;
  my $length_of_w2 = length($w2);
  $similarity = $match*$length_of_w2+
   (1-$match)*($length_of_w2-distance($w1,$w2));
  return $similarity;
}

sub edge_aligned {
  my $w1 = shift;
  my $w2 = shift;
  my $success = 0;
#  if($w2 =~ /^$w1/ || $w2 =~ /$w1$/) {   #use this version for either-edge alignment
   if($w2 =~ /^$w1/) {   #use this version for left-alignment only
   $success = 1;
  }
  else  {  #recursive calls to edge_aligned
  #see BSS pp. 280-281: once an outer morpheme becomes
  #available, the adjacent inner morpheme acts as though
  #it's edge-aligned
    foreach my $w (@list_of_threshold_morphs) {
      my $substring;
      my $length_of_w = length($w);
      if(length($w1)>$length_of_w){
        if($w =~ /^$w1/
         && edge_aligned(substr($w1,$length_of_w),$w2)) {  #recursion!
          $success = 1;
        }
#        elsif($w =~ /$w1$/  #uncomment this for either-edge alignment
#         && edge_aligned(substr($w1,$length_of_w),$w2)) {  #recursion!
#          $success = 1;
#        }
      }
    }
  }
  return $success;
}
