use src/grids/dbgrid.tcl
use src/common/tktree_tracer.tcl

class TracedDbGrid {
	inherit DBGrid TkTreeTracer

	#>
	# @method constructor {args}
	# <li><code>-itementercmd</code> - Tcl script to execute when mouse pointer enters any cell in grid. Script is executed in the Grid context.
	# <li><code>-itemleavecmd</code> - Tcl script to execute when mouse pointer leaves any cell in grid. Script is executed in the Grid context.
	# <li><code>-columnentercmd</code> - Tcl script to execute when mouse pointer enter any column in grid. Script is executed in the Grid context.
	# <li><code>-columnleavecmd</code> - Tcl script to execute when mouse pointer leaves any column in grid. Script is executed in the Grid context.
	# <li><code>-headerentercmd</code> - Tcl script to execute when mouse pointer enter any header in grid. Script is executed in the Grid context.
	# <li><code>-headerleavecmd</code> - Tcl script to execute when mouse pointer leaves any header in grid. Script is executed in the Grid context.
	#<
	constructor {args} {
		DBGrid::constructor {*}$args
	} {}

}

body TracedDbGrid::constructor {args} {
	set _itemEnterCmd $itk_option(-itementercmd)
	set _itemLeaveCmd $itk_option(-itemleavecmd)
	set _columnEnterCmd $itk_option(-columnentercmd)
	set _columnLeaveCmd $itk_option(-columnleavecmd)
	set _headerEnterCmd $itk_option(-headerentercmd)
	set _headerLeaveCmd $itk_option(-headerleavecmd)
	initTracer $_tree
}
