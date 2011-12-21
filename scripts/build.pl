#!/usr/bin/perl -w 
#
# convert, build and montage svg files.
#
# we use:
# *  ImageMagick: convert, montage
# * Perl Modules: JSON, XML::LibXML
# *     librsvg2: rsvg-convert
#
# on Debian / Ubuntu you can install these packages as follows:
#
# $ sudo apt-get -y install imagemagick
# $ sudo apt-get -y install libxml-libxml-perl libjson-perl librsvg2-bin
#

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
my $geoScale; # geometry scale factor. eg.: 0.781
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

# for example cmd xplanet
my $json; my $lang;

GetOptions(
    "cmd=s" => \$cmd,
    "svg=s" => \$imgSvg,
    "svgs=s" => \$dirSvg,
    "geo=s" => \$geo,
    "geoscale=s" => \$geoScale,
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

my $cmds = "help|svg2png|png2png|svg2svg|example";
my $stys = "flat|simple|fancy|glossy";

sub u {
    my $app = $0; my $err = shift;
    print STDERR << "USAGE";
 usage:
      $app --cmd [$cmds] --svg [dir] --mask [D+D+DxD] --sty [$stys] --res [DxD,..] --out [dir]

USAGE
    if (defined $err) {
	print STDERR " ".RED."error:".RESET." ".$err." Exiting.\n\n";
	exit 1;
    } else {
	exit 0;
    }
}

if (!$cmd)               {u("missing  --cmd.")}
if ($cmd eq "help")      {u()}
if ($cmd !~ /^($cmds)$/) {u("valid --cmd [$cmds]")}

my $jsonDB;

if (defined $json) {
    $jsonDB = readJson($json);

    if (!defined $jsonDB) {u("Error reading json db.")}
}

if ($cmd eq "example") {
    my $subcmd = shift || "list";

    if ($subcmd eq "list" or $subcmd eq "help") {
	print STDERR "Available --cmd example commands:\n\n";
	print STDERR " kml     - generate kml geo files.\n";
	print STDERR " xplanet - generate xplanet marker config files.\n";
	print STDERR "\n";
    } elsif ($subcmd eq "xplanet") {
	example_xplanet();
    } elsif ($subcmd eq "kml") {
	example_kml();
    }
}

sub example_xplanet {
    if (!defined $jsonDB) {
	u("missing --json [file], eg.: iso-3166-1.json.");
    }

    if (!$out)   {u("missing --out [dir], eg.: build.")}
    if (!-d $out){u("--out dir \"".$out."\" does not exist.")}

    if (!$res) { u("missing --res [DxD], eg.: 16x16.")}
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
	u("Error parsing --lang \"".$lang."\", eg.: \"all\" or \"en,..\".");
    }

    print STDERR " generating:\n";
    foreach my $l (@langs) {

	my $file = $out."/xplanet/markers/iso-countries-".$l;

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

sub example_kml {
    if (!defined $jsonDB) {
	u("missing --json [file], eg.: iso-3166-1.json.");
    }

    if (!$out)   {u("missing --out [dir], eg.: build.")}
    if (!-d $out){u("--out dir \"".$out."\" does not exist.")}

    if (!$res) { u("missing --res [DxD], eg.: 16x16.")}
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
	u("Error parsing --lang \"".$lang."\", eg.: \"all\" or \"en,..\".");
    }

    print STDERR " generating:\n";
    foreach my $l (@langs) {

	my $file = $out."/kml/iso-countries-".$l."/doc.kml"; 

	print STDERR "  ".$file."\n";

	my $dom = XML::LibXML::Document->new("1.0", "UTF-8");
	
	my $root = $dom->createElement("kml");
	$dom->setDocumentElement($root);
	
	$root->setAttribute("xmlns:gx",   "http://www.opengis.net/kml/2.2");
	$root->setAttribute("xmlns:kml",  "http://www.opengis.net/kml/2.2");
	$root->setAttribute("xmlns:atom", "http://www.w3.org/2005/Atom");

	my $kml = XML::LibXML::Element->new("Document");
	$root->appendChild($kml);

	my $name = XML::LibXML::Element->new("name"); $kml->appendChild($name);
	$name->appendText("iso-country-code-".$l);

	my $open = XML::LibXML::Element->new("open"); $kml->appendChild($open);
	$open->appendText("1");

	my $desc = XML::LibXML::Element->new("description");
	$desc->appendText("iso-countries-".$l);
	$kml->appendChild($desc);

	my $doc = $kml;

#	my @cos = ("DE");
	my @cos = sort keys %d;
	foreach my $co (@cos) {
#	    print STDERR " $co \n";
	    my $img = lc($co);
	    
	    my $x = $d{$co}{GeoPt}[0];
	    my $y = $d{$co}{GeoPt}[1];
	    
	    my $name = $d{$co}{Name};

	    if (defined $d{$co}{Names}{$l}) {
		$name = $d{$co}{Names}{$l}; # get translated country name
#		print STDERR "  ".$img." ".$name."\n";
	    }

	    my $stylemap =  XML::LibXML::Element->new("StyleMap");
	    $stylemap->setAttribute("id", "style_map_".$img);

	    my $pair1 = XML::LibXML::Element->new("Pair");
	    $stylemap->appendChild($pair1);

	    my $key1 = XML::LibXML::Element->new("key");
	    $key1->appendText("normal");
	    $pair1->appendChild($key1);

	    my $styleurl1 = XML::LibXML::Element->new("styleUrl");
	    $styleurl1->appendText("#style_".$img);
	    $pair1->appendChild($styleurl1);

	    my $pair2 = XML::LibXML::Element->new("Pair");
	    my $key2 = XML::LibXML::Element->new("key");
	    $key2->appendText("highlight");

	    my $styleurl2 = XML::LibXML::Element->new("styleUrl");
	    $styleurl2->appendText("#style_".$img);
	    $pair2->appendChild($styleurl2);

	    $doc->appendChild($stylemap);
   
	    my $style = XML::LibXML::Element->new("Style");
	    $style->setAttribute("id", "style_".$img);

	    my $iconstyle = XML::LibXML::Element->new("IconStyle");

	    my $scale =  XML::LibXML::Element->new("scale");
	    $scale->appendText("1.1");
	    $iconstyle->appendChild($scale);

	    my $icon =  XML::LibXML::Element->new("Icon");
	    $iconstyle->appendChild($icon);

	    my $href =  XML::LibXML::Element->new("href");
	    $href->appendText($img.".png");
	    $icon->appendChild($href);

	    $style->appendChild($iconstyle);

	    $doc->appendChild($style);
    	}

	foreach my $co (@cos) {
	    my $img = lc($co);
	    
	    my $x = $d{$co}{GeoPt}[0];
	    my $y = $d{$co}{GeoPt}[1];
	    
	    my $cname = $d{$co}{Name};

	    if (defined $d{$co}{Names}{$l}) {
		$cname = $d{$co}{Names}{$l}; # get translated country name
#		print STDERR "  ".$img." ".$cname."\n";
	    }

	    my $placemark = XML::LibXML::Element->new("Placemark");
	    
	    my $name = XML::LibXML::Element->new("name");
	    $placemark->appendChild($name);
	    $name->appendText($cname);

#	    my $snippet = XML::LibXML::Element->new("Snippet");
#	    $placemark->appendChild($snippet);

#	    my $desc = XML::LibXML::Element->new("description");
#	    $placemark->appendChild($desc);
#	    $desc->appendText($img . " - " . $cname);

	    my $styleUrl = XML::LibXML::Element->new("styleUrl");
	    $placemark->appendChild($styleUrl);
	    $styleUrl->appendText("#style_map_".$img);

	    my $point = XML::LibXML::Element->new("Point");
	    $placemark->appendChild($point);

	    my $coords = XML::LibXML::Element->new("coordinates");
	    $point->appendChild($coords);
	    $coords->appendText($y.",".$x);

	    $doc->appendChild($placemark);
	}

	$root->appendChild($doc);
	writeFile($file, $dom->toString(), ":utf8");
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

if ($cmd eq "svg2svg") {
    if (!$imgSvg) {u("missing --svg [output image], eg.: ad.svg.")}
    if (!$dirSvg) {u("missing --svgs [rel path], eg.: ../../svg/country-4x3.")}
    if (!$imgBack){u("missing --back [image], eg.: 4x2-back-shadow.png.")}
    if (!$imgFlag){u("missing --flag [input image], eg.: ad.svg.")}
    if (!$imgFore){u("missing --fore [image], eg.: 4x2-fore-glossy.png.")}

    if (!$res) { u("missing --res [DxD], e.g.: 1280x960.")}
    my ($resX,$resY) = $res =~ m#(\d+)x(\d+)#;
    if ($resX eq 0){u("invalid --res: \"".$res."\", width  must be > 0.")}
    if ($resY eq 0){u("invalid --res: \"".$res."\", height must be > 0.")}

    if (!$mask) {
	u("missing --mask [DxD+DxD+DxD], eg.: 109x109+65x65+1065x742.");
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
	u("missing --geo [DxD+DxD], eg.: 77x77+1129x807.");
    }

    my ($geoX, $geoY, $geoW, $geoH) =
	$geo =~ m#(\d+)x(\d+)\+(\d+)x(\d+)#;

    if ($geoX eq 0) {u("invalid geo: \"".$geo."\", x must be >0.")}
    if ($geoY eq 0) {u("invalid geo: \"".$geo."\", y must be >0.")}

    if ($geoW eq 0) {u("invalid geo: \"".$geo."\", width  must be >0.")}
    if ($geoH eq 0) {u("invalid geo: \"".$geo."\", height must be >0.")}

    if (!defined $geoScale) {
	u("missing --geoscale [float], eg.: 0.781.");
    }

    if (!$out) {u("missing --out [build dir], eg.: build/country-4x2-glossy")}

    $out =~ s/\/$//;

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
    $lm->setAttribute("x", $mX);
    $lm->setAttribute("y", $mY);
    $lm->setAttribute("width", $mW);
    $lm->setAttribute("height", $mH);
    $lm->setAttribute("inkscape:groupmode", "layer");
    $lm->setAttribute("inkscape:label", "mask");
    $lm->setAttribute("style", "display:inline");
    $lm->setAttribute("clip-path", "url(#clipPathFlag)");

    my $m = XML::LibXML::Element->new("g");
    $m->setAttribute("id", "flag_mask_group");
    $m->setAttribute("x", $geoX);
    $m->setAttribute("y", $geoY);
    $m->setAttribute("width", $geoW);
    $m->setAttribute("height", $geoH);
    $m->setAttribute("transform",
		     "translate(".$geoX.",".$geoY.") scale(".$geoScale.")");

    my $fName = $dirSvg."/".$imgFlag; my $content = readFile($fName);
    if (!defined $content) { u("Error reading file ".$fName."."); }

    my $dom = XML::LibXML->load_xml(string => $content);
    if (!defined $dom) { u("Error parsing file ".$fName."."); }
    
    my $xpc = XML::LibXML::XPathContext->new($dom);
    my @nodes = $xpc->findnodes("./*");

#    print STDERR "nodes: \n";
    foreach my $n (@nodes) {
#	print STDERR "node : " . $n->toString() . "\n";
#	$n->setAttribute("x", $geoX);
#	$n->setAttribute("y", $geoY);
#	$n->setAttribute("width", $geoW);
#	$n->setAttribute("height", $geoH);
#	$n->setAttribute("transform", "scale(0.777)");
	$m->appendChild($n);
#	$dom->importNode($n);
    }

#    print STDERR Dumper(@nodes);
    
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
    if (!$pngDir){u("missing --pngs [dir], eg.: build/png-country-squared/res-512x512.")}
    if (!-d $pngDir){u("--pngs \"".$pngDir."\" does not exist.")}
    
    if (!$out)   {u("missing --out [dir], e.g.: build.")}
    if (!-d $out){u("--out dir \"".$out."\" does not exist.")}

    find(\&add_png_file, split(",", $pngDir));

    if (0 eq length @pngs) {
	u("no png files in ".$pngDir.".");
    }

    if (!$res) {u("missing --res [DxD,..], eg.: 64x64,128x128.")}

    my @rs = ();
    foreach my $r (split (",", $res)) {
	my ($w, $h) = ($r =~ m /(\d+)x(\d+)/);

	if ($w eq 0) {u("invalid res: \"".$r."\", width  must be > 0.")}
	if ($h eq 0) {u("invalid res: \"".$r."\", height must be > 0.")}
	if (!$w or !$h) {
	    u("could not parse: res \"".$r."\", must be [DxD,..]");
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
	    #                  build/png-country-4x2/res-1280x960
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
    if (!$dirSvg){u("missing --svgs [dir], eg.: svg/country-squared.")}
    if (!-d $dirSvg){u("--svgs \"".$dirSvg."\" does not exist.")}
    
    if (!$out)   {u("missing --out [dir], eg.: build.")}
    if (!-d $out){u("--out dir \"".$out."\" does not exist.")}

    find(\&add_svg_file, split(",", $dirSvg));

    if (0 eq length @svgs) {u("no svg files in ".$dirSvg.".")}

    if (!$res) { u("missing --res [DxD,..], eg.: 64x64,128x128.")}
    my @rs = ();
    foreach my $r (split (",", $res)) {
	my ($w, $h) = ($r =~ m /(\d+)x(\d+)/);

	if ($w eq 0) {u("invalid res: \"".$r."\", width  must be > 0.")}
	if ($h eq 0) {u("invalid res: \"".$r."\", height must be > 0.")}
	if (!$w or !$h) {
	    u("could not parse: res \"".$r."\", must be [DxD,..].");
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
	    #                  build/png-country-4x2/res-1280x960
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
	u("missing --res [DxD,..], eg.: 8x8,16x16,64x64");
    }

    if (!$dirSvg) { u("missing --svg [dir], eg.: svg/country-squared.")}
    if (!-d $dirSvg) { u("--svg dir \"".$dirSvg."\" does not exist.")}

    if (!$geo) { u("missing --geo [D+D+DxD], eg.: 54+54+403x403.")}

    if (!$out) { u("missing --out [dir], eg.: build.")}
    if (!-d $out) { u("--out dir \"".$out."\" does not exist.")}

    if (!$sty) { u("missing --sty [$stys], e.g.: simple.")}
    if ($sty !~ /^($stys)$/) { u("invalid --sty [$stys].")}

    my @rs = ();
    foreach my $r (split (",", $res)) {
	my ($w, $h) = ($r =~ m /(\d+)x(\d+)/);

	if ($w eq 0) { u("invalid res: \"".$r."\". Width must be > 0.")}
	if ($h eq 0) { u("invalid res: \"".$r."\". Height must be > 0.")}
	if (!$w or !$h) {
	    u("could not parse: res \"".$r."\". Must be [DxD,..].");
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

    print STDERR " writing ".$fName."\n";

    my($filename, $dirs, $suffix) = fileparse($fName);

    if (! -d $dirs ) {
        mkpath($dirs);
    }

    open FILE, ">$fName" or die " Error writing file $fName: $!. Exiting.";
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
