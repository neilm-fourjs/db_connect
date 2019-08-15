MAIN
	DEFINE l_db, l_un, l_pw STRING
	LET l_db = ARG_VAL(1)
	LET l_un = ARG_VAL(2)
	LET l_pw = ARG_VAL(3)
	CONNECT TO l_db USER l_un USING l_pw
	DISPLAY "Status:",STATUS,":",SQLERRMESSAGE
END MAIN