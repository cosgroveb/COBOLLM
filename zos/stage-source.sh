#!/bin/sh
set -eu

fail() {
    printf '%s\n' "stage-source: $*" >&2
    exit 1
}

if [ "$#" -ne 2 ]; then
    printf '%s\n' 'usage: stage-source.sh SOURCE MVS_TARGET' >&2
    exit 2
fi
if [ "$(uname -s)" != 'OS/390' ]; then
    printf '%s\n' 'stage-source.sh runs only in z/OS USS' >&2
    exit 2
fi

source_file=$1
target=$2
case "$source_file" in
    *.jcl) max=71; jcl=1 ;;
    *.cob|*.cpy) max=72; jcl=0 ;;
    *) fail 'source must be .cob, .cpy, or .jcl' ;;
esac
[ -f "$source_file" ] || fail "$source_file is not a regular file"
[ -r "$source_file" ] || fail "$source_file is not readable"

export _BPXK_AUTOCVT=OFF
export _ICONV_TECHNIQUE=L

# Validate the uploaded byte stream before creating staging or changing tags.
perl -e '
    use strict;
    my ($file, $max) = @ARGV;
    open my $fh, "<", $file or die "$file: $!\n";
    binmode $fh;
    local $/;
    my $data = <$fh>;
    defined($data) && length($data) or die "$file: empty\n";
    substr($data, -1, 1) eq "\x0a" or
        die "$file: missing final LF\n";
    length($data) == 1 || substr($data, -2, 1) ne "\x0a" or
        die "$file: more than one final LF\n";
    $data !~ /[^\x20-\x7e\x0a]/ or
        die "$file: invalid repository byte\n";
    my @lines = split /\x0a/, $data, -1;
    pop @lines;
    @lines or die "$file: no source record\n";
    for my $line (@lines) {
        length($line) <= $max or die "$file: long source line\n";
    }
' "$source_file" "$max" || fail 'source validation failed'

stage_dir=$(mktemp -d "${TMPDIR:-/tmp}/cobollm-stage.XXXXXX")
case "$stage_dir" in
    "${TMPDIR:-/tmp}"/cobollm-stage.*) ;;
    *) fail 'mktemp returned an unexpected path' ;;
esac
trap 'rm -rf "$stage_dir"' EXIT HUP INT TERM

chtag -b "$source_file"
chtag -p "$source_file" > "$stage_dir/source.tag"
awk 'NR == 1 && $1 == "b" && $2 == "binary" && $3 == "T=off" {
    found=1
} END { exit !found }' "$stage_dir/source.tag" ||
    fail 'uploaded source is not tagged binary'

perl -e '
    use strict;
    my ($in, $out) = @ARGV;
    open my $ifh, "<", $in or die "$in: $!\n";
    open my $ofh, ">", $out or die "$out: $!\n";
    binmode $ifh;
    binmode $ofh;
    while (my $line = <$ifh>) {
        $line =~ s/\x0a\z// or die "record without LF\n";
        print {$ofh} $line, " " x (80 - length($line)), "\x0a";
    }
' "$source_file" "$stage_dir/padded.utf8"
chtag -b "$stage_dir/padded.utf8"

