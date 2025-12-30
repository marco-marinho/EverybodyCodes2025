-module(librs).
-export([rato/0]).
-nifs([rato/0]).
-on_load(init/0).

init() ->
    ok = erlang:load_nif("priv/librslib", 0).

rato() ->
    exit(nif_library_not_loaded).