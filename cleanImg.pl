#!/usr/bin/perl

use POSIX qw( strftime ) ;
use Date::Calc qw(Add_Delta_Days);
use File::Basename;

my $name = basename($0);

%datHash  ;
@datesuse ;
%newHash ;

$contName="$ARGV[0]" ;
chomp($contName) ; 	 


unless ($contName =~ /[a-zA-Z]+$/){
 print "Error:Please input valid contaner Name\n";
 usage() ;
 exit 1 ;
}

$keepdays="$ARGV[1]" ;

unless ($keepdays =~ /[0-9]+$/){
 print "Error:Please input valid days\n";
 usage() ;
 exit 1 ;
}

unless( $contName and $keepdays ) {

  print "$name:Error:Insuffcient input, Please input both contanerName and number of days to keep image\n"  ;
  usage() ;
  exit  1 ;
}


sub usage {

 print "USAGE:\n";
 print "$name <contaner_name> <number_days_keep_image>\n" ;

}


@listImges=`curl -u _token:\$\(gcloud auth print-access-token\)  \"https://us.gcr.io/v2/pg-us-p-app-109512/\"$contName\"/tags/list\"\| python -mjson.tool ` ;


print "Input Container Name:$contName\n"; 

foreach $item (@listImges){

   #print "$item\n";

   if ( "$item" =~  /(sha256:.*)\".*/ ) {
    $img = "$1" ;
   # print "$1=>";

   } 

   if ("$item" =~ /\"timeCreatedMs\":\s+\"(.*)\"\,/ ) {
      $formatted = strftime ( "%Y%m%d" , localtime ( $1 /1000)) ;
      #print "Date:$formatted\n";   
   }
   
    $datHash{"$formatted"} = "$img" ; 

}

foreach $key (sort keys %datHash)
{
   $value = $datHash{$key};
   #print "  $key ===>  $value\n";

}
#exit,

$date = strftime "%m/%d/%Y/%H/%M/%S", localtime;
($month,$day,$year,$hour,$min,$sec) = split ('/',$date) ;


my ($y,$m,$d) = Add_Delta_Days( $year, $month, $day,  -$keepdays );


if ( $m < 10 ) {
  $m = "0$m" ;
}

if ( $d < 10 ) {
  $d = "0$d" ;

}
$date = strftime "%Y%m%d", localtime;


@finalDates = get_dates( "$y-$m-$d" ,"$year-$month-$day" );
#print join(',', get_dates('2005-08-29', '2005-09-02'));
foreach $d (@finalDates) {

  #print "$d\n" ;
  $d =~ s/(\d{4})\-(\d\d)\-(\d\d)/$1$2$3/ ;
  #print "DAtes:$d\n" ;

 push(@datesuse,$d)  ;
  
}

#print "@datesuse\n" ;

@hashKeys=keys  %datHash ;

#print "Hash Keys @hashKeys\n ";


foreach $elem (@datesuse) {
     delete $datHash{$elem} ;
}

#NOw we are ready to delete the required images from contaner registry 
foreach $i ( keys %datHash ) {

            $acces_token=`gcloud auth print-access-token` ;
            chomp($acces_token) ;
            $gce_url="https://us.gcr.io/v2/pg-us-p-app-109512/$contName/manifests" ;

            print "Date:$i ===> Image to be delated:$datHash{$i}\t\t \n" ;
            $image=$datHash{$i} ;
            $i =~ s/(\d{4})(\d\d)(\d\d)/$1-$2-$3/ ;
            print "Date of upload:$i\n" ;
            print"---------------------------------------------------------\n"; 
       

#NOw delete the image older than 3 week
@arg = "curl -X DELETE -u _token:${acces_token} https://us.gcr.io/v2/pg-us-p-app-109512/$contName/manifests/$image" ;

#system @arg ;
         
} 

sub get_dates {
    my ($from, $to) = @_;
    chomp($from) ;
    chomp($to) ;
    my @return_dates = $from;
    my $intermediate = $from;

    while ($intermediate ne $to) {
        $intermediate =  sprintf "%04d-%02d-%02d", Add_Delta_Days(split(/-/, $intermediate), 1)  ;
        push @return_dates, $intermediate;
        
    }
    return @return_dates;   

}