lines=$(perl -e '
    use strict;
    my ($file, $jcl) = @ARGV;
    open my $fh, "<", $file or die "$file: $!\n";
    binmode $fh;
    my $count = 0;
    while (read($fh, my $record, 81)) {
        length($record) == 81 or die "short padded record\n";
        substr($record, 80, 1) eq "\x0a" or die "bad delimiter\n";
        substr($record, 72, 8) eq " " x 8 or die "bad padding\n";
        !$jcl || substr($record, 71, 1) eq " " or die "JCL col 72\n";
        ++$count;
    }
    $count or die "no padded records\n";
    print $count;
' "$stage_dir/padded.utf8" "$jcl") || fail 'padding validation failed'

iconv -f UTF-8 -t IBM-1047 "$stage_dir/padded.utf8" \
    > "$stage_dir/padded.1047"
chtag -b "$stage_dir/padded.1047"
iconv -f IBM-1047 -t UTF-8 "$stage_dir/padded.1047" \
    > "$stage_dir/roundtrip.utf8"
chtag -b "$stage_dir/roundtrip.utf8"
cmp "$stage_dir/padded.utf8" "$stage_dir/roundtrip.utf8"

perl -e '
    use strict;
    my $out = shift;
    open my $fh, ">", $out or die "$out: $!\n";
    binmode $fh;
    print {$fh} pack("H*", "5b5d7b7d5c5e7e7c402324");
' "$stage_dir/variant.utf8"
chtag -b "$stage_dir/variant.utf8"
iconv -f UTF-8 -t IBM-1047 "$stage_dir/variant.utf8" \
    > "$stage_dir/variant.1047"
perl -e '
    use strict;
    my $file = shift;
    open my $fh, "<", $file or die "$file: $!\n";
    binmode $fh;
    local $/;
    my $got = <$fh>;
    $got eq pack("H*", "adbdc0d0e05fa14f7c7b5b") or
        die "IBM-1047 variant mapping differs\n";
' "$stage_dir/variant.1047" || fail 'variant conversion failed'

perl -e '
    use strict;
    my ($in, $out, $jcl) = @ARGV;
    open my $ifh, "<", $in or die "$in: $!\n";
    open my $ofh, ">", $out or die "$out: $!\n";
    binmode $ifh;
    binmode $ofh;
    while (read($ifh, my $record, 81)) {
        length($record) == 81 or die "short IBM-1047 record\n";
        substr($record, 80, 1) eq "\x25" or die "bad delimiter\n";
        substr($record, 72, 8) eq "\x40" x 8 or die "bad padding\n";
        !$jcl || substr($record, 71, 1) eq "\x40" or
            die "JCL col 72\n";
        print {$ofh} substr($record, 0, 80);
    }
' "$stage_dir/padded.1047" "$stage_dir/expected.fb80" "$jcl"
chtag -b "$stage_dir/expected.fb80"

case "$target" in
    "//'"*"'") dsn=${target#//\'}; dsn=${dsn%\'} ;;
    *) fail 'MVS_TARGET must use //'"'"'DATA.SET[(MEMBER)]'"'"' syntax' ;;
esac
base=${dsn%%\(*}
tsocmd "LISTDS '$base'" > "$stage_dir/attributes"
tsocmd "LISTCAT ENTRIES('$base') ALL" > "$stage_dir/catalog"
awk '
    /^[[:space:]]*FB[[:space:]]+80[[:space:]]+[1-9][0-9]*[[:space:]]+/ {
        if ($4 == "PS" || $4 == "PO") found=1
    }
    END { exit !found }
' "$stage_dir/attributes" || fail 'target is not FB/80 with a block size'
case "$dsn" in
    *\(*\))
        grep -q '[[:space:]]PO[[:space:]]*$' \
            "$stage_dir/attributes" ||
            fail 'member target is not partitioned'
        grep -Eq 'DSNTYPE-+LIBRARY' "$stage_dir/catalog" ||
            fail 'member target is not a PDSE'
        ;;
    *) grep -q '[[:space:]]PS[[:space:]]*$' \
        "$stage_dir/attributes" || fail 'sequential target is not PS' ;;
esac

# Target syntax and every nonmutating attribute check precede its first write.
cp -T "$stage_dir/padded.1047" "$target"
cp -B "$target" "$stage_dir/readback.fb80"
chtag -b "$stage_dir/readback.fb80"
cmp "$stage_dir/expected.fb80" "$stage_dir/readback.fb80"

bytes=$(wc -c < "$stage_dir/readback.fb80" | tr -d ' ')
[ "$bytes" -eq $((lines * 80)) ] || fail 'FB80 byte count differs'

cp -T "$target" "$stage_dir/readback.1047"
chtag -b "$stage_dir/readback.1047"
iconv -f IBM-1047 -t UTF-8 "$stage_dir/readback.1047" \
    > "$stage_dir/readback.utf8"
chtag -b "$stage_dir/readback.utf8"
perl -e '
    use strict;
    for my $pair ([0, 1], [2, 3]) {
        open my $in, "<", $ARGV[$pair->[0]] or die "$!\n";
        open my $out, ">", $ARGV[$pair->[1]] or die "$!\n";
        binmode $in;
        binmode $out;
        while (my $line = <$in>) {
            $line =~ s/\x0a\z// or die "record without LF\n";
            $line =~ s/\x20+\z//;
            print {$out} $line, "\x0a";
        }
    }
' "$source_file" "$stage_dir/source.trimmed" \
    "$stage_dir/readback.utf8" "$stage_dir/readback.trimmed"
cmp "$stage_dir/source.trimmed" "$stage_dir/readback.trimmed"

printf '%s\n' "PASS staged $source_file: $lines FB80 records"
printf '%s\n' 'Target attributes:'
cat "$stage_dir/attributes"
cat "$stage_dir/catalog"
