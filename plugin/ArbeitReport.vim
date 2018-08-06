scriptencoding cp932
command! -nargs=? MkArbeitReport call <SID>MkArbeitReport(<f-args>)

function! s:MkArbeitReport(...) abort

	" アルバイター一覧
	let l:arbeiters = ["山田君", "岡野君"]

	" 初期カーソル
	let l:init_cursol_line_no = 6

	" 次の月曜と金曜を求める {{{
	" 引数から日時を取得
	let l:date_list = split(get(a:,1,""),"/")
	let l:time_len = len(l:date_list)
	if l:time_len == 3
		let l:base_date = <SID>Localtime(l:date_list[0], l:date_list[1], l:date_list[2],0,0,0)
	elseif l:time_len == 2
		let l:month = l:date_list[0]
		let l:day = l:date_list[1]
		let l:year = str2nr(strftime('%Y'))
		let l:now = localtime()
		let l:base_date = <SID>Localtime(l:year, l:month, l:day,0,0,0)

		" " 日付が未来の場合、去年の日付に変更する
		" if l:now < l:base_date
		" 	let l:year = l:year - 1
		" 	let l:base_date = <SID>Localtime(l:year, l:month, l:day,0,0,0)
		" endif

	else
		let l:base_date = localtime()
	endif

	" パース
	let l:year = str2nr(strftime('%Y', l:base_date))
	let l:month = str2nr(strftime('%m', l:base_date))
	let l:day = str2nr(strftime('%d', l:base_date))
	for l:idx in range(7)
		let l:timestamp = <SID>Localtime(l:year, l:month, l:day + l:idx, 0, 0, 0)
		let l:weekday = str2nr(strftime('%w', l:timestamp))
		if 1 == l:weekday
			let l:monday = l:timestamp
			let l:friday = <SID>Localtime(l:year, l:month, l:day + l:idx + 4, 0, 0, 0)
		endif
	endfor

	let l:monday_str = printf("%d/%d", str2nr(strftime('%m', l:monday)), str2nr(strftime('%d', l:monday)))	" 01/10 -> 1/10 に変換
	let l:friday_str = printf("%d/%d", str2nr(strftime('%m', l:friday)), str2nr(strftime('%d', l:friday)))	" 01/10 -> 1/10 に変換
	" }}}

	let l:lines = []

	call add(l:lines, "お疲れ様です。谷川です。")
	call add(l:lines, "")
	call add(l:lines, "2Fのアルバイトの出社予定を報告します。")
	call add(l:lines, "")
	for l:arbeiter in l:arbeiters
		call add(l:lines, l:arbeiter)
		call add(l:lines, "")
	endfor
	call add(l:lines, "以上です。")
	call add(l:lines, "【アルバイト】2Fアルバイト予定 " . l:monday_str . "-" . l:friday_str)

	new
	setlocal bt=nofile
	call append(line('.'), l:lines)
	1 delete _
	call cursor(l:init_cursol_line_no, 1)
	command! -buffer -nargs=* AppendReportLine call <SID>AppendReportLine(<f-args>)
	nmap <buffer> <silent> <C-C> :%y*<CR>
endfunction

function! s:AppendReportLine(...) abort
	let l:date_list = split(get(a:,1,""),"/")
	let l:begin_time = get(a:, 2, "830")
	let l:end_time = get(a:, 3, "1730")

	let l:has_next_engagement = v:true
	let l:time_len = len(l:date_list)
	if l:time_len == 3
		let l:timestamp = <SID>Localtime(l:date_list[0], l:date_list[1], l:date_list[2],0,0,0)
	elseif l:time_len == 2
		let l:month = l:date_list[0]
		let l:day = l:date_list[1]
		let l:year = str2nr(strftime('%Y'))
		let l:now = localtime()
		let l:timestamp = <SID>Localtime(l:year, l:month, l:day,0,0,0)

		" 日付が過去の場合、来年の日付に変更する
		if l:timestamp < l:now
			let l:year = l:year + 1
			let l:timestamp = <SID>Localtime(l:year, l:month, l:day,0,0,0)
		endif

	else
		" " 入力がない場合、今日の日付とする
		" let l:timestamp = localtime()

		" 入力がない場合、来週の予定はなしとする
		let l:has_next_engagement = v:false
	endif

	if l:has_next_engagement
		" 来週の予定あり
		let l:month = str2nr(strftime('%m', l:timestamp))
		let l:day = str2nr(strftime('%d', l:timestamp))
		let l:weekday = strftime('%a', l:timestamp)

		let l:line = l:month ."/". l:day ."(". l:weekday .")　". <SID>ParseTime(l:begin_time) ."-". <SID>ParseTime(l:end_time)
	else
		" 来週の予定なし
		let l:line = "来週の出社予定はありません。"
	endif
	call append( line('.')-1, l:line )
endfunction

function! s:ParseTime(time) abort
	let l:hour = a:time[:-3]
	let l:min = a:time[-2:]
	return printf("%d:%02d", l:hour, l:min)
endfunction

function! s:Localtime(year, month, day, hour, minute, second)
	" days from 0000/01/01
	let l:year  = a:month < 3 ? a:year - 1   : a:year
	let l:month = a:month < 3 ? 12 + a:month : a:month
	let l:days = 365*l:year + l:year/4 - l:year/100 + l:year/400 + 306*(l:month+1)/10 + a:day - 428

	" days from 0000/01/01 to 1970/01/01
	" 1970/01/01 == 1969/13/01
	let l:ybase = 1969
	let l:mbase = 13
	let l:dbase = 1
	let l:basedays = 365*l:ybase + l:ybase/4 - l:ybase/100 + l:ybase/400 + 306*(l:mbase+1)/10 + l:dbase - 428

	" seconds from 1970/01/01
	return (l:days-l:basedays)*86400 + (a:hour-9)*3600 + a:minute*60 + a:second
endfunction

" vim: fdm=marker
