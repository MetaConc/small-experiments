-module(ping_pong).
-export([play/0]).

play() ->
  Ping = spawn(fun ping/0),
    spawn(fun() -> pong(Ping) end).

    ping() ->
    receive
      pong -> ok
    end.

    pong(Ping) ->
      Ping ! pong,
      receive
        ping -> ok
      end.
