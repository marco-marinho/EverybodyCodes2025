-module(libcppnif).
-export([q17_1/0, q17_2/0]).
-nifs([q17_1/0, q17_2/0]).
-on_load(init/0).

init() ->
    ok = erlang:load_nif("priv/libcppnif", 0).

q17_1() ->
    exit(nif_library_not_loaded).

q17_2() ->
    exit(nif_library_not_loaded).
