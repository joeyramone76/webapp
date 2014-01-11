use src/common/common.tcl

class PoolJob {
	private {
		variable _lastEval 0
	}

	public {
		method evalByPool {script}
		method getLastEvalTime {}

		abstract method eval {script}
	}
}

body PoolJob::evalByPool {script} {
	set _lastEval [clock seconds]
	return [$this eval $script]
}

body PoolJob::getLastEvalTime {} {
	return $_lastEval
}
