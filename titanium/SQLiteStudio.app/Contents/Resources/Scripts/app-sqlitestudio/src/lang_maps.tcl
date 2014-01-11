array set ::langLabelsMap {
	de_de		{Deutsch}
	en			{English}
	es			{Español}
	fr_fr		{Française}
	it			{Italiano}
	ja_jp		{日本}
	nl			{Nederlands}
	pl_pl		{Polski}
	ru			{Pусский}
	zh_cn		{中国}
}

foreach f [lsort -dictionary -unique [concat \
		[glob -nocomplain -tails -directory lang *.msg] \
		[glob -nocomplain -tails -directory $::applicationDir/lang *.msg] \
	]] {
	set lang [lindex [split $f .] 0]
	if {![info exists ::langLabelsMap($lang)]} {
		set ::langLabelsMap($lang) $lang
	}
}

array set ::winLangMap {
	3076	zh_cn
	2052	zh_cn
	4100	zh_cn
	1028	zh_cn
	3081	en
	10249	en
	4105	en
	6153	en
	8201	en
	5129	en
	7177	en
	11273	en
	2057	en
	1033	en
	1031	de_de
	3079	de_de
	5127	de_de
	4103	de_de
	2055	de_de
	1043	nl
	1040	it
	2064	it
	1041	ja_jp
	1045	pl_pl
	1049	ru
	2073	ru
	11274	es
	16394	es
	13322	es
	9226	es
	5130	es
	7178	es
	12298	es
	17418	es
	4106	es
	18442	es
	2058	es
	19466	es
	6154	es
	15370	es
	10250	es
	20490	es
	1034	es
	14346	es
	8202	es
}

array set ::unixLangMap {
	"de*"		de_de
	"en*"		en
	"es*"		es
	"it*"		it
	"pl*"		pl_pl
	"zh_cn*"	zh_cn
}

#############################################################


##
# Unix map
##

