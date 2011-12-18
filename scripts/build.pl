#!/usr/bin/perl -w 
#
# convert, build and montage svg files.
#
# we use ImageMagick (convert, montage), JSON, XML::LibXML and librsvg2.
#
# sudo apt-get -y install libxml-libxml-perl libjson-perl librsvg2-bin

use strict;
use warnings;

use utf8;

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

# for png2png
my $png;
my $pngDir; # rel. image path to png file

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
    "png=s"   => \$png,
    "pngs=s"  => \$pngDir,
    );

my $cmds = "help|svg2png|png2png|template|xplanet";
my $stys = "flat|simple|fancy|glossy";

sub u {
    my $app = $0; my $err = shift;
    print STDERR << "USAGE";
 usage:
      $app --cmd [$cmds] --svg [dir] --mask [D+D+DxD] --sty [$stys] --res [DxD,..] --out [dir]

USAGE
    if (defined $err) {
	print STDERR " ".RED."error:".RESET." ".$err."\n\n";
	exit 1;
    } else {
	exit 0;
    }
}

if (!$cmd)               {u("missing  --cmd. Exiting.")}
if ($cmd eq "help")      {u()}
if ($cmd !~ /^($cmds)$/) {u("valid --cmd [$cmds]")}

my $jsonDB;

if (defined $json) {
    $jsonDB = readJson($json);

    if (!defined $jsonDB) {u("Error reading json db. Exiting")}
}

