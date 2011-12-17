#!/usr/bin/perl -w 
#
# convert, build and montage svg files.
#
# we use inkscape and XML::LibXML.
#
#

use strict;
use warnings;

use Data::Dumper;

use File::Find;
use File::stat;
use File::Path;
use File::Basename;

use Getopt::Long qw(GetOptions);

use JSON -support_by_pp;

use Term::ANSIColor qw(:constants);

use XML::LibXML;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

local $| = 1; # auto flush

my $cmds = "help|svg2png|template|xplanet";
my $stys = "flat|simple|fancy|glossy";

sub usage {
    my $app = $0;
    my $err = shift; my $isErr = shift;
    print STDERR << "USAGE";
 usage:
      $app --cmd [$cmds] --svg [dir] --mask [D+D+DxD] --sty [$stys] --res [DxD,..] --out [dir]

USAGE
    if (defined $err) {
	print STDERR " ".
	    (defined $isErr ? (RED."error:".RESET) : "").
	    " ".$err."\n\n"; }

    exit 1;
}

my $cmd; # cmd, see "cmds" above

my $geo; # geometry, eg.: 77x77+1129x807
my $dirSvg; # directory to svg images (for command svg2png)
my $sty; # style, see "stys" above

my $res; # comma sep. list of resolutions for png output
my $out; # rel. dir path to output

my $imgSvg; # rel. image path to svg file
my $imgFore; my $imgFlag; my $imgBack; # images for template command
my $mask; # [D+D+DxD] mask spec for template command

my $zoom; # for svg2png

# for xplanet
my $json; my $lang;

GetOptions(
    "cmd=s" => \$cmd,
    "svg=s" => \$imgSvg,
    "svgdir=s" => \$dirSvg,
    "geo=s" => \$geo,
    "res=s" => \$res,
    "sty=s" => \$sty,
    "out=s" => \$out,
    "fore=s" => \$imgFore,
    "flag=s" => \$imgFlag,
    "mask=s" => \$mask,
    "back=s" => \$imgBack,
    "zoom=f" => \$zoom,
    "json=s" => \$json,
    "lang=s" => \$lang,
    );

if (!$cmd) { usage("missing  --cmd. Exiting.", 1); }
if ($cmd eq "help") { usage(); }
if ($cmd !~ /^($cmds)$/) { usage("valid --cmd [$cmds]", 1); }

my $jsonDB;

if (defined $json) {
    $jsonDB = readJson($json);
}

if ($cmd eq "xplanet") {
    if (!defined $jsonDB) {
	usage("missing --json [file], eg.: iso-3166-1.json. Exiting.",1);
    }

    if (!$out)   {usage("missing --out [dir], eg.: build. Exiting.",1)}
    if (!-d $out){usage("--out dir \"".$out."\" does not exist. Exiting.",1)}

    if (!$res) { usage("missing --res [DxD], eg.: 16x16. Exiting.", 1) }
    my ($resX,$resY) = $res =~ m#(\d+)x(\d+)#;

    if (!defined $resX or $resX eq 0){
	usage("invalid res: \"".$res."\", width  must be > 0.",1)
    }
    if (!defined $resY or $resY eq 0){
	usage("invalid res: \"".$res."\", height must be > 0.",1)
    }

    my %d = %{$jsonDB->{Results}};

    my @langs;

    if (!defined $lang or $lang eq "all") {
	# TODO add translated language names here
	push @langs, "en";
    } else {
	foreach my $l (split(",",$lang)) {
	    push @langs, $l;
	}
    }

    if (!scalar @langs) {
	usage("Error parsing --lang \"".$lang."\", eg.: \"all\" or \"en,..\". Exiting.",1);
    }

    my $content = "";

    print STDERR " generating:\n";
    foreach my $l (@langs) {

	my $file = $out."/xplanet/markers/iso-country-code-".$l; 

	print STDERR "  ".$file."\n";

	foreach my $co (sort keys %d) {
	    my $img = lc($co);
	    
	    my $x = $d{$co}{GeoPt}[0];
	    my $y = $d{$co}{GeoPt}[1];
	    
	    my $name = $d{$co}{Name};
	    
	    $content .= sprintf "%05.2f %05.2f\t\"%s\"\t\timage=res-%sx%s/%s.png\n", $x, $y, $name, $resX, $resY, $img;
	}

	writeFile($file, $content);
    }
    print STDERR " done.\n";
}

my @svgs = ();

sub add_svg_file {
    my $file = $File::Find::name;

    if ($file =~ m/.svg$/) {
	push @svgs, $file;
#	print STDERR " adding   " . $file . "\n";
    } else {
#	print STDERR " skipping " . $file . "\n";
    }
}