# aa_DJ
# aa_DJ.utf8
# aa_ER
# aa_ER@saaho
# aa_ET
# af_ZA
# af_ZA.utf8
# am_ET
# an_ES
# an_ES.utf8
# ar_AE
# ar_AE.utf8
# ar_BH
# ar_BH.utf8
# ar_DZ
# ar_DZ.utf8
# ar_EG
# ar_EG.utf8
# ar_IN
# ar_IQ
# ar_IQ.utf8
# ar_JO
# ar_JO.utf8
# ar_KW
# ar_KW.utf8
# ar_LB
# ar_LB.utf8
# ar_LY
# ar_LY.utf8
# ar_MA
# ar_MA.utf8
# ar_OM
# ar_OM.utf8
# ar_QA
# ar_QA.utf8
# ar_SA
# ar_SA.utf8
# ar_SD
# ar_SD.utf8
# ar_SY
# ar_SY.utf8
# ar_TN
# ar_TN.utf8
# ar_YE
# ar_YE.utf8
# as_IN.utf8
# ast_ES
# ast_ES.utf8
# az_AZ.utf8
# be_BY
# be_BY.utf8
# be_BY@latin
# ber_DZ
# ber_MA
# bg_BG
# bg_BG.utf8
# bn_BD
# bn_IN
# bo_CN
# bo_IN
# br_FR
# br_FR.utf8
# br_FR@euro
# bs_BA
# bs_BA.utf8
# byn_ER
# ca_AD
# ca_AD.utf8
# ca_ES
# ca_ES.utf8
# ca_ES@euro
# ca_FR
# ca_FR.utf8
# ca_IT
# ca_IT.utf8
# crh_UA
# cs_CZ
# cs_CZ.utf8
# csb_PL
# cv_RU
# cy_GB
# cy_GB.utf8
# da_DK
# da_DK.utf8
# de_AT
# de_AT.utf8
# de_AT@euro
# de_BE
# de_BE.utf8
# de_BE@euro
# de_CH
# de_CH.utf8
# de_DE
# de_DE.utf8
# de_DE@euro
# de_LU
# de_LU.utf8
# de_LU@euro
# dv_MV
# dz_BT
# el_CY
# el_CY.utf8
# el_GR
# el_GR.utf8
# en_AG
# en_AU
# en_AU.utf8
# en_BW
# en_BW.utf8
# en_CA
# en_CA.utf8
# en_DK
# en_DK.utf8
# en_GB
# en_GB.utf8
# en_HK
# en_HK.utf8
# en_IE
# en_IE.utf8
# en_IE@euro
# en_IN
# en_NG
# en_NZ
# en_NZ.utf8
# en_PH
# en_PH.utf8
# en_SG
# en_SG.utf8
# en_US
# en_US.utf8
# en_ZA
# en_ZA.utf8
# en_ZW
# en_ZW.utf8
# es_AR
# es_AR.utf8
# es_BO
# es_BO.utf8
# es_CL
# es_CL.utf8
# es_CO
# es_CO.utf8
# es_CR
# es_CR.utf8
# es_DO
# es_DO.utf8
# es_EC
# es_EC.utf8
# es_ES
# es_ES.utf8
# es_ES@euro
# es_GT
# es_GT.utf8
# es_HN
# es_HN.utf8
# es_MX
# es_MX.utf8
# es_NI
# es_NI.utf8
# es_PA
# es_PA.utf8
# es_PE
# es_PE.utf8
# es_PR
# es_PR.utf8
# es_PY
# es_PY.utf8
# es_SV
# es_SV.utf8
# es_US
# es_US.utf8
# es_UY
# es_UY.utf8
# es_VE
# es_VE.utf8
# et_EE
# et_EE.iso885915
# et_EE.utf8
# eu_ES
# eu_ES.utf8
# eu_ES@euro
# fa_IR
# fi_FI
# fi_FI.utf8
# fi_FI@euro
# fil_PH
# fo_FO
# fo_FO.utf8
# fr_BE
# fr_BE.utf8
# fr_BE@euro
# fr_CA
# fr_CA.utf8
# fr_CH
# fr_CH.utf8
# fr_FR
# fr_FR.utf8
# fr_FR@euro
# fr_LU
# fr_LU.utf8
# fr_LU@euro
# fur_IT
# fy_DE
# fy_NL
# ga_IE
# ga_IE.utf8
# ga_IE@euro
# gd_GB
# gd_GB.utf8
# gez_ER
# gez_ER@abegede
# gez_ET
# gez_ET@abegede
# gl_ES
# gl_ES.utf8
# gl_ES@euro
# gu_IN
# gv_GB
# gv_GB.utf8
# ha_NG
# he_IL
# he_IL.utf8
# hi_IN
# hne_IN
# hr_HR
# hr_HR.utf8
# hsb_DE
# hsb_DE.utf8
# ht_HT
# hu_HU
# hu_HU.utf8
# hy_AM
# hy_AM.armscii8
# id_ID
# id_ID.utf8
# ig_NG
# ik_CA
# is_IS
# is_IS.utf8
# it_CH
# it_CH.utf8
# it_IT
# it_IT.utf8
# it_IT@euro
# iu_CA
# iw_IL
# iw_IL.utf8
# ja_JP.eucjp
# ja_JP.utf8
# ka_GE
# ka_GE.utf8
# kk_KZ
# kk_KZ.utf8
# kl_GL
# kl_GL.utf8
# km_KH
# kn_IN
# ko_KR.euckr
# ko_KR.utf8
# kok_IN
# ks_IN
# ks_IN@devanagari
# ku_TR
# ku_TR.utf8
# kw_GB
# kw_GB.utf8
# ky_KG
# lg_UG
# lg_UG.utf8
# li_BE
# li_NL
# lo_LA
# lt_LT
# lt_LT.utf8
# lv_LV
# lv_LV.utf8
# mai_IN
# mg_MG
# mg_MG.utf8
# mi_NZ
# mi_NZ.utf8
# mk_MK
# mk_MK.utf8
# ml_IN
# mn_MN
# mr_IN
# ms_MY
# ms_MY.utf8
# mt_MT
# mt_MT.utf8
# my_MM
# nan_TW@latin
# nb_NO
# nb_NO.utf8
# nds_DE
# nds_NL
# ne_NP
# nl_AW
# nl_BE
# nl_BE.utf8
# nl_BE@euro
# nl_NL
# nl_NL.utf8
# nl_NL@euro
# nn_NO
# nn_NO.utf8
# nr_ZA
# nso_ZA
# oc_FR
# oc_FR.utf8
# om_ET
# om_KE
# om_KE.utf8
# or_IN
# pa_IN
# pa_PK
# pap_AN
# pl_PL
# pl_PL.utf8
# ps_AF
# pt_BR
# pt_BR.utf8
# pt_PT
# pt_PT.utf8
# pt_PT@euro
# ro_RO
# ro_RO.utf8
# ru_RU
# ru_RU.cp1251
# ru_RU.koi8r
# ru_RU.utf8
# ru_UA
# ru_UA.utf8
# rw_RW
# sa_IN
# sc_IT
# sd_IN
# sd_IN@devanagari
# se_NO
# shs_CA
# si_LK
# sid_ET
# sk_SK
# sk_SK.utf8
# sl_SI
# sl_SI.utf8
# so_DJ
# so_DJ.utf8
# so_ET
# so_KE
# so_KE.utf8
# so_SO
# so_SO.utf8
# sq_AL
# sq_AL.utf8
# sq_MK
# sr_ME
# sr_RS
# sr_RS@latin
# ss_ZA
# st_ZA
# st_ZA.utf8
# sv_FI
# sv_FI.utf8
# sv_FI@euro
# sv_SE
# sv_SE.utf8
# ta_IN
# te_IN
# tg_TJ
# tg_TJ.utf8
# th_TH
# th_TH.utf8
# ti_ER
# ti_ET
# tig_ER
# tk_TM
# tl_PH
# tl_PH.utf8
# tn_ZA
# tr_CY
# tr_CY.utf8
# tr_TR
# tr_TR.utf8
# ts_ZA
# tt_RU.utf8
# tt_RU.utf8@iqtelif
# ug_CN
# uk_UA
# uk_UA.utf8
# ur_PK
# uz_UZ
# uz_UZ@cyrillic
# ve_ZA
# vi_VN
# vi_VN.tcvn
# wa_BE
# wa_BE.utf8
# wa_BE@euro
# wo_SN
# xh_ZA
# xh_ZA.utf8
# yi_US
# yi_US.utf8
# yo_NG
# zh_CN
# zh_CN.gb18030
# zh_CN.gbk
# zh_CN.utf8
# zh_HK
# zh_HK.utf8
# zh_SG
# zh_SG.gbk
# zh_SG.utf8
# zh_TW
# zh_TW.euctw
# zh_TW.utf8
# zu_ZA
# zu_ZA.utf8