if ($cmd eq "xplanet") {
    if (!defined $jsonDB) {
	u("missing --json [file], eg.: iso-3166-1.json. Exiting.");
    }

    if (!$out)   {u("missing --out [dir], eg.: build. Exiting.")}
    if (!-d $out){u("--out dir \"".$out."\" does not exist. Exiting.")}

    if (!$res) { u("missing --res [DxD], eg.: 16x16. Exiting.")}
    my ($resX,$resY) = $res =~ m#(\d+)x(\d+)#;

    if (!defined $resX or $resX eq 0){
	u("invalid res: \"".$res."\", width  must be > 0.")
    }
    if (!defined $resY or $resY eq 0){
	u("invalid res: \"".$res."\", height must be > 0.")
    }

    my %d = %{$jsonDB->{Results}};

    my @langs;

    if (!defined $lang or $lang eq "all") {
	foreach my $l (split(",", "af,sq,ar,be,bg,ca,zh,zh-TW,hr,cs,da,nl,et,tl,fi,fr,gl,de,el,ht,iw,hi,hu,is,id,ga,it,ja,ko,lv,lt,mk,ms,mt,no,fa,pl,pt,ro,ru,sr,sk,sl,es,sw,sv,th,tr,uk,vi,cy,yi")) {
	    push @langs, $l;
	}
    } else {
	foreach my $l (split(",", $lang)) {
	    push @langs, $l;
	}
    }

    if (!scalar @langs) {
	u("Error parsing --lang \"".$lang."\", eg.: \"all\" or \"en,..\". Exiting.",1);
    }

    print STDERR " generating:\n";
    foreach my $l (@langs) {

	my $file = $out."/xplanet/markers/iso-country-code-".$l; 

	print STDERR "  ".$file."\n";

	my $content = "";
	foreach my $co (sort keys %d) {
	    my $img = lc($co);
	    
	    my $x = $d{$co}{GeoPt}[0];
	    my $y = $d{$co}{GeoPt}[1];
	    
	    my $name = $d{$co}{Name};

	    if (defined $d{$co}{Names}{$l}) {
		$name = $d{$co}{Names}{$l}; # get translated country name
		print STDERR "  ".$img." ".$name."\n";
	    }
	    
	    $content .= sprintf "%05.2f %05.2f\t\"%s\"\t\timage=res-%sx%s/%s.png\n", $x, $y, $name, $resX, $resY, $img;
	}

	writeFile($file, $content, ":utf8");
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

my @pngs = ();
sub add_png_file {
    my $file = $File::Find::name;
    if ($file =~ m/.png$/) {
	push @pngs, $file;
#	print STDERR " adding   " . $file . "\n";
    } else {
#	print STDERR " skipping " . $file . "\n";
    }
}

if ($cmd eq "template") {
    if (!$imgSvg) {u("missing --svg [image], e.g.: ad.svg. Exiting.") }

    if (!$dirSvg) {u("missing --svgdir [rel path], e.g.: ../../svg/country-4x3. Exiting.") }

    if (!$imgBack) {u("missing --back [image], e.g.: 4x3-back-shadow.png. Exiting.") }

    if (!$imgFlag) {u("missing --flag [image], e.g.: ad.png. Exiting.") }

    if (!$imgFore) {u("missing --fore [image], e.g.: 4x3-fore-glossy.png. Exiting.") }

    if (!$res) { u("missing --res [DxD], e.g.: 1280x960. Exiting.") }
    my ($resX,$resY) = $res =~ m#(\d+)x(\d+)#;
    if ($resX eq 0){u("invalid res: \"".$res."\", width  must be > 0.")}
    if ($resY eq 0){u("invalid res: \"".$res."\", height must be > 0.")}

    if (!$mask) {
	u("missing --mask [DxD+DxD+DxD], ".
	      "e.g.: 109x109+65x65+1065x742. Exiting.", 1);
    }
    my ($mX, $mY, $mrX, $mrY, $mW, $mH) =
	$mask =~ m#(\d+)x(\d+)\+(\d+)x(\d+)\+(\d+)x(\d+)#;

#    print STDERR "mask: ".$mX."x".$mY."+".$mrX."x".$mrY."+".$mW."x".$mH."\n";
    if ($mX eq 0) {u("invalid mask: \"".$mask."\", x must be > 0.")}
    if ($mY eq 0) {u("invalid mask: \"".$mask."\", y must be > 0.")}
    if ($mrX eq 0){u("invalid mask: \"".$mask."\", rx must be > 0.")}
    if ($mrX eq 0){u("invalid mask: \"".$mask."\", ry must be > 0.")}
    if ($mX eq 0) {u("invalid mask: \"".$mask."\", width must be > 0.")}
    if ($mX eq 0){u("invalid mask: \"".$mask."\", height must be > 0.")}

    if (!$geo) {
	u("missing --geo [DxD+DxD], ".
	      "e.g.: 77x77+1129x807. Exiting.", 1);
    }

    my ($geoX, $geoY, $geoW, $geoH) =
	$geo =~ m#(\d+)x(\d+)\+(\d+)x(\d+)#;

    if ($geoX eq 0) {u("invalid geo: \"".$geo."\", x must be >0.")}
    if ($geoY eq 0) {u("invalid geo: \"".$geo."\", y must be >0.")}

    if ($geoW eq 0) {u("invalid geo: \"".$geo."\", width  must be >0.")}
    if ($geoH eq 0) {u("invalid geo: \"".$geo."\", height must be >0.")}

    if (!$out) { u("missing --out [build dir], eg.: build/country-4x3-glossy. Exiting.")}

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

if ($cmd eq "png2png") {
    if (!$pngDir){u("missing --pngs [dir], e.g.: build/png-country-squared/res-512x512")}
    if (!-d $pngDir){u("--pngs \"".$pngDir."\" does not exist. Exiting.")}
    
    if (!$out)   {u("missing --out [dir], e.g.: build")}
    if (!-d $out){u("--out dir \"".$out."\" does not exist. Exiting.")}

    find(\&add_png_file, split(",", $pngDir));

    if (0 eq length @pngs) {
	u("no png files in ".$pngDir.". Exiting.");
    }

    if (!$res) { u("missing --res [DxD,..], eg.: 64x64,128x128. Exiting.")}

    my @rs = ();
    foreach my $r (split (",", $res)) {
	my ($w, $h) = ($r =~ m /(\d+)x(\d+)/);

	if ($w eq 0) {u("invalid res: \"".$r."\", width  must be > 0.")}
	if ($h eq 0) {u("invalid res: \"".$r."\", height must be > 0.")}
	if (!$w or !$h) {
	    u("could not parse: res \"".$r.
		  "\", must be [DxD,..]. Exiting.");
	}

	push @rs, {"w" => $w, "h" => $h};
    }

    foreach my $p (@pngs) {

	print STDERR " processing ".$p."\n";

	foreach my $r (@rs) {
	    my %dim = %{$r}; my $rx = $dim{w}; my $ry = $dim{h};
	    my $o = $p;
	    
	    my ($name, $path, $suffix) = fileparse($o, (".png"));
	    # keep things simple, make only 2 sub-dirs:
	    # path style is => build/png-dir/res-DxD, eg.:
	    #                  build/png-country-4x3/res-1280x960
	    $path =~ s#/#-#g; 
	    $path =~ s#-$##g;
	    $path =~ s#^svg#png#g;

	    # case for path starting with "build-png-" => "png-"
	    $path =~ s#^build-png-#png-#g;
	    $path =~ s#-res-.*##g;

	    my $png_out = $out."/".$path."/res-".$rx."x".$ry."/".$name.$suffix;
	    my $cmd = png2png($p, $png_out, $rx, $ry);

	    my ($n, $pa, $s) = fileparse($png_out, (".png"));
	    if (! -d $pa) {
		print STDERR " mkdir " . $pa . "\n";
		mkpath($pa);
	    }

#	    print STDERR " " . $cmd . "\n";
	    cmd_exec($cmd);
	}
    }
}

if ($cmd eq "svg2png") {
    if (!$dirSvg){u("missing --svgdir [dir], e.g.: svg/country-squared")}
    if (!-d $dirSvg){u("--svgdir \"".$dirSvg."\" does not exist. Exiting.")}
    
    if (!$out)   {u("missing --out [dir], e.g.: build")}
    if (!-d $out){u("--out dir \"".$out."\" does not exist. Exiting.")}

    find(\&add_svg_file, split(",", $dirSvg));

    if (0 eq length @svgs) {
	u("no svg files in ".$dirSvg.". Exiting.");
    }

    if (!$res) { u("missing --res [DxD,..], eg.: 64x64,128x128. Exiting.")}

    my @rs = ();
    foreach my $r (split (",", $res)) {
	my ($w, $h) = ($r =~ m /(\d+)x(\d+)/);

	if ($w eq 0) {u("invalid res: \"".$r."\", width  must be > 0.")}
	if ($h eq 0) {u("invalid res: \"".$r."\", height must be > 0.")}
	if (!$w or !$h) {
	    u("could not parse: res \"".$r.
		  "\", must be [DxD,..]. Exiting.");
	}

	push @rs, {"w" => $w, "h" => $h};
    }

    foreach my $s (@svgs) {
	foreach my $r (@rs) {
	    my %dim = %{$r}; my $rx = $dim{w}; my $ry = $dim{h};
	    my $o = $s; $o =~ s/.svg$/.png/;

	    my ($name, $path, $suffix) = fileparse($o, (".png"));

	    # keep things simple, make only 2 sub-dirs:
	    # path style is => build/png-dir/res-DxD, eg.:
	    #                  build/png-country-4x3/res-1280x960
	    $path =~ s#/#-#g; 
	    $path =~ s#-$##g;
	    $path =~ s#^svg#png#g;

	    # case for path starting with "build-svg-" => "png-"
	    $path =~ s#^build-svg-#png-#g;

	    my $png_out = $out."/".$path."/res-".$rx."x".$ry."/".$name.$suffix;
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
	u("missing --res [DxD,..], e.g.: 8x8,16x16,64x64");
    }

    if (!$dirSvg) { u("missing --svg [dir], e.g.: svg/country-squared")}
    if (!-d $dirSvg) { u("--svg dir \"".$dirSvg."\" does not exist. Exiting.")}

    if (!$geo) { u("missing --geo [D+D+DxD], e.g.: 54+54+403x403")}

    if (!$out) { u("missing --out [dir], e.g.: build")}
    if (!-d $out) { u("--out dir \"".$out."\" does not exist. Exiting.")}

    if (!$sty) { u("missing --sty [$stys], e.g.: simple")}
    if ($sty !~ /^($stys)$/) { u("valid --sty [$stys]")}

    my @rs = ();
    foreach my $r (split (",", $res)) {
	my ($w, $h) = ($r =~ m /(\d+)x(\d+)/);

	if ($w eq 0) { u("invalid res: \"".$r."\". Width must be > 0.")}
	if ($h eq 0) { u("invalid res: \"".$r."\". Height must be > 0.")}
	if (!$w or !$h) {
	    u("could not parse: res \"".$r."\". Must be [DxD,..]. Exiting.");
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
    my $binmode = shift;

    my($filename, $dirs, $suffix) = fileparse($fName);

    if (! -d $dirs ) {
        mkpath($dirs);
    }

    open FILE, ">$fName" or die "Error writing file $fName: $!";
    if (defined $binmode) {
	binmode(FILE, $binmode);
    }
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
	if ($@){ u("Error reading json: $@", 1) }
	return $json;
    } else {
	u("Error reading ".$file.". Exiting.", 1);
    }
}

sub svg2png {
    my ($in, $o, $w, $h, $zoom) = @_;

    if (defined $zoom) {
	return "rsvg-convert -o ".$o." -w ".$w." -h ".$h." -z ".$zoom." ".$in;
#       return "inkscape -w ".$w." -h ".$h." --export-png=".$out. " ".$in;
    } else {
	return "rsvg-convert -o ".$o." -w ".$w." -h ".$h." ".$in;
    }
}

sub png2png {
    my ($in, $o, $w, $h) = @_;

    return "convert ".$in." -resize ".$w."x".$h." ".$o;
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
