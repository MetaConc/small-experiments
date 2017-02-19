-module(concdb_inc).
-export([main/0]).

main() ->
   DB = spawn(fun()->dataBase(#{})end),
   spawnmany(fun()->client(DB) end).

spawnmany(F) ->
   spawn(F),
   case any_bool() of
       false -> ok;
       true -> spawnmany(F)
   end.

dataBase(M) ->
   receive
       {allocate,Key,P} ->
           case lookup(Key,M) of
               fail ->
                   P!free,
                   print(lookupfail),
                   dataBase(M);
                   % to avoid memory inconsistencies comment previous line and from 38 to 42
                   % uncomment from 25 to 30
                   % receive
                   %     {value,Key,V} ->
                   %        printvar(Key, V),
                   %           printmap(maps:put(Key,V, M)),
                   %           dataBase(maps:put(Key,V, M))
                   %  end;
               succ ->
                   P!allocated,
                   dataBase(M)
           end;
       {lookup,Key,P} ->
           P!lookup(Key,M),
           dataBase(M);
       {value,Key,V} ->
          printvar(Key, V),
          printmap(maps:put(Key,V, M)),
          dataBase(maps:put(Key,V, M))
   end.

lookup(K,M) ->
   case maps:find(K,M) of
       error -> fail;
       _V     -> succ
   end.

client(DB) ->
   case read() of
       {ok,i} ->
           K = readKey(),
           DB!{allocate,K,self()},
           receive
               free ->
                   V = readVal(),
                   print(client_writes),
                   DB!{value,K,V},
                   client(DB);
               allocated ->
                   print(client_denied),
                   client(DB)
           end;
       {ok,l} ->
           K = readKey(),
           DB!{lookup,K,self()},
           receive
               fail -> print(client_fail),client_not_found(DB, K);
               {succ,V} -> print(client_reads), client_found(DB, K, V)
           end,
           client(DB)
   end.

client_found(DB,_,_) -> client(DB).
client_not_found(DB,_) -> client(DB).

read() ->
  N1 = rand:uniform(5),
  case N1 =< 3 of
   true -> {ok,i};
   _false -> {ok,l}
  end.

readVal() ->
  rand:uniform(10).

readKey() ->
  rand:uniform(2).

any_bool() ->
  case rand:uniform(5) < 4 of
    true -> true;
    _false -> false
   end.

print(Text) ->
  io:nl(),
  io:format(Text),
  io:nl().

printmap(M) ->
    print("--map values"),
    maps:fold(
  	fun(K, V, ok) ->
  		io:format("~p: ~p~n", [K, V])
  	end, ok, M).

printvar(Var1, Var2) ->
  print("--var values"),
  erlang:display(Var1),
  erlang:display(Var2).
