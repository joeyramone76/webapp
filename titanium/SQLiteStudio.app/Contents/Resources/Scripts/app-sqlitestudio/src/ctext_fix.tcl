# This is quiet ugly hack to make Ctext working with multi-line strings.
# Ugly, but works without modification of ctext.
rename ctext::highlight ctext::highlight_orig
proc ctext::highlight {win start end} {
	ctext::highlight_orig $win $start $end

	set twin "$win._t"

	ctext::getAr $win config ar

	if {![info exists ar(ext_strings)] && ![info exists ar(ext_comments)]} return
	if {!$ar(ext_strings) || !$ar(ext_comments)} return

	set si 1.0
	set twin "$win._t"
	set state ""
	set stateIdx ""
	$twin tag remove comments 1.0 end
	$twin tag remove string 1.0 end
	while {1} {
		set res [$twin search -count length -nolinestop -regexp -nocase -- {('[^']+'|'{2}|'[^']*$|\/\*|\*\/)} $si end]
		if {$res == ""} {
			break
		}
		set si [$twin index "$res + $length chars"]
		set token [$twin get $res "$res +2 chars"]
		switch -- $token {
			"/*" {
				if {$state != "comment"} {
					set state "comment"
					set stateIdx $res
				}
			}
			"*/" {
				if {$state == "comment"} {
					set state ""
					$twin tag add comments $stateIdx $si
				}
			}
			default {
				set tags [concat [$twin tag names $res] [$twin tag names $si]]
				if {$state != "comment" && "line_comments" ni $tags} {
					$twin tag add string $res $si
				} else {
					set si [$twin index "$res +1 chars"]
				}
			}
		}
	}
	if {$state == "comment"} {
		$twin tag add comments $stateIdx end
	}
}