if ($cmd eq "template") {
    if (!$imgSvg) {usage("missing --svg [image], e.g.: ad.svg. Exiting.", 1) }

    if (!$dirSvg) {usage("missing --svgdir [rel path], e.g.: ../../svg/country-4x3. Exiting.", 1) }

    if (!$imgBack) {usage("missing --back [image], e.g.: 4x3-back-shadow.png. Exiting.", 1) }

    if (!$imgFlag) {usage("missing --flag [image], e.g.: ad.png. Exiting.", 1) }

    if (!$imgFore) {usage("missing --fore [image], e.g.: 4x3-fore-glossy.png. Exiting.", 1) }

    if (!$res) { usage("missing --res [DxD], e.g.: 1280x960. Exiting.", 1); }
    my ($resX,$resY) = $res =~ m#(\d+)x(\d+)#;
    if ($resX eq 0){usage("invalid res: \"".$res."\", width  must be > 0.",1);}
    if ($resY eq 0){usage("invalid res: \"".$res."\", height must be > 0.",1);}

    if (!$mask) {
	usage("missing --mask [DxD+DxD+DxD], ".
	      "e.g.: 109x109+65x65+1065x742. Exiting.", 1);
    }
    my ($mX, $mY, $mrX, $mrY, $mW, $mH) =
	$mask =~ m#(\d+)x(\d+)\+(\d+)x(\d+)\+(\d+)x(\d+)#;

#    print STDERR "mask: ".$mX."x".$mY."+".$mrX."x".$mrY."+".$mW."x".$mH."\n";
    if ($mX eq 0) {usage("invalid mask: \"".$mask."\", x must be > 0.", 1); }
    if ($mY eq 0) {usage("invalid mask: \"".$mask."\", y must be > 0.", 1); }
    if ($mrX eq 0){usage("invalid mask: \"".$mask."\", rx must be > 0.", 1); }
    if ($mrX eq 0){usage("invalid mask: \"".$mask."\", ry must be > 0.", 1); }
    if ($mX eq 0) {usage("invalid mask: \"".$mask."\", width must be > 0.",1);}
    if ($mX eq 0){usage("invalid mask: \"".$mask."\", height must be > 0.",1);}

    if (!$geo) {
	usage("missing --geo [DxD+DxD], ".
	      "e.g.: 77x77+1129x807. Exiting.", 1);
    }

    my ($geoX, $geoY, $geoW, $geoH) =
	$geo =~ m#(\d+)x(\d+)\+(\d+)x(\d+)#;

    if ($geoX eq 0) {usage("invalid geo: \"".$geo."\", x must be >0.",1) }
    if ($geoY eq 0) {usage("invalid geo: \"".$geo."\", y must be >0.",1) }

    if ($geoW eq 0) {usage("invalid geo: \"".$geo."\", width  must be >0.",1)}
    if ($geoH eq 0) {usage("invalid geo: \"".$geo."\", height must be >0.",1)}

    if (!$out) { usage("missing --out [build dir], eg.: build/country-4x3-glossy. Exiting.", 1); }

    my $doc = XML::LibXML::Document->new("1.0", "UTF-8");

    my $svg = $doc->createElement("svg");
    $doc->setDocumentElement($svg);
    
    $svg->setAttribute("id",      "svg2");
    $svg->setAttribute("version",  "1.1");

    $svg->setAttribute("width",  $resX);
    $svg->setAttribute("height", $resY);
    
    $svg->setAttribute(
	"xmlns:inkscape",
	"http://www.inkscape.org/namespaces/inkscape");
    
    $svg->setAttribute(
	"xmlns:svg",
	"http://www.w3.org/2000/svg");
    
    $svg->setAttribute(
	"xmlns:sodipodi",
	"http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd");
    
    $svg->setAttribute(
	"xmlns:xlink",
	"http://www.w3.org/1999/xlink");
    
    ## defs
    my $defs = XML::LibXML::Element->new("defs");
    
    $svg->appendChild($defs);
    my $cp = XML::LibXML::Element->new("clipPath");
    
    $cp->setAttribute("clipPathUnits", "userSpaceOnUse");
    $cp->setAttribute("id", "clipPathFlag");
    
    my $rect = XML::LibXML::Element->new("rect");
    $rect->setAttribute("id",    "clipPathMask");
    $rect->setAttribute("width", $mW);
    $rect->setAttribute("height", $mH);
    $rect->setAttribute("x", $mX);
    $rect->setAttribute("y", $mY);
    $rect->setAttribute("rx", $mrX);
    $rect->setAttribute("ry", $mrY);
    
    $cp->appendChild($rect); $defs->appendChild($cp);
    
    ## layer back
    my $lb = XML::LibXML::Element->new("g");
    $lb->setAttribute("id", "layer_back");
    $lb->setAttribute("inkscape:groupmode", "layer");
    $lb->setAttribute("inkscape:label", "back");
    $lb->setAttribute("style", "display:inline");
    
    my $shadow = XML::LibXML::Element->new("image");
    $shadow->setAttribute("id", "image_back");
    $shadow->setAttribute("x", "0");
    $shadow->setAttribute("y", "0");
    $shadow->setAttribute("width", $resX);
    $shadow->setAttribute("height", $resY);
    $shadow->setAttribute("xlink:href", $imgBack);
    
    $lb->appendChild($shadow); $svg->appendChild($lb);

    ## layer mask
    my $lm = XML::LibXML::Element->new("g");
    $lm->setAttribute("id", "layer_mask");
    $lm->setAttribute("inkscape:groupmode", "layer");
    $lm->setAttribute("inkscape:label", "mask");
    $lm->setAttribute("style", "display:inline");
    
    my $m = XML::LibXML::Element->new("image");
    $m->setAttribute("id", "image_mask");
    $m->setAttribute("x", $geoX);
    $m->setAttribute("y", $geoY);
    $m->setAttribute("width", $geoW);
    $m->setAttribute("height", $geoH);
    $m->setAttribute("xlink:href", $dirSvg."/".$imgFlag);
    
#    print STDERR "SVG " . $imgFlag . "\n";
    
    $m->setAttribute("clip-path", "url(#clipPathFlag)");
    
    $lm->appendChild($m); $svg->appendChild($lm);
    
    ## layer fore
    my $lf = XML::LibXML::Element->new("g");
    $lf->setAttribute("id", "layer_fore");
    $lf->setAttribute("inkscape:groupmode", "layer");
    $lf->setAttribute("inkscape:label", "fore");
    $lf->setAttribute("style", "display:inline");
    
    my $fore = XML::LibXML::Element->new("image");
    $fore->setAttribute("id", "image_fore");
    $fore->setAttribute("x", "0");
    $fore->setAttribute("y", "0");
    $fore->setAttribute("width", $resX);
    $fore->setAttribute("height", $resY);
    $fore->setAttribute("xlink:href", $imgFore);
    
    $lf->appendChild($fore); $svg->appendChild($lf);
    
    writeFile($out."/".$imgSvg, $doc->toString());
}

