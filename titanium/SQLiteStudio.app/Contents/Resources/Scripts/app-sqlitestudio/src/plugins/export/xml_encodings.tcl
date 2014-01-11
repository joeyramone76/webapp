#	TCL_ENCODING		XML_ENCODINGS
array set ::XML_encoding {
	ascii		{US-ASCII		ASCII}
	big5		{big5}
	cp437		{windows-437	cp437}
	cp737		{windows-737	cp737}
	cp775		{windows-775	cp775}
	cp850		{windows-850	cp850}
	cp852		{windows-852	cp852}
	cp855		{windows-855	cp855}
	cp857		{windows-857	cp857}
	cp860		{windows-860	cp860}
	cp861		{windows-861	cp861}
	cp862		{windows-862	cp862}
	cp863		{windows-863	cp863}
	cp864		{windows-864	cp864}
	cp865		{windows-865	cp865}
	cp866		{windows-866	cp866}
	cp869		{windows-869	cp869}
	cp874		{windows-874	cp874}
	cp932		{windows-932	cp932}
	cp936		{windows-936	cp936}
	cp949		{windows-949	cp949}
	cp950		{windows-950	cp950}
	cp1250		{windows-1250	cp1250}
	cp1251		{windows-1251	cp1251}
	cp1252		{windows-1252	cp1252}
	cp1253		{windows-1253	cp1253}
	cp1254		{windows-1254	cp1254}
	cp1255		{windows-1255	cp1255}
	cp1256		{windows-1256	cp1256}
	cp1257		{windows-1257	cp1257}
	cp1258		{windows-1258	cp1258}
	euc-cn		{euc-cn}
	euc-jp		{euc-jp}
	euc-kr		{euc-kr}
	gb1988		{gb1988}
	gb2312		{gb2312}
	gb12345		{gb12345}
	iso2022		{ISO-2022}
	iso2022-jp	{ISO-2022-jp}
	iso2022-kr	{ISO-2022-kr}
	iso8859-1	{ISO-8859-1		latin1}
	iso8859-2	{ISO-8859-2}
	iso8859-3	{ISO-8859-3}
	iso8859-4	{ISO-8859-4}
	iso8859-5	{ISO-8859-5}
	iso8859-6	{ISO-8859-6}
	iso8859-7	{ISO-8859-7}
	iso8859-8	{ISO-8859-8}
	iso8859-9	{ISO-8859-9}
	iso8859-10	{ISO-8859-10}
	iso8859-13	{ISO-8859-13}
	iso8859-14	{ISO-8859-14}
	iso8859-15	{ISO-8859-15}
	iso8859-16	{ISO-8859-16}
	koi8-r		{koi8-r}
	koi8-u		{koi8-u}
	shiftjis	{shift_jis		shift-jis}
	utf-8		{UTF-8			UTF8}
	identity	{UTF-8			UTF8}
	unicode		{UTF-16			UTF16}
}

# Setting up reverse mapping
array set ::XML_encoding_reverse {}
foreach idx [array names XML_encoding] {
	foreach val $XML_encoding($idx) {
		if {![info exists ::XML_encoding_reverse($val)]} {
			set ::XML_encoding_reverse($val) $idx
		}
	}
}
