-module(librs).
-export([quest10_1/0, quest12_1/0, quest12_2/0]).
-nifs([quest10_1/0, quest12_1/0, quest12_2/0]).
-on_load(init/0).

init() ->
    ok = erlang:load_nif("priv/librslib", 0).

quest10_1() ->
    exit(nif_library_not_loaded).

quest12_1() ->
    exit(nif_library_not_loaded).

quest12_2() ->
    exit(nif_library_not_loaded).