if ($cmd eq "svg2png") {
    if (!$dirSvg)   {usage("missing --svgdir [dir], e.g.: svg/country-squared", 1);}
    if (!-d $dirSvg){usage("--svgdir \"".$dirSvg."\" does not exist. Exiting.",1);}
    
    if (!$out)   {usage("missing --out [dir], e.g.: build", 1); }
    if (!-d $out){usage("--out dir \"".$out."\" does not exist. Exiting.",1);}

    find(\&add_svg_file, split(",", $dirSvg));

    if (0 eq length @svgs) {
	usage("no svg files in ".$dirSvg.". Exiting.", 1);
    }

    if (!$res) { usage("missing --res [DxD,..], eg.: 64x64,128x128. Exiting.",1)}

    my @rs = ();
    foreach my $r (split (",", $res)) {
	my ($w, $h) = ($r =~ m /(\d+)x(\d+)/);

	if ($w eq 0) {usage("invalid res: \"".$r."\", width  must be > 0.",1);}
	if ($h eq 0) {usage("invalid res: \"".$r."\", height must be > 0.",1);}
	if (!$w or !$h) {
	    usage("could not parse: res \"".$r.
		  "\", must be [DxD,..]. Exiting.", 1);
	}

	push @rs, {"w" => $w, "h" => $h};
    }

    foreach my $s (@svgs) {
	foreach my $r (@rs) {
	    my %dim = %{$r}; my $rx = $dim{w}; my $ry = $dim{h};
	    my $o = $s; $o =~ s/.svg$/.png/;

	    my ($name, $path, $suffix) = fileparse($o, (".png"));

	    $path =~ s#/#-#g; # keep things simple, make only 1 sub-directory.
	    my $png_out = $out."/".$path."res-".$rx."x".$ry."/".$name.$suffix;
	    my $cmd = svg2png($s, $png_out, $rx, $ry, $zoom);

	    my ($n, $p, $s) = fileparse($png_out, (".png"));
	    if (! -d $p) {
		print STDERR " mkdir " . $p . "\n";
		mkpath($p);
	    }

#	    print STDERR " " . $cmd . "\n";
	    cmd_exec($cmd);
	}
    }
}

