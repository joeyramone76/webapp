use src/dialogs/pickdialog.tcl

class LangDialog {
	inherit PickDialog

	constructor {args} {
		PickDialog::constructor {*}$args
	} {}

	protected {
		method center {}
	}
}

body LangDialog::center {} {
	wcenter $path req
}
