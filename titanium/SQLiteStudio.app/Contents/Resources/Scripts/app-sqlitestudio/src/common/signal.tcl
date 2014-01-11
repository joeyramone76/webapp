use src/common/common.tcl

#>
# @class Signal
# Signal class is used to communication between numerous objects
# that implements this class.<br><br>
# Signals are propagated by {@class Singleton} objects,
# or static methods (internal class procedures).<br>
# They (signals) are nothing more than calling <code>signal</code> method by some objects to others.<br>
# For example:<br>
# Any object can call <code>signal</code> method on {@class TaskBar} with <code>receiver</code>
# parameter value <code>'EditorWin'</code> to send custom <i>data</i> to all {@class EditorWin} class instances,
# because {@class TaskBar} inherites Signal and Singleton class and it's used to propagate signals to all
# MDI windows (which also inherites Signal class).
#<
class Signal {
	public {
		#>
		# @method signal
		# @param receiver Destination object class to detect which object should handle the signal.
		# @param data Data transported with signal.
		# Signal method is called by any other object and should be handled by local object,
		# or sent to another object/objects.
		#<
		abstract method signal {receiver data}
	}
}