##
# Windows map
##

# 			Afrikaans						1078
# 			Albanian						1052
# 			Arabic (Algeria)				5121
# 			Arabic (Bahrain)				15361
# 			Arabic (Egypt)					3073
# 			Arabic (Iraq)					2049
# 			Arabic (Jordan)					11265
# 			Arabic (Kuwait)					13313
# 			Arabic (Lebanon)				12289
# 			Arabic (Libya)					4097
# 			Arabic (Morocco)				614
# 			Arabic (Oman)					8193
# 			Arabic (Qatar)					16385
# 			Arabic (Saudi Arabia)			1025
# 			Arabic (Syria)					10241
# 			Arabic (Tunisia)				7169
# 			Arabic (U.A.E.)					14337
# 			Arabic (Yemen)					9217
# 			Basque							1069
# 			Belarusian						1059
# 			Bulgarian						1026
# 			Catalan							1027
# 			Chinese (Hong Kong SAR)			3076
# 			Chinese (PRC)					2052
# 			Chinese (Singapore)				4100
# 			Chinese (Taiwan)				1028
# 			Croatian						1050
# 			Czech							1029
# 			Danish							1030
# 			Dutch							1043
# 			Dutch (Belgium)					2067
# 			English (Australia)				3081
# 			English (Belize)				10249
# 			English (Canada)				4105
# 			English (Ireland)				6153
# 			English (Jamaica)				8201
# 			English (New Zealand)			5129
# 			English (South Africa)			7177
# 			English (Trinidad)				11273
# 			English (United Kingdom)		2057
# 			English (United States)			1033
# 			Estonian						1061
# 			Faeroese						1080
# 			Farsi							1065
# 			Finnish							1035
# 			French (Standard)				1036
# 			French (Belgium)				2060
# 			French (Canada)					3084
# 			French (Luxembourg)				5132
# 			French (Switzerland)			4108
# 			Gaelic (Scotland)				1084
# 			German (Standard)				1031
# 			German (Austrian)				3079
# 			German (Liechtenstein)			5127
# 			German (Luxembourg)				4103
# 			German (Switzerland)			2055
# 			Greek							1032
# 			Hebrew							1037
# 			Hindi							1081
# 			Hungarian						1038
# 			Icelandic						1039
# 			Indonesian						1057
# 			Italian (Standard)				1040
# 			Italian (Switzerland)			2064
# 			Japanese						1041
# 			Korean							1042
# 			Latvian							1062
# 			Lithuanian						1063
# 			Macedonian (FYROM)				1071
# 			Malay (Malaysia)				1086
# 			Maltese							1082
# 			Norwegian (Bokmål)				1044
# 			Polish							1045
# 			Portuguese (Brazil)				1046
# 			Portuguese (Portugal)			2070
# 			Raeto (Romance)					1047
# 			Romanian						1048
# 			Romanian (Moldova)				2072
# 			Russian							1049
# 			Russian (Moldova)				2073
# 			Serbian (Cyrillic)				3098
# 			Setsuana						1074
# 			Slovak							1051
# 			Slovenian						1060
# 			Sorbian							1070
# 			Spanish (Argentina)				11274
# 			Spanish (Bolivia)				16394
# 			Spanish (Chile)					13322
# 			Spanish (Columbia)				9226
# 			Spanish (Costa Rica)			5130
# 			Spanish (Dominican Republic)	7178
# 			Spanish (Ecuador)				12298
# 			Spanish (El Salvador)			17418
# 			Spanish (Guatemala)				4106
# 			Spanish (Honduras)				18442
# 			Spanish (Mexico)				2058
# 			Spanish (Nicaragua)				19466
# 			Spanish (Panama)				6154
# 			Spanish (Paraguay)				15370
# 			Spanish (Peru)					10250
# 			Spanish (Puerto Rico)			20490
# 			Spanish (Spain)					1034
# 			Spanish (Uruguay)				14346
# 			Spanish (Venezuela)				8202
# 			Sutu							1072
# 			Swedish							1053
# 			Swedish (Finland)				2077
# 			Thai							1054
# 			Turkish							1055
# 			Tsonga							1073
# 			Ukranian						1058
# 			Urdu (Pakistan)					1056
# 			Vietnamese						1066
# 			Xhosa							1076
# 			Yiddish							1085
# 			Zulu							1077
