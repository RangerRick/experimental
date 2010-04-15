package com.befunk.fink.core;

public class Package {

	public class Version {
		protected Integer m_epoch;
		protected String m_version;
		protected String m_revision;
	}

	public static enum State {
		OUTDATED,
		CURRENT,
		ABSENT,
		TOONEW
	}

	protected State m_state;
	protected String m_name;
	protected Version m_version;
	protected String m_description;
}
