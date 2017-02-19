-module(ping_pong).
-export([play/0]).

play() ->
  Ping = spawn(fun ping/0),
  Pong = spawn(fun pong/0),
  Pong ! {ping, Ping}.


ping() ->
  Ping = self(),
  receive
    {pong, Pong} ->
      io:format("pong~n"),
      Pong ! {ping,Ping },
      ping()
  end.

pong() ->
  Pong = self(),
  receive
    {ping, Ping} ->
        io:format("ping~n"),
        Ping ! { pong, Pong},
        pong()
  end.
