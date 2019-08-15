IMPORT os
DEFINE m_prf, m_usr STRING
TYPE t_con RECORD
		con STRING,
		dbn STRING,
		src STRING,
		rsc STRING,
		drv STRING,
		usr STRING,
		psw STRING,
		res STRING
	END RECORD

MAIN
	DEFINE l_con t_con

	OPEN FORM f FROM "form"
	DISPLAY FORM f

	LET m_prf = fgl_getEnv("FGLPROFILE")
	LET m_usr = fgl_getEnv("LOGNAME")
	IF m_usr IS NULL THEN
		LET m_usr = fgl_getEnv("USERNAME")
	END IF

	IF m_prf IS NULL THEN
		LET m_prf = os.path.join(fgl_getEnv("FGLDIR"),"etc/fglprofile")
	END IF
	LET l_con.dbn = "njm_demo310"
	LET l_con.drv = "dbmifx_9"
	LET l_con.con = setConnection( l_con.* )
	INPUT BY NAME l_con.* ATTRIBUTES(UNBUFFERED, WITHOUT DEFAULTS, ACCEPT=FALSE, CANCEL=FALSE )
		AFTER FIELD dbn LET l_con.con = setConnection( l_con.* )
		AFTER FIELD src LET l_con.con = setConnection( l_con.* )
		AFTER FIELD rsc LET l_con.con = setConnection( l_con.* )
		ON CHANGE drv LET l_con.con = setConnection( l_con.* )
		AFTER FIELD usr LET l_con.con = setConnection( l_con.* )
		AFTER FIELD psw LET l_con.con = setConnection( l_con.* )
		ON ACTION test1
			LET l_con.con = setConnection( l_con.* )
			LET l_con.res = testConnection1( l_con.* )
		ON ACTION test2
			LET l_con.con = setConnection( l_con.* )
			LET l_con.res = testConnection2( l_con.* )
		ON ACTION quit
			EXIT INPUT
	END INPUT

END MAIN
----------------------------------------------------------------------------------------------------
-- "stores+driver='dbmora',source='orcl',resource='myconfig'"
FUNCTION setConnection( l_con t_con )
	DEFINE l_env STRING
	LET l_con.con = SFMT("%1",l_con.dbn)
	IF l_con.drv IS NOT NULL THEN
		LET l_con.con = SFMT("%1+driver='%2'",l_con.dbn,l_con.drv)
	END IF
	IF l_con.src IS NOT NULL THEN
		LET l_con.con = l_con.con.append(SFMT(",source='%1'",l_con.src) )
	END IF
	IF l_con.rsc IS NOT NULL THEN
		LET l_con.con = l_con.con.append(SFMT(",resource='%1'",l_con.rsc) )
	END IF
	IF l_con.usr IS NOT NULL THEN
		LET l_con.con = l_con.con.append(SFMT(",username='%1',password='%2'",l_con.usr,l_con.psw) )
	END IF

	LET l_env = SFMT("FGLDIR=%1\nFGLPROFILE=%2\nUSER=%3\nLD_LIBRARY_PATH=%4"
				, fgl_getenv("FGLDIR")
				, m_prf
				, m_usr
				, fgl_getenv("LD_LIBRARY_PATH"))

	IF l_con.drv.subString(4,6) = "ifx" THEN
		LET l_env = l_env.append( SFMT("\nINFORMIXDIR=%1\nINFORMIXSERVER=%2\nINFORMIXSQLHOSTS=%3"
				, fgl_getenv("INFORMIXDIR")
				, fgl_getenv("INFORMIXSERVER")
				, fgl_getenv("INFORMIXSQLHOSTS")))
	END IF
	IF l_con.drv.subString(4,6) = "odc" THEN
		LET l_env = l_env.append( SFMT("\ODBC=%1\ODBCINI=%2\n"
				, fgl_getenv("\nODBC")
				, fgl_getenv("\nODBCINI")))
	END IF

	LET l_env = l_env.append( get_Resources( l_con.dbn, l_con.rsc ) )

	DISPLAY l_env TO env

	RETURN l_con.con
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION testConnection1( l_con t_con )
	TRY
		LET l_con.res = SFMT("Trying: DATABASE '%1'", l_con.con)
		DATABASE l_con.con
		LET l_con.res = l_con.res.append("\nSuccess")
	CATCH
		LET l_con.res = l_con.res.append("\n"||STATUS||":"||SQLERRMESSAGE)
	END TRY
	RETURN l_con.res
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION testConnection2( l_con t_con )
	TRY
		IF l_con.usr IS NOT NULL THEN
			LET l_con.res = SFMT("Trying: CONNECT TO '%1' AS '%2' USING '%3'",l_con.dbn, l_con.usr, l_con.psw)
			CONNECT TO l_con.dbn AS l_con.usr USING l_con.psw
		ELSE
			LET l_con.res = SFMT("Trying: CONNECT TO '%1'",l_con.dbn)
			CONNECT TO l_con.dbn
		END IF
		LET l_con.res = l_con.res.append("\nSuccess")
	CATCH
		LET l_con.res = l_con.res.append("\n"||STATUS||":"||SQLERRMESSAGE)
	END TRY
	RETURN l_con.res
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION get_Resources( l_dbn STRING, l_res STRING )
	DEFINE l_ret, l_line STRING
	DEFINE c base.Channel
	LET l_ret = "\n\nfglprofile resources:"
	LET c = base.Channel.create()
	CALL c.openFile( m_prf,"r")
	WHILE NOT c.isEof()
		LET l_line = c.readLine()
		IF l_line IS NOT NULL AND l_line MATCHES "dbi.*" THEN
			DISPLAY CURRENT, ":PRF:",l_line
			IF l_line MATCHES "dbi.default.driver*" 
			OR l_line MATCHES "dbi.database."||l_dbn||".*"
			OR l_line MATCHES "dbi.database."||l_res||".*" THEN
				LET l_ret = l_ret.append("\n"||l_line)
			END IF
		END IF
	END WHILE
	CALL c.close()
	RETURN l_ret
END FUNCTION
----------------------------------------------------------------------------------------------------
FUNCTION cb_driver( l_cb ui.ComboBox )
	DEFINE c base.Channel
	DEFINE l_line STRING
	LET c = base.Channel.create()
	CALL c.openPipe("find $FGLDIR/dbdrivers -type f | sort","r")
	WHILE NOT c.isEof()
		LET l_line = c.readLine()
		IF l_line IS NOT NULL THEN
			LET l_line = os.Path.baseName(l_line)
			LET l_line = os.path.rootName(l_line)
			CALL l_cb.addItem(l_line,l_line.subString(4, l_line.getLength()))
		END IF
	END WHILE
	CALL c.close()
END FUNCTION