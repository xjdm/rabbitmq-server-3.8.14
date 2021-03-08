%% This Source Code Form is subject to the terms of the Mozilla Public
%% License, v. 2.0. If a copy of the MPL was not distributed with this
%% file, You can obtain one at https://mozilla.org/MPL/2.0/.
%%
%% Copyright (c) 2007-2021 VMware, Inc. or its affiliates.  All rights reserved.
%%
-module(unit_cluster_formation_locking_mocks_SUITE).

-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").

-compile(export_all).

all() ->
    [
      {group, non_parallel_tests}
    ].

groups() ->
    [
     {non_parallel_tests, [], [
                               init_with_lock_exits_after_errors,
                               init_with_lock_ignore_after_errors,
                               init_with_lock_not_supported,
                               init_with_lock_supported
                              ]}
    ].

init_per_testcase(Testcase, Config) when Testcase == init_with_lock_exits_after_errors;
                                         Testcase == init_with_lock_not_supported;
                                         Testcase == init_with_lock_supported ->
    application:set_env(rabbit, cluster_formation,
                        [{peer_discover_backend, peer_discover_classic_config},
                         {lock_acquisition_failure_mode, fail}]),
    ok = meck:new(rabbit_peer_discovery_classic_config, [passthrough]),
    Config;
init_per_testcase(init_with_lock_ignore_after_errors, Config) ->
    application:set_env(rabbit, cluster_formation,
                        [{peer_discover_backend, peer_discover_classic_config},
                         {lock_acquisition_failure_mode, ignore}]),
    ok = meck:new(rabbit_peer_discovery_classic_config, [passthrough]),
    Config.

end_per_testcase(_, _) ->
    meck:unload(),
    application:unset_env(rabbit, cluster_formation).

init_with_lock_exits_after_errors(_Config) ->
    meck:expect(rabbit_peer_discovery_classic_config, lock, fun(_) -> {error, "test error"} end),
    ?assertExit(cannot_acquire_startup_lock, rabbit_mnesia:init_with_lock(2, 10, fun() -> ok end)),
    ?assert(meck:validate(rabbit_peer_discovery_classic_config)),
    passed.

init_with_lock_ignore_after_errors(_Config) ->
    meck:expect(rabbit_peer_discovery_classic_config, lock, fun(_) -> {error, "test error"} end),
    ?assertEqual(ok, rabbit_mnesia:init_with_lock(2, 10, fun() -> ok end)),
    ?assert(meck:validate(rabbit_peer_discovery_classic_config)),
    passed.

init_with_lock_not_supported(_Config) ->
    meck:expect(rabbit_peer_discovery_classic_config, lock, fun(_) -> not_supported end),
    ?assertEqual(ok, rabbit_mnesia:init_with_lock(2, 10, fun() -> ok end)),
    ?assert(meck:validate(rabbit_peer_discovery_classic_config)),
    passed.

init_with_lock_supported(_Config) ->
    meck:expect(rabbit_peer_discovery_classic_config, lock, fun(_) -> {ok, data} end),
    meck:expect(rabbit_peer_discovery_classic_config, unlock, fun(data) -> ok end),
    ?assertEqual(ok, rabbit_mnesia:init_with_lock(2, 10, fun() -> ok end)),
    ?assert(meck:validate(rabbit_peer_discovery_classic_config)),
    passed.
