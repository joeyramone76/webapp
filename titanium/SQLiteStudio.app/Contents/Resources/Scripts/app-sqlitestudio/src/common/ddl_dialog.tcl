use src/common/common.tcl

class DdlDialog {
	protected {
		variable _tabs ""
		variable _ddlEdit ""

		method initDdlDialog {}
		abstract method createSql {}
		abstract method validateForSql {}
		abstract method getDdlContextDb {}
	}

	public {
		method tabChanged {}
	}
}

body DdlDialog::initDdlDialog {} {
	if {$_tabs != ""} {
		bind $_tabs <<NotebookTabChanged>> "$this tabChanged"
	}
}

body DdlDialog::tabChanged {} {
	if {$_ddlEdit == ""} return
	if {[string first "ddl" [$_tabs select]] == -1} return

	set validation [validateForSql]
	if {$validation != ""} {
		$_ddlEdit enable
		$_ddlEdit removeHighlighting
		$_ddlEdit setContents [mc "Cannot prepare DDL. Dialog configuration is incomplete.\nProblem details:\n%s" $validation]
		$_ddlEdit readonly
	} else {
		$_ddlEdit enable
		$_ddlEdit updateUISettings
		$_ddlEdit setContents [Formatter::format [createSql] [$this getDdlContextDb]]
		$_ddlEdit readonly
	}
}
