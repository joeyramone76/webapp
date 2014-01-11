use src/common/common.tcl
use src/common/tktree_tracer.tcl

#>
# @class GridHints
# Item-column context based hints for grids.
# Inherit, call "initHints" for Grid tree and implement fillHint to get it working.
# The initHelpHint has to be called once at application startup.
#<
class GridHints {
	inherit TkTreeTracer

	common columnHelpHintWin ".columnHelpHint"

	private {
		variable _tree ""
	}
	
	protected {
		method initHints {tree}
	}

	public {
		method columnHelpHint {w data}
		method headerEnter {col}
		method headerLeave {col}
		method itemEnter {it col}
		method itemLeave {it col}
		
		#>
		# @method fillHint {it col hintTable}
		# @param it TkTree item.
		# @param col TkTree column.
		# @param hintTable HintTable instance to fill with data.
		#<
		abstract method fillHint {it col hintTable}
		
		proc initHelpHint {}
	}
}

body GridHints::initHints {tree} {
	set _tree $tree
	initTracer $_tree
}

body GridHints::initHelpHint {} {
	initFancyHelpHint $columnHelpHintWin
}

body GridHints::columnHelpHint {w data} {
	set cmd "
		lassign \$data it col
		$this fillHint \$it \$col \$container
	"
	raiseFancyHelpHint $columnHelpHintWin $cmd $w $data
}

body GridHints::headerEnter {col} {
	helpHint_onEnter $_tree [list "" $col] [list $this columnHelpHint] 1000 false
}

body GridHints::headerLeave {col} {
	helpHint_onLeave $_tree [list "" $col] $columnHelpHintWin [list $this columnHelpHint] 1000 false
}

body GridHints::itemEnter {it col} {
	helpHint_onEnter $_tree [list $it $col] [list $this columnHelpHint] 1000 false
}

body GridHints::itemLeave {it col} {
	helpHint_onLeave $_tree [list $it $col] $columnHelpHintWin [list $this columnHelpHint] 1000 false
}
