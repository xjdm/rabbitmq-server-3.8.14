%% This Source Code Form is subject to the terms of the Mozilla Public
%% License, v. 2.0. If a copy of the MPL was not distributed with this
%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%
%% Copyright (c) 2007-2021 VMware, Inc. or its affiliates.  All rights reserved.
%%

-module(sup_delayed_restart_SUITE).

-behaviour(supervisor2).

-include_lib("common_test/include/ct.hrl").

-compile(export_all).

all() ->
    [
      delayed_restart
    ].

%%----------------------------------------------------------------------------
%% Public API
%%----------------------------------------------------------------------------

delayed_restart(_Config) ->
    passed = with_sup(simple_one_for_one,
                      fun (SupPid) ->
                              {ok, _ChildPid} =
                                  supervisor2:start_child(SupPid, []),
                              test_supervisor_delayed_restart(SupPid)
                      end),
    passed = with_sup(one_for_one, fun test_supervisor_delayed_restart/1).

test_supervisor_delayed_restart(SupPid) ->
    ok = ping_child(SupPid),
    ok = exit_child(SupPid),
    timer:sleep(100),
    ok = ping_child(SupPid),
    ok = exit_child(SupPid),
    timer:sleep(100),
    timeout = ping_child(SupPid),
    timer:sleep(1010),
    ok = ping_child(SupPid),
    passed.

with_sup(RestartStrategy, Fun) ->
    {ok, SupPid} = supervisor2:start_link(?MODULE, [RestartStrategy]),
    Res = Fun(SupPid),
    unlink(SupPid),
    exit(SupPid, shutdown),
    Res.

init([RestartStrategy]) ->
    {ok, {{RestartStrategy, 1, 1},
          [{test, {?MODULE, start_child, []}, {permanent, 1},
            16#ffffffff, worker, [?MODULE]}]}}.

start_child() ->
    {ok, proc_lib:spawn_link(fun run_child/0)}.

ping_child(SupPid) ->
    Ref = make_ref(),
    with_child_pid(SupPid, fun(ChildPid) -> ChildPid ! {ping, Ref, self()} end),
    receive {pong, Ref} -> ok
    after 1000          -> timeout
    end.

exit_child(SupPid) ->
    with_child_pid(SupPid, fun(ChildPid) -> exit(ChildPid, abnormal) end),
    ok.

with_child_pid(SupPid, Fun) ->
    case supervisor2:which_children(SupPid) of
        [{_Id, undefined, worker, [?MODULE]}] -> ok;
        [{_Id, restarting, worker, [?MODULE]}] -> ok;
        [{_Id,  ChildPid, worker, [?MODULE]}] -> Fun(ChildPid);
        []                                     -> ok
    end.

run_child() ->
    receive {ping, Ref, Pid} -> Pid ! {pong, Ref},
                                run_child()
    end.
