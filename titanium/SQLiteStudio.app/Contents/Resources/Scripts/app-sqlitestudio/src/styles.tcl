proc initCustomStyles {w} {
	if {$w != "."} return
	set theme $::ttk::currentTheme

	if {$theme == "vista"} {
		# Fix for center-aligned spinbox in FormView
		ttk::style layout TSpinboxLeftAligned {
			Spinbox.field -sticky nswe -children {
				Spinbox.background -sticky nswe -children {
					Spinbox.padding -sticky nswe -children {
						Spinbox.innerbg -sticky nswe -children {
							Spinbox.textarea -expand 1 -sticky nswe
						}
					}
					Spinbox.uparrow -side top -sticky nse Spinbox.downarrow -side bottom -sticky nse
				}
			}
		}
		ttk::style map TSpinboxLeftAligned {*}[ttk::style map TSpinbox]
		ttk::style configure TSpinboxLeftAligned {*}[ttk::style configure TSpinbox]
	}

	if {$theme == "clam"} {
		ttk::style layout TButtonThin [ttk::style layout TButton]
		ttk::style map TButtonThin {*}[ttk::style map TButton]
		ttk::style configure TButtonThin {*}[ttk::style configure TButton]
		ttk::style configure TButtonThin -padding 0
	}
}

bind . <<ThemeChanged>> "initCustomStyles %W"

# Text behaviour fix:
bind Text <KP_Enter> [list %W insert insert "\n"]
