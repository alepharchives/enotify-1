-module(enotify).
-export([start/0, start/1, stop/0, init/1]).
-export([add_watch/0, echo1/1, echo2/1, echo3/1, add_watch/3, remove_watch/1, foo/1, bar/1]).

start() ->
    ExtPrg =
	"priv/win32/executable/enotify" ++
	case os:type() of
	    {win32,nt} -> ".exe";
	    win32 -> ".exe"
			 ; _ -> ""
	end,
    start(ExtPrg).

start(ExtPrg) ->
    spawn(?MODULE, init, [ExtPrg]).

stop() ->
    ?MODULE ! stop.

foo(X) ->
    call_port({foo, X}).
bar(Y) ->
    call_port({bar, Y}).

add_watch() ->
    call_port({watch_dir, "c:/Davide Marqu�s", 7, 1}).

add_watch(Dir, NotifyFilter, WatchSubdir) ->
    call_port({add_watch, Dir, NotifyFilter, WatchSubdir}).

remove_watch(WatchID) ->
    call_port({add_watch, WatchID}).

echo1(Dir) ->
    call_port({echo1, Dir}).

echo2(Dir) ->
    Bin = unicode:characters_to_binary(Dir),
    call_port({echo2, Bin}).

echo3(Dir) ->
    DirUTF16 = unicode:characters_to_binary(Dir, utf8, {utf16,little}),
    call_port({echo3, DirUTF16}).


call_port(Msg) ->
    ?MODULE ! {call, self(), Msg},
    receive
        {?MODULE, Result} ->
            Result
    end.

init(ExtPrg) ->
    register(?MODULE, self()),
    process_flag(trap_exit, true),
    Port = open_port({spawn, ExtPrg}, [{packet, 2}, binary, exit_status]),
%    loop(Port) % DEV-MODE
    try loop(Port)
    catch
	T:Err ->
	    error_logger:error_msg("catch: ~p:~p~n", [T, Err])
    end.

loop(Port) ->
    receive
        {call, Caller, Msg} ->
	    Binary = term_to_binary(Msg),
	    io:format("Sending to port:~n~p~n~p~n", [Msg, Binary]),
	    erlang:port_command(Port, Binary),
	    receive
		{Port, {data, Data}} ->
		    Caller ! {?MODULE, binary_to_term(Data)};
		{Port, {exit_status, Status}} when Status > 128 ->
		    exit({port_terminated, Status});
		{Port, {exit_status, Status}} ->
		    exit({port_terminated, Status});
		{'EXIT', Port, Reason} ->
		    exit(Reason);
		%%   following two lines used for development and testing only
		Other ->
		    io:format("received: ~p~n", [Other])
	    after 5000 ->
		    io:format("got no reply in 5 seconds...~n"),
		    loop(Port)
	    end,
            loop(Port);
        stop ->
            erlang:port_close(Port),
            exit(normal);
        {'EXIT', Port, _Reason} ->
            exit(port_terminated);
	{Port, {data, Data}} ->
	    handle_port_message(binary_to_term(Data)),
	    loop(Port);
	_Other ->
	    io:format("received (unexpected): ~s~n", [_Other]),
	    loop(Port)
    end.

handle_port_message({WatchID, Action, DirUTF16, FileUTF16}) ->
    Dir = unicode:characters_to_binary(DirUTF16, {utf16,little}, utf8),
    io:format("~w~n", [DirUTF16]),
    File = unicode:characters_to_binary(FileUTF16, {utf16,little}, utf8),
    io:format("watchID: ~p, action: ~p, dir: ~ts, file: ~ts~n", [WatchID, Action, Dir, File]);
handle_port_message(Data) ->
 io:format("unknown port message: ~w~n", [Data]).