if ($cmd eq "montage") {
    if (!$res or !($res =~ m/^(\d+x\d+)(,(\d+x\d+))*/)) {
	usage("missing --res [DxD,..], e.g.: 8x8,16x16,64x64", 1);
    }

    if (!$dirSvg) { usage("missing --svg [dir], e.g.: svg/country-squared", 1); }
    if (!-d $dirSvg) { usage("--svg dir \"".$dirSvg."\" does not exist. Exiting.", 1); }

    if (!$geo) { usage("missing --geo [D+D+DxD], e.g.: 54+54+403x403", 1); }

    if (!$out) { usage("missing --out [dir], e.g.: build", 1); }
    if (!-d $out) { usage("--out dir \"".$out."\" does not exist. Exiting.", 1); }

    if (!$sty) { usage("missing --sty [$stys], e.g.: simple", 1); }
    if ($sty !~ /^($stys)$/) { usage("valid --sty [$stys]", 1); }

    my @rs = ();
    foreach my $r (split (",", $res)) {
	my ($w, $h) = ($r =~ m /(\d+)x(\d+)/);

	if ($w eq 0) { usage("invalid res: \"".$r."\". Width must be > 0.", 1); }
	if ($h eq 0) { usage("invalid res: \"".$r."\". Height must be > 0.", 1); }
	if (!$w or !$h) {
	    usage("could not parse: res \"".$r."\". Must be [DxD,..]. Exiting.", 1);
	}

	push @rs, {"w" => $w, "h" => $h};
    }

    print STDERR "resolutions: ";
    foreach my $r (@rs) {
	my %dim = %{$r}; print STDERR $dim{w} . "x" . $dim{h} . " ";
    }
    print STDERR "\n";

    my @ss = ();
    print STDERR "styles     : ";
    foreach my $s (split (",", $sty)) {
	print STDERR $s." ";
	push @ss, $s;
    }
    print STDERR "\n";

}

sub sec2human {
    my $s = shift;
    if    ($s >= 365*24*60*60) { return sprintf '%.1fy', $s/(365+*24*60*60)}
    elsif ($s >=     24*60*60) { return sprintf '%.1fd', $s/(24*60*60) }
    elsif ($s >=        60*60) { return sprintf '%.1fh', $s/(60*60) }
    elsif ($s >=           60) { return sprintf '%.1fm', $s/(60) }
    else                       { return sprintf '%.1fs', $s  }
}

sub fileAge {
    my $fName = shift;

    my $age = -M $fName; $age *= 24*60*60;

#    return sec2human($age);
    return $age;
}

sub writeFile {
    my $fName = shift;
    my $content = shift;

    my($filename, $dirs, $suffix) = fileparse($fName);

    if (! -d $dirs ) {
        mkpath($dirs);
    }

    open FILE, ">$fName" or die "Error writing file $fName: $!";

    print FILE $content;
    close FILE;
}

sub readFile {
    my $fName = shift;

    local $/=undef;

    open FILE, $fName or return undef;
    binmode FILE;

    my $string = <FILE>;
    close FILE;

    return $string;
}

sub readJson {
    my $file = shift;

    my $content = readFile($file);
    if (defined $content) {
	my $json = JSON->new->allow_nonref->utf8->relaxed->escape_slash->loose->allow_singlequote->allow_barekey->decode($content);
	if ($@){ usage("Error reading json: $@", 1) }
	return $json;
    } else {
	usage("Error reading ".$file.". Exiting.", 1);
    }
}

sub svg2png {
    my ($in, $out, $w, $h, $zoom) = @_;

    if (defined $zoom) {
	return "rsvg-convert -o ".$out." -w ".$w." -h ".$h." -z ".$zoom." ".$in;
#       return "inkscape -w ".$w." -h ".$h." --export-png=".$out. " ".$in;
    } else {
	return "rsvg-convert -o ".$out." -w ".$w." -h ".$h." ".$in;
    }
}

sub cmd_exec {
    my $cmd = shift;

    my $out = `$cmd`; my $ret = ${^CHILD_ERROR_NATIVE};

    if ($ret eq 0) {
	print STDERR " ".$cmd." # ".GREEN."ok".RESET."\n";
    } else {
	print STDERR " ".$cmd." # ".RED."fail".RESET.": ".$out."\n";
	exit 1;
    }
}

1;
