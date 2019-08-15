IMPORT os
TYPE t_con RECORD
		con STRING,
		dbn STRING,
		src STRING,
		drv STRING,
		usr STRING,
		psw STRING,
		res STRING
	END RECORD
MAIN
	DEFINE l_con t_con

	OPEN FORM f FROM "form"
	DISPLAY FORM f

	LET l_con.dbn = "njm_demo310"
	LET l_con.drv = "dbmifx_9"
	LET l_con.con = setConnection( l_con.* )
	INPUT BY NAME l_con.* ATTRIBUTES(UNBUFFERED, WITHOUT DEFAULTS, ACCEPT=FALSE, CANCEL=FALSE )
		AFTER FIELD dbn LET l_con.con = setConnection( l_con.* )
		AFTER FIELD src LET l_con.con = setConnection( l_con.* )
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
	LET l_con.con = SFMT("%1",l_con.dbn)
	IF l_con.drv IS NOT NULL THEN
		LET l_con.con = SFMT("%1+driver='%2'",l_con.dbn,l_con.drv)
	END IF
	IF l_con.src IS NOT NULL THEN
		LET l_con.con = l_con.con.append(SFMT(",source='%1'",l_con.src) )
	END IF
	IF l_con.usr IS NOT NULL THEN
		LET l_con.con = l_con.con.append(SFMT(",username='%1',password='%2'",l_con.usr,l_con.psw) )
	END IF
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
		LET l_con.res = SFMT("Trying: CONNECT TO '%1' AS '%2' USING '%3'",l_con.dbn, l_con.usr, l_con.psw)
		CONNECT TO l_con.dbn AS l_con.usr USING l_con.psw
		LET l_con.res = l_con.res.append("\nSuccess")
	CATCH
		LET l_con.res = l_con.res.append("\n"||STATUS||":"||SQLERRMESSAGE)
	END TRY
	RETURN l_con.res
